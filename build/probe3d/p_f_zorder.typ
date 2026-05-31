#import "@preview/cetz:0.5.2"

// Probe (f): painter's algorithm (later draw on top) + on-layer + depth sort in ortho
#set page(width: auto, height: auto, margin: 6pt)

#cetz.canvas({
  import cetz.draw: *

  // later draw should be ON TOP
  rect((0,0),(2,2), fill: rgb("#73000A"))
  rect((1,1),(3,3), fill: rgb("#466A9F"))   // overlaps, should cover the garnet corner

  // on-layer: force something to a different layer index
  on-layer(-1, {
    rect((0.5,0.5),(2.5,2.5), fill: rgb("#CED318"))  // layer -1 -> BEHIND despite later draw
  })
})

// Depth-sorted ortho: two intersecting faces, sorted:true should order them correctly
#cetz.canvas({
  import cetz.draw: *
  ortho(sorted: true, {
    on-xy(z: 0, { rect((0,0),(2,2), fill: rgb("#A2A2A2")) })
    on-xz(y: 1, { rect((0,0),(2,2), fill: rgb("#CC2E40")) })
  })
})
