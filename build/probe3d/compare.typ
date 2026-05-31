// Head-to-head: cetz NATIVE 3-D (ortho + on-* planes, sorted) vs HAND-ROLLED isometric.
#import "@preview/cetz:0.5.2"
#set page(width: 22cm, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---------- NATIVE: one box, 6 faces on planes, painter-sorted (cull-face:none) ----------
#let nbox(draw, x0, w, h, dep, base, edge: rgb("#33474C")) = {
  import cetz.draw: on-xy, on-xz, on-zy, rect
  let s = 0.5pt + edge
  // hidden faces first is irrelevant — `sorted:true` on the enclosing ortho re-orders by depth
  on-xy(z: 0, rect((x0, 0), (x0 + w, h), fill: base, stroke: s)) // front
  on-xy(z: dep, rect((x0, 0), (x0 + w, h), fill: base.darken(24%), stroke: s)) // back
  on-xz(y: 0, rect((x0, 0), (x0 + w, dep), fill: base.darken(30%), stroke: s)) // bottom
  on-xz(y: h, rect((x0, 0), (x0 + w, dep), fill: base.lighten(18%), stroke: s)) // top
  on-zy(x: x0, rect((0, 0), (dep, h), fill: base, stroke: s)) // left
  on-zy(x: x0 + w, rect((0, 0), (dep, h), fill: base.darken(24%), stroke: s)) // right
}

// ---------- HAND-ROLLED: isometric, 8 corners once, cull, 3-tier edges ----------
#let hbox(draw, origin, w, h, dep, base, edge: rgb("#1A1A1A"), shade: false) = {
  let (ox, oy) = origin
  let c30 = calc.cos(30deg)
  let s30 = calc.sin(30deg)
  let P(x, y, z) = (ox + (x - z) * c30, oy + y - (x + z) * s30)
  let C = (
    P(0, 0, 0), P(w, 0, 0), P(w, h, 0), P(0, h, 0),
    P(0, 0, dep), P(w, 0, dep), P(w, h, dep), P(0, h, dep),
  )
  let topc = if shade { base.lighten(18%) } else { base }
  let rightc = if shade { base.darken(24%) } else { base }
  let f(idx, fill) = draw.line(..idx.map(i => C.at(i)), close: true, fill: fill, stroke: none)
  f((3, 2, 6, 7), topc) // top
  f((4, 7, 6, 5), base) // left
  f((1, 2, 6, 5), rightc) // right
  let iw = if shade { 0.45pt } else { 0.7pt }
  let icol = if shade { edge.lighten(45%) } else { edge }
  draw.line(C.at(6), C.at(2), stroke: iw + icol)
  draw.line(C.at(6), C.at(7), stroke: iw + icol)
  draw.line(C.at(6), C.at(5), stroke: iw + icol)
  draw.line(C.at(3), C.at(2), C.at(1), C.at(5), C.at(4), C.at(7), close: true, stroke: 0.95pt + edge)
}

#let row = (
  (0.9, 1.6, 0.6, rgb("#E9EDF0")),
  (0.9, 1.6, 1.0, rgb("#F4C58D")),
  (0.9, 1.3, 1.4, rgb("#F4C58D")),
  (0.9, 1.0, 1.8, rgb("#E2999B")),
  (0.9, 0.7, 2.2, rgb("#9AA7E6")),
)

*1. cetz NATIVE — `ortho(x: 25deg, y: -32deg, sorted: true, cull-face: none)`, 6 faces/box*
#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  ortho(x: 25deg, y: -32deg, sorted: true, cull-face: none, {
    let x = 0.0
    for (w, h, dep, base) in row {
      nbox(none, x, w, h, dep, base)
      x = x + w + dep + 0.8
    }
  })
})

#v(4pt)
*2. HAND-ROLLED isometric — flat (the proposed default): one hull + thin folds, flat fills*
#cetz.canvas(length: 1cm, {
  import cetz.draw
  let x = 0.6
  for (w, h, dep, base) in row {
    hbox(draw, (x, 0.2 + (1.6 - h) / 2), 0.45, h, dep, base)
    x = x + 1.2
  }
})

#v(4pt)
*3. HAND-ROLLED isometric — `shade: true` (opt-in directional lighting)*
#cetz.canvas(length: 1cm, {
  import cetz.draw
  let x = 0.6
  for (w, h, dep, base) in row {
    hbox(draw, (x, 0.2 + (1.6 - h) / 2), 0.45, h, dep, base, shade: true)
    x = x + 1.2
  }
})
