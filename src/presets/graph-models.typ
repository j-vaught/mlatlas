// mlatlas · presets/graph-models.typ — graph neural networks.

#import "../ir/ir.typ": ir-node, ir-edge, frag

// One message-passing step: neighbour states aggregated into the central node update.
#let message-passing(neighbors: 3) = {
  let nodes = (ir-node("c", label: [$h_v^(t+1)$], role: "attention", pos: (0, 0)),)
  let edges = ()
  let span = (neighbors - 1) / 2
  for i in range(neighbors) {
    let u = (i - span) * 1.3
    nodes.push(ir-node("n" + str(i), label: [$h_(u_#i)$], role: "op", pos: (u, 1.3)))
    edges.push(ir-edge("n" + str(i), "c", kind: "data", route: "straight", label: if i == 0 { [msg] } else { none }))
  }
  frag(nodes: nodes, edges: edges, meta: ("in": "c", "out": "c"))
}

// A 2-layer GCN as a labelled pipeline.
#import "../prim/block.typ": block
#import "../sugar/sugar.typ": seq
#let gcn(layers: 2) = seq(
  block(id: "in", label: [Node features $X$\, edges $A$], role: "data"),
  ..range(layers).map(i => block(label: [Graph Conv #(i + 1)\ #text(size: 0.8em)[$tilde(A) H W$]], role: "attention")),
  block(label: [Softmax], role: "param"),
  block(id: "out", label: [Node labels], role: "output"),
)
