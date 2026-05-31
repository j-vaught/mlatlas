// Llama 3.2 1B vs Qwen3 0.6B — small dense GQA decoder-only transformers.
// Rebuilt from architectural knowledge in mlatlas style (not traced).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// Llama 3.2 1B: 16 blocks, embed 2048, FFN 8192, 32 Q / 8 KV heads (GQA),
// vocab 128k, RoPE, no QK-norm, 128k context. "Wider" architecture.
#let llama3-1b = (
  name: "Llama 3.2 1B", accent: rgb("#466A9F"), vocab: "128k",
  attention: [Grouped-query\ attention], ffn: [Feed forward], layers: "16×",
  rope: true, qk-norm: false,
  dims: (([32 / 8 heads], []), ([Hidden dim ], [8,192]), ([Embedding dim ], [2,048]), ([Context ], [128k])),
)

// Qwen3 0.6B: 28 blocks, embed 1024, FFN 3072, 16 Q / 8 KV heads (GQA),
// vocab 151k, RoPE, QK-norm, 32k context. "Deeper" architecture.
#let qwen3-06b = (
  name: "Qwen3 0.6B", accent: rgb("#73000A"), vocab: "151k",
  attention: [Grouped-query\ attention], ffn: [Feed forward], layers: "28×",
  rope: true, qk-norm: true,
  dims: (([16 / 8 heads], []), ([Hidden dim ], [3,072]), ([Embedding dim ], [1,024]), ([Context ], [32k])),
)

#llm-compare((llama3-1b, qwen3-06b))
