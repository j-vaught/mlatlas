// Prototype: a CORRECT 3-D block engine.
// Fixes the probe defects:
//  1. project the 8 cube corners ONCE -> single source of truth (no vertex misalignment)
//  2. every face references shared corner indices (shared edges are bit-identical)
//  3. back-face culling: only the 3 visible faces are drawn (no sliver bleed-through)
//  4. one global light -> consistent 3-tone (top brightest, front mid, side darkest)
//  5. fills carry NO stroke; a crisp silhouette + thin internal "Y" edges overlaid on
//     top from the same shared points -> seams covered, corners exact.
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 8pt)

#let block3d(
  draw,
  origin: (0, 0), // 2-D screen pos of the front-bottom-left corner
  w: 1.0, h: 2.4, dep: 1.4, // front width, front height, depth (into page)
  base: rgb("#F4C58D"),
  angle: 34deg, dscale: 0.5, // cabinet-oblique depth angle + foreshorten
  edge: rgb("#243038"),
  band: none, band-frac: 0.0, // optional trailing ReLU band on front+top
) = {
  let kx = dscale * calc.cos(angle)
  let ky = dscale * calc.sin(angle)
  let (ox, oy) = origin
  let proj(x, y, z) = (ox + x + z * kx, oy + y + z * ky)
  // 8 corners, projected once: 0-3 front (z=0), 4-7 back (z=dep)
  let C = (
    proj(0, 0, 0), proj(w, 0, 0), proj(w, h, 0), proj(0, h, 0),
    proj(0, 0, dep), proj(w, 0, dep), proj(w, h, dep), proj(0, h, dep),
  )
  let topcol = base.lighten(19%)
  let rightcol = base.darken(26%)
  let face(idx, fill) = draw.line(..idx.map(i => C.at(i)), close: true, fill: fill, stroke: none)
  // ---- visible faces only (top, right, front) ----
  face((3, 2, 6, 7), topcol) // top  (+y)
  face((1, 5, 6, 2), rightcol) // right (+x) = the "side"
  face((0, 1, 2, 3), base) // front (-z)
  // ---- optional ReLU band on the trailing edge of front + top ----
  if band != none and band-frac > 0 {
    let bx = w * (1 - band-frac)
    let bf = (proj(bx, 0, 0), proj(w, 0, 0), proj(w, h, 0), proj(bx, h, 0))
    let bt = (proj(bx, h, 0), proj(w, h, 0), proj(w, h, dep), proj(bx, h, dep))
    draw.line(..bt, close: true, fill: band.lighten(19%), stroke: none)
    draw.line(..bf, close: true, fill: band, stroke: none)
  }
  // ---- internal "Y" edges (thin, lighter) all meet at the shared corner 2 ----
  let ie = 0.45pt + edge.lighten(34%)
  draw.line(C.at(2), C.at(3), stroke: ie)
  draw.line(C.at(2), C.at(1), stroke: ie)
  draw.line(C.at(2), C.at(6), stroke: ie)
  // ---- silhouette hull (thick, crisp) from the same shared points ----
  draw.line(C.at(0), C.at(1), C.at(5), C.at(6), C.at(7), C.at(3), close: true, stroke: 0.9pt + edge)
}

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---------- (1) one clean lit block ----------
  draw.content((1.0, 3.4), text(weight: "bold")[A. single lit block])
  block3d(draw, origin: (0.3, 0.4), w: 1.1, h: 2.4, dep: 1.5, base: rgb("#F4C58D"))

  // ---------- (2) feature-map row (PlotNeuralNet-style), one shared projection ----------
  draw.content((10.0, 3.4), text(weight: "bold")[B. feature-map stack — shared projection, clean seams])
  let pal = (
    input: rgb("#E9EDF0"), conv: rgb("#F4C58D"), conv-band: rgb("#E07B39"),
    pool: rgb("#E2999B"), fc: rgb("#9AA7E6"),
  )
  // (x-cursor, h spatial, dep channels, base, band?)
  let stack = (
    (4.6, 2.6, 0.5, pal.input, false),
    (5.5, 2.6, 0.9, pal.conv, true),
    (6.6, 2.6, 0.9, pal.conv, true),
    (7.8, 2.0, 1.3, pal.pool, false),
    (8.8, 2.0, 1.3, pal.conv, true),
    (10.0, 1.5, 1.8, pal.pool, false),
    (11.1, 1.5, 1.8, pal.conv, true),
    (12.5, 0.9, 2.3, pal.fc, false),
  )
  for s in stack {
    let (x, h, dep, base, band) = s
    block3d(
      draw, origin: (x, 0.4 + (2.6 - h) / 2), w: 0.34, h: h, dep: dep, base: base,
      band: if band { pal.conv-band } else { none }, band-frac: if band { 0.28 } else { 0 },
    )
  }
})
