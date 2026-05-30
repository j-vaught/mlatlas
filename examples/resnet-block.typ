// A ResNet stem + bottleneck stage. `resnet-stage` emits each residual unit with an
// auto-routed identity skip around the conv sub-stack.
#import "../lib.typ": *

#standalone(seq(
  block(id: "stem", label: [7#sym.times 7 conv, /2], role: "data"),
  block(id: "pool", label: [maxpool, /2], role: "op"),
  resnet-stage(blocks: 3, channels: 64, bottleneck: true),
))
