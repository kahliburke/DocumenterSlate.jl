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

The key a bundle records for the notebook it was rendered from: the file's SHA-256 with line endings
normalised. Identical to `KaimonSlate.NotebookServer.doc_bundle_key`, restated here so checking
whether a bundle is current does not need KaimonSlate.
"""
notebook_key(path::AbstractString) = bytes2hex(SHA.sha256(replace(read(path, String), "\r\n" => "\n")))

bundle_key(b::Bundle) = String(get(b.manifest, "key", ""))

"""
    runtime_file(b) -> String

The `<slate-cell>` runtime this bundle was written with.
"""
runtime_file(b::Bundle) = joinpath(b.dir, String(get(b.manifest, "runtime", "runtime/slate-embed.js")))

cell(b::Bundle, id::AbstractString) = get(b.cells, String(id), nothing)
