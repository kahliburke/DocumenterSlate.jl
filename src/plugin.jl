# ── The plugin: configuration, and the build stages that act on it ─────────────────────────────

"""
    SlateDocs(; notebooks = [], bundles = "slate", stale = :warn, render = :never)

Documenter plugin for Slate notebooks. Pass it to `makedocs(plugins = [...])`.

- `notebooks`: `name => path` pairs (or a `Dict`), the notebook each bundle is rendered from, relative
  to the docs directory. Naming a notebook is what lets the build tell whether its bundle is current.
  A bundle directory with no notebook listed is still usable; it is just never checked.
- `bundles`: where bundles live, relative to the docs directory. Bundle `name` is `<bundles>/<name>/`.
- `stale`: what to do when a bundle was rendered from a different version of its notebook:
  `:warn` (default), `:error` (fail the build, the right setting for CI that must not publish stale
  output), or `:ignore`.
- `render`: re-render bundles during the build, which needs `KaimonSlate` loaded in `make.jl`.
  `:never` (default) uses what is on disk; `:missing` renders only absent bundles; `:stale` also
  re-renders out-of-date ones; `:always` renders every listed notebook.
- `backend`: how a render runs the notebook — see `KaimonSlate.render_doc_bundle`. `:auto` (default)
  uses the Slate hub already running on this machine, or, with none (CI), starts an isolated Kaimon
  host for the build; `:inprocess` runs it inside the docs build with no worker.
- `light`, `dark`: the Slate palettes a rendered bundle uses under the site's light and dark themes.
"""
mutable struct SlateDocs <: Documenter.Plugin
    notebooks::Vector{Pair{String,String}}
    bundles::String
    stale::Symbol
    render::Symbol
    backend::Symbol
    light::String
    dark::String
    # Filled in during a build.
    loaded::Dict{String,Bundle}
    public::String            # a directory whose contents a Vitepress build copies into `public/`
end

function SlateDocs(; notebooks = Pair{String,String}[], bundles::AbstractString = "slate",
                   stale::Symbol = :warn, render::Symbol = :never, backend::Symbol = :auto,
                   light::AbstractString = "daylight", dark::AbstractString = "midnight")
    stale in (:warn, :error, :ignore) || throw(ArgumentError("stale must be :warn, :error or :ignore"))
    render in (:never, :missing, :stale, :always) ||
        throw(ArgumentError("render must be :never, :missing, :stale or :always"))
    nbs = Pair{String,String}[String(k) => String(v) for (k, v) in notebooks]
    return SlateDocs(nbs, String(bundles), stale, render, backend, String(light), String(dark),
                     Dict{String,Bundle}(), "")
end

"""
    RENDERER

Set by the KaimonSlate package extension to a function `(notebook, outdir; backend, light, dark)`
that renders one notebook into a bundle. `nothing` when KaimonSlate is not loaded.
"""
const RENDERER = Ref{Any}(nothing)

plugin(doc::Documenter.Document) = Documenter.getplugin(doc, SlateDocs)

bundles_dir(doc, p::SlateDocs) = normpath(joinpath(doc.user.root, p.bundles))

is_vitepress(fmt) = nameof(typeof(fmt)) === :MarkdownVitepress
html_format(doc) = (i = findfirst(f -> f isa Documenter.HTML, doc.user.format); i === nothing ? nothing : doc.user.format[i])

# ── Stage 1: find bundles, check them, render what was asked for, install them into the build ──

abstract type SlatePrepare <: Builder.DocumentPipeline end
Selectors.order(::Type{SlatePrepare}) = 1.05          # after SetupBuildDirectory, before anything reads pages

function Selectors.runner(::Type{SlatePrepare}, doc::Documenter.Document)
    p = plugin(doc)
    root = bundles_dir(doc, p)
    empty!(p.loaded)
    for (name, nbrel) in p.notebooks
        nb = normpath(joinpath(doc.user.root, nbrel))
        isfile(nb) || error("SlateDocs: notebook '$name' not found at $nb")
        dir = joinpath(root, name)
        have = isfile(joinpath(dir, MANIFEST))
        stale = have && bundle_key(load_bundle(name, dir)) != notebook_key(nb)
        want = p.render === :always || (p.render in (:missing, :stale) && !have) ||
               (p.render === :stale && stale)
        if want
            RENDERER[] === nothing &&
                error("SlateDocs(render = :$(p.render)) needs KaimonSlate: add `using KaimonSlate` to make.jl")
            @info "SlateDocs: rendering '$name'" notebook = nb
            RENDERER[](nb, dir; backend = p.backend, light = p.light, dark = p.dark)
            stale = false
        elseif !have
            error("SlateDocs: no bundle for '$name' at $dir. Render it with KaimonSlate " *
                  "(`KaimonSlate.render_doc_bundle`), or build with `SlateDocs(render = :missing)`.")
        end
        if stale && p.stale !== :ignore
            msg = "SlateDocs: the bundle for '$name' was rendered from a different version of $nbrel. " *
                  "Re-render it, or build with `SlateDocs(render = :stale)`."
            p.stale === :error ? error(msg) : @warn(msg)
        end
    end
    if isdir(root)
        for name in readdir(root)
            dir = joinpath(root, name)
            isfile(joinpath(dir, MANIFEST)) && (p.loaded[name] = load_bundle(name, dir))
        end
    end
    isempty(p.loaded) && return
    install!(doc, p)
end

# The runtime every page loads. Bundles each carry the runtime they were rendered with; the site gets
# the one from the newest schema, most recently rendered.
function site_runtime(p::SlateDocs)
    best = argmax(b -> (Int(get(b.manifest, "schema", 0)), String(get(get(b.manifest, "rendered", Dict()), "at", ""))),
                  collect(values(p.loaded)))
    return runtime_file(best)
end

# Copy every bundle to `<site>/slate/<name>/` and the runtime to `<site>/slate/runtime/`, which is
# where `<slate-cell bundle=…>` resolves them from.
function install!(doc, p::SlateDocs)
    function fill!(dest)
        isdir(dest) && rm(dest; recursive = true, force = true)
        mkpath(dest)
        for (name, b) in p.loaded
            cp(b.dir, joinpath(dest, name); force = true)
        end
        mkpath(joinpath(dest, "runtime"))
        cp(site_runtime(p), joinpath(dest, "runtime", "slate-embed.js"); force = true)
    end
    if any(is_vitepress, doc.user.format)
        # Vitepress serves `public/` at the site root; its build copies this directory's contents
        # there (`vitepress_assets` in the extension).
        # Outside `build/`: DocumenterVitepress moves everything there into its markdown directory
        # before it copies plugin assets, so a staging directory inside it is gone by then.
        p.public = mktempdir(; prefix = "slatedocs-public-")
        fill!(joinpath(p.public, "slate"))
    end
    html = html_format(doc)
    if html !== nothing
        fill!(joinpath(doc.user.build, "slate"))
        uri = "slate/runtime/slate-embed.js"
        any(a -> a isa HTMLWriter.HTMLAsset && a.uri == uri, html.assets) ||
            push!(html.assets, Documenter.asset(uri; class = :js, islocal = true))
    end
    return nothing
end

function bundle(doc, name::AbstractString)
    p = plugin(doc)
    b = get(p.loaded, String(name), nothing)
    b === nothing && error("@slate: no bundle named '$name' (looked in $(bundles_dir(doc, p)))")
    return b
end
