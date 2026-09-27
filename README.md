# DocumenterSlate.jl

Put [Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl) notebooks into
[Documenter](https://github.com/JuliaDocs/Documenter.jl) docs, with Documenter's HTML writer or
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl).

A notebook's prose becomes the page's own markdown (headings, cross-references and search all work),
its code becomes ordinary highlighted code blocks, and each output is drawn by a `<slate-cell>`
element: interactive ECharts, sortable tables, and `@bind` controls that still work on a static page
through precomputed `@replay` sweeps. Cells follow the site's light/dark theme.

## Use

In a page, a whole notebook:

````markdown
```@slate oscillator
```
````

or one cell of it:

````markdown
```@slate oscillator trace
show = "both"    # "output" (default), "code", or "both"
```
````

In `docs/make.jl`:

```julia
using Documenter, DocumenterSlate

makedocs(; …,
    plugins = [SlateDocs(notebooks = ["oscillator" => "notebooks/oscillator.jl"],
                         stale = get(ENV, "CI", "false") == "true" ? :error : :warn)])
```

## How it works

The docs build never runs a notebook. Each notebook is rendered once into a *bundle*
(`docs/slate/<name>/`), which is committed with the docs:

```julia
using KaimonSlate
render_doc_bundle("notebooks/oscillator.jl", "slate/oscillator")
```

`render_doc_bundle` runs the notebook through the Slate hub already running on your machine, or,
with none, an isolated Kaimon host started for the render, so the bundle has the same fidelity as
the live notebook. A bundle records the hash of the notebook it came from; the build warns about (or,
in CI, fails on) a bundle that no longer matches. To render during the build instead, load
KaimonSlate in `make.jl` and pass `SlateDocs(render = :stale)`.

Cells tagged `nodocs` are left out of a whole-notebook page; `hidecode` cells show only their output.
