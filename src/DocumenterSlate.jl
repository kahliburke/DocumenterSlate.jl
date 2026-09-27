"""
    DocumenterSlate

Put Slate notebooks into Documenter docs. In a page, a whole notebook, by its file relative to the page:

````markdown
```@slate ../notebooks/oscillator.jl
```
````

Its markdown becomes the page's own prose, its code becomes ordinary highlighted code blocks, and
each output is drawn by a `<slate-cell>` element, interactive charts, tables and `@replay` controls
included. One cell of it:

````markdown
```@slate ../notebooks/oscillator.jl trace
show = "both"   # "output" (default), "code", or "both"
```
````

In `make.jl`, `makedocs(; …, plugins = [SlateDocs()])`. The build renders each referenced notebook into
a *bundle* (a directory of files under `docs/slate/`, build output) when the bundle is missing or older
than the notebook, through Kaimon Slate.

See [`SlateDocs`](@ref) for where bundles live and what happens when one is out of date.
"""
module DocumenterSlate

using Documenter
import Documenter: Selectors, Builder, Expanders, HTMLWriter, MDFlatten, MarkdownAST
using Documenter.MarkdownAST: Node
import Markdown, JSON, SHA
import KaimonSlate

export SlateDocs

include("bundles.jl")
include("plugin.jl")
include("splice.jl")
include("links.jl")
include("expander.jl")
include("html.jl")
include("vitepress.jl")
include("render.jl")

end
