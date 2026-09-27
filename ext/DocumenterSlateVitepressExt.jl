# DocumenterVitepress: the cell element in the generated markdown, the bundles in `public/`, and two
# additions to `config.mts` — the runtime script in <head>, and `slate-` tags declared as custom
# elements so Vue leaves them to the browser.
module DocumenterSlateVitepressExt

using DocumenterSlate: DocumenterSlate, SlateDocs, SlateCellBlock, slate_cell_html
import DocumenterVitepress
import Documenter

# A raw HTML block on its own lines, which markdown-it passes through and Vue compiles as an element.
function DocumenterVitepress.render(io::IO, ::MIME"text/plain", node::Documenter.MarkdownAST.Node,
                                    b::SlateCellBlock, page, doc; kwargs...)
    print(io, "\n", slate_cell_html(b), "\n\n")
end

DocumenterVitepress.vitepress_assets(p::SlateDocs) = isempty(p.public) ? String[] : [p.public]

DocumenterVitepress.vitepress_config_transform(p::SlateDocs, config::String) =
    isempty(p.loaded) ? config : DocumenterSlate.vitepress_config(config)

end
