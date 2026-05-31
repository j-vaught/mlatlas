#import "@preview/cetz:0.5.2"

// Probe (a): native orthographic 3-D mode + cube via on-xy/on-xz/on-zy
#set page(width: auto, height: auto, margin: 6pt)

#cetz.canvas({
  import cetz.draw: *

  ortho(cull-face: "cw", {
    // bottom and top
    on-xy(z: 0, { rect((0,0), (2,2), fill: rgb("#C7C7C7")) })
    on-xy(z: 2, { rect((0,0), (2,2), fill: rgb("#FFF2E3")) })
    // front/back on xz
    on-xz(y: 0, { rect((0,0), (2,2), fill: rgb("#A2A2A2")) })
    on-xz(y: 2, { rect((0,0), (2,2), fill: rgb("#5C5C5C")) })
    // left/right on zy
    on-zy(x: 0, { rect((0,0), (2,2), fill: rgb("#73000A")) })
    on-zy(x: 2, { rect((0,0), (2,2), fill: rgb("#363636")) })
  })
})
