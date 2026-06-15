#import "@preview/cetz:0.5.2"

// Probe (c): polygon fills with COMPUTED coordinates (build faces from projected vertices)
#set page(width: auto, height: auto, margin: 6pt)

// Hand-roll an isometric projection in plain Typst, feed computed 2-D points to draw.line
#let iso(x, y, z) = {
  let ax = 30deg
  // simple isometric: project (x,y,z) -> 2d
  let px = (x - y) * calc.cos(ax)
  let py = (x + y) * calc.sin(ax) - z
  (px, py)
}

#cetz.canvas({
  import cetz.draw: *

  // top face of a unit cube, computed vertices
  let v000 = iso(0,0,0)
  let v100 = iso(2,0,0)
  let v110 = iso(2,2,0)
  let v010 = iso(0,2,0)
  let v001 = iso(0,0,2)
  let v101 = iso(2,0,2)
  let v111 = iso(2,2,2)
  let v011 = iso(0,2,2)

  // top
  line(v001, v101, v111, v011, close: true, fill: rgb("#FFF2E3"), stroke: rgb("#000000"))
  // left
  line(v000, v001, v011, v010, close: true, fill: rgb("#A2A2A2"), stroke: rgb("#000000"))
  // right (front)
  line(v000, v100, v101, v001, close: true, fill: rgb("#73000A"), stroke: rgb("#000000"))

  // Also probe merge-path with computed points
  merge-path(close: true, fill: rgb("#466A9F"), {
    line(iso(3,0,0), iso(5,0,0))
    line(iso(5,0,0), iso(5,2,1))
    line(iso(5,2,1), iso(3,2,1))
  })
})
