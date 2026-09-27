# DocumenterSlate.jl

[![Docs: Vitepress](https://img.shields.io/badge/docs-vitepress-blue.svg)](https://kahliburke.github.io/DocumenterSlate.jl/dev/)
[![Docs: Documenter](https://img.shields.io/badge/docs-documenter-blue.svg)](https://kahliburke.github.io/DocumenterSlate.jl/html/dev/)
[![Docs: Material](https://img.shields.io/badge/docs-material-blue.svg)](https://kahliburke.github.io/DocumenterSlate.jl/material/dev/)
[![CI](https://github.com/kahliburke/DocumenterSlate.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/kahliburke/DocumenterSlate.jl/actions/workflows/CI.yml)
[![Documentation](https://github.com/kahliburke/DocumenterSlate.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/kahliburke/DocumenterSlate.jl/actions/workflows/Docs.yml)
[![Julia 1.12+](https://img.shields.io/badge/Julia-1.12%2B-9558b2.svg)](https://julialang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Put [Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl) notebooks into
[Documenter](https://github.com/JuliaDocs/Documenter.jl) docs, with Documenter's HTML writer,
[DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl) or
[MaterialDocs](https://github.com/mthelm85/MaterialDocs.jl).

A notebook's prose becomes the page's own markdown (headings, cross-references and search all work),
its code becomes ordinary highlighted code blocks, and each output is drawn by a `<slate-cell>`
element: interactive ECharts, sortable tables, and `@bind` controls that still work on a static page
through precomputed `@replay` sweeps. Cells follow the site's light/dark theme.

The docs are built by all three writers, so you can see how cells sit in each:
[Vitepress](https://kahliburke.github.io/DocumenterSlate.jl/dev/),
[Documenter](https://kahliburke.github.io/DocumenterSlate.jl/html/dev/) (with DocumenterLandingPage
and DocumenterCodeBlocks), and [Material](https://kahliburke.github.io/DocumenterSlate.jl/material/dev/).

## Use

In `docs/make.jl`:

```julia
using Documenter, DocumenterSlate

makedocs(; …, plugins = [SlateDocs()])
```

In a page, a whole notebook, by its file relative to the page:

````markdown
```@slate ../notebooks/oscillator.jl
```
````

or one cell of it:

````markdown
```@slate ../notebooks/oscillator.jl trace
show = "both"    # "output" (default), "code", or "both"
```
````

Cells tagged `nodocs` are left out of a whole-notebook page; `hidecode` cells show only their output.

## How it works

The docs build never runs a notebook itself. It keeps each notebook's rendered *bundle* under
`docs/slate/<name>/` and, when a notebook is newer than its bundle, renders it through Kaimon Slate:
the Slate hub already running on your machine, or, with none (CI), an isolated Kaimon host it starts
for the build. The bundle has the same fidelity as the live notebook.

**Export → Docs** in the notebook writes the same bundle from its live state, and an agent can call
`slate.export_docs`.

To keep CI from running notebooks at all, commit the bundles and build with
`SlateDocs(render = :never, stale = :error)`: the build uses them as they are and fails on one that no
longer matches its notebook. This package's own docs work that way.
