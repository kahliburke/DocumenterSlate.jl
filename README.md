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

A docs build does this before any page is rendered:

1. **Finds the notebooks.** Every `@slate` block names a notebook file; the plugin collects them from
   all pages.
2. **Renders what changed.** Each notebook has a rendered *bundle* under `docs/slate/<name>/`, keyed by
   the notebook file's hash. A notebook with no bundle, or one newer than its bundle, is run through
   Kaimon Slate in its own worker, with the fidelity of the live notebook: charts, tables, and the
   `@replay` sweeps that keep controls working. On your machine that goes through the Slate hub you
   already run; in CI, through an isolated Kaimon host the build starts itself.
3. **Places the notebook in the page.** Markdown cells become the page's own markdown, code cells become
   code blocks highlighted by the site, and each output becomes a `<slate-cell>` element. The bundles
   and the small script that draws them are copied into the site.

In the browser, each `<slate-cell>` loads its cell's output from the bundle and draws it in its own
shadow DOM, so the site's styles and the cell's don't mix. Cells follow the site's light and dark
theme, and a control in one cell drives the charts, tables and prose of the others.

`docs/slate/` is build output; keep it out of git. **Export → Docs** in the notebook writes a bundle
from the notebook's live state, and an agent can call `slate.export_docs`. For a notebook too heavy to
run in CI, render its bundle elsewhere and build with `SlateDocs(render = :never)`.
