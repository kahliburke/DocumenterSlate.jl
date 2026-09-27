# DocumenterSlate

Put [Kaimon Slate](https://github.com/kahliburke/KaimonSlate.jl) notebooks into Documenter docs:
prose as prose, code as code, and outputs drawn live — interactive charts, sortable tables, and
controls that still work without a Julia process behind the page.

A single cell from a notebook, with its source:

```@slate oscillator trace
show = "both"
```

The whole notebook is on its own page: [A damped oscillator](oscillator.md).
