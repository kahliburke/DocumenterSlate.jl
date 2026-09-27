# ── The plugin: configuration, and the build stages that act on it ─────────────────────────────

"""
    SlateDocs(; render = :auto, stale = :warn, bundles = "slate", notebooks = [], backend = :auto,
              light = "daylight", dark = "midnight")

Documenter plugin for Slate notebooks. Pass it to `makedocs(plugins = [SlateDocs()])`.

A page refers to a notebook by its file, relative to the page like a link:
```` ```@slate ../examples/tour.jl ````. The build keeps each referenced notebook's rendered *bundle*
under `docs/<bundles>/<name>/` (the notebook's file name without `.jl`) and renders it when it is
missing or older than the notebook.

- `render`: `:auto` (default) renders a missing or out-of-date bundle; `:never` uses the bundles on
  disk as they are (commit them, and CI never runs a notebook); `:always` renders every one.
- `stale`: with `render = :never`, what an out-of-date bundle does: `:warn` (default), `:error` (the
  setting for a CI that must not publish output the notebook no longer produces), or `:ignore`.
- `backend`: how a render runs a notebook, see `KaimonSlate.render_doc_bundle`. `:auto` uses the Slate
  hub running on this machine, or, with none (CI), starts an isolated Kaimon host for the build;
  `:inprocess` runs it inside the docs build with no worker (controls export frozen).
- `bundles`: where bundles live, relative to the docs directory.
- `notebooks`: `name => path` pairs (relative to the docs directory) for bundles a page refers to by
  name (```` ```@slate tour ````) rather than by file.
- `light`, `dark`: the Slate palettes a bundle uses under the site's light and dark themes.
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
    sources::Dict{String,String}  # bundle name => notebook file, for every notebook the build knows
    loaded::Dict{String,Bundle}
    public::String                # a directory whose contents a Vitepress build copies into `public/`
end

function SlateDocs(; notebooks = Pair{String,String}[], bundles::AbstractString = "slate",
                   stale::Symbol = :warn, render::Symbol = :auto, backend::Symbol = :auto,
                   light::AbstractString = "daylight", dark::AbstractString = "midnight")
    stale in (:warn, :error, :ignore) || throw(ArgumentError("stale must be :warn, :error or :ignore"))
    render in (:auto, :never, :always) || throw(ArgumentError("render must be :auto, :never or :always"))
    nbs = Pair{String,String}[String(k) => String(v) for (k, v) in notebooks]
    return SlateDocs(nbs, String(bundles), stale, render, backend, String(light), String(dark),
                     Dict{String,String}(), Dict{String,Bundle}(), "")
end

"""
    RENDERER

The function that renders notebooks into bundles: `(jobs; backend, light, dark)` with `jobs` a vector
of `notebook => bundle dir` pairs, all rendered through one host. KaimonSlate's `render_doc_bundles`;
tests put a stub here.
"""
const RENDERER = Ref{Any}(nothing)

plugin(doc::Documenter.Document) = Documenter.getplugin(doc, SlateDocs)

bundles_dir(doc, p::SlateDocs) = normpath(joinpath(doc.user.root, p.bundles))

is_vitepress(fmt) = nameof(typeof(fmt)) === :MarkdownVitepress

"""
    html_settings(format) -> Union{Documenter.HTML, Nothing}

The `Documenter.HTML` settings whose `assets` a writer puts in each page's `<head>`, or `nothing` for a
writer that doesn't produce HTML pages that way. A package extension adds a method for its writer
(MaterialDocs keeps one in `fmt.html`).
"""
html_settings(fmt::Documenter.HTML) = fmt
html_settings(::Any) = nothing

# ── References: what a page's `@slate` block names ────────────────────────────────────────────────

const REF_RE = r"^@slate\s+(\S+)"

isnotebookref(token) = endswith(lowercase(token), ".jl")

page_file(doc, page) = abspath(joinpath(doc.user.root, page.source))

# The notebook file a `.jl` reference names, resolved against the page that holds it.
notebook_file(doc, page, token) = normpath(joinpath(dirname(page_file(doc, page)), token))

"""
    bundle_name(doc, page, token) -> String

