#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 6pt)

// Probe (g): perspective() projection + gradient fill on a 3-D-projected face
#cetz.canvas({
  import cetz.draw: *
  perspective(sorted: true, cull-face: none, {
    on-xy(z: 0, { rect((0,0),(2,2), fill: rgb("#C7C7C7"), stroke: black) })
    on-zy(x: 0, {
      rect((0,0),(2,2),
        fill: gradient.linear(rgb("#FFF2E3"), rgb("#73000A")),
        stroke: black)
    })
    on-xz(y: 0, { rect((0,0),(2,2), fill: rgb("#73000A"), stroke: black) })
    on-xy(z: 2, { rect((0,0),(2,2), fill: rgb("#FFF2E3"), stroke: black) })
  })
})
