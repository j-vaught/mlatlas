// Overview comparison of four modern LLM architectures, Sebastian-Raschka style.
// Dense pre-norm GQA (Llama 3) · dense post-/QK-norm MHA (OLMo 2) ·
// MoE + multi-head latent attention (DeepSeek V3) · MoE + GQA (Qwen3).
// Rebuilt from architectural knowledge in mlatlas's own style.
#import "../../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#llm-compare((llama3-8b, olmo2-7b, deepseek-v3, qwen3-235b))
