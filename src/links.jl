# ── Stage 3: links to notebooks become links to the pages that hold them ─────────────────────────
# A notebook links to another the way it would anywhere else: `[the free case](oscillator.jl)`, or
# to a heading, `oscillator.jl#peaks`. A hand-written page can do the same with a path relative to
# itself. On the site, the notebook is a page, so the link has to go there instead: to the page, or,
# with a fragment, to the heading, through a Documenter cross-reference so a heading that doesn't
# exist fails the build instead of producing a dead link.

abstract type SlateLinks <: Builder.DocumentPipeline end
Selectors.order(::Type{SlateLinks}) = 1.95            # after SlateSplice, before ExpandTemplates (2.0)

function Selectors.runner(::Type{SlateLinks}, doc::Documenter.Document)
    p = plugin(doc)
    isempty(p.loaded) && return
    for (_, page) in doc.blueprint.pages, n in collect_nodes(page.mdast)
        el = n.element
        el isa MarkdownAST.Link || continue
        resolved = notebook_link(doc, page, el.destination)
        resolved === nothing && continue
        file, frag = resolved
        target = get(p.pages, file, nothing)
        if target === nothing
            @warn "SlateDocs: a link in $(page.source) goes to $(basename(file)), which no page places " *
                  "(```@slate …``` on its own); the link is left as written."
            continue
        end
        el.destination = isempty(frag) ?
            relpath(page_file(doc, target), dirname(page_file(doc, page))) :
            "@ref " * heading_id(notebook_name(p, file), frag)
    end
end

# (notebook file, fragment) for a destination that names a notebook, or `nothing`.
function notebook_link(doc, page, dest::AbstractString)
    if startswith(dest, NB_LINK)
        target, frag = split_fragment(dest[(length(NB_LINK) + 1):end])
        return (target, frag)
    end
    target, frag = split_fragment(dest)
    (isrelative(target) && isnotebookref(target)) || return nothing
    return (normpath(joinpath(dirname(page_file(doc, page)), target)), frag)
end

notebook_name(p::SlateDocs, file) = something(findfirst(==(file), p.sources), splitext(basename(file))[1])
