using Test
using Documenter
using DocumenterSlate
import JSON

const DS = DocumenterSlate

# A bundle as KaimonSlate writes it, reduced to what this package reads.
function write_bundle(dir; key = "", schema = 1)
    mkpath(joinpath(dir, "cells")); mkpath(joinpath(dir, "runtime"))
    cells = [
        Dict("id" => "intro", "kind" => "markdown", "tags" => String[], "native" => true, "output" => true,
             "markdown" => "# Springs\n\nA paragraph with ``x^2`` in it.\n\n## Results\n"),
        Dict("id" => "setup", "kind" => "code", "tags" => String[], "source" => "k = 3", "hidecode" => false,
             "output" => false),
        Dict("id" => "plot", "kind" => "code", "tags" => String[], "source" => "echart(k)", "hidecode" => false,
             "output" => true, "file" => "cells/plot.json"),
        Dict("id" => "cite", "kind" => "markdown", "tags" => String[], "native" => false, "output" => true,
             "markdown" => "See [@ref].", "file" => "cells/cite.json"),
        Dict("id" => "secret", "kind" => "code", "tags" => ["nodocs"], "source" => "hidden()", "output" => true,
             "file" => "cells/secret.json"),
    ]
    for c in cells
        haskey(c, "file") && write(joinpath(dir, c["file"]), JSON.json(Dict("id" => c["id"], "html" => "<p>x</p>", "charts" => [])))
    end
    write(joinpath(dir, "runtime", "slate-embed.js"), "/* runtime */")
    man = Dict("schema" => schema, "key" => key, "notebook" => Dict("title" => "Springs"),
               "rendered" => Dict("at" => "2026-01-01T00:00:00Z"), "runtime" => "runtime/slate-embed.js",
               "cells" => cells)
    write(joinpath(dir, "slate-bundle.json"), JSON.json(man))
end

# The renderer a build calls, stubbed: it records what it was asked to render and writes a current
# bundle for it, the way KaimonSlate would.
const RENDERED = String[]
DS.RENDERER[] = function (jobs; backend, light, dark)
    for (nb, dir) in jobs
        push!(RENDERED, basename(nb))
        write_bundle(dir; key = DS.notebook_key(nb))
    end
end

# A site whose pages refer to the notebook by FILE. `bundle` is the key of a bundle already on disk
# (`nothing` = the current key, `:none` = no bundle yet).
function site(f; stale = :warn, render = :auto, bundle = nothing, byname = false)
    empty!(RENDERED)
    mktempdir() do root
        src = joinpath(root, "src"); mkpath(src)
        nb = joinpath(root, "springs.jl"); write(nb, "#%% code id=setup\nk = 3\n")
        bundle === :none || write_bundle(joinpath(root, "slate", "springs"); key = something(bundle, DS.notebook_key(nb)))
        ref = byname ? "springs" : "../springs.jl"
        write(joinpath(src, "index.md"), "# Home\n\n```@slate $ref plot\nshow = \"both\"\n```\n")
        write(joinpath(src, "springs.md"), "```@slate $ref\n```\n")
        makedocs(; root, source = "src", build = "build", sitename = "T", remotes = nothing,
                 format = Documenter.HTML(; prettyurls = false), pages = ["index.md", "springs.md"],
                 plugins = [SlateDocs(; stale, render,
                                      notebooks = byname ? ["springs" => "springs.jl"] : Pair{String,String}[])],
                 warnonly = true, doctest = false)
        f(root)
    end
end

