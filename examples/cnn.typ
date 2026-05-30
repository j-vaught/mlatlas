// A LeNet-style CNN drawn with 3-D feature-map prisms (`conv`/`slab`). Spatial size
// shrinks and depth (channels) grows left-to-right, the classic CNN look.
#import "../lib.typ": *

#standalone(
  seq(
    slab(label: [], dims: [32#sym.times 32#sym.times 1], h: 58pt, w: 11pt, depth: 8pt, role: "data"),
    conv(label: [C1], spatial: [28#sym.times 28], channels: 6, h: 52pt, role: "attn"),
    conv(label: [S2], spatial: [14#sym.times 14], channels: 6, h: 30pt, role: "norm"),
    conv(label: [C3], spatial: [10#sym.times 10], channels: 16, h: 22pt, role: "attn"),
    conv(label: [S4], spatial: [5#sym.times 5], channels: 16, h: 14pt, role: "norm"),
    block(id: "fc", label: [FC\ 120], role: "op"),
    block(id: "out", label: [Softmax\ 10], role: "param"),
  ),
  dir: "ltr",
  spacing: (9mm, 10mm),
)
