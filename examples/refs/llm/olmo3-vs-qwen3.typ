// OLMo 3 7B vs Qwen3 8B — dense decoder-only LLM architecture comparison.
// Rebuilt from architectural knowledge in mlatlas's Sebastian-Raschka-style
// llm-arch renderer (not traced from the reference). Both are dense (non-MoE)
// transformer stacks with RMSNorm, SwiGLU feed-forward and RoPE. Nuances:
//   OLMo 3 7B — QK-Norm, full multi-head attention (32 Q / 32 KV), sliding-window
//               local attention (4,096) with full global layers (YaRN on global
//               layers only), 32 blocks, 11,008 intermediate FFN, 100k vocab.
//   Qwen3 8B  — QK-Norm, grouped-query attention (32 Q / 8 KV), 36 blocks,
//               12,288 intermediate FFN (3 × 4,096), 151k vocab.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let olmo3-7b = (
  name: "OLMo 3 7B",
  accent: rgb("#CC2E40"),
  vocab: "100k",
  attention: [Masked multi-head\ attention],
  ffn: [Feed forward],
  layers: "32×",
  rope: true,
  qk-norm: true,
  dims: (
    ([32 / 32 heads], []),
    ([Hidden dim ], [11,008]),
    ([Embedding dim ], [4,096]),
    ([Context ], [64k]),
  ),
)

#let qwen3-8b = (
  name: "Qwen3 8B",
  accent: rgb("#466A9F"),
  vocab: "151k",
  attention: [Masked grouped-query\ attention],
  ffn: [Feed forward],
  layers: "36×",
  rope: true,
  qk-norm: true,
  dims: (
    ([32 / 8 heads], []),
    ([Hidden dim ], [12,288]),
    ([Embedding dim ], [4,096]),
    ([Context ], [32k]),
  ),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw: content
  let gap = 9.6
  llm-arch(..olmo3-7b, origin: (0, 0))
  llm-arch(..qwen3-8b, origin: (gap, 0))

  // OLMo 3 signature: local layers use sliding-window attention (4,096);
  // full attention + YaRN on the global layers only. The RoPE / QK-Norm taps
  // sit on the far left (x ~ -3.5 to -4.4); place this note clear below them.
  content(
    (-3.9, 2.5),
    text(size: 6.5pt, fill: rgb("#CC2E40"))[Sliding window\ (4,096) on\ local layers],
  )
})
