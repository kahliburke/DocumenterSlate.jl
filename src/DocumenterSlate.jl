"""
    DocumenterSlate

Put Slate notebooks into Documenter docs. A notebook is rendered once into a *bundle* (a directory of
files, committed with the docs); the docs build reads bundles and never runs a notebook itself.

In a page, a whole notebook:

````markdown
```@slate oscillator
```
````

Its markdown becomes the page's own prose, its code becomes ordinary highlighted code blocks, and
each output is drawn by a `<slate-cell>` element — interactive charts, tables and `@replay` controls
included. One cell of it:

````markdown
```@slate oscillator phase_plot
show = "both"   # "output" (default), "code", or "both"
```
````

In `make.jl`:

```julia
makedocs(; …, plugins = [SlateDocs(notebooks = ["oscillator" => "../examples/oscillator.jl"])])
```

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
include("expander.jl")
include("html.jl")
include("vitepress.jl")
include("render.jl")

end
