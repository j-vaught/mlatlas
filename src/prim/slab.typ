// mlatlas · prim/slab.typ
// 3-D feature-map prisms. The cuboid is drawn by the renderer (theme + luminance-
// adaptive shading). `conv` gives the canonical "shrinking tower": the front face
// scales with spatial size and the depth scales with channel count.

#import "../ir/ir.typ": ir-node, frag

#let slab(id: auto, caption: none, role: "op", w: 26pt, h: 26pt, depth: 14pt, fill: auto, stroke: auto, style: (:)) = {
  let nid = if id == auto { "slab" } else { id }
  let n = ir-node(
    nid, label: none, kind: "slab", role: role, pos: (0, 0),
    fill: fill, stroke: stroke, style: style,
    data: (w: w, h: h, depth: depth, caption: caption),
  )
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid))
}

// A convolution feature map. `spatial` is the side length (front face), `channels` the
// depth. Front shrinks with spatial; depth grows with channels.
#let conv(id: auto, label: none, spatial: 28, channels: 16, role: "data", ..rest) = {
  let front = calc.min(48pt, 9pt + spatial * 0.85pt)
  let depth = calc.min(28pt, 5pt + channels * 0.5pt)
  let cap = if label != none {
    [#label\ #text(size: 0.82em, fill: luma(95))[#spatial×#spatial×#channels]]
  } else {
    text(size: 0.82em)[#spatial×#spatial×#channels]
  }
  slab(id: id, caption: cap, role: role, w: front, h: front, depth: depth, ..rest.named())
}
