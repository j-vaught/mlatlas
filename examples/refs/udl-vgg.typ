// VGG-16 (Simonyan & Zisserman, 2014) — UDL / Prince "Understanding Deep Learning" style.
// Rebuilt from architectural knowledge in mlatlas's own style (3-D feature-map stack):
// five blocks of repeated 3×3 convs, each closed by a 2×2 MaxPool that halves the spatial
// resolution (224→112→56→28→14→7) while channels double (3→64→128→256→512), then a dense
// head of two 4096-wide FC layers + a 1000-way classifier with softmax. 13 conv + 3 FC.
// Reference confirms params only — not traced.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let garnet = rgb("#73000A")
#let muted = rgb("#5C5C5C")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: garnet)[VGG-16] #h(6pt)
  #text(size: 10pt, fill: muted)[— repeated 3×3 conv blocks · 2×2 max-pool · dense head]

  #v(8pt)

  // Front face shrinks with spatial size; depth grows (log) with channel count.
  // Salmon volumes = conv stacks (UDL "Conv 3×3" + "MaxPool"); blue slabs = the FC head.
  #feature-stack-fig((
    (spatial: 224, channels: 3, base: cnn3d-palette.input, label: [input], sub: [224²×3]),
    (spatial: 224, channels: 64, n: 2, relu: true, label: [Conv 3×3], sub: [224²×64]),
    (spatial: 112, channels: 128, n: 2, relu: true, label: [MaxPool], sub: [112²×128]),
    (spatial: 56, channels: 256, n: 3, relu: true, label: [Conv 3×3], sub: [56²×256]),
    (spatial: 28, channels: 512, n: 3, relu: true, label: [MaxPool], sub: [28²×512]),
    (spatial: 14, channels: 512, n: 3, relu: true, label: [Conv 3×3], sub: [14²×512]),
    (spatial: 7, channels: 4096, base: cnn3d-palette.fc, width: 0.20, label: [FC], sub: [4096]),
    (spatial: 7, channels: 4096, base: cnn3d-palette.fc, width: 0.20, label: [FC], sub: [4096]),
    (spatial: 7, channels: 1000, base: cnn3d-palette.up, width: 0.20, label: [Softmax], sub: [1000]),
  ))

  #v(4pt)

  #text(size: 8pt, fill: muted)[
    Each block: $n times$ (3×3 conv, pad 1, ReLU) then 2×2 max-pool, stride 2 ·
    spatial halves, channels double · 13 conv + 3 FC = 16 weight layers · ≈138M parameters
  ]
]
