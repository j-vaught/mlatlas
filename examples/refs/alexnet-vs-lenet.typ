// AlexNet (2012) vs LeNet-5 (1998) — both rendered as 3-D feature-map stacks in
// mlatlas's own style. Built from architectural knowledge; the d2l reference is
// used only to confirm layer counts / dimensions. AlexNet is visibly deeper and
// wider — the point of the comparison.
#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// LeNet-5 (LeCun et al., 1998) as a 3-D feature-map stack, matching alexnet3d()'s style.
// input 32²×1 → C1 28²×6 → S2 14²×6 → C3 10²×16 → S4 5²×16 → F6 120 → F7 84 → out 10.
#let lenet5-3d() = feature-stack-fig((
  (spatial: 32, channels: 1, base: cnn3d-palette.input, label: [input]),
  (spatial: 28, channels: 6, relu: true, label: [C1]),
  (spatial: 14, channels: 6, base: cnn3d-palette.pool, label: [S2]),
  (spatial: 10, channels: 16, relu: true, label: [C3]),
  (spatial: 5, channels: 16, base: cnn3d-palette.pool, label: [S4]),
  (spatial: 4, channels: 120, base: cnn3d-palette.fc, width: 0.24, label: [F6]),
  (spatial: 4, channels: 84, base: cnn3d-palette.fc, width: 0.24, label: [F7]),
  (spatial: 4, channels: 10, base: cnn3d-palette.fc, width: 0.24, label: [out]),
))

#let garnet = rgb("#73000A")

#let head(title, sub) = [
  #text(size: 12pt, weight: "bold", fill: garnet)[#title]
  #h(6pt)
  #text(size: 8.5pt, fill: rgb("#5C5C5C"))[#sub]
]

#align(center)[
  #stack(
    dir: ttb,
    spacing: 4pt,
    align(left, head([AlexNet], [Krizhevsky et al., 2012 · 227²×3 input · 8 weight layers · #sym.tilde.op 60M params])),
    alexnet3d(),
    v(16pt),
    align(left, head([LeNet-5], [LeCun et al., 1998 · 32²×1 input · 7 weight layers · #sym.tilde.op 60K params])),
    lenet5-3d(),
  )
]
