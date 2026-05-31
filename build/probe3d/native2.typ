// "Simple command on cetz" done RIGHT: let cetz.ortho do the projection (camera),
// but draw faces with stroke:none and the edges as single 3-D polylines so corners
// stay clean. This keeps cetz's projection + (optional) depth-sort, and avoids the
// per-face-stroke miter spikes.
#import "@preview/cetz:0.5.2"
#set page(width: 22cm, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let nblock(x0, w, h, dep, base, edge: rgb("#33474C"), shade: true) = {
  import cetz.draw: line
  let topc = if shade { base.lighten(18%) } else { base }
  let sidec = if shade { base.darken(24%) } else { base }
  // 8 corners as 3-D points; cetz's ortho projects them
  let FBL = (x0, 0, 0)
  let FBR = (x0 + w, 0, 0)
  let FTR = (x0 + w, h, 0)
  let FTL = (x0, h, 0)
  let BBR = (x0 + w, 0, dep)
  let BTR = (x0 + w, h, dep)
  let BTL = (x0, h, dep)
  // visible faces only, NO per-face stroke (this is what kills the corner spikes)
  line(FTL, FTR, BTR, BTL, close: true, fill: topc, stroke: none) // top
  line(FBR, BBR, BTR, FTR, close: true, fill: sidec, stroke: none) // right
  line(FBL, FBR, FTR, FTL, close: true, fill: base, stroke: none) // front
  // fold edges (thin) — three single segments meeting at the near corner FTR
  let ie = 0.45pt + edge.lighten(40%)
  line(FTR, FTL, stroke: ie)
  line(FTR, FBR, stroke: ie)
  line(FTR, BTR, stroke: ie)
  // silhouette: ONE closed polyline -> proper joins -> clean corners
  line(FBL, FBR, BBR, BTR, BTL, FTL, close: true, stroke: 0.95pt + edge)
}

#let row = (
  (0.9, 1.6, 0.6, rgb("#E9EDF0")),
  (0.9, 1.6, 1.0, rgb("#F4C58D")),
  (0.9, 1.3, 1.4, rgb("#F4C58D")),
  (0.9, 1.0, 1.8, rgb("#E2999B")),
  (0.9, 0.7, 2.2, rgb("#9AA7E6")),
)

*cetz `ortho` for projection + faces(stroke:none) + single-polyline edges — flat*
#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  ortho(x: 25deg, y: -32deg, {
    let x = 0.0
    for (w, h, dep, base) in row {
      nblock(x, w, h, dep, base, shade: false)
      x = x + w + dep + 0.8
    }
  })
})

#v(4pt)
*same, shade: true (per-face tones)*
#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  ortho(x: 25deg, y: -32deg, {
    let x = 0.0
    for (w, h, dep, base) in row {
      nblock(x, w, h, dep, base, shade: true)
      x = x + w + dep + 0.8
    }
  })
})
