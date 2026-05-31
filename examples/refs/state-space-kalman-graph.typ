// mlatlas · Linear-Gaussian state-space model (Kalman filter) as a graph.
// The continuous analogue of the HMM chain: latent continuous states z_t evolve
// z_t -> z_{t+1} under a linear-Gaussian transition (matrix A, process noise Q),
// and each emits an observation x_t under a linear-Gaussian emission (matrix C,
// measurement noise R). Latent = open circle, observed = shaded circle, directed
// edges = stealth arrows. The transition fan z_t -> z_{t+1} is the focal (garnet)
// edge; A and C are called out as matrix annotations.
//
//   transition:  z_t = A z_{t-1} + w_t,   w_t ~ N(0, Q)
//   emission:    x_t = C z_t     + v_t,   v_t ~ N(0, R)
//   initial:     z_1 ~ N(mu_0, P_0)
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- palette: print-first, garnet as the sparse focal accent ----------------
  let p = (
    garnet: rgb("#73000A"),     // focal transition edge A
    latent: rgb("#FFFFFF"),     // continuous latent state z_t
    observed: rgb("#ECECEC"),   // observed x_t (shaded)
    stroke: rgb("#363636"),
    edge: rgb("#5C5C5C"),       // emission edges C
    muted: rgb("#5C5C5C"),
    faint: rgb("#A2A2A2"),
    text: rgb("#1A1A1A"),
  )

  // ---- chain geometry ---------------------------------------------------------
  let steps = 4
  let sp = 2.8                  // column spacing
  let r = 0.56                  // node radius
  let zy = 1.7                  // latent row y
  let xy = -1.7                 // observation row y

  let zx(t) = t * sp           // x of column t (0-based)

  // ---- helpers ----------------------------------------------------------------
  let arr(a, b, color: p.stroke, w: 1.1pt, s: 0.7) = draw.line(
    a, b, stroke: w + color, mark: (end: "stealth", scale: s),
  )

  // ===========================================================================
  // (1) transition chain  z_t -> z_{t+1}   (focal garnet edges, matrix A)
  // ===========================================================================
  for t in range(steps - 1) {
    arr(
      (zx(t) + r, zy), (zx(t + 1) - r, zy),
      color: p.garnet, w: 2.2pt, s: 0.75,
    )
    // A label centred above each transition edge
    draw.content(
      ((zx(t) + zx(t + 1)) / 2, zy + 0.42),
      text(size: 9pt, fill: p.garnet)[$bold(A)$],
    )
  }

  // dashed continuation arrow off the right end (chain continues)
  draw.line(
    (zx(steps - 1) + r, zy), (zx(steps - 1) + sp - r - 0.1, zy),
    stroke: (paint: p.faint, thickness: 1.6pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.75),
  )
  draw.content(
    (zx(steps - 1) + sp - r + 0.1, zy), anchor: "west",
    text(size: 10pt, fill: p.faint)[$dots.h.c$],
  )

  // ===========================================================================
  // (2) emission edges  z_t -> x_t   (matrix C)
  // ===========================================================================
  for t in range(steps) {
    arr((zx(t), zy - r), (zx(t), xy + r), color: p.edge, w: 1.2pt, s: 0.7)
    // C label beside each emission edge
    draw.content(
      (zx(t) + 0.34, (zy + xy) / 2), anchor: "west",
      text(size: 8.5pt, fill: p.edge)[$bold(C)$],
    )
  }

  // ===========================================================================
  // (3) nodes — latent (open) on top, observed (shaded) below
  // ===========================================================================
  for t in range(steps) {
    // latent continuous state z_t
    draw.circle((zx(t), zy), radius: r, fill: p.latent, stroke: 1.3pt + p.stroke)
    draw.content((zx(t), zy), text(size: 11pt, fill: p.text)[$bold(z)_(#(t + 1))$])
    // observed x_t (shaded)
    draw.circle((zx(t), xy), radius: r, fill: p.observed, stroke: 1.3pt + p.stroke)
    draw.content((zx(t), xy), text(size: 11pt, fill: p.text)[$bold(x)_(#(t + 1))$])
  }

  // initial-state callout into z_1
  draw.line(
    (zx(0) - sp + 0.3, zy), (zx(0) - r, zy),
    stroke: (paint: p.faint, thickness: 1.6pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.75),
  )
  draw.content(
    (zx(0) - sp + 0.2, zy), anchor: "east",
    text(size: 8.5pt, fill: p.muted)[$bold(z)_1 tilde N(bold(mu)_0, bold(P)_0)$],
  )

  // ===========================================================================
  // (4) row labels on the right edge of the canvas
  // ===========================================================================
  let rxr = zx(steps - 1) + sp + 0.9
  draw.content(
    (rxr, zy), anchor: "west",
    text(size: 8.5pt, fill: p.muted)[latent state],
  )
  draw.content(
    (rxr, xy), anchor: "west",
    text(size: 8.5pt, fill: p.muted)[observation],
  )

  // ===========================================================================
  // (5) time axis along the bottom
  // ===========================================================================
  let axisY = xy - 1.35
  arr((zx(0) - 0.5, axisY), (zx(steps - 1) + 0.5, axisY), color: p.faint, w: 1.2pt, s: 0.7)
  draw.content(
    (zx(steps - 1) + 0.65, axisY), anchor: "west",
    text(size: 9pt, fill: p.text)[time $t$],
  )
  for t in range(steps) {
    draw.line((zx(t), axisY + 0.08), (zx(t), axisY - 0.08), stroke: 1pt + p.faint)
    draw.content(
      (zx(t), axisY - 0.18), anchor: "north",
      text(size: 8pt, fill: p.muted)[$#(t + 1)$],
    )
  }

  // ===========================================================================
  // (6) title + the two governing linear-Gaussian equations
  // ===========================================================================
  let cx = (zx(0) + zx(steps - 1)) / 2
  draw.content(
    (cx, zy + 1.55), anchor: "center",
    text(size: 12pt, weight: "bold", fill: p.text)[
      Linear-Gaussian state-space model · Kalman
    ],
  )

  // equation panel under the time axis
  draw.content(
    (cx, axisY - 1.05), anchor: "center",
    box(inset: 0pt)[
      #set text(size: 9pt, fill: p.text)
      #grid(
        columns: 2, column-gutter: 1.4em, row-gutter: 0.55em,
        align: left,
        text(fill: p.garnet)[$bold(z)_t = bold(A) thin bold(z)_(t-1) + bold(w)_t$],
        text(fill: p.muted)[$bold(w)_t tilde N(bold(0), bold(Q))$  (transition)],
        text(fill: p.edge)[$bold(x)_t = bold(C) thin bold(z)_t + bold(v)_t$],
        text(fill: p.muted)[$bold(v)_t tilde N(bold(0), bold(R))$  (emission)],
      )
    ],
  )
})