The bundle a block's first argument refers to: a notebook file (`…/tour.jl` → `tour`) or a bundle name.
"""
function bundle_name(doc, page, token::AbstractString)
    isnotebookref(token) || return String(token)
    file = notebook_file(doc, page, token)
    for (name, src) in plugin(doc).sources
        src == file && return name
    end
    error("@slate: $token (in $(page.source)) is not a notebook this build knows; is the path right?")
end

# Every `@slate` block in the document as (page, first argument), including blocks nested in
# admonitions and lists.
function slate_refs(doc)
    out = Tuple{Any,String}[]
    for (_, page) in doc.blueprint.pages
        for n in collect_nodes(page.mdast)
            el = n.element
            el isa MarkdownAST.CodeBlock || continue
            m = match(REF_RE, el.info)
            m === nothing || push!(out, (page, String(m.captures[1])))
        end
    end
    return out
end

function collect_nodes(node, out = Node[])
    push!(out, node)
    for ch in node.children
        collect_nodes(ch, out)
    end
    return out
end

# ── Stage 1: find the notebooks, bring their bundles up to date, install them into the build ─────

abstract type SlatePrepare <: Builder.DocumentPipeline end
Selectors.order(::Type{SlatePrepare}) = 1.05          # after SetupBuildDirectory, before anything reads pages

function Selectors.runner(::Type{SlatePrepare}, doc::Documenter.Document)
    p = plugin(doc)
    root = bundles_dir(doc, p)
    empty!(p.sources); empty!(p.loaded)
    for (name, rel) in p.notebooks
        p.sources[name] = normpath(joinpath(doc.user.root, rel))
    end
    for (page, token) in slate_refs(doc)
        isnotebookref(token) || continue
        file = notebook_file(doc, page, token)
        isfile(file) || error("@slate: no notebook at $file (referenced as $token in $(page.source))")
        name = splitext(basename(file))[1]
        prev = get(p.sources, name, nothing)
        prev === nothing || prev == file ||
            error("@slate: two notebooks are both named '$name' ($prev and $file); their bundles " *
                  "would share `$(p.bundles)/$name`. Rename one.")
        p.sources[name] = file
    end
    refresh_bundles!(p, root)
    if isdir(root)
        for name in readdir(root)
            dir = joinpath(root, name)
            isfile(joinpath(dir, MANIFEST)) && (p.loaded[name] = load_bundle(name, dir))
        end
    end
    isempty(p.loaded) || install!(doc, p)
    return nothing
end

# Render what the policy asks for, all through one host, then report anything still out of date.
function refresh_bundles!(p::SlateDocs, root)
    jobs = Pair{String,String}[]
    stale = String[]
    for (name, file) in sort!(collect(p.sources))
        isfile(file) || error("SlateDocs: notebook '$name' not found at $file")
        dir = joinpath(root, name)
        have = isfile(joinpath(dir, MANIFEST))
        current = have && bundle_key(load_bundle(name, dir)) == notebook_key(file)
        if p.render === :always || (p.render === :auto && !current)
            push!(jobs, file => dir)
        elseif !have
            error("SlateDocs: no bundle for '$name' at $dir, and `render = :never`. Render it (Export → " *
                  "Docs in the notebook), or build once with the default `render = :auto`.")
        elseif !current
            push!(stale, name)
        end
    end
    if !isempty(jobs)
        @info "SlateDocs: rendering $(length(jobs)) notebook(s)" notebooks = [basename(f) for (f, _) in jobs]
        RENDERER[](jobs; backend = p.backend, light = p.light, dark = p.dark)
    end
    if !isempty(stale) && p.stale !== :ignore
        msg = "SlateDocs: out of date with their notebooks: $(join(stale, ", ")). Re-render them, or " *
              "build with the default `render = :auto`."
        p.stale === :error ? error(msg) : @warn(msg)
    end
    return nothing
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
        # Outside `build/`: DocumenterVitepress moves everything there into its markdown directory
        # before it copies plugin assets, so a staging directory inside it is gone by then.
        p.public = mktempdir(; prefix = "slatedocs-public-")
        fill!(joinpath(p.public, "slate"))
    end
    htmls = filter(!isnothing, map(html_settings, doc.user.format))
    isempty(htmls) || fill!(joinpath(doc.user.build, "slate"))
    uri = "slate/runtime/slate-embed.js"
    for html in htmls
        # `defer`: the element upgrades whenever the script runs, so nothing waits on it.
        any(a -> a isa HTMLWriter.HTMLAsset && a.uri == uri, html.assets) ||
            push!(html.assets, Documenter.asset(uri; class = :js, islocal = true,
                                                attributes = Dict(:defer => "defer")))
    end
    return nothing
end

function bundle(doc, name::AbstractString)
    p = plugin(doc)
    b = get(p.loaded, String(name), nothing)
    b === nothing && error("@slate: no bundle named '$name' (looked in $(bundles_dir(doc, p)))")
    return b
end
