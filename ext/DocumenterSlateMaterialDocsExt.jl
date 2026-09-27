# MaterialDocs: its own writer, which renders a page by printing into `ctx.io` rather than through
# Documenter's HTMLWriter, and keeps a `Documenter.HTML` in `fmt.html` whose assets go into <head>.
module DocumenterSlateMaterialDocsExt

using DocumenterSlate: DocumenterSlate, SlateCellBlock, slate_cell_html
import MaterialDocs

DocumenterSlate.html_settings(fmt::MaterialDocs.Material3) = fmt.html

MaterialDocs.domify(ctx::MaterialDocs.DomifyContext, node, b::SlateCellBlock) =
    print(ctx.io, slate_cell_html(b))

end
