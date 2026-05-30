// mlatlas · prim/slab.typ
// 3-D feature-map prisms for conv layers / tensor volumes. The cuboid is drawn by the
// renderer (so it picks up the active theme + luminance-adaptive shading).

#import "../ir/ir.typ": ir-node, frag

#let slab(id: auto, label: none, role: "op", w: 15pt, h: 34pt, depth: 15pt, dims: none, fill: auto, style: (:)) = {
  let nid = if id == auto { "slab" } else { id }
  let n = ir-node(
    nid, label: if label != none { label } else { [] }, kind: "slab", role: role, pos: (0, 0),
    fill: fill, style: style, data: (w: w, h: h, depth: depth, dims: dims),
  )
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid))
}

// A convolution feature map: dims caption + depth scales with channel count.
#let conv(id: auto, label: none, spatial: none, channels: none, role: "op", h: 34pt, w: 14pt, depth: auto, ..rest) = {
  let dims = if spatial != none and channels != none { [#spatial$times$#channels] } else if channels != none { [#channels] } else { none }
  let d = if depth != auto { depth } else if channels != none { calc.min(40pt, 8pt + channels * 0.12pt) } else { 15pt }
  slab(id: id, label: label, role: role, h: h, w: w, depth: d, dims: dims, ..rest.named())
}
