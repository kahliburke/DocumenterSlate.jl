# ── The `@slate <name> <cell>` block ────────────────────────────────────────────────────────────

"""
    SlateCellBlock

A page node standing for one cell's rendered output. Each writer draws it as a `<slate-cell>`
element; `text` is what search indexes and what a writer with no JavaScript shows.
"""
struct SlateCellBlock <: Documenter.AbstractDocumenterBlock
    codeblock::MarkdownAST.CodeBlock
    bundle::String
    cell::String
    text::String
end

abstract type SlateBlocks <: Expanders.NestedExpanderPipeline end
Selectors.order(::Type{SlateBlocks}) = 7.9
Selectors.matcher(::Type{SlateBlocks}, node, page, doc) = Documenter.iscode(node, r"^@slate\b")

const CELL_RE = r"^@slate\s+(\S+)(?:\s+(\S+))?\s*$"

# `key = value` lines in the block body. Values may be quoted.
function block_options(body::AbstractString)
    opts = Dict{String,String}()
    for line in split(body, '\n')
        s = strip(line)
        (isempty(s) || startswith(s, '#')) && continue
        m = match(r"^(\w+)\s*=\s*\"?([^\"]*)\"?\s*$", s)
        m === nothing && error("@slate: can't read option line `$s` (expected `key = value`)")
        opts[m.captures[1]] = strip(m.captures[2])
    end
    return opts
end

function Selectors.runner(::Type{SlateBlocks}, node, page, doc)
    el = node.element::MarkdownAST.CodeBlock
    m = match(CELL_RE, el.info)
    m === nothing && error("@slate: expected ```@slate <notebook> [<cell>]```, got ```$(el.info)``` in $(page.source)")
    name = String(m.captures[1])
    m.captures[2] === nothing &&
        error("@slate $name: a whole notebook can only be placed at the top level of a page ($(page.source))")
    id = String(m.captures[2])
    b = bundle(doc, name)
    c = cell(b, id)
    c === nothing && error("@slate $name: no cell '$id' in the notebook (cells: $(join(b.order, ", ")))")
    opts = block_options(el.code)
    show = get(opts, "show", "output")
    show in ("output", "code", "both") || error("@slate $name $id: show must be output, code or both")
    src = String(get(c, "source", ""))
    if show in ("code", "both") && !isempty(strip(src))
        insert_before!(node, Node(MarkdownAST.CodeBlock("julia", strip(src))))
    end
    if show == "code" || get(c, "output", false) !== true
        MarkdownAST.unlink!(node)
        return
    end
    text = String(get(c, "kind", "")) == "markdown" ? String(get(c, "markdown", "")) : ""
    node.element = SlateCellBlock(el, name, id, text)
    return
end

MDFlatten.mdflatten(io, ::Node, b::SlateCellBlock) = print(io, b.text)

# The element a writer emits. Attribute values are ids and bundle names, but escape anyway.
_attr(s) = replace(String(s), "&" => "&amp;", "\"" => "&quot;", "<" => "&lt;")
slate_cell_html(b::SlateCellBlock) =
    string("<slate-cell bundle=\"", _attr(b.bundle), "\" cell=\"", _attr(b.cell), "\"></slate-cell>")
