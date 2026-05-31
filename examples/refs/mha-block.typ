// Multi-head self-attention block — rebuilt in mlatlas style.
// A single block: the token sequence is projected to Q, K, V; scaled dot-product attention
// QKᵀ/√d is computed in parallel across H heads (heads live in the depth of the score cube,
// never chopped), softmax-normalised, applied to V, then the per-head outputs are produced.
// Built from architectural knowledge; the reference (UDL multihead block) only confirms that
// this is the standard H-head scaled-dot-product self-attention block (here H = 8, d_k = 64).
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let garnet = rgb("#73000A")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: ink)[Multi-head self-attention block]

  #v(2pt)
  #text(size: 9pt, fill: muted)[
    $H = 8$ heads · $d_k = d_v = 64$ · scaled dot-product attention $op("softmax")(Q K^top \/ sqrt(d_k)) V$ per head
  ]

  #v(8pt)
  #attention-3d(seq: 6, d-k: 64, heads: 8)

  #v(6pt)
  #box(width: 16cm, [
    #set par(justify: false)
    #set align(center)
    #text(size: 8.5pt, fill: muted)[
      Q, K, V are linear projections of the input sequence (seq #sym.times $d_k$). The score tensor
      $Q K^top \/ sqrt(d_k)$ is a seq #sym.times seq #sym.times #text(fill: garnet)[8] cube — one
      seq #sym.times seq attention map per head (the depth seams). After softmax, each head's
      weights are applied to V; the 8 head outputs are concatenated and linearly transformed to
      the block output.
    ]
  ])
]
