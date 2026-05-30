// mlatlas · prim/block.typ
// The atom: a labelled node. First positional is flexible (id string doubles as label).

#import "../ir/ir.typ": ir-node, frag

#let block(
  id: auto,
  label: none,
  role: "op",
  kind: "rect",
  emphasis: false,
  fill: auto,
  stroke: auto,
  text-fill: auto,
  width: auto,
  height: auto,
  font: auto,
  text-size: auto,
  style: (:),
) = {
  let nid = if id == auto { "n" } else { id }
  let lbl = if label != none { label } else if id != auto and type(id) == str { [#id] } else { [] }
  let n = ir-node(
    nid, label: lbl, kind: kind, role: role, emphasis: emphasis, pos: (0, 0),
    fill: fill, stroke: stroke, text-fill: text-fill, width: width, height: height,
    font: font, text-size: text-size, style: style,
  )
  frag(nodes: (n,), edges: (), meta: ("in": nid, "out": nid))
}
