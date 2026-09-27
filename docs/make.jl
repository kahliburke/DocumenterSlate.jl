using Documenter, DocumenterSlate

# The same site, built by different writers and published side by side (see `styles.md`):
#   vitepress  DocumenterVitepress                                        → /
#   html       Documenter's HTML writer + DocumenterLandingPage + DocumenterCodeBlocks → /html/
#   material   MaterialDocs + DocumenterLandingPage                       → /material/
const FLAVOR = get(ENV, "DOCS_FLAVOR", "vitepress")
const CI = get(ENV, "CI", "false") == "true"
const REPO = "github.com/kahliburke/DocumenterSlate.jl"

FLAVOR in ("vitepress", "html", "material") || error("DOCS_FLAVOR must be vitepress, html or material")

# Bundles are a build product (git-ignored): each build renders a notebook whose bundle is missing
# or older than the notebook, through the Slate hub on this machine or, in CI, a Kaimon host it starts.
slate = SlateDocs()

if FLAVOR == "vitepress"
    using DocumenterVitepress
    format = MarkdownVitepress(; repo = REPO, devbranch = "main", devurl = "dev")
    plugins = [slate]
elseif FLAVOR == "html"
    using DocumenterLandingPage, DocumenterCodeBlocks
    format = Documenter.HTML(; prettyurls = CI, edit_link = "main",
                             inventory_version = pkgversion(DocumenterSlate))
    plugins = [LandingPage(), CodeBlocks(), slate]
else
    using DocumenterLandingPage, MaterialDocs
    format = Material3(; prettyurls = CI, edit_link = "main", dark_mode = :toggle,
                       inventory_version = pkgversion(DocumenterSlate))
    plugins = [LandingPage(), slate]
end

build = FLAVOR == "vitepress" ? "build" : "build-$FLAVOR"

makedocs(;
    sitename = "DocumenterSlate",
    repo = Remotes.GitHub("kahliburke", "DocumenterSlate.jl"),
    modules = [DocumenterSlate],
    checkdocs = :exports,
    format, plugins, build,
    pages = ["Home" => "index.md", "Guide" => "guide.md",
             "Notebooks" => ["A damped oscillator" => "oscillator.md", "Resonance" => "resonance.md"],
             "Styles" => "styles.md", "Reference" => "reference.md"],
)

if CI
    FLAVOR == "vitepress" ?
        DocumenterVitepress.deploydocs(; repo = REPO, target = joinpath(@__DIR__, build),
                                       branch = "gh-pages", devbranch = "main", push_preview = true) :
        deploydocs(; repo = REPO, target = build, dirname = FLAVOR, devbranch = "main", push_preview = true)
end
