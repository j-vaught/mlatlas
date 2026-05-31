// mlatlas · Confusion matrix as a sequential heatmap.
// A square grid of predicted-vs-actual class counts. Rows = true (actual) class,
// columns = predicted class; cell (i, j) = #samples whose true class is i and
// whose model prediction is j. The diagonal holds correct predictions; off-
// diagonal cells are confusions. Counts are encoded by a sequential beige→garnet
// ramp (light = few, dark = many) and printed in each cell, with a matching
// colorbar at the right. A strong diagonal reads as a well-calibrated classifier.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// ── data ──────────────────────────────────────────────────────────────────────
// Four-class problem. M[i][j] = count(true = class i, predicted = class j).
#let classes = ("cat", "dog", "bird", "fish")
#let M = (
  (52,  4,  3,  1),   // true cat   → mostly cat
  ( 6, 47,  5,  2),   // true dog
  ( 3,  2, 41,  4),   // true bird
  ( 1,  0,  6, 43),   // true fish
)

// ── palette ─────────────────────────────────────────────────────────────────
#let p = (
  ink:    rgb("#1A1A1A"),
  text:   rgb("#222222"),
  muted:  rgb("#5C5C5C"),
  edge:   rgb("#363636"),
  grid:   rgb("#A2A2A2"),
  beige:  rgb("#FFF2E3"),   // ramp lo
  garnet: rgb("#73000A"),   // ramp hi (sparse accent)
)

// sequential ramp: beige (t=0) → garnet (t=1), interpolated in oklab.
#let ramp(t) = {
  let t = calc.max(0.0, calc.min(1.0, t))
  p.beige.mix((p.garnet, t * 100%), space: oklab)
}
// pick a readable text color for a given fill darkness (t in 0..1)
#let on-fill(t) = if t > 0.55 { white } else { p.ink }

// flatten to find the max count for normalization
#let counts = M.flatten()
#let cmax = calc.max(..counts)

#let cell = 1.30                 // cell side (cm)
#let nC = classes.len()         // columns = predicted
#let nR = classes.len()         // rows = actual
#let W = nC * cell
#let H = nR * cell

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── heatmap cells ──────────────────────────────────────────────────────────
  // row 0 sits at the TOP; canvas y grows up, so flip the row index.
  for i in range(nR) {
    for j in range(nC) {
      let v = M.at(i).at(j)
      let t = v / cmax
      let xx = j * cell
      let yy = (nR - 1 - i) * cell
      let fil = ramp(t)
      draw.rect(
        (xx, yy), (xx + cell, yy + cell),
        fill: fil, stroke: 0.6pt + p.grid, radius: 0pt,
      )
      // diagonal (correct) cells get a bold count; off-diagonal regular.
      let diag = i == j
      draw.content(
        (xx + cell / 2, yy + cell / 2),
        text(
          size: 11pt,
          fill: on-fill(t),
          weight: if diag { "bold" } else { "regular" },
        )[#v],
      )
    }
  }

  // outline + a garnet box tracing the correct-prediction diagonal
  draw.rect((0, 0), (W, H), fill: none, stroke: 1.2pt + p.edge, radius: 0pt)
  for k in range(nR) {
    let xx = k * cell
    let yy = (nR - 1 - k) * cell
    draw.rect(
      (xx, yy), (xx + cell, yy + cell),
      fill: none, stroke: 1.6pt + p.garnet, radius: 0pt,
    )
  }

  // ── axis labels ────────────────────────────────────────────────────────────
  // predicted-class labels across the top
  for j in range(nC) {
    draw.content(
      (j * cell + cell / 2, H + 0.20),
      anchor: "south",
      text(size: 9.5pt, fill: p.text, style: "italic")[#classes.at(j)],
    )
  }
  // actual-class labels down the left (row 0 on top)
  for i in range(nR) {
    draw.content(
      (-0.20, (nR - 1 - i) * cell + cell / 2),
      anchor: "east",
      text(size: 9.5pt, fill: p.text, style: "italic")[#classes.at(i)],
    )
  }

  // axis captions
  draw.content(
    (W / 2, H + 0.78),
    text(size: 11pt, fill: p.ink, weight: "bold")[Predicted class],
  )
  draw.content(
    (-1.70, H / 2), angle: 90deg,
    text(size: 11pt, fill: p.ink, weight: "bold")[Actual class],
  )

  // ── colorbar (sequential ramp legend) ──────────────────────────────────────
  let bx = W + 0.70            // left edge of bar
  let bw = 0.46               // bar width
  let nseg = 40               // ramp segments
  for s in range(nseg) {
    let t0 = s / nseg
    let t1 = (s + 1) / nseg
    let y0 = t0 * H
    let y1 = t1 * H
    draw.rect(
      (bx, y0), (bx + bw, y1),
      fill: ramp((t0 + t1) / 2), stroke: none,
    )
  }
  draw.rect((bx, 0), (bx + bw, H), fill: none, stroke: 0.8pt + p.edge, radius: 0pt)
  // colorbar ticks: 0 .. cmax
  for (frac, lbl) in ((0.0, "0"), (0.5, str(calc.round(cmax / 2))), (1.0, str(cmax))) {
    let yy = frac * H
    draw.line((bx + bw, yy), (bx + bw + 0.12, yy), stroke: 0.8pt + p.edge)
    draw.content(
      (bx + bw + 0.20, yy), anchor: "west",
      text(size: 8pt, fill: p.muted)[#lbl],
    )
  }
  draw.content(
    (bx + bw / 2, H + 0.30), anchor: "south",
    text(size: 8.5pt, fill: p.muted)[count],
  )

  // ── footnote: diagonal = correct ───────────────────────────────────────────
  draw.content(
    (0, -0.62), anchor: "west",
    text(size: 8.5pt, fill: p.garnet, style: "italic")[diagonal = correct predictions],
  )
})
