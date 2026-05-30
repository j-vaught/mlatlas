// Graph neural network: message passing + a GCN pipeline.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 8pt, fill: white)

#stack(
  dir: ltr,
  spacing: 20pt,
  align(horizon, render(message-passing(neighbors: 3))),
  align(horizon, render(gcn(layers: 2))),
)
