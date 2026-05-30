// mlatlas · presets/sequence.typ — recurrent / sequence models.

#import "../ir/ir.typ": ir-node, ir-edge, frag

// An unrolled recurrent network: input x_t (below) -> cell -> hidden h_t (above), with
// the recurrent state passed left-to-right between cells.
#let rnn-unroll(steps: 4, cell: [RNN]) = {
  let nodes = ()
  let edges = ()
  for t in range(steps) {
    nodes.push(ir-node("x" + str(t), label: [$x_(#t)$], role: "data", pos: (t, 1)))
    nodes.push(ir-node("c" + str(t), label: cell, role: "attention", pos: (t, 0)))
    nodes.push(ir-node("h" + str(t), label: [$h_(#t)$], role: "output", pos: (t, -1)))
    edges.push(ir-edge("x" + str(t), "c" + str(t)))
    edges.push(ir-edge("c" + str(t), "h" + str(t)))
    if t > 0 {
      edges.push(ir-edge("c" + str(t - 1), "c" + str(t), kind: "data", label: if t == 1 { [$h$] } else { none }))
    }
  }
  frag(nodes: nodes, edges: edges, meta: ("in": "c0", "out": "c" + str(steps - 1)))
}
