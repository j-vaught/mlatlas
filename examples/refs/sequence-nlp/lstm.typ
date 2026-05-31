// LSTM memory cell — rebuilt in mlatlas style (after the d2l "Long Short-Term Memory" figure).
// The cell state C_t rides a conveyor along the top; the hidden state h_t along the bottom.
// Three sigmoid gates (forget, input, output) plus a tanh candidate control what the memory
// keeps, writes, and reads:  C_t = f_t ⊙ C_{t-1} + i_t ⊙ C̃_t ,  h_t = o_t ⊙ tanh(C_t).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let c-garnet = rgb("#73000A")
#let c-muted = rgb("#5C5C5C")

#align(center)[
  #text(size: 13pt, weight: "bold")[LSTM memory cell]
  #v(2pt)
  #text(size: 9pt, fill: c-muted)[
    cell state #text(fill: c-garnet)[$C_t$] (top conveyor) · hidden state $h_t$ (bottom) · three gates
  ]
  #v(10pt)

  // the dedicated 3-D renderer: C_t / h_t ribbons threading the forget / input / output gates
  #lstm-cell3d()

  #v(14pt)

  // gate semantics — the four FC pre-activations of an LSTM, in mlatlas-light text
  #set text(size: 9.5pt)
  #grid(
    columns: (auto, auto),
    column-gutter: 26pt,
    row-gutter: 6pt,
    align: left,
    [forget  #h(4pt) $f_t = sigma(W_f [h_(t-1), x_t] + b_f)$],
    [candidate #h(4pt) $tilde(C)_t = tanh(W_c [h_(t-1), x_t] + b_c)$],
    [input  #h(6pt) $i_t = sigma(W_i [h_(t-1), x_t] + b_i)$],
    [output #h(4pt) $o_t = sigma(W_o [h_(t-1), x_t] + b_o)$],
  )
  #v(8pt)
  #text(fill: c-garnet)[
    $C_t = f_t dot.o C_(t-1) + i_t dot.o tilde(C)_t
       quad quad
     h_t = o_t dot.o tanh(C_t)$
  ]
]
