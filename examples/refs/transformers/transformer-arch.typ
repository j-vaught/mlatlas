// Full Transformer (encoder-decoder, "Attention Is All You Need" / d2l).
// Rebuilt from architectural knowledge in mlatlas's 2-D IR. The reference is used only to
// confirm the canonical structure: an N× encoder stack of [Multi-Head Attention -> Add&Norm
// -> Feed-Forward -> Add&Norm] and an N× decoder stack of [Masked Multi-Head Attention ->
// Add&Norm -> Encoder-Decoder (cross) Attention -> Add&Norm -> Feed-Forward -> Add&Norm],
// with positional encodings added to both embeddings and a Linear + Softmax output head.
// The encoder memory feeds the K,V of every decoder cross-attention block (garnet arrow).
#import "../../../lib.typ": *

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let garnet = rgb("#73000A")
#let grey = rgb("#5C5C5C")

// ---- geometry: u = horizontal lane, v = vertical (smaller = higher on the page) -------
#let EU = 0      // encoder column
#let DU = 5      // decoder column
#let W = 30mm    // uniform block width for tidy columns (half-width ~ 1.07 grid units)

// vertical levels (top of page is small v). encoder & decoder share the embedding row.
#let v-out      = 0    // Output Probabilities
#let v-softmax  = 1
#let v-linear   = 2
#let v-an3      = 3.4   // decoder Add & Norm (after FFN)
#let v-ffn      = 4.4   // FFN  (both stacks)
#let v-an2      = 5.4   // Add & Norm (after cross-attn / after enc attn)
#let v-cross    = 6.4   // decoder cross-attention  (encoder: -- none --)
#let v-an1      = 7.4   // Add & Norm (after self-attn)
#let v-attn     = 8.4   // self-attention (encoder MHA / decoder masked MHA)
#let v-pos      = 9.8   // positional-encoding merge (⊕)
#let v-embed    = 10.8  // input / output embedding
#let v-tokens   = 11.8  // Inputs / Outputs (shifted right)

#let nrect(id, lbl, role, u, v, w: W, emph: false, ts: auto) = ir-node(
  id, label: lbl, role: role, pos: (u, v), width: w, emphasis: emph, text-size: ts,
)
#let add-circ(id, u, v) = ir-node(id, label: [#sym.plus.o], kind: "circle", role: "add", pos: (u, v), width: 7mm, height: 7mm, inset: 1pt)

// =================== ENCODER nodes ===================
#let enc-nodes = (
  nrect("e-tok",  [Inputs],            "data",      EU, v-tokens),
  nrect("e-emb",  [Input\ Embedding],  "input",     EU, v-embed),
  add-circ("e-pos", EU, v-pos),
  nrect("e-attn", [Multi-Head\ Attention], "attention", EU, v-attn),
  nrect("e-an1",  [Add & Norm],        "norm",      EU, v-an1),
  nrect("e-ffn",  [Feed\ Forward],     "compute",   EU, v-ffn),
  nrect("e-an2",  [Add & Norm],        "norm",      EU, v-an2),
)

// =================== DECODER nodes ===================
#let dec-nodes = (
  nrect("d-tok",  [Outputs\ #text(size: 0.78em, fill: grey)[(shifted right)]], "data", DU, v-tokens),
  nrect("d-emb",  [Output\ Embedding], "input",     DU, v-embed),
  add-circ("d-pos", DU, v-pos),
  nrect("d-attn", [Masked\ Multi-Head\ Attention], "attention", DU, v-attn, ts: 0.92em),
  nrect("d-an1",  [Add & Norm],        "norm",      DU, v-an1),
  nrect("d-cross",[Multi-Head\ Attention], "attention", DU, v-cross),
  nrect("d-an2",  [Add & Norm],        "norm",      DU, v-an2),
  nrect("d-ffn",  [Feed\ Forward],     "compute",   DU, v-ffn),
  nrect("d-an3",  [Add & Norm],        "norm",      DU, v-an3),
  nrect("d-lin",  [Linear],            "op",        DU, v-linear),
  nrect("d-soft", [Softmax],           "activation", DU, v-softmax),
  nrect("d-out",  [Output\ Probabilities], "output", DU, v-out, emph: true),
)

// positional-encoding source markers (small pills off to the side feeding the ⊕)
#let pe-nodes = (
  ir-node("e-pe", label: [Positional\ Encoding], kind: "pill", role: "op", pos: (EU - 2.15, v-pos), width: 24mm, text-size: 0.8em),
  ir-node("d-pe", label: [Positional\ Encoding], kind: "pill", role: "op", pos: (DU + 2.15, v-pos), width: 24mm, text-size: 0.8em),
)

