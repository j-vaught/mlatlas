#import "@preview/cetz:0.5.2"

// Probe (d): gradient + pattern/tiling fills on a polygon/parallelogram face
#set page(width: auto, height: auto, margin: 6pt)

#let face-grad = gradient.linear(rgb("#FFF2E3"), rgb("#73000A"), angle: 45deg)
#let hatch = tiling(size: (6pt, 6pt))[
  #place(line(start: (0%, 0%), end: (100%, 100%), stroke: 0.6pt + rgb("#363636")))
]

#cetz.canvas({
  import cetz.draw: *

  // gradient across a parallelogram (sheen)
  line((0,0), (3,0), (4,2), (1,2), close: true, fill: face-grad, stroke: rgb("#000000"))

  // pattern / tiling fill (hatch) on another parallelogram
  line((5,0), (8,0), (9,2), (6,2), close: true, fill: hatch, stroke: rgb("#000000"))

  // gradient on a rect too
  rect((0,-3), (3,-1), fill: gradient.linear(rgb("#466A9F"), rgb("#1F414D")))
})
