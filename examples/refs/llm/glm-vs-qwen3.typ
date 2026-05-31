// GLM-4.5 (355B) vs Qwen3 235B-A22B — two MoE LLM backbones, side by side.
// Both share the pre-norm transformer skeleton (RMSNorm → attention → ⊕ →
// RMSNorm → FFN → ⊕) with RoPE + QK-Norm and grouped-query attention, but
// differ in scale and the shape of the mixture-of-experts feed-forward stack:
//   · GLM-4.5  — 355B total / ~32B active, MoE = 1 shared + 8 of 160 experts;
//                first 3 blocks use a dense SwiGLU FFN instead of MoE.
//   · Qwen3 235B-A22B — 235B total / 22B active, MoE = 8 of 128 experts.
// Rebuilt from architectural knowledge in mlatlas's own style.
#import "../../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let glm-45 = (
  name: "GLM-4.5 (355B)", accent: rgb("#466A9F"), vocab: "151k",
  attention: [Grouped-query\ attention], ffn: [MoE (1 shared + 8 of 160)], ffn-kind: "moe",
  layers: "92×", rope: true, qk-norm: true,
  dims: (([96 heads], []), ([Active params ], [32B]), ([Total params ], [355B]), ([Experts ], [160])),
)

#llm-compare((glm-45, qwen3-235b))
