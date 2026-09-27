# ── Stage 2: a whole notebook becomes page content ─────────────────────────────────────────────
# A top-level ```@slate <notebook.jl or name>``` block is replaced, before any expander runs, by the
# notebook itself as ordinary page nodes: markdown cells as markdown, code as julia code blocks, and
# one ```@slate <name> <cell>``` block per output for the expander to turn into an embedded cell.
# Doing it here rather than in an expander is what makes the prose first-class: headings are tracked
# and linkable, `@ref`s resolve, and the text is in the search index, because every node the splice
# produces then goes through the same expansion as a hand-written page.

abstract type SlateSplice <: Builder.DocumentPipeline end
Selectors.order(::Type{SlateSplice}) = 1.9            # after SlatePrepare, before ExpandTemplates (2.0)

const WHOLE_RE = r"^@slate\s+(\S+)\s*$"

function Selectors.runner(::Type{SlateSplice}, doc::Documenter.Document)
    p = plugin(doc)
    isempty(p.loaded) && return
    empty!(p.pages)
    for (_, page) in doc.blueprint.pages
        for node in collect(page.mdast.children)
            el = node.element
            el isa MarkdownAST.CodeBlock || continue
            m = match(WHOLE_RE, el.info)
            m === nothing && continue
            name = bundle_name(doc, page, m.captures[1])
            file = get(p.sources, name, nothing)
            file === nothing || (p.pages[file] = page)
            splice_notebook!(node, bundle(doc, name), file)
        end
    end
end

"""
    heading_id(notebook_name, text) -> String

The anchor a notebook's heading gets on its page: the notebook's name and the heading's slug, so the
same heading in two notebooks gets two anchors. A link to `tour.jl#getting-started` resolves to it.
"""
heading_id(name, text) = string(name, "-", slugify(text))

slugify(s) = strip(replace(lowercase(strip(String(s))), r"[^\p{L}\p{N}]+" => "-"), '-')

# Prefix for a link destination rewritten to an absolute notebook file at splice time: a spliced
# notebook's links are relative to the NOTEBOOK, which the page that holds them says nothing about.
const NB_LINK = "slate-notebook:"

"""
    notebook_nodes(b::Bundle, file = nothing) -> Vector{Node}

The page nodes a whole notebook expands to. Cells tagged `nodocs` are left out, as are cells folded
away in the notebook (`collapsed`). With the notebook's `file`, its headings get notebook-scoped ids
and its links to other notebooks (or to its own headings) are made resolvable from the page.
"""
function notebook_nodes(b::Bundle, file = nothing)
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
                    file === nothing || localize!(ch, b.name, file)
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

# Headings get their notebook-scoped id (Documenter's `# [Title](@id id)` form); links relative to
# the notebook (another notebook, or `#heading` in this one) become absolute notebook links.
function localize!(node::Node, name, file)
    for n in collect_nodes(node)
        el = n.element
        if el isa MarkdownAST.Heading && !any(c -> c.element isa MarkdownAST.Link, n.children)
            text = MDFlatten.mdflatten(n)
            link = Node(MarkdownAST.Link("@id " * heading_id(name, text), ""))
            for ch in collect(n.children)
                push!(link.children, MarkdownAST.unlink!(ch))
            end
            push!(n.children, link)
        elseif el isa MarkdownAST.Link
            target, frag = split_fragment(el.destination)
            if isempty(target) && !isempty(frag)
                el.destination = NB_LINK * file * "#" * frag
            elseif isrelative(target) && isnotebookref(target)
                el.destination = NB_LINK * normpath(joinpath(dirname(file), target)) * (isempty(frag) ? "" : "#" * frag)
            end
        end
    end
    return node
end

split_fragment(dest) = (i = findfirst('#', dest); i === nothing ? (String(dest), "") :
                                                     (String(dest[1:prevind(dest, i)]), String(dest[nextind(dest, i):end])))

isrelative(target) = !isempty(target) && !startswith(target, '/') && !startswith(target, '@') &&
                     !occursin(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target)

cell_block(name, id) = Node(MarkdownAST.CodeBlock("@slate $name $id", ""))

# `MarkdownAST.insert_before!` fails when `node` is its parent's first child (it reaches for a
# `pushfirst!(::Node, …)` that MarkdownAST leaves unimplemented), which a page consisting of just an
# `@slate` block always hits.
function insert_before!(node::Node, new::Node)
    node.previous === nothing ? pushfirst!(node.parent.children, new) : MarkdownAST.insert_after!(node.previous, new)
    return new
end

function splice_notebook!(node::Node, b::Bundle, file = nothing)
    for n in notebook_nodes(b, file)
        insert_before!(node, n)
    end
    MarkdownAST.unlink!(node)
    return nothing
end
