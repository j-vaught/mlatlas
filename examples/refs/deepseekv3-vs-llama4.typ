// DeepSeek V3 vs Llama 4 Maverick — two frontier MoE LLMs, rebuilt in mlatlas style.
// DeepSeek V3: Multi-head latent attention (MLA) + fine-grained MoE (1 shared + 8 of 256).
// Llama 4 Maverick: Grouped-query attention (iRoPE) + coarse MoE (1 shared + 1 of 128),
// with dense FFN layers interleaved between MoE layers. "More, smaller experts" vs
// "fewer, bigger experts".  Built from architecture knowledge, not traced.
#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// Llama 4 Maverick spec (deepseek-v3 ships with the library).
#let llama4-maverick = (
  name: "Llama 4 Maverick",
  accent: rgb("#466A9F"),
  vocab: "202k",
  attention: [Grouped-query\ attention (iRoPE)],
  ffn: [MoE (1 shared + 1 of 128)],
  ffn-kind: "moe",
  layers: "48×",
  rope: true,
  dims: (
    ([40 heads], []),
    ([Active params ], [17B]),
    ([Total params ], [400B]),
    ([Experts ], [128]),
  ),
)

#llm-compare((deepseek-v3, llama4-maverick))
