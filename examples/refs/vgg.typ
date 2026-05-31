// VGG-16 (Simonyan & Zisserman, 2014) — the canonical "very deep" CNN built from
// repeated 3×3 conv blocks, each followed by 2×2 max-pooling that halves the spatial
// resolution while the channel count doubles, ending in three fully-connected layers.
// Rebuilt from architectural knowledge in mlatlas's own style (D2L-style stage stack).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let garnet = rgb("#73000A")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: garnet)[VGG-16] #h(6pt)
  #text(size: 10pt, fill: rgb("#5C5C5C"))[— stacked 3×3 conv blocks · 2×2 max-pool · 3 dense layers]

  #v(6pt)

  // 3-D feature-map stack: front face shrinks with spatial size (224 → 7),
  // depth grows with channels (3 → 64 → 128 → 256 → 512), then the dense head.
  #feature-stack-fig((
    (spatial: 224, channels: 3, base: cnn3d-palette.input, label: [input], sub: [224²×3]),
    (spatial: 224, channels: 64, n: 2, relu: true, label: [conv1], sub: [×2, 224²×64]),
    (spatial: 112, channels: 128, n: 2, relu: true, label: [conv2], sub: [×2, 112²×128]),
    (spatial: 56, channels: 256, n: 3, relu: true, label: [conv3], sub: [×3, 56²×256]),
    (spatial: 28, channels: 512, n: 3, relu: true, label: [conv4], sub: [×3, 28²×512]),
    (spatial: 14, channels: 512, n: 3, relu: true, label: [conv5], sub: [×3, 14²×512]),
    (spatial: 7, channels: 4096, base: cnn3d-palette.fc, width: 0.24, label: [fc6–8], sub: [4096·4096·1000]),
  ))

  #v(2pt)

  #text(size: 8pt, fill: rgb("#5C5C5C"))[
    Every block: $n times$ (3×3 conv, pad 1, ReLU) then 2×2 max-pool, stride 2 ·
    13 conv + 3 FC = 16 weight layers · ≈138M parameters
  ]
]
