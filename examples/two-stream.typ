// Two-stream / multi-modal fusion (dual backbone) — built with `two-stream` / `merge`.
#import "../lib.typ": *

#let image-stream = seq(
  block(id: "img", label: [Image], role: "data"),
  conv(label: [Conv], channels: 64, role: "attention"),
  conv(label: [Conv], channels: 128, role: "attention"),
)
#let text-stream = seq(
  block(id: "txt", label: [Text], role: "data"),
  block(label: [Embed], role: "op"),
  block(label: [Transformer], role: "attention"),
)

#standalone(
  two-stream(
    image-stream, text-stream,
    fusion: [Fusion],
    head: seq(block(label: [MLP Head], role: "op"), block(label: [Output], role: "output")),
  ),
  theme: colorful,
)
