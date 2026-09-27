# Getting started

## Install

Add DocumenterSlate to your docs environment, and the plugin to `makedocs`:

```julia
using Documenter, DocumenterSlate

makedocs(; sitename = "MyPkg", plugins = [SlateDocs()], pages = […])
```

## Reference a notebook

In any page, refer to a notebook by its file, relative to the page like a link:

````markdown
```@slate ../notebooks/tour.jl
```
````

That places the whole notebook: its markdown cells become the page's own markdown (headings,
cross-references and search all work), its code cells become `julia` code blocks, and each output is
drawn live. Cells tagged `nodocs` are left out; `hidecode` cells show only their output.

For one cell, add its id, and `show` to include its source:

````markdown
```@slate ../notebooks/tour.jl trace
show = "both"
```
````

## Rendering

The docs build never runs a notebook itself. It keeps each notebook's rendered *bundle* under
`docs/slate/<name>/`, and when a notebook is newer than its bundle it renders it through
[Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl): through the Slate hub you already have
running, or, on a machine with none, an isolated Kaimon host it starts for the build.

**Export → Docs** in the notebook writes the same bundle from the notebook as it stands.

## In CI

With the defaults, CI renders every notebook: the build starts an isolated Kaimon host, runs each
notebook in its own worker, and writes its bundle before the pages are built. This site is built that
way. Keep `docs/slate/` out of git; it is build output.

A notebook too heavy for CI (GPU work, long fits) can instead have its bundle rendered on a machine
that can run it and handed to the build: build with `SlateDocs(render = :never, stale = :error)` and
the build uses the bundles it is given, and fails on one that no longer matches its notebook.
