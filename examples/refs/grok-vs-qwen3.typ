// Grok 2.5 (270B) vs Qwen3 235B-A22B — two large mixture-of-experts LLM
// backbones, side by side. Both ride the pre-norm transformer skeleton
// (RMSNorm -> attention -> + -> RMSNorm -> MoE FFN -> +) with RoPE, but
// differ in the attention variant and the shape of the MoE stack:
//   · Grok 2.5    — Grouped-query attention, MoE = 8 experts (2 active)
//   · Qwen3 235B  — Grouped-query attention + QK-Norm, MoE = 8 of 128
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let grok-2-5 = (
  name: "Grok 2.5 (270B)", accent: rgb("#73000A"), vocab: "131k",
  attention: [Grouped-query\ attention], ffn: [MoE (8 experts, 2 active)], ffn-kind: "moe",
  layers: "64×", rope: true,
  dims: (([64 heads], []), ([Active params ], [≈115B]), ([Total params ], [270B]), ([Experts ], [8])),
)

#llm-compare((grok-2-5, qwen3-235b))
