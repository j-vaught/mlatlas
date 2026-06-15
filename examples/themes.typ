// The SAME diagram across four themes — one setting flips the whole look.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 8pt, fill: rgb("#C7C7C7"))

#let g = seq(
  block2d(label: [Input], role: "data"),
  transformer-block(heads: 8),
  block2d(label: [Output], role: "output", emphasis: true),
)

#stack(
  dir: ltr,
  spacing: 10pt,
  box(fill: mono.paper, inset: 6pt, stroke: 0.5pt)[#render(g, theme: mono)],
  box(fill: colorful.paper, inset: 6pt, stroke: 0.5pt)[#render(g, theme: colorful)],
  box(fill: grayscale.paper, inset: 6pt, stroke: 0.5pt)[#render(g, theme: grayscale)],
  box(fill: slides.paper, inset: 6pt, stroke: 0.5pt)[#render(g, theme: slides)],
)
