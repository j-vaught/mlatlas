// Gemma 3 27B vs Mistral 3.1 Small 24B — both dense GQA transformers.
// Rebuilt from architectural knowledge in mlatlas style (Raschka-style columns).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let gemma3-27b = (
  name: "Gemma 3 27B", accent: rgb("#466A9F"), vocab: "256k",
  attention: [Grouped-query attn.\ (+ sliding window)], ffn: [Feed forward],
  layers: "62×", rope: true, qk-norm: true,
  dims: (
    ([32 heads, 16 KV], []),
    ([Hidden dim ], [21,504]),
    ([Embedding dim ], [5,376]),
    ([Context ], [128k]),
  ),
)

#let mistral-small-24b = (
  name: "Mistral 3.1 Small 24B", accent: rgb("#CC2E40"), vocab: "256k",
  attention: [Grouped-query\ attention], ffn: [Feed forward],
  layers: "40×", rope: true, qk-norm: false,
  dims: (
    ([40 heads, 8 KV], []),
    ([Hidden dim ], [32,768]),
    ([Embedding dim ], [5,120]),
    ([Context ], [128k]),
  ),
)

#llm-compare((gemma3-27b, mistral-small-24b))
