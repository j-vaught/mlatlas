// Graph neural network: radial message passing (multi-head) + a GCN pipeline.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 12pt, fill: white)

#stack(
  dir: ltr,
  spacing: 24pt,
  align(horizon, message-passing(neighbors: 5, heads: 3)),
  align(horizon, render(gcn(layers: 2), theme: paper)),
)
