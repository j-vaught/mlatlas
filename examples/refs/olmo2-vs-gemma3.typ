// OLMo 2 7B vs Gemma 3 27B — architecture comparison (mlatlas style).
// Both are dense, RoPE + QK-norm transformers; the headline difference is
// norm placement (OLMo 2 post-norm vs Gemma 3 hybrid pre+post norm) and
// Gemma 3's sliding-window / GQA attention. Built from architectural
// knowledge in mlatlas's own style — reference used only to confirm params.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let gemma3-27b = (
  name: "Gemma 3 27B",
  accent: rgb("#466A9F"),
  vocab: "256k",
  attention: [Sliding-window\ grouped-query attention],
  ffn: [Feed forward],
  layers: "62×",
  rope: true,
  qk-norm: true,
  dims: (
    ([32 query / 16 KV heads], []),
    ([Hidden dim ], [21,504]),
    ([Embedding dim ], [5,376]),
    ([Context ], [128k]),
  ),
)

#llm-compare((olmo2-7b, gemma3-27b))
