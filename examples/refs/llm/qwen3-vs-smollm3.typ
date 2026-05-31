// Qwen3 4B vs SmolLM3 3B — dense decoder-only LLM architecture comparison.
// Built from architectural knowledge in mlatlas's Sebastian-Raschka-style llm-arch
// renderer. Both are dense (non-MoE) transformer stacks with grouped-query attention,
// RMSNorm, SwiGLU feed-forward, and RoPE. Distinguishing nuances:
//   Qwen3 4B   — QK-Norm (RMSNorm on Q/K), 32 heads, deeper FFN, 41k context.
//   SmolLM3 3B — NoPE every 4th layer (RoPE on the other 3), 16 heads, 65k context.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let qwen3-4b = (
  name: "Qwen3 4B",
  accent: rgb("#466A9F"),
  vocab: "151k",
  attention: [Masked grouped-query\ attention],
  ffn: [Feed forward],
  layers: "36×",
  rope: true,
  qk-norm: true,
  dims: (
    ([32 heads], []),
    ([Hidden dim ], [9,728]),
    ([Embedding dim ], [2,560]),
    ([Context ], [41k]),
  ),
)

#let smollm3-3b = (
  name: "SmolLM3 3B",
  accent: rgb("#A49137"),
  vocab: "128k",
  attention: [Masked grouped-query\ attention],
  ffn: [Feed forward],
  layers: "36×",
  rope: true,
  qk-norm: false,
  dims: (
    ([16 heads], []),
    ([Hidden dim ], [11,008]),
    ([Embedding dim ], [2,048]),
    ([Context ], [65k]),
  ),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw: content
  let gap = 9.6
  llm-arch(..qwen3-4b, origin: (0, 0))
  llm-arch(..smollm3-3b, origin: (gap, 0))

  // SmolLM3 signature: RoPE applied to 3 of every 4 layers; the 4th uses NoPE.
  // Annotate beneath SmolLM3's RoPE tap (column origin x = gap, RoPE box at ~ -3.9).
  content(
    (gap - 3.9, 3.55),
    text(size: 6.5pt, fill: rgb("#A49137"))[NoPE every\ 4#super[th] layer],
  )
})

