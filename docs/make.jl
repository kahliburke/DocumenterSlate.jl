using Documenter, DocumenterVitepress, DocumenterSlate

# DOCS_FORMAT=html builds with Documenter's own HTML writer instead of Vitepress, to check both.
const HTML_WRITER = get(ENV, "DOCS_FORMAT", "vitepress") == "html"
const CI = get(ENV, "CI", "false") == "true"
const REPO = "github.com/kahliburke/DocumenterSlate.jl"

format = HTML_WRITER ?
    Documenter.HTML(; prettyurls = CI, inventory_version = pkgversion(DocumenterSlate)) :
    MarkdownVitepress(; repo = REPO, devbranch = "main", devurl = "dev")

makedocs(;
    sitename = "DocumenterSlate",
    repo = Remotes.GitHub("kahliburke", "DocumenterSlate.jl"),
    modules = [DocumenterSlate],
    checkdocs = :exports,
    format,
    pages = ["Home" => "index.md", "A damped oscillator" => "oscillator.md", "Reference" => "reference.md"],
    # Bundles are rendered by the author and committed. CI builds from them and fails if one no
    # longer matches its notebook, rather than publishing output the notebook no longer produces.
    plugins = [SlateDocs(notebooks = ["oscillator" => "notebooks/oscillator.jl"],
                         stale = CI ? :error : :warn)],
)

if CI
    HTML_WRITER ?
        deploydocs(; repo = REPO, devbranch = "main", push_preview = true) :
        DocumenterVitepress.deploydocs(; repo = REPO, target = joinpath(@__DIR__, "build"),
                                       branch = "gh-pages", devbranch = "main", push_preview = true)
end
