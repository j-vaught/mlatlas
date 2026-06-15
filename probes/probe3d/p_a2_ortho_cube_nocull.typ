#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 6pt)

// Variant 1: no culling, depth-sorted, with strokes -> full cube, painter order
#cetz.canvas({
  import cetz.draw: *
  ortho(sorted: true, cull-face: none, {
    on-xy(z: 0, { rect((0,0),(2,2), fill: rgb("#C7C7C7"), stroke: black) })
    on-zy(x: 0, { rect((0,0),(2,2), fill: rgb("#A2A2A2"), stroke: black) })
    on-zy(x: 2, { rect((0,0),(2,2), fill: rgb("#5C5C5C"), stroke: black) })
    on-xz(y: 0, { rect((0,0),(2,2), fill: rgb("#73000A"), stroke: black) })
    on-xz(y: 2, { rect((0,0),(2,2), fill: rgb("#363636"), stroke: black) })
    on-xy(z: 2, { rect((0,0),(2,2), fill: rgb("#FFF2E3"), stroke: black) })
  })
})

// Variant 2: cull-face ccw (opposite winding) to test which faces survive
#cetz.canvas({
  import cetz.draw: *
  ortho(sorted: true, cull-face: "ccw", {
    on-xy(z: 0, { rect((0,0),(2,2), fill: rgb("#C7C7C7"), stroke: black) })
    on-xy(z: 2, { rect((0,0),(2,2), fill: rgb("#FFF2E3"), stroke: black) })
    on-xz(y: 0, { rect((0,0),(2,2), fill: rgb("#73000A"), stroke: black) })
    on-xz(y: 2, { rect((0,0),(2,2), fill: rgb("#363636"), stroke: black) })
    on-zy(x: 0, { rect((0,0),(2,2), fill: rgb("#A2A2A2"), stroke: black) })
    on-zy(x: 2, { rect((0,0),(2,2), fill: rgb("#5C5C5C"), stroke: black) })
  })
})
