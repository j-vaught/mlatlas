// GPT-OSS 20B vs Qwen3 235B-A22B — two open-weight mixture-of-experts (MoE) LLM
// backbones, side by side. Built from architectural knowledge in mlatlas's
// Sebastian-Raschka-style llm-arch renderer. Both share the pre-norm transformer
// skeleton (RMSNorm → attention → ⊕ → RMSNorm → MoE FFN → ⊕) with RoPE, but differ
// in width / depth and the shape of the MoE feed-forward stack:
//   · GPT-OSS 20B  — wider, fewer & bigger experts: GQA with attention sinks +
//                    alternating sliding-window / full attention, MoE = 4 of 32,
//                    24 layers, 3.6B active / 20B total.
//   · Qwen3 235B   — deeper, more & smaller experts: GQA + QK-Norm, MoE = 8 of 128,
//                    94 layers, 22B active / 235B total.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let gpt-oss = (
  name: "GPT-OSS 20B",
  accent: rgb("#73000A"),
  vocab: "200k",
  attention: [Grouped-query attn.\ #text(size: 6pt)[sinks · sliding window]],
  ffn: [MoE (4 of 32)],
  ffn-kind: "moe",
  layers: "24×",
  rope: true,
  dims: (
    ([64 heads], []),
    ([Active params ], [3.6B]),
    ([Total params ], [20B]),
    ([Context ], [131k]),
  ),
)

#llm-compare((gpt-oss, qwen3-235b))
