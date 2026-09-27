# Reference

## In a page

A whole notebook, as the page's content:

````markdown
```@slate oscillator
```
````

Its markdown cells become the page's own markdown, code cells become `julia` code blocks, and each
cell with output is drawn in place. Cells tagged `nodocs` are left out; `hidecode` cells show only
their output.

One cell:

````markdown
```@slate oscillator trace
show = "both"
```
````

`show` is `"output"` (the default), `"code"`, or `"both"`.

## Bundles

A bundle is the directory `<bundles>/<name>/` (default `docs/slate/<name>/`), written by
KaimonSlate: **Export → Docs** in the notebook, `slate.export_docs` for an agent, or
`KaimonSlate.render_doc_bundle(notebook, dir)` from a script. It holds a manifest, one file per
cell's output, the data behind interactive controls, and the script that draws them. Commit it with
the docs; the build copies it into the site and never runs the notebook.

## Plugin

```@docs
DocumenterSlate
SlateDocs
```
