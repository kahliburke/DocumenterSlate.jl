# ── Bundles on disk ─────────────────────────────────────────────────────────────────────────────
# The format is written by KaimonSlate (`export_doc_bundle`); this side only reads it. The schema
# number is the contract: a bundle newer than this package understands is refused rather than
# half-rendered.

const MANIFEST = "slate-bundle.json"
const SCHEMA = 1

"""
    Bundle

A rendered notebook: its directory, its manifest, and its cells by id.
"""
struct Bundle
    name::String
    dir::String
    manifest::AbstractDict
    cells::Dict{String,AbstractDict}
    order::Vector{String}
end

function load_bundle(name::AbstractString, dir::AbstractString)
    path = joinpath(dir, MANIFEST)
    isfile(path) || error("Slate bundle '$name': no $MANIFEST in $dir")
    man = JSON.parsefile(path)
    schema = get(man, "schema", 0)
    schema isa Integer && 1 <= schema <= SCHEMA ||
        error("Slate bundle '$name' has schema $schema; this DocumenterSlate reads up to $SCHEMA. " *
              "Update DocumenterSlate, or re-render the bundle with a matching KaimonSlate.")
    cells = Dict{String,AbstractDict}()
    order = String[]
    for c in get(man, "cells", Any[])
        id = String(c["id"])
        cells[id] = c
        push!(order, id)
    end
    return Bundle(String(name), String(dir), man, cells, order)
end

"""
    notebook_key(path) -> String

The key a bundle rendered from `path` records while it is current: KaimonSlate's `doc_bundle_key`,
which covers the notebook, its environment, the packages that environment takes by path, and the
files the notebook reads.
"""
notebook_key(path::AbstractString) = KaimonSlate.doc_bundle_key(path)

"""
    changed_inputs(b::Bundle, path) -> Vector{String}

The files whose content differs from when `b` was rendered from `path`, for saying why it is out of
date. Empty for a bundle that recorded no inputs.
"""
function changed_inputs(b::Bundle, path::AbstractString)
    old = get(b.manifest, "inputs", nothing)
    old isa AbstractDict || return String[]
    new = Dict(KaimonSlate.doc_bundle_inputs(path))
    return sort!([f for f in union(keys(old), keys(new)) if get(old, f, nothing) != get(new, f, nothing)])
end

bundle_key(b::Bundle) = String(get(b.manifest, "key", ""))

"""
    runtime_file(b) -> String

The `<slate-cell>` runtime this bundle was written with.
"""
runtime_file(b::Bundle) = joinpath(b.dir, String(get(b.manifest, "runtime", "runtime/slate-embed.js")))

cell(b::Bundle, id::AbstractString) = get(b.cells, String(id), nothing)
