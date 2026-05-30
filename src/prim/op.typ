// mlatlas · prim/op.typ
// Small operator glyphs (elementwise add/mul/concat), drawn as a circle.

#import "../ir/ir.typ": ir-node, frag

#let op-node(id: auto, sym: sym.plus.o, role: "add", size: 6mm, kind: "circle") = {
  let nid = if id == auto { "op" } else { id }
  let n = ir-node(nid, label: [#sym], kind: kind, role: role, pos: (0, 0), width: size, height: size, inset: 1pt)
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid))
}

#let add-op(id: auto) = op-node(id: id, sym: sym.plus.o)
#let mul-op(id: auto) = op-node(id: id, sym: sym.times.circle)
