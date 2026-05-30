// ResNet stem + bottleneck stage; each unit gets an auto-routed identity skip.
#import "../lib.typ": *

#standalone(seq(
  block(id: "stem", label: [7×7 conv, /2], role: "data"),
  block(id: "pool", label: [maxpool, /2], role: "norm"),
  resnet-stage(blocks: 3, channels: 64, bottleneck: true),
))
