// Prototype v2 — TRUE ISOMETRIC, flat (unshaded) by default; shading is opt-in.
// Same correctness guarantees: 8 corners projected once, faces share indices,
// back-face culling, crisp silhouette + internal "Y" edges overlaid last.
// Isometric: vertical edges stay vertical; the two ground axes go at +-30deg, so all
// faces read as parallelograms and you see TOP + LEFT + RIGHT (corner-front).
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 8pt)

#let block3d(
  draw,
  origin: (0, 0),
  w: 1.4, h: 1.4, dep: 1.4,
  base: rgb("#FFF2E3"),
  edge: rgb("#1A1A1A"),
  shade: false, // opt-in directional shading (top light, right dark)
  label: none, // external horizontal caption below the block
  lcol: rgb("#363636"),
) = {
  let (ox, oy) = origin
  let c30 = calc.cos(30deg)
  let s30 = calc.sin(30deg)
  let P(x, y, z) = (ox + (x - z) * c30, oy + y - (x + z) * s30)
  let C = (
    P(0, 0, 0), P(w, 0, 0), P(w, h, 0), P(0, h, 0),
    P(0, 0, dep), P(w, 0, dep), P(w, h, dep), P(0, h, dep),
  )
  let topc = if shade { base.lighten(20%) } else { base }
  let leftc = base
  let rightc = if shade { base.darken(24%) } else { base }
  let face(idx, fill) = draw.line(..idx.map(i => C.at(i)), close: true, fill: fill, stroke: none)
  // visible faces only
  face((3, 2, 6, 7), topc) // top
  face((4, 7, 6, 5), leftc) // left
  face((1, 2, 6, 5), rightc) // right
  // internal "Y" edges meet at the visible centre vertex 6
  let iw = if shade { 0.45pt } else { 0.7pt }
  let icol = if shade { edge.lighten(45%) } else { edge }
  draw.line(C.at(6), C.at(2), stroke: iw + icol)
  draw.line(C.at(6), C.at(7), stroke: iw + icol)
  draw.line(C.at(6), C.at(5), stroke: iw + icol)
  // crisp silhouette hull from the same shared points
  draw.line(C.at(3), C.at(2), C.at(1), C.at(5), C.at(4), C.at(7), close: true, stroke: 0.95pt + edge)
  if label != none {
    draw.content((C.at(5).at(0), C.at(5).at(1) - 0.42), text(size: 7pt, fill: lcol)[#label])
  }
}

#let row(draw, oy, specs, shade: false, colored: false) = {
  let mono = (rgb("#FFF2E3"), rgb("#ECECEC"), rgb("#E3E8EC"))
  let i = 0
  for s in specs {
    let (sx, w, h, dep, ci, lab, cbase) = s
    let base = if colored { cbase } else { mono.at(calc.rem(ci, mono.len())) }
    block3d(draw, origin: (sx, oy), w: w, h: h, dep: dep, base: base, shade: shade, label: lab)
  }
}

#cetz.canvas(length: 1cm, {
  import cetz.draw
  let pal = (conv: rgb("#F4C58D"), pool: rgb("#E2999B"), fc: rgb("#9AA7E6"), input: rgb("#E9EDF0"))

  // ---- A: single block, FLAT (default) ----
  draw.content((0.7, 2.7), text(weight: "bold")[A. default — isometric, flat])
  block3d(draw, origin: (0.7, 0.4), w: 1.3, h: 1.6, dep: 1.3)

  // ---- B: single block, SHADED (opt-in) ----
  draw.content((4.4, 2.7), text(weight: "bold")[B. shade: true (opt-in)])
  block3d(draw, origin: (4.4, 0.4), w: 1.3, h: 1.6, dep: 1.3, shade: true)

  // ---- C: feature-map row, MONO + FLAT (the real default look) ----
  draw.content((10.0, 2.7), text(weight: "bold")[C. feature-map row — mono, flat (default theme)])
  // (screen-x, w, h(spatial), dep(channels), category-idx, label, colored-base)
  let specs = (
    (7.2, 0.5, 1.6, 0.5, 0, [3], pal.input),
    (8.4, 0.5, 1.6, 0.9, 1, [64], pal.conv),
    (9.6, 0.5, 1.3, 1.2, 1, [128], pal.conv),
    (10.9, 0.5, 1.0, 1.6, 2, [256], pal.pool),
    (12.4, 0.5, 0.7, 2.0, 1, [512], pal.conv),
    (14.2, 0.5, 0.5, 2.4, 3, [fc], pal.fc),
  )
  row(draw, 0.4, specs)

  // ---- D: same row, COLORED + SHADED (the loud option) ----
  draw.content((10.0, -2.6), text(weight: "bold")[D. same row — colorful + shade: true (opt-in)])
  row(draw, -4.9, specs, shade: true, colored: true)
})
