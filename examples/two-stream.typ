// Two-stream / multi-modal fusion via the dedicated symmetric renderer.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 14pt, fill: white)

#two-stream(
  left-label: [Image], left: ([Conv 64], [Conv 128]),
  right-label: [Text], right: ([Embed], [Transformer]),
  fusion: [Fusion],
  head: ([MLP Head], [Output]),
)
