// mlatlas · renderers/multistream.typ
// Dedicated, mirror-symmetric renderers for fan-out / fan-in topologies that fletcher's
// auto-router handles asymmetrically: `dual-head` (shared backbone -> N task heads via a
// shared bus) and `two-stream` (two aligned streams -> a fusion node -> a head).
// Drawn in one cetz canvas for full control. Brand-adapted: sharp corners, stealth arrows.

#import "@preview/cetz:0.5.2"
#import "../adapters/3d.typ": block3d, cam-cabinet

#let ms-palette = (
  ink: rgb("#363636"),
  garnet: rgb("#73000A"),
  data: rgb("#FFF2E3"), data-stroke: rgb("#363636"),
  op: rgb("#FFFFFF"), op-stroke: rgb("#363636"),
  out: rgb("#ECECEC"), out-stroke: rgb("#363636"),
  left: rgb("#CBE0F4"), left-stroke: rgb("#3F6DAA"),
  right: rgb("#F2E4C4"), right-stroke: rgb("#9A7F2E"),
  edge: rgb("#243038"),
  text: rgb("#1A1A1A"),
)

#let _msbox(draw, cx, cy, lbl, fill, stroke, w: 2.5, h: 0.72, sz: 8.5pt, tcol: rgb("#1A1A1A")) = {
  draw.rect((cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), fill: fill, stroke: stroke, radius: 0pt)
  draw.content((cx, cy), text(size: sz, fill: tcol)[#lbl])
}

// a small 3-D feature-map prism via the engine (cabinet oblique: upright front face, clean
// hull silhouette). The `stroke` arg is kept for call-site compatibility but unused — the
// engine draws fills stroke:none and lays one silhouette. The label sits on the upright front.
#let _msprism(draw, cx, cy, lbl, fill, stroke, w: 2.5, h: 0.72) = {
  block3d(draw, origin: (cx, cy), w: w, h: h, dep: 0.34, base: fill, edge: ms-palette.edge, cam: cam-cabinet)
  if lbl != none { draw.content((cx, cy), text(size: 8.5pt, fill: rgb("#1A1A1A"))[#lbl]) }
}

// A shared backbone fanning out to N task heads (each head = a vertical list of labels).
#let dual-head(
  input: [Input],
  backbone: [Backbone],
  heads: (([Cls Head], [Class]), ([Box Head], [BBox])),
  palette: ms-palette,
  spread: 3.2,
) = {
  let p = palette
  cetz.canvas(length: 1cm, {
    import cetz.draw as draw
    let h = 0.72
    let rowh = 1.18
    let arr(a, b, ..mid) = draw.line(a, ..mid.pos(), b, stroke: 1.1pt + p.ink, mark: (end: "stealth", scale: 0.7))
    let ln(..pts) = draw.line(..pts.pos(), stroke: 1.1pt + p.ink)
    let n = heads.len()
    let xs = range(n).map(i => -spread * (n - 1) / 2 + i * spread)

    // trunk
    _msbox(draw, 0, 0, input, p.data, 1.2pt + p.data-stroke)
    _msbox(draw, 0, -1.35, backbone, p.op, 1.6pt + p.garnet)
    arr((0, -h / 2), (0, -1.35 + h / 2))

    // bus
    let busY = -2.6
    ln((0, -1.35 - h / 2), (0, busY)) // backbone -> bus
    draw.circle((0, busY), radius: 0.06, fill: p.ink, stroke: none)
    ln((xs.first(), busY), (xs.last(), busY)) // the bus

    for (i, head) in heads.enumerate() {
      let hx = xs.at(i)
      if hx != 0 { draw.circle((hx, busY), radius: 0.06, fill: p.ink, stroke: none) }
      let firstY = busY - rowh
      arr((hx, busY), (hx, firstY + h / 2)) // drop into the first head box
      for (j, lbl) in head.enumerate() {
        let y = firstY - j * rowh
        let last = j == head.len() - 1
        _msbox(draw, hx, y, lbl, if last { p.out } else { p.op }, if last { 1.2pt + p.out-stroke } else { 1.2pt + p.op-stroke })
        if j > 0 { arr((hx, firstY - (j - 1) * rowh - h / 2), (hx, y + h / 2)) }
      }
    }
  })
}

// Two aligned streams merging into a fusion node, then a head. Bottoms are aligned so
// the merge is symmetric; both streams enter the fusion node's top face mirrored.
#let two-stream(
  left-label: [Image], left: ([Conv], [Conv]),
  right-label: [Text], right: ([Embed], [Transformer]),
  fusion: [Fusion],
  head: ([MLP Head], [Output]),
  palette: ms-palette,
  sx: 2.25,
) = {
  let p = palette
  cetz.canvas(length: 1cm, {
    import cetz.draw as draw
    let h = 0.72
    let rowh = 1.18
    let arr(a, b, ..mid) = draw.line(a, ..mid.pos(), b, stroke: 1.1pt + p.ink, mark: (end: "stealth", scale: 0.7))
    let L = (left-label,) + left
    let R = (right-label,) + right
    let maxlen = calc.max(L.len(), R.len())

    let draw-stream(xp, nodes, fill, stroke, prism: false) = {
      let off = maxlen - nodes.len()
      for (i, lbl) in nodes.enumerate() {
        let y = -(off + i) * rowh
        if i == 0 {
          _msbox(draw, xp, y, lbl, p.data, 1.1pt + p.data-stroke)
        } else if prism {
          _msprism(draw, xp, y, lbl, fill, 1.1pt + stroke)
        } else {
          _msbox(draw, xp, y, lbl, fill, 1.2pt + stroke)
        }
        if i > 0 { arr((xp, -(off + i - 1) * rowh - h / 2), (xp, y + h / 2)) }
      }
    }
    draw-stream(-sx, L, p.left, p.left-stroke, prism: true) // image CNN stream = 3-D prisms
    draw-stream(sx, R, p.right, p.right-stroke)

    let bottomY = -(maxlen - 1) * rowh
    let fusionY = bottomY - rowh
    // symmetric merge: each stream bottom -> down -> across -> into the fusion TOP face.
    // Draw the arrows FIRST, then the fusion box on top so its stroke caps the arrow tips
    // (no pierce). (arr is arr(start, end, ..midpoints), so end comes 2nd, waypoints after.)
    let busY = fusionY + 0.55
    arr((-sx, bottomY - h / 2), (-0.55, fusionY + h / 2), (-sx, busY), (-0.55, busY))
    arr((sx, bottomY - h / 2), (0.55, fusionY + h / 2), (sx, busY), (0.55, busY))
    _msbox(draw, 0, fusionY, fusion, p.op, 2pt + p.garnet)

    // head below the fusion (centred)
    for (i, lbl) in head.enumerate() {
      let y = fusionY - (i + 1) * rowh
      let last = i == head.len() - 1
      _msbox(draw, 0, y, lbl, if last { p.out } else { p.op }, if last { 1.2pt + p.out-stroke } else { 1.2pt + p.op-stroke })
      let prevY = if i == 0 { fusionY } else { fusionY - i * rowh }
      arr((0, prevY - h / 2), (0, y + h / 2))
    }
  })
}
