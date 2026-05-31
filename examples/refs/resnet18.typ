// ResNet-18 — full convolutional backbone (He et al., 2015), textbook/d2l layout.
//
// Rebuilt from architectural knowledge in mlatlas's own 3-D style. ResNet-18 is the
// shallowest of the canonical ResNets: a 7x7/stride-2 stem + 3x3 max-pool, then FOUR
// residual STAGES of TWO basic blocks each (each basic block = two 3x3 convs + an
// identity / projection skip), ending in global average pooling and a 1000-way FC head.
//
//   stem  : 7x7 conv 64, s2  -> 112^2 ;  3x3 maxpool s2 -> 56^2
//   stage1: 2 basic blocks, 64 ch , 56^2
//   stage2: 2 basic blocks, 128 ch, 28^2   (first block downsamples, projection skip)
//   stage3: 2 basic blocks, 256 ch, 14^2   (")
//   stage4: 2 basic blocks, 512 ch, 7^2    (")
//   head  : global avg-pool -> fc 1000
//
// The stock `resnet3d` renderer draws exactly this shrink-and-deepen pyramid: spatial
// shrinks left-to-right, channels deepen, and a garnet identity skip arcs over each stage.

#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#align(center)[
  #text(size: 14pt, weight: "bold")[ResNet-18 architecture]
  #v(2pt)
  #text(size: 9pt, fill: rgb("#5C5C5C"))[
    7×7 stem + 3×3 max-pool, four residual stages (2 basic blocks each), global avg-pool, fc-1000
  ]
  #v(8pt)

  #resnet3d(stages: (
    (56, 64, [stage1], 2),
    (28, 128, [stage2], 2),
    (14, 256, [stage3], 2),
    (7, 512, [stage4], 2),
  ))
]
