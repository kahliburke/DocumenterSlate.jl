using Documenter, DocumenterSlate

# DOCS_FORMAT=html builds with Documenter's own HTML writer; the default is Vitepress.
const FORMAT = get(ENV, "DOCS_FORMAT", "vitepress")

if FORMAT == "vitepress"
    using DocumenterVitepress
end

format = FORMAT == "html" ?
    Documenter.HTML(; prettyurls = get(ENV, "CI", "false") == "true") :
    DocumenterVitepress.MarkdownVitepress(; repo = "github.com/kahliburke/DocumenterSlate.jl",
                                          devbranch = "main", devurl = "dev")

makedocs(;
    sitename = "DocumenterSlate",
    # Source links need a commit to point at; a local build before the first one goes without.
    (get(ENV, "CI", "false") == "true" ? (; repo = Remotes.GitHub("kahliburke", "DocumenterSlate.jl")) :
                                         (; remotes = nothing))...,
    modules = [DocumenterSlate],
    format,
    pages = ["Home" => "index.md", "A damped oscillator" => "oscillator.md"],
    # Bundles are rendered by the author and committed. CI builds from them and fails if one no
    # longer matches its notebook, rather than publishing output the notebook no longer produces.
    plugins = [SlateDocs(notebooks = ["oscillator" => "notebooks/oscillator.jl"],
                         stale = get(ENV, "CI", "false") == "true" ? :error : :warn)],
    warnonly = [:missing_docs],
)

FORMAT == "vitepress" && get(ENV, "CI", "false") == "true" &&
    DocumenterVitepress.deploydocs(; repo = "github.com/kahliburke/DocumenterSlate.jl",
                                   target = joinpath(@__DIR__, "build"), branch = "gh-pages",
                                   devbranch = "main", push_preview = true)
