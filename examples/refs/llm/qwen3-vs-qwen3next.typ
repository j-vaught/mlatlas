// Qwen3 235B-A22B vs Qwen3 Next 80B-A3B — two Qwen MoE backbones, side by side.
// Both keep the pre-norm transformer skeleton (RMSNorm → attention → ⊕ → RMSNorm →
// MoE FFN → ⊕) with RoPE, but Qwen3 Next swaps in a HYBRID / GATED attention stack
// and a much sparser mixture-of-experts feed-forward:
//   · Qwen3 235B-A22B — Grouped-query attention (GQA) + QK-Norm, MoE = 8 of 128
//                       experts, 22B active of 235B total.
//   · Qwen3 Next 80B-A3B — Hybrid linear attention: Gated DeltaNet interleaved with
//                       Gated (GQA) attention, MoE = 10 + 1 shared of 512 experts,
//                       only ~3B active of 80B total.
#import "../../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let qwen3-next = (
  name: "Qwen3 Next 80B-A3B",
  accent: rgb("#466A9F"),
  vocab: "151k",
  attention: [Gated DeltaNet /\ Gated attention],
  attn-kind: "moe-attn", // salmon — flags the hybrid / gated variant
  ffn: [MoE (10+1 of 512)],
  ffn-kind: "moe",
  layers: "48×",
  rope: true,
  qk-norm: true,
  dims: (([16 heads], []), ([Active params ], [3B]), ([Total params ], [80B]), ([Experts ], [512])),
)

#llm-compare((qwen3-235b, qwen3-next))
