// ResNet stem + bottleneck stage; each unit gets an auto-routed identity skip (garnet).
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 10pt, fill: white)

#standalone(seq(
  block2d(id: "stem", label: [7×7 conv, /2], role: "op"),
  block2d(id: "pool", label: [maxpool, /2], role: "op"),
  resnet-stage(blocks: 3, channels: 64, bottleneck: true),
))