// =================== edges ===================
#let dedge(a, b) = ir-edge(a, b, kind: "data")
#let enc-edges = (
  dedge("e-tok", "e-emb"), dedge("e-emb", "e-pos"),
  dedge("e-pos", "e-attn"), dedge("e-attn", "e-an1"),
  dedge("e-an1", "e-ffn"),  dedge("e-ffn", "e-an2"),
  // residual skips (round the side into the Add & Norm) — hug just outside the left edge
  ir-edge("e-pos", "e-an1", kind: "residual", route: "gutter", gutter: -1.25),
  ir-edge("e-an1", "e-an2", kind: "residual", route: "gutter", gutter: -1.25),
  // positional-encoding feed
  ir-edge("e-pe", "e-pos", kind: "data"),
)
#let dec-edges = (
  dedge("d-tok", "d-emb"), dedge("d-emb", "d-pos"),
  dedge("d-pos", "d-attn"), dedge("d-attn", "d-an1"),
  dedge("d-an1", "d-cross"), dedge("d-cross", "d-an2"),
  dedge("d-an2", "d-ffn"),  dedge("d-ffn", "d-an3"),
  dedge("d-an3", "d-lin"),  dedge("d-lin", "d-soft"),
  dedge("d-soft", "d-out"),
  // residual skips — hug just outside the right edge
  ir-edge("d-pos", "d-an1", kind: "residual", route: "gutter", gutter: 1.25),
  ir-edge("d-an1", "d-an2", kind: "residual", route: "gutter", gutter: 1.25),
  ir-edge("d-an2", "d-an3", kind: "residual", route: "gutter", gutter: 1.25),
  // positional-encoding feed
  ir-edge("d-pe", "d-pos", kind: "data"),
)
// encoder memory (K,V) -> decoder cross-attention
#let bridge-edges = (
  ir-edge("e-an2", "d-cross", kind: "data", route: "corner",
    stroke: 1.4pt + garnet,
    label: text(size: 0.74em, fill: garnet)[memory K, V]),
)

// =================== plates (×N) ===================
// labels suppressed here; clean column headers drawn as standalone IR nodes below
#let enc-plate = ir-group("enc-plate",
  ("e-attn", "e-an1", "e-ffn", "e-an2"),
  label: none, kind: "plate")
#let dec-plate = ir-group("dec-plate",
  ("d-attn", "d-an1", "d-cross", "d-an2", "d-ffn", "d-an3"),
  label: none, kind: "plate")

// ×N stack headers placed just outside the top-left corner of each plate
#let stack-labels = (
  ir-node("enc-hdr", label: text(size: 0.92em, fill: grey)[Encoder #h(1pt) $times N$],
    kind: "rect", role: "op", pos: (EU - 1.95, v-attn - 1.05),
    fill: none, stroke: none, width: auto),
  ir-node("dec-hdr", label: text(size: 0.92em, fill: grey)[Decoder #h(1pt) $times N$],
    kind: "rect", role: "op", pos: (DU + 1.95, v-attn - 1.05),
    fill: none, stroke: none, width: auto),
)

#let fig = (
  nodes: enc-nodes + dec-nodes + pe-nodes + stack-labels,
  edges: enc-edges + dec-edges + bridge-edges,
  groups: (enc-plate, dec-plate),
  meta: (:),
)

#align(center)[
  #text(size: 13pt, weight: "bold")[The Transformer — encoder--decoder architecture]
  #v(2pt)
  #text(size: 8.5pt, fill: grey)[
    Vaswani et al., 2017.#h(6pt)
    Garnet = attention sublayers and the encoder memory (K, V) feeding decoder cross-attention.
  ]
  #v(12pt)
  #render(fig, spacing: (15mm, 9mm), check: "off")
]
