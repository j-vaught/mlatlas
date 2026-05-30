// mlatlas · prim/neuron-graph.typ
// Columns of neurons (circles) with weighted edges — the classic perceptron / MLP /
// node-edge picture. `layers` is an array of layer sizes, e.g. (3, 5, 2). Edges are
// straight (diagonal) lines, not orthogonal, which is the convention for these.

#import "../ir/ir.typ": ir-node, ir-edge, frag

#let neuron-graph(
  layers,
  id: "ng",
  role: "op",
  layer-roles: none, // optional array of roles per layer (e.g. input/op/output)
  node-size: 6mm,
  hgap: 1.4,
  vgap: 1,
  dense: true,
  edge-kind: "data",
) = {
  let nodes = ()
  let edges = ()
  let nid(l, i) = id + "-" + str(l) + "-" + str(i)
  for (l, count) in layers.enumerate() {
    let r = if layer-roles != none and l < layer-roles.len() { layer-roles.at(l) } else { role }
    for i in range(count) {
      let v = i - (count - 1) / 2
      nodes.push(ir-node(nid(l, i), label: [], kind: "circle", role: r, pos: (l * hgap, v * vgap), width: node-size, height: node-size, inset: 1pt))
    }
  }
  if dense {
    for l in range(layers.len() - 1) {
      for i in range(layers.at(l)) {
        for j in range(layers.at(l + 1)) {
          edges.push(ir-edge(nid(l, i), nid(l + 1, j), kind: edge-kind, route: "straight", marks: (none, none)))
        }
      }
    }
  }
  frag(
    nodes: nodes, edges: edges,
    meta: ("in": nid(0, 0), "out": nid(layers.len() - 1, 0)),
  )
}