@testset "DocumenterSlate" begin
    @testset "a whole notebook becomes page content" begin
        site() do root
            html = read(joinpath(root, "build", "springs.html"), String)
            # prose is the page's own: its headings are real headings, tracked for the TOC
            @test occursin(r"<h1[^>]*>.*Springs"s, html) && occursin(r"<h2[^>]*>.*Results"s, html)
            @test occursin("A paragraph with", html)
            # code as ordinary highlighted blocks; a cell with no output gets none
            @test occursin("k = 3", html) && occursin("echart(k)", html)
            @test occursin("<slate-cell bundle=\"springs\" cell=\"plot\"></slate-cell>", html)
            @test !occursin("cell=\"setup\"", html)
            # prose Slate must render itself is embedded, not dropped
            @test occursin("cell=\"cite\"", html)
            # `nodocs` leaves a cell out entirely
            @test !occursin("hidden()", html) && !occursin("cell=\"secret\"", html)
            # the runtime is on the page and the bundle is in the site
            @test occursin("slate/runtime/slate-embed.js", html)
            @test isfile(joinpath(root, "build", "slate", "springs", "cells", "plot.json"))
            @test isfile(joinpath(root, "build", "slate", "runtime", "slate-embed.js"))
        end
    end

    @testset "one cell, with its source" begin
        site() do root
            html = read(joinpath(root, "build", "index.html"), String)
            @test occursin("echart(k)", html)
            @test occursin("cell=\"plot\"", html)
        end
    end

    @testset "the build renders a notebook it has no current bundle for" begin
        site(_ -> nothing; bundle = :none)
        @test RENDERED == ["springs.jl"]
        site(_ -> nothing; bundle = "not-the-key")
        @test RENDERED == ["springs.jl"]
        site(_ -> nothing)                                   # current: nothing to do
        @test isempty(RENDERED)
        site(_ -> nothing; render = :always)
        @test RENDERED == ["springs.jl"]
    end

    @testset "a page can name a bundle instead of a file" begin
        site(; byname = true) do root
            @test occursin("cell=\"plot\"", read(joinpath(root, "build", "index.html"), String))
        end
    end

    @testset "with render = :never a stale bundle warns, or fails the build" begin
        @test_logs (:warn, r"out of date") match_mode = :any site(_ -> nothing; render = :never, bundle = "not-the-key")
        @test isempty(RENDERED)
        @test_throws Exception site(_ -> nothing; render = :never, bundle = "not-the-key", stale = :error)
        @test_throws Exception site(_ -> nothing; render = :never, bundle = :none)
        logs, _ = Test.collect_test_logs() do
            site(_ -> nothing; render = :never, bundle = "not-the-key", stale = :ignore)
        end
        @test !any(l -> occursin("out of date", string(l.message)), logs)
    end

    @testset "a reference to a missing notebook says which page and path" begin
        mktempdir() do root
            mkpath(joinpath(root, "src"))
            write(joinpath(root, "src", "index.md"), "```@slate ../nope.jl\n```\n")
            err = try
                makedocs(; root, source = "src", build = "build", sitename = "T", remotes = nothing,
                         format = Documenter.HTML(; prettyurls = false), pages = ["index.md"],
                         plugins = [SlateDocs()], doctest = false)
                nothing
            catch e
                e
            end
            @test err !== nothing && occursin("nope.jl", sprint(showerror, err))
        end
    end

    @testset "a bundle from a newer schema is refused" begin
        mktempdir() do d
            write_bundle(d; schema = DS.SCHEMA + 1)
            @test_throws ErrorException DS.load_bundle("x", d)
        end
    end

    @testset "block options" begin
        @test DS.block_options("show = \"both\"\n# a comment\n") == Dict("show" => "both")
        @test_throws ErrorException DS.block_options("nonsense")
    end

    @testset "Vitepress config" begin
        cfg = """
        export default defineConfig({
          base: '/Pkg.jl/dev/',
          head: [
            ['link', { rel: 'icon' }],
          ],
        })
        """
        out = DS.vitepress_config(cfg)
        @test occursin("['script', { src: '/Pkg.jl/dev/slate/runtime/slate-embed.js' }]", out)
        @test occursin("isCustomElement: (tag) => tag.startsWith('slate-')", out)
        @test DS.vitepress_config(out) == out                          # idempotent
        # a config that already configures Vue is left for the author, with a warning saying what to add
        @test_logs (:warn, r"isCustomElement") DS.vitepress_config(replace(cfg, "head:" => "vue: { },\n  head:"))
    end
end
