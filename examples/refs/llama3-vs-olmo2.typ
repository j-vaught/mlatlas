// Llama 3 8B vs OLMo 2 7B — Sebastian-Raschka-style architecture comparison.
//
// Built from architectural knowledge in mlatlas's own style. The headline
// contrast is NORM PLACEMENT inside the transformer block:
//   • Llama 3  — PRE-norm: RMSNorm -> sublayer -> (+)   [stock llm-arch]
//   • OLMo 2   — POST-norm: sublayer -> RMSNorm -> (+),  plus QK-norm on Q,K
// The stock `olmo2-7b` spec renders pre-norm, so OLMo 2 gets a small inline
// post-norm variant here to keep the defining difference visible. Llama 3 uses
// the shipped renderer + spec unchanged.

#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// ---- OLMo 2 post-norm column (mirrors llm-arch geometry & palette) ----
#let olmo2-postnorm(origin: (0, 0)) = {
  import cetz.draw: rect, line, content, circle
  let p = llm-palette
  let ink = p.ink
  let accent = rgb("#CC2E40")
  let w = 3.7
  let chw = w / 2 + 0.72
  let lane = w / 2 + 0.3
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

  // y-layout — sublayer first, THEN its norm, then the add (post-norm)
  let yIn = 0.0
  let yTok = 0.95
  let yEmb = 1.95
  let cBot = 2.6
  let yAttn = 3.55   // masked multi-head attention
  let yN1 = 4.65     // RMSNorm 1  (after attention)
  let yAdd1 = 5.55
  let yFfn = 6.55    // feed forward
  let yN2 = 7.65     // RMSNorm 2  (after FFN)
  let yAdd2 = 8.55
  let cTop = 9.2
  let yFinal = 9.95
  let yOut = 10.85
  let yVocab = 11.7

  // grey container behind the repeated block
  rect(g((-chw, cBot)), g((chw, cTop)), fill: p.container, stroke: 0.8pt + p.container-stroke, radius: 0pt)
  content(g((-chw - 0.25, (cBot + cTop) / 2)), text(size: 11pt, weight: "bold", fill: accent)[32×], anchor: "east")

  // bottom stack
  content(g((0, yIn)), text(size: 7.5pt, style: "italic", fill: ink)[Sample input text])
  box(yTok, [Tokenized text])
  box(yEmb, [Token embedding layer])
  arr((0, yIn + 0.22), (0, yTok - 0.3))
  arr((0, yTok + 0.3), (0, yEmb - 0.3))
  arr((0, yEmb + 0.3), (0, yAttn - 0.4))

  // attention sublayer -> RMSNorm 1 -> add
  box(yAttn, [Masked multi-head\ attention], fill: p.attn, stroke: 1pt + p.attn-stroke, h: 0.8, sz: 7pt)
  box(yN1, [RMSNorm 1], fill: p.norm)
  op(yAdd1, $+$)
  arr((0, yAttn + 0.4), (0, yN1 - 0.3))
  arr((0, yN1 + 0.3), (0, yAdd1 - 0.23))

  // FFN sublayer -> RMSNorm 2 -> add
  box(yFfn, [Feed forward], fill: p.ffn)
  box(yN2, [RMSNorm 2], fill: p.norm)
  op(yAdd2, $+$)
  arr((0, yAdd1 + 0.23), (0, yFfn - 0.3))
  arr((0, yFfn + 0.3), (0, yN2 - 0.3))
  arr((0, yN2 + 0.3), (0, yAdd2 - 0.23))

  // residual lanes: tapped BEFORE each sublayer (post-norm => skip wraps norm too)
  let lane2 = lane + 0.2
  ln((0, yAttn - 0.42), (-lane, yAttn - 0.42), (-lane, yAdd1), (-0.23, yAdd1))
  ln((0, yAdd1 + 0.34), (-lane2, yAdd1 + 0.34), (-lane2, yAdd2), (-0.23, yAdd2))
  circle(g((0, yAttn - 0.42)), radius: 0.06, fill: ink, stroke: none)
  circle(g((0, yAdd1 + 0.34)), radius: 0.06, fill: ink, stroke: none)

  // RoPE + QK-Norm taps into the attention block (far left)
  rect(g((-chw - 1.95, yAttn + 0.05)), g((-chw - 1.05, yAttn + 0.55)), fill: p.rope, stroke: 0.9pt + ink)
  content(g((-chw - 1.5, yAttn + 0.3)), text(size: 7pt, fill: ink)[RoPE])
  line(g((-chw - 1.05, yAttn + 0.3)), g((-w / 2 - 0.02, yAttn + 0.2)), stroke: 0.9pt + ink, mark: (end: "stealth", scale: 0.7))
  rect(g((-chw - 1.95, yAttn - 0.55)), g((-chw - 1.05, yAttn - 0.05)), fill: p.norm, stroke: 0.9pt + ink)
  content(g((-chw - 1.5, yAttn - 0.3)), text(size: 6.5pt, fill: ink)[QK-Norm])
  line(g((-chw - 1.05, yAttn - 0.3)), g((-w / 2 - 0.02, yAttn - 0.2)), stroke: 0.9pt + ink, mark: (end: "stealth", scale: 0.7))

  // top stack
  arr((0, yAdd2 + 0.23), (0, yFinal - 0.3))
  box(yFinal, [Final RMSNorm], fill: p.norm)
  box(yOut, [Linear output layer])
  arr((0, yFinal + 0.3), (0, yOut - 0.3))
  arr((0, yOut + 0.3), (0, yVocab - 0.05))
  content(g((w / 2 + 0.3, yVocab)), text(size: 7.5pt, fill: ink)[Vocabulary size of #text(fill: accent)[100k]], anchor: "west")
  content(g((0, yVocab + 0.75)), text(size: 12pt, weight: "bold", fill: accent)[OLMo 2 7B])

  // right-side dimension annotations (heads, hidden, embedding, context)
  let dims = (([32 heads], []), ([Hidden dim ], [11,008]), ([Embedding dim ], [4,096]), ([Context ], [4k]))
  let anchors = (yAttn, yFfn, yEmb, yTok)
  for (i, d) in dims.enumerate() {
    let yy = anchors.at(i)
    line(g((w / 2 + 0.05, yy)), g((w / 2 + 0.95, yy)), stroke: 0.7pt + p.muted)
    content(g((w / 2 + 1.05, yy)), text(size: 7pt, fill: rgb("#5C5C5C"))[#d.at(0) #text(fill: accent)[#d.at(1)]], anchor: "west")
  }
}

#cetz.canvas(length: 1cm, {
  llm-arch(..llama3-8b, origin: (0, 0))
  olmo2-postnorm(origin: (9.6, 0))
})
