#import "@preview/cetz:0.5.2"

// Probe (e): stroke join (miter vs round), opacity, multi-stop gradient shading
#set page(width: auto, height: auto, margin: 6pt)

#cetz.canvas({
  import cetz.draw: *

  // miter join (sharp silhouette corners)
  line((0,0),(2,0),(2,2),(0,2), close: true,
    stroke: (paint: rgb("#000000"), thickness: 4pt, join: "miter"),
    fill: rgb("#C7C7C7"))

  // round join for comparison
  line((3,0),(5,0),(5,2),(3,2), close: true,
    stroke: (paint: rgb("#000000"), thickness: 4pt, join: "round"),
    fill: rgb("#C7C7C7"))

  // opacity fill (semi-transparent face)
  rect((0,-3),(2,-1), fill: rgb(115,0,10,128))

  // multi-stop gradient (per-position shading control)
  rect((3,-3),(6,-1),
    fill: gradient.linear(
      (rgb("#FFF2E3"), 0%),
      (rgb("#A2A2A2"), 50%),
      (rgb("#73000A"), 100%),
    ))
})
