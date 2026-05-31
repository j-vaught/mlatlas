// mlatlas · renderers/llm.typ
// Sebastian-Raschka-style LLM architecture columns: a vertical model stack (input ->
// tokenize -> embed -> N× transformer block -> final norm -> output head -> vocab),
// residual ⊕ routing on the left, a RoPE tap, the grey block container with an "N×"
// multiplier, colour-coded dimension annotations, and a side-by-side compare.
// Brand-adapted: sharp corners, stealth arrows.

#import "@preview/cetz:0.5.2"

#let llm-palette = (
  ink: rgb("#333333"),
  container: rgb("#EAEAEA"), container-stroke: rgb("#9A9A9A"),
  norm: rgb("#ECECEC"),
  attn: rgb("#F2A6C9"), attn-stroke: rgb("#C24C84"),
  moe: rgb("#F6B0A0"), moe-stroke: rgb("#C9543B"),
  ffn: rgb("#FFFFFF"),
  rope: rgb("#F4F4F4"),
  muted: rgb("#6A6A6A"),
)

// One model column (call inside a cetz.canvas, or via llm-figure / llm-compare).
#let llm-arch(
  name: "Llama 3 8B",
  accent: rgb("#466A9F"),
  vocab: "128k",
  attention: "Grouped-query attention",
  attn-kind: "attn", // "attn" (pink) | "moe-attn" (salmon)
  ffn: "Feed forward",
  ffn-kind: "ffn", // "ffn" | "moe"
  layers: "32×",
  rope: true,
  qk-norm: false,
  dims: (), // array of (label, value) annotation pairs
  palette: llm-palette,
  origin: (0, 0),
) = {
  import cetz.draw: rect, line, content, circle
  let p = palette
  let ink = p.ink
  let w = 3.7
  let lane = w / 2 + 0.32 // residual gutter OUTSIDE the blocks (never crosses a border)
  let g(c) = (origin.at(0) + c.at(0), origin.at(1) + c.at(1))
  let box(y, lbl, fill: white, stroke: 0.9pt + ink, h: 0.6, tw: w, sz: 7.5pt) = {
    rect(g((-tw / 2, y - h / 2)), g((tw / 2, y + h / 2)), fill: fill, stroke: stroke, radius: 0pt)
    content(g((0, y)), text(size: sz, fill: rgb("#1A1A1A"))[#lbl])
  }
  let op(y, sym) = {
    circle(g((0, y)), radius: 0.23, fill: white, stroke: 0.9pt + ink)
    content(g((0, y)), text(size: 8pt, fill: ink)[#sym])
  }
  let arr(a, b) = line(g(a), g(b), stroke: 0.9pt + ink, mark: (end: "stealth", scale: 0.8))
  let ln(..pts) = line(..pts.pos().map(g), stroke: 1pt + ink)

  let yIn = 0.0
  let yTok = 0.95
  let yEmb = 1.95
  let cBot = 2.6
  let yN1 = 3.25
  let yAttn = 4.45
  let yAdd1 = 5.55
  let yN2 = 6.35
  let yFfn = 7.45
  let yAdd2 = 8.55
  let cTop = 9.2
  let yFinal = 9.95
  let yOut = 10.85
  let yVocab = 11.7

  // grey container behind the repeated block
  rect(g((-w / 2 - 0.55, cBot)), g((w / 2 + 0.55, cTop)), fill: p.container, stroke: 0.8pt + p.container-stroke, radius: 0pt)
  content(g((-w / 2 - 0.95, (cBot + cTop) / 2)), text(size: 11pt, weight: "bold", fill: accent)[#layers], anchor: "east")

  // bottom stack
  content(g((0, yIn)), text(size: 7.5pt, style: "italic", fill: ink)[Sample input text])
  box(yTok, [Tokenized text])
  box(yEmb, [Token embedding layer])
  arr((0, yIn + 0.22), (0, yTok - 0.3))
  arr((0, yTok + 0.3), (0, yEmb - 0.3))
  arr((0, yEmb + 0.3), (0, yN1 - 0.3))

  // sublayers
  box(yN1, [RMSNorm 1], fill: p.norm)
  let ac = if attn-kind == "moe-attn" { p.moe } else { p.attn }
  let acs = if attn-kind == "moe-attn" { 1pt + p.moe-stroke } else { 1pt + p.attn-stroke }
  box(yAttn, attention, fill: ac, stroke: acs, h: 0.8, sz: 7pt)
  op(yAdd1, $+$)
  box(yN2, [RMSNorm 2], fill: p.norm)
  let fc = if ffn-kind == "moe" { p.moe } else { p.ffn }
  let fcs = if ffn-kind == "moe" { 1pt + p.moe-stroke } else { 0.9pt + ink }
  box(yFfn, ffn, fill: fc, stroke: fcs)
  op(yAdd2, $+$)

  arr((0, yN1 + 0.3), (0, yAttn - 0.4))
  arr((0, yAttn + 0.4), (0, yAdd1 - 0.23))
  arr((0, yAdd1 + 0.23), (0, yN2 - 0.3))
  arr((0, yN2 + 0.3), (0, yFfn - 0.3))
  arr((0, yFfn + 0.3), (0, yAdd2 - 0.23))

  // residual lanes (left side)
  ln((0, yN1 - 0.45), (-lane, yN1 - 0.45), (-lane, yAdd1), (-0.23, yAdd1))
  ln((0, yN2 - 0.5), (-lane, yN2 - 0.5), (-lane, yAdd2), (-0.23, yAdd2))

  // RoPE / QK-norm taps on the far left
  if rope {
    rect(g((-w / 2 - 2.0, yAttn - 0.27)), g((-w / 2 - 1.1, yAttn + 0.27)), fill: p.rope, stroke: 0.9pt + ink)
    content(g((-w / 2 - 1.55, yAttn)), text(size: 7pt, fill: ink)[RoPE])
    line(g((-w / 2 - 1.1, yAttn)), g((-w / 2 - 0.02, yAttn)), stroke: 0.9pt + ink, mark: (end: "stealth", scale: 0.7))
  }
  if qk-norm {
    rect(g((-w / 2 - 2.0, yN1 - 0.27)), g((-w / 2 - 1.1, yN1 + 0.27)), fill: p.norm, stroke: 0.9pt + ink)
    content(g((-w / 2 - 1.55, yN1)), text(size: 6.5pt, fill: ink)[QK-Norm])
    line(g((-w / 2 - 1.1, yN1)), g((-w / 2 - 0.02, yN1)), stroke: 0.9pt + ink, mark: (end: "stealth", scale: 0.7))
  }

  // top stack
  arr((0, yAdd2 + 0.23), (0, yFinal - 0.3))
  box(yFinal, [Final RMSNorm], fill: p.norm)
  box(yOut, [Linear output layer])
  arr((0, yFinal + 0.3), (0, yOut - 0.3))
  arr((0, yOut + 0.3), (0, yVocab - 0.05))
  content(g((w / 2 + 0.3, yVocab)), text(size: 7.5pt, fill: ink)[Vocabulary size of #text(fill: accent)[#vocab]], anchor: "west")

  content(g((0, yVocab + 0.75)), text(size: 12pt, weight: "bold", fill: accent)[#name])

  // right-side dimension annotations
  let anchors = (yAttn, yN2 + 0.4, yEmb + 0.3, yTok)
  for (i, d) in dims.enumerate() {
    let yy = anchors.at(calc.rem(i, anchors.len()))
    line(g((w / 2 + 0.05, yy)), g((w / 2 + 0.7, yy)), stroke: 0.6pt + p.muted)
    content(g((w / 2 + 0.78, yy)), text(size: 6.8pt, fill: p.muted)[#d.at(0) #text(fill: accent)[#d.at(1)]], anchor: "west")
  }
}

// ---- a few ready-made model specs (pass to llm-compare) ----
#let llama3-8b = (
  name: "Llama 3 8B", accent: rgb("#466A9F"), vocab: "128k",
  attention: [Masked grouped-query\ attention], ffn: [Feed forward], layers: "32×", rope: true,
  dims: (([32 heads], []), ([Hidden dim ], [14,336]), ([Embedding dim ], [4,096]), ([Context ], [128k])),
)
#let olmo2-7b = (
  name: "OLMo 2 7B", accent: rgb("#CC2E40"), vocab: "100k",
  attention: [Masked multi-head\ attention], ffn: [Feed forward], layers: "32×", rope: true, qk-norm: true,
  dims: (([32 heads], []), ([Hidden dim ], [11,008]), ([Embedding dim ], [4,096]), ([Context ], [4k])),
)
#let deepseek-v3 = (
  name: "DeepSeek V3", accent: rgb("#73000A"), vocab: "129k",
  attention: [Multi-head latent\ attention], attn-kind: "moe-attn",
  ffn: [MoE (1 shared + 8 of 256)], ffn-kind: "moe", layers: "61×", rope: true,
  dims: (([128 heads], []), ([Active params ], [37B]), ([Total params ], [671B]), ([Experts ], [256])),
)
#let qwen3-235b = (
  name: "Qwen3 235B-A22B", accent: rgb("#65780B"), vocab: "151k",
  attention: [Grouped-query\ attention], ffn: [MoE (8 of 128)], ffn-kind: "moe", layers: "94×", rope: true, qk-norm: true,
  dims: (([64 heads], []), ([Active params ], [22B]), ([Total params ], [235B]), ([Experts ], [128])),
)

#let llm-figure(..args) = cetz.canvas(length: 1cm, { llm-arch(..args) })

#let llm-compare(models, gap: 9.6) = cetz.canvas(length: 1cm, {
  for (i, m) in models.enumerate() { llm-arch(..m, origin: (i * gap, 0)) }
})
