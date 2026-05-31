// mlatlas · renderers/rnn3d.typ
// Unrolled recurrent network in 3-D: a row of cell blocks, per-step input/output slabs, and a
// recurrent hidden-state ribbon threading the cells. Plus a single lstm-cell3d with a C_t/h_t
// conveyor. Print-first, sharp, stealth arrows.
#import "@preview/cetz:0.5.2"
#import "../adapters/3d.typ": block3d, block3d-anchors, project, cam-cabinet

#let rnn3d-palette = (
  cell: rgb("#F3D9A6"), input: rgb("#E9EDF0"), output: rgb("#CBE0F4"),
  state: rgb("#73000A"), gate: rgb("#F2A6C9"),
  edge: rgb("#243038"), text: rgb("#222222"), muted: rgb("#5C5C5C"),
)

#let rnn-unroll3d(steps: 4, cell: [RNN], hidden: 128, palette: rnn3d-palette, cam: cam-cabinet, dx: 2.5) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let p = palette
  let cw = 1.5
  let ch = 1.4
  let cd = 1.0
  let arr(a, b, color: p.edge, w: 1.4pt) = draw.line(a, b, stroke: w + color, mark: (end: "stealth", scale: 0.7))
  let prev = none
  for t in range(steps) {
    let cx = t * dx
    // cell
    block3d(draw, origin: (cx, 0), w: cw, h: ch, dep: cd, base: p.cell, edge: p.edge, cam: cam)
    draw.content((cx, 0), text(size: 8.5pt, weight: "bold", fill: p.text)[#cell])
    let ca = block3d-anchors(origin: (cx, 0), w: cw, h: ch, dep: cd, cam: cam)
    // input x_t below
    block3d(draw, origin: (cx, -2.1), w: 0.7, h: 0.55, dep: 0.35, base: p.input, edge: p.edge, cam: cam)
    draw.content((cx, -2.1), text(size: 7.5pt, fill: p.text)[x#sub[#(t + 1)]])
    arr((cx, -1.85), ((ca.anchor)("bottom-screen").at(0), (ca.anchor)("bottom-screen").at(1)))
    // output h_t above
    block3d(draw, origin: (cx, 2.1), w: 0.7, h: 0.55, dep: 0.35, base: p.output, edge: p.edge, cam: cam)
    draw.content((cx, 2.1), text(size: 7.5pt, fill: p.text)[h#sub[#(t + 1)]])
    arr(((ca.anchor)("top-screen").at(0), (ca.anchor)("top-screen").at(1)), (cx, 1.85))
    // recurrent hidden-state (garnet) from previous cell
    if prev != none { arr((prev.at(0) + 0.05, 0), ((ca.anchor)("west").at(0) - 0.05, 0), color: p.state, w: 1.6pt) }
    prev = (ca.anchor)("east")
  }
  draw.content((-(dx) / 2 - 0.1, 0), anchor: "east", text(size: 7pt, fill: p.state)[h₀])
  draw.line((-(dx) / 2 + 0.05, 0), (((block3d-anchors(origin: (0, 0), w: cw, h: ch, dep: cd, cam: cam)).anchor)("west").at(0) - 0.05, 0), stroke: 1.6pt + p.state, mark: (end: "stealth", scale: 0.7))
  draw.content((dx * (steps - 1) / 2, -2.95), text(size: 7.5pt, fill: p.muted)[hidden dim = #hidden, unrolled #steps steps])
})

// single LSTM cell with the C_t (cell) and h_t (hidden) conveyor ribbons through three gates.
#let lstm-cell3d(palette: rnn3d-palette, cam: cam-cabinet) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let p = palette
  let gates = ([forget], [input], [output])
  let gx = (0, 2.0, 4.0)
  // conveyor ribbon (cell state C_t) across the top
  draw.line((-1.2, 1.55), (5.6, 1.55), stroke: 2.2pt + p.state)
  draw.content((-1.4, 1.55), anchor: "east", text(size: 7.5pt, fill: p.state)[C#sub[t-1]])
  draw.content((5.8, 1.55), anchor: "west", text(size: 7.5pt, fill: p.state)[C#sub[t]])
  // hidden ribbon along the bottom
  draw.line((-1.2, -1.55), (5.6, -1.55), stroke: 1.8pt + p.output.darken(20%))
  draw.content((-1.4, -1.55), anchor: "east", text(size: 7.5pt, fill: p.muted)[h#sub[t-1]])
  draw.content((5.8, -1.55), anchor: "west", text(size: 7.5pt, fill: p.muted)[h#sub[t]])
  for (i, g) in gates.enumerate() {
    let x = gx.at(i)
    block3d(draw, origin: (x, 0), w: 1.2, h: 1.5, dep: 0.8, base: p.gate, edge: p.edge, cam: cam)
    draw.content((x, 0), text(size: 7.5pt, fill: p.text)[#g\ gate])
    draw.line((x, 0.75), (x, 1.5), stroke: 1.2pt + p.edge, mark: (end: "stealth", scale: 0.6))
    draw.line((x, -1.5), (x, -0.75), stroke: 1.2pt + p.edge, mark: (end: "stealth", scale: 0.6))
  }
})
