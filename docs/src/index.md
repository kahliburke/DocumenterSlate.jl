```@raw html
---
layout: home

hero:
  name: DocumenterSlate
  text: Live notebooks in your docs
  tagline: Reference a Kaimon Slate notebook from any Documenter page. Its prose becomes your page, its code your code blocks, and its charts, tables and controls stay interactive.
  actions:
    - theme: brand
      text: Get started
      link: /guide
    - theme: alt
      text: See a notebook
      link: /oscillator
    - theme: alt
      text: GitHub
      link: https://github.com/kahliburke/DocumenterSlate.jl

features:
  - icon: 📓
    title: Write a notebook, reference it
    details: One line in a page places a whole notebook, or a single cell of it. No export step.
  - icon: 🎛️
    title: Controls that work on a static page
    details: Sliders and selects keep driving charts, tables and prose, from sweeps computed when the notebook was rendered.
  - icon: 🌗
    title: Fits the site it lands in
    details: Follows the site's light and dark theme, and works with Documenter, DocumenterVitepress and MaterialDocs.
  - icon: 🔒
    title: CI runs nothing, if you like
    details: Commit the rendered bundles and the docs build never executes a notebook; a stale one fails the build.
---
```

## One cell, live

The chart below is a cell of the [damped oscillator](oscillator.md) notebook. Drag the slider on
that page and it moves; here it shows the notebook's current state.

```@slate ../notebooks/oscillator.jl trace
```
