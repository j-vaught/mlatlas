// mlatlas · theme/swatch.typ
// `theme-swatch(th)` renders every role of a theme as a chip — a one-glance audit that
// fills are light, text is readable (via pick-text), and categories are distinguishable.

#import "contrast.typ": pick-text

#let _chip(name, st, th) = {
  let fill = st.at("fill", default: none)
  let stroke = st.at("stroke", default: 1pt + th.ink)
  let tf = st.at("text-fill", default: auto)
  if tf == auto { tf = pick-text(if fill == none { th.paper } else { fill }) }
  box(width: 100%, inset: 7pt, fill: fill, stroke: stroke, radius: 0pt)[
    #set text(fill: tf, size: 8pt)
    #set align(center)
    #name
  ]
}

#let theme-swatch(th, cols: 4, col-width: 30mm) = {
  block(fill: th.paper, inset: 9pt, stroke: 0.5pt + th.palette.b50, radius: 0pt, width: cols * (col-width + 6pt))[
    #set text(font: th.at("font", default: "New Computer Modern"))
    #text(weight: "bold", size: 10pt, fill: pick-text(th.paper))[mlatlas theme — #th.name]
    #v(5pt)
    #grid(
      columns: (1fr,) * cols,
      column-gutter: 6pt,
      row-gutter: 6pt,
      ..th.roles.pairs().map(((r, st)) => _chip(r, st, th)),
    )
  ]
}
