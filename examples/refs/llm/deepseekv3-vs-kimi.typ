// DeepSeek V3/R1 vs Kimi K2 — two DeepSeek-style MoE + MLA transformer stacks.
// Both share the same recipe (Multi-head latent attention + MoE feed-forward, 61 blocks,
// RoPE). Kimi K2 scales the recipe up: fewer attention heads (64 vs 128) but far more
// experts (384 vs 256), giving ~1T total / 32B active vs 671B / 37B.
// Rebuilt from architectural knowledge in mlatlas's own style — not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let deepseek-v3 = (
  name: "DeepSeek V3 / R1", accent: rgb("#73000A"), vocab: "129k",
  attention: [Multi-head latent\ attention], attn-kind: "moe-attn",
  ffn: [MoE (1 shared + 8 of 256)], ffn-kind: "moe", layers: "61×", rope: true,
  dims: (
    ([128 heads], []),
    ([Expert hidden ], [2,048]),
    ([Embedding dim ], [7,168]),
    ([Active / total ], [37B / 671B]),
  ),
)

#let kimi-k2 = (
  name: "Kimi K2", accent: rgb("#466A9F"), vocab: "160k",
  attention: [Multi-head latent\ attention], attn-kind: "moe-attn",
  ffn: [MoE (1 shared + 8 of 384)], ffn-kind: "moe", layers: "61×", rope: true,
  dims: (
    ([64 heads], []),
    ([Expert hidden ], [2,048]),
    ([Embedding dim ], [7,168]),
    ([Active / total ], [32B / 1.04T]),
  ),
)

#llm-compare((deepseek-v3, kimi-k2))
