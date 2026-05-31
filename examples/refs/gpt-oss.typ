// GPT-OSS 20B — open-weight MoE transformer.
// Pre-norm (RMSNorm) blocks · Grouped-query attention with attention sinks and
// alternating sliding-window / full attention · MoE feed-forward (4 of 32 experts).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let gpt-oss-20b = (
  name: "GPT-OSS 20B",
  accent: rgb("#73000A"),
  vocab: "200k",
  attention: [Grouped-query attn.\ #text(size: 6pt)[sinks · sliding window]],
  ffn: [MoE (4 of 32 experts)],
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

#llm-figure(..gpt-oss-20b)
