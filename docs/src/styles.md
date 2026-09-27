# Styles

This site is built three times from the same sources, once per documentation writer, so you can see
how Slate cells sit in each:

| Writer | Site |
|---|---|
| [DocumenterVitepress](https://github.com/LuxDL/DocumenterVitepress.jl) | [kahliburke.github.io/DocumenterSlate.jl/dev/](https://kahliburke.github.io/DocumenterSlate.jl/dev/) |
| Documenter's HTML writer, with [DocumenterLandingPage](https://github.com/csvance/DocumenterLandingPage.jl) and [DocumenterCodeBlocks](https://github.com/fredrikekre/DocumenterCodeBlocks.jl) | […/html/dev/](https://kahliburke.github.io/DocumenterSlate.jl/html/dev/) |
| [MaterialDocs](https://github.com/mthelm85/MaterialDocs.jl) with DocumenterLandingPage | […/material/dev/](https://kahliburke.github.io/DocumenterSlate.jl/material/dev/) |

Locally, `DOCS_FLAVOR=html julia --project=docs docs/make.jl` (or `material`) builds the others.
