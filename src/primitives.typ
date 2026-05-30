// mlatlas · primitives.typ
// Leaf builders that emit IR fragments. Phase 0 ships the two most-used leaves:
// `block` (a labelled rectangle — the atom of every architecture figure) and
// `op-node` (a small operator glyph: sum, product, ...). More primitives (slab,
// matrix, neuron-graph, gate, ...) arrive in later phases.

#import "ir.typ": *

// A labelled block. The first positional arg is flexible for ergonomics:
//   block("conv", label: [3x3 conv])   // explicit id + label
//   block(label: [Softmax])            // auto id, content label
//   block("Linear")                    // id doubles as label
#let block(
  id: auto,
  label: none,
  role: "op",
  kind: "rect",
  fill: auto,
  stroke: auto,
  text-fill: auto,
  corner-radius: auto,
  width: auto,
  height: auto,
  style: (:),
) = {
  let nid = if id == auto { "n" } else { id }
  let lbl = if label != none { label } else if id != auto and type(id) == str { [#id] } else { [] }
  let n = ir-node(
    nid,
    label: lbl,
    kind: kind,
    role: role,
    pos: (0, 0),
    fill: fill,
    stroke: stroke,
    text-fill: text-fill,
    corner-radius: corner-radius,
    width: width,
    height: height,
    style: style,
  )
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid, w: 1, h: 1))
}

// A 3-D feature-map "slab" (oblique cuboid) — the right look for conv layers and
// tensor volumes. `w`/`h` are the front-face size, `depth` the projected extrusion;
// `dims` is an optional shape caption shown beneath (e.g. [28x28x6]). The cuboid is
// actually drawn by the renderer (so it picks up the active theme colours).
#let slab(
  id: auto,
  label: none,
  role: "op",
  w: 15pt,
  h: 34pt,
  depth: 15pt,
  dims: none,
  fill: auto,
  style: (:),
) = {
  let nid = if id == auto { "slab" } else { id }
  let n = ir-node(
    nid,
    label: if label != none { label } else { [] },
    kind: "slab",
    role: role,
    pos: (0, 0),
    fill: fill,
    style: style,
    data: (w: w, h: h, depth: depth, dims: dims),
  )
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid, w: 1, h: 1))
}

// Convenience: a convolution feature map. `spatial`/`channels` fill the dims caption
// and scale the prism so deeper layers look deeper.
#let conv(id: auto, label: none, spatial: none, channels: none, role: "op", h: 34pt, depth: auto, ..rest) = {
  let dims = if spatial != none and channels != none { [#spatial$times$#channels] } else if channels != none { [#channels] } else { none }
  let d = if depth != auto { depth } else if channels != none { calc.min(38pt, 8pt + channels * 0.12pt) } else { 15pt }
  slab(id: id, label: label, role: role, h: h, depth: d, dims: dims, ..rest.named())
}

// A small operator node (element-wise add/mul/etc.), drawn as a circle glyph.
#let op-node(id: auto, sym: sym.plus.o, role: "add", size: 6mm) = {
  let nid = if id == auto { "op" } else { id }
  let n = ir-node(
    nid,
    label: [#sym],
    kind: "circle",
    role: role,
    pos: (0, 0),
    width: size,
    height: size,
    inset: 1pt,
  )
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid, w: 1, h: 1))
}
