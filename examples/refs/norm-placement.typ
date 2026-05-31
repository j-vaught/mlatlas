// Pre-norm vs post-norm transformer block — where the RMSNorm sits relative to the
// residual ⊕. Pre-norm (GPT-2 / Llama 3): norm INSIDE the residual, BEFORE each sublayer.
// Post-norm a la OLMo 2: norm moved to AFTER each sublayer but still INSIDE the residual
// (so the residual stream stays un-normalised). Rebuilt from architecture knowledge in
// mlatlas's own 2-D IR; reference used only to confirm the OLMo 2 norm placement.
#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// garnet accent for the moved-norm role; everything else stays monochrome
#let garnet = rgb("#73000A")

// --- block factories (uniform width for tidy columns); sublayers stay monochrome so
// the ONLY garnet block-outline is the RMSNorm whose position moves -----------------
#let attn = block(label: [Masked multi-head\ attention], role: "compute", width: 34mm)
#let ffn = block(label: [Feed forward], role: "compute", width: 34mm)
#let rms(emph: false) = block(
  label: [RMSNorm], role: "norm", width: 34mm,
  stroke: if emph { 1.6pt + garnet } else { auto },
)

// --- PRE-NORM column: x -> Norm -> Attn -> (+) -> Norm -> FFN -> (+) ---------------
// the norm (garnet) sits BEFORE each sublayer; the skip bypasses both norm + sublayer
#let pre-norm-block = seq(
  gap: 2,
  residual(seq(gap: 1, rms(emph: true), attn)),
  residual(seq(gap: 1, rms(emph: true), ffn)),
)

// --- POST-NORM (OLMo 2) column: x -> Attn -> Norm -> (+) -> FFN -> Norm -> (+) -----
// the norm (garnet) moves AFTER each sublayer, yet the skip still bypasses it, so the
// residual stream stays un-normalised — "post-norm but inside the residual"
#let post-norm-block = seq(
  gap: 2,
  residual(seq(gap: 1, attn, rms(emph: true))),
  residual(seq(gap: 1, ffn, rms(emph: true))),
)

#let col(title, subtitle, body) = box(width: 60mm)[
  #set align(center)
  #text(size: 12pt, weight: "bold")[#title]
  #v(-4pt)
  #text(size: 8.5pt, fill: rgb("#5C5C5C"))[#subtitle]
  #v(8pt)
  #render(body, spacing: (11mm, 7mm))
]

#align(center)[
  #text(size: 14pt, weight: "bold")[Norm placement in a Transformer block]
  #v(2pt)
  #text(size: 9pt, fill: rgb("#5C5C5C"))[
    Garnet outline = the RMSNorm whose position moves.
    #h(8pt) Garnet line = residual skip ($x + #[sublayer]$).
  ]
]

#v(14pt)

#grid(
  columns: (auto, auto),
  column-gutter: 40pt,
  col(
    [Pre-Norm],
    [GPT-2 · Llama 3 — norm *before* each sublayer],
    pre-norm-block,
  ),
  col(
    [Post-Norm (OLMo 2)],
    [norm *after* each sublayer, *inside* the residual],
    post-norm-block,
  ),
)
