# ── Stage 2: a whole notebook becomes page content ─────────────────────────────────────────────
# A top-level ```@slate <notebook.jl or name>``` block is replaced, before any expander runs, by the notebook itself
# as ordinary page nodes: markdown cells as markdown, code as julia code blocks, and one
# ```@slate <name> <cell>``` block per output for the expander to turn into an embedded cell. Doing it
# here rather than in an expander is what makes the prose first-class — headings are tracked and
# linkable, `@ref`s resolve, and the text is in the search index — because every node the splice
# produces then goes through the same expansion as a hand-written page.

abstract type SlateSplice <: Builder.DocumentPipeline end
Selectors.order(::Type{SlateSplice}) = 1.9            # after SlatePrepare, before ExpandTemplates (2.0)

const WHOLE_RE = r"^@slate\s+(\S+)\s*$"

function Selectors.runner(::Type{SlateSplice}, doc::Documenter.Document)
    isempty(plugin(doc).loaded) && return
    for (_, page) in doc.blueprint.pages
        for node in collect(page.mdast.children)
            el = node.element
            el isa MarkdownAST.CodeBlock || continue
            m = match(WHOLE_RE, el.info)
            m === nothing && continue
            splice_notebook!(node, bundle(doc, bundle_name(doc, page, m.captures[1])))
        end
    end
end

"""
    notebook_nodes(b::Bundle) -> Vector{Node}

The page nodes a whole notebook expands to. Cells tagged `nodocs` are left out, as are cells folded
away in the notebook (`collapsed`).
"""
function notebook_nodes(b::Bundle)
    out = Node[]
    for id in b.order
        c = b.cells[id]
        tags = Set(String.(get(c, "tags", String[])))
        ("nodocs" in tags || "collapsed" in tags) && continue
        kind = String(c["kind"])
        if kind == "markdown"
            if get(c, "native", false) === true
                md = Markdown.parse(String(c["markdown"]))
                doc = convert(MarkdownAST.Node, md)
                for ch in collect(doc.children)
                    MarkdownAST.unlink!(ch)
                    push!(out, ch)
                end
            elseif get(c, "output", false) === true
                push!(out, cell_block(b.name, id))
            end
        else
            src = strip(String(get(c, "source", "")))
            (get(c, "hidecode", false) === true || isempty(src)) || push!(out, Node(MarkdownAST.CodeBlock("julia", src)))
            get(c, "output", false) === true && push!(out, cell_block(b.name, id))
        end
    end
    return out
end

cell_block(name, id) = Node(MarkdownAST.CodeBlock("@slate $name $id", ""))

# `MarkdownAST.insert_before!` fails when `node` is its parent's first child (it reaches for a
# `pushfirst!(::Node, …)` that MarkdownAST leaves unimplemented), which a page consisting of just an
# `@slate` block always hits.
function insert_before!(node::Node, new::Node)
    node.previous === nothing ? pushfirst!(node.parent.children, new) : MarkdownAST.insert_after!(node.previous, new)
    return new
end

function splice_notebook!(node::Node, b::Bundle)
    for n in notebook_nodes(b)
        insert_before!(node, n)
    end
    MarkdownAST.unlink!(node)
    return nothing
end
