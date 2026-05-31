// DeepSeek V3 (671B) vs Qwen3 235B-A22B — two MoE LLM backbones, side by side.
// Both share the pre-norm transformer skeleton (RMSNorm → attention → ⊕ →
// RMSNorm → FFN → ⊕) with RoPE, but differ in the attention variant and the
// shape of the mixture-of-experts feed-forward stack:
//   · DeepSeek V3   — Multi-head latent attention (MLA), MoE = 1 shared + 8 of 256
//   · Qwen3 235B    — Grouped-query attention (GQA) + QK-Norm, MoE = 8 of 128
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#llm-compare((deepseek-v3, qwen3-235b))
