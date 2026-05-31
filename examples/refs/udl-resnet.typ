// ResNet residual pyramid (UDL / Prince "Understanding Deep Learning" style).
// Stem 7x7/2 + maxpool, then four residual stages that halve spatial resolution and
// double channels (256 -> 512 -> 1024 -> 2048), each bracketed by an identity skip;
// global average pool + 1000-way classifier head.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#align(center)[
  #text(size: 13pt, weight: "bold")[Deep residual network (ResNet) backbone]

  #v(2pt)

  #resnet3d(
    stages: (
      (56, 256, [ResBlock 1], 3),
      (28, 512, [ResBlock 2], 4),
      (14, 1024, [ResBlock 3], 6),
      (7, 2048, [ResBlock 4], 3),
    ),
  )

  #v(2pt)

  #text(size: 8.5pt, fill: rgb("#5C5C5C"))[
    Conv 7#sym.times 7 / stride 2 + max-pool stem · four residual stages
    (spatial halves, channels double) · identity skips over each stage · avg-pool + 1000-way fc
  ]
]
