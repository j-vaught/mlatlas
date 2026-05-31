// mlatlas · renderers/lstm.typ
// A dedicated Olah-style LSTM cell drawn in one cetz canvas: green cell container, the
// cell-state "conveyor" across the top with ⊗ (forget) and ⊕ (input add), yellow gate
// boxes (σ / tanh), pink pointwise-op circles, a tanh oval, and orthogonal connectors.
// Brand-adapted: sharp corners, stealth arrowheads.

#import "@preview/cetz:0.5.2"

#let lstm-palette = (
  cell: rgb("#3E7D2E"), cell-fill: rgb("#F2FAEE"),
  gate: rgb("#FFF3A0"), gate-stroke: rgb("#A8901C"),
  op: rgb("#F8C7C7"), op-stroke: rgb("#C44B4B"),
  line: rgb("#262626"),
  inp: rgb("#A7CBEC"), inp-stroke: rgb("#4F86C0"),
  out: rgb("#D9BBF2"), out-stroke: rgb("#9B6FC8"),
  text: rgb("#1E1E1E"), muted: rgb("#5C5C5C"),
)

#let lstm-cell(palette: lstm-palette) = {
  let p = palette
  cetz.canvas(length: 0.4cm, {
    import cetz.draw: rect, circle, line, content

    let gw = 1.7
    let gh = 1.15
    let gate(x, y, lbl) = {
      rect((x - gw / 2, y - gh / 2), (x + gw / 2, y + gh / 2), fill: p.gate, stroke: 0.9pt + p.gate-stroke)
      content((x, y), text(size: 9pt, fill: p.text)[#lbl])
    }
    let opc(x, y, sym) = {
      circle((x, y), radius: 0.62, fill: p.op, stroke: 0.9pt + p.op-stroke)
      content((x, y), text(size: 9pt, fill: p.text)[#sym])
    }
    let oval(x, y, lbl) = {
      circle((x, y), radius: (1.0, 0.62), fill: p.op, stroke: 0.9pt + p.op-stroke)
      content((x, y), text(size: 8.5pt, fill: p.text)[#lbl])
    }
    let term(x, y, lbl, fill, stroke) = {
      circle((x, y), radius: 0.7, fill: fill, stroke: 0.9pt + stroke)
      content((x, y), text(size: 8.5pt, fill: p.text)[#lbl])
    }
    let ln(..pts) = line(..pts.pos(), stroke: 1.3pt + p.line)
    let arr(..pts) = line(..pts.pos(), stroke: 1.3pt + p.line, mark: (end: "stealth", scale: 0.55))

    // cell container
    rect((0, 0), (14, 8), stroke: 1.7pt + p.cell, fill: p.cell-fill, radius: 0pt)

    // --- cell-state conveyor (top) ---
    let cy = 6.7
    ln((-1.6, cy), (2.5 - 0.62, cy)) // C_{t-1} -> forget x
    ln((2.5 + 0.62, cy), (6.0 - 0.62, cy)) // forget x -> add +
    ln((6.0 + 0.62, cy), (15.6, cy)) // add + -> C_t (with tap to tanh)
    opc(2.5, cy, $times$)
    opc(6.0, cy, $plus$)
    content((-2.1, cy), text(size: 9pt, fill: p.text)[$C_(t-1)$])
    content((15.9, cy), text(size: 9pt, fill: p.text)[$C_t$], anchor: "west")

    // --- input line (bottom) ---
    let iy = 1.1
    ln((-1.0, iy), (10.6, iy))
    // taps up to gates
    for gx in (2.5, 4.6, 6.6, 9.6) { ln((gx, iy), (gx, 3.3 - gh / 2)) }

    // --- gates ---
    gate(2.5, 3.3, $sigma$) // forget
    gate(4.6, 3.3, $sigma$) // input
    gate(6.6, 3.3, $tanh$) // candidate
    gate(9.6, 3.3, $sigma$) // output

    // forget gate -> forget x
    arr((2.5, 3.3 + gh / 2), (2.5, cy - 0.62))

    // input gate + candidate -> input-multiply -> add +
    opc(5.6, 5.0, $times$)
    arr((4.6, 3.3 + gh / 2), (4.6, 5.0), (5.6 - 0.62, 5.0))
    arr((6.6, 3.3 + gh / 2), (6.6, 5.0), (5.6 + 0.62, 5.0))
    arr((5.6, 5.0 + 0.62), (5.6, 6.0), (6.0, 6.0), (6.0, cy - 0.62))

    // output path: h_t = o_t · tanh(C_t)  — routed to avoid crossing the conveyor
    let toval = 7.6
    let oy = 4.7
    ln((toval, cy), (toval, oy + 0.62)) // tap the cell state down to the tanh oval
    oval(toval, oy, $tanh$)
    let omul = 9.6 // aligned under the output gate
    opc(omul, oy, $times$)
    arr((toval + 1.05, oy), (omul - 0.62, oy)) // tanh(C_t) -> output× from the left
    arr((omul, 3.3 + gh / 2), (omul, oy - 0.62)) // output σ -> output× from below
    arr((omul + 0.62, oy), (14.4, oy)) // h_t exits right at mid height (clear of conveyor + input bus)
    content((14.7, oy), text(size: 9pt, fill: p.text)[$h_t$], anchor: "west")
    // junction dots where wires genuinely branch
    for jp in ((2.5, cy), (6.0, cy), (toval, cy)) { circle(jp, radius: 0.07, fill: p.line, stroke: none) }

    // input terminals
    term(-1.0, iy - 0.0, $h_(t-1)$, p.out, p.out-stroke)
    // (x_t enters the input line from below, drawn as a small stub)
    content((1.0, iy - 1.2), text(size: 9pt, fill: p.text)[$x_t$])
    arr((1.0, iy - 0.9), (1.0, iy))
  })
}
