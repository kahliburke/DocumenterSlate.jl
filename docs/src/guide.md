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

To place part of a notebook, list the cells to include, in any order; they appear in notebook order:

````markdown
```@slate ../notebooks/tour.jl
cells = "intro trace"
```
````

A notebook can be split across several pages this way. A link to the notebook goes to the page that
places all of it, or else to the first page that places part of it.

For one cell, add its id, and `show` to include its source:

````markdown
```@slate ../notebooks/tour.jl trace
show = "both"
```
````

## Notebook environments

A notebook runs in the nearest `Project.toml` above it. Give your notebooks a project of their own
(`docs/notebooks/Project.toml` here) holding just the packages they use, so a render doesn't load the
docs toolchain into every notebook's worker.

## Rendering

Before any page is built, the docs build renders each referenced notebook whose *bundle* is missing
or older than the notebook. A bundle is the notebook's rendered output, kept under
`docs/slate/<name>/`: the output of each cell, the data behind interactive controls, and the script
that draws them. The notebook runs in its own [Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl)
worker, through the Slate hub you already have running, or, on a machine with none, an isolated
Kaimon host the build starts. A notebook that hasn't changed isn't run again.

`docs/slate/` is build output: keep it out of git. **Export → Docs** in the notebook writes a bundle
from the notebook as it stands, without a docs build.

## In CI

With the defaults, CI renders every notebook: the build starts an isolated Kaimon host, runs each
notebook in its own worker, and writes its bundle before the pages are built. This site is built that
way. Keep `docs/slate/` out of git; it is build output.

A notebook too heavy for CI (GPU work, long fits) can instead have its bundle rendered on a machine
that can run it and handed to the build: build with `SlateDocs(render = :never, stale = :error)` and
the build uses the bundles it is given, and fails on one that no longer matches its notebook.
