# ── Documenter.HTML ─────────────────────────────────────────────────────────────────────────────
# The runtime is in every page's <head> (`install!` adds it to the format's assets), so a cell is
# just the element. The page does a full load on navigation, so nothing else is needed.

HTMLWriter.domify(::HTMLWriter.DCtx, ::Node, b::SlateCellBlock) =
    HTMLWriter.DOM.Tag(Symbol("#RAW#"))(slate_cell_html(b))
