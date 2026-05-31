// mlatlas · K-fold cross-validation split strip (K = 5).
//
// The dataset is partitioned once into K equal folds. We then run K rounds: in
// round i the i-th fold is HELD OUT as the validation set (garnet) and the
// remaining K-1 folds are concatenated to TRAIN the model (neutral). The held-
// out block rotates one position to the right each round, so every fold serves
// as validation exactly once. The K validation scores are averaged into the
// final cross-validation estimate.
//
// Original mlatlas figure of a standard model-selection concept (ESL; ISLR/ISLP;
// UML). Built from knowledge, not traced. A grid leaf: K rows × K cells, one
// garnet validation cell per row stepping along the diagonal.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── palette ───────────────────────────────────────────────────────────────
  let p = (
    edge:   rgb("#363636"),
    text:   rgb("#1A1A1A"),
    muted:  rgb("#5C5C5C"),
    grid:   rgb("#C7C7C7"),
    train:  rgb("#ECECEC"),     // 10% black — training folds (neutral)
    trtext: rgb("#5C5C5C"),
    garnet: rgb("#73000A"),     // validation fold (focal accent)
    valfil: rgb("#73000A").transparentize(82%),  // light garnet wash
    score:  rgb("#1F414D"),     // dark-blue — per-round score chips
  )

  // ── geometry ────────────────────────────────────────────────────────────────
  let K = 5
  let cw = 1.55                 // cell width
  let ch = 0.92                 // cell height
  let gap = 0.10                // small gutter between cells
  let row-gap = 0.34            // gutter between rounds (rows)
  let ox = 0.0                  // left edge of the strip grid
  let top = 0.0                 // baseline; rows go DOWN from here (round 1 on top)

  // cell origin (lower-left) for column c (0-indexed) in row r (0-indexed, top=0)
  let cell-x(c) = ox + c * (cw + gap)
  let cell-y(r) = top - r * (ch + row-gap)

  // ── per-round strips ─────────────────────────────────────────────────────────
  for r in range(K) {
    let yb = cell-y(r)          // top of this row's cells
    for c in range(K) {
      let xl = cell-x(c)
      let held = (c == r)       // diagonal: fold c is held out in round r
      let fil = if held { p.valfil } else { p.train }
      let str = if held { 1.6pt + p.garnet } else { 0.9pt + p.grid }
      draw.rect(
        (xl, yb - ch), (xl + cw, yb),
        fill: fil, stroke: str, radius: 0pt,
      )
      let lbl = if held { [validate] } else { [train] }
      let tc  = if held { p.garnet } else { p.trtext }
      let wt  = if held { "bold" } else { "regular" }
      draw.content(
        (xl + cw / 2, yb - ch / 2),
        text(size: 8.5pt, fill: tc, weight: wt)[#lbl],
      )
    }
  }

  // ── round (row) labels on the left ──────────────────────────────────────────
  for r in range(K) {
    let yc = cell-y(r) - ch / 2
    draw.content(
      (ox - 0.45, yc), anchor: "east",
      text(size: 9pt, fill: p.text, weight: "bold")[Round #(r + 1)],
    )
  }

  // ── fold-index axis along the top ────────────────────────────────────────────
  let axis-y = top + 0.30
  for c in range(K) {
    let xc = cell-x(c) + cw / 2
    draw.content(
      (xc, axis-y + 0.18),
      text(size: 8.5pt, fill: p.muted)[fold #(c + 1)],
    )
  }
  // brace-like span line over the K folds
  let span-l = cell-x(0)
  let span-r = cell-x(K - 1) + cw
  draw.line((span-l, axis-y - 0.06), (span-r, axis-y - 0.06), stroke: 0.9pt + p.muted)
  draw.line((span-l, axis-y - 0.06), (span-l, axis-y - 0.20), stroke: 0.9pt + p.muted)
  draw.line((span-r, axis-y - 0.06), (span-r, axis-y - 0.20), stroke: 0.9pt + p.muted)
  draw.content(
    ((span-l + span-r) / 2, axis-y + 0.62),
    text(size: 9pt, fill: p.text)[dataset split into $K = #K$ equal folds],
  )

  // ── per-round score chips on the right ───────────────────────────────────────
  let chip-x = cell-x(K - 1) + cw + 0.55
  let scores = ($s_1$, $s_2$, $s_3$, $s_4$, $s_5$)
  // arrow header
  draw.content(
    (chip-x + 0.70, axis-y + 0.18),
    text(size: 8.5pt, fill: p.score)[score],
  )
  for r in range(K) {
    let yc = cell-y(r) - ch / 2
    // little arrow from the validation cell out to its score chip
    draw.line(
      (cell-x(K - 1) + cw + 0.08, yc), (chip-x - 0.04, yc),
      stroke: 0.8pt + p.muted, mark: (end: "stealth", scale: 0.5),
    )
    draw.rect(
      (chip-x, yc - 0.30), (chip-x + 1.40, yc + 0.30),
      fill: white, stroke: 1.0pt + p.score, radius: 0pt,
    )
    draw.content(
      (chip-x + 0.70, yc),
      text(size: 9pt, fill: p.score)[#scores.at(r)],
    )
  }

  // ── final averaged estimate below ────────────────────────────────────────────
  let bottom = cell-y(K - 1) - ch
  let avg-y = bottom - 0.70
  // collect arrows from each score chip down to the average box
  let avg-cx = chip-x + 0.70
  draw.rect(
    (avg-cx - 1.95, avg-y - 0.42), (avg-cx + 1.95, avg-y + 0.42),
    fill: p.valfil, stroke: 1.6pt + p.garnet, radius: 0pt,
  )
  draw.content(
    (avg-cx, avg-y),
    text(size: 9.5pt, fill: p.garnet)[
      $"CV" = 1 / K sum_(i=1)^K s_i$
    ],
  )
  // bracket gathering the score chips into the average
  let chip-bot = cell-y(K - 1) - ch / 2 - 0.30
  draw.line(
    (avg-cx, chip-bot - 0.04), (avg-cx, avg-y + 0.42 + 0.04),
    stroke: 0.9pt + p.muted, mark: (end: "stealth", scale: 0.55),
  )
  draw.content(
    (avg-cx + 1.55, (chip-bot + avg-y + 0.42) / 2),
    anchor: "west",
    text(size: 7.5pt, fill: p.muted, style: "italic")[average the $K$ scores],
  )

  // ── title ─────────────────────────────────────────────────────────────────────
  draw.content(
    (span-l - 1.05 / 2 + (span-r - span-l) / 2, axis-y + 1.18),
    text(size: 11.5pt, weight: "bold", fill: p.text)[$K$-fold cross-validation],
  )

  // ── legend (bottom-left) ──────────────────────────────────────────────────────
  let ly = avg-y
  let lx = ox - 0.45
  // validation swatch
  draw.rect((lx, ly + 0.10), (lx + 0.52, ly + 0.52), fill: p.valfil, stroke: 1.6pt + p.garnet, radius: 0pt)
  draw.content((lx + 0.66, ly + 0.31), anchor: "west", text(size: 8.5pt, fill: p.text)[held-out validation fold])
  // training swatch
  draw.rect((lx, ly - 0.52), (lx + 0.52, ly - 0.10), fill: p.train, stroke: 0.9pt + p.grid, radius: 0pt)
  draw.content((lx + 0.66, ly - 0.31), anchor: "west", text(size: 8.5pt, fill: p.text)[training folds (the other $K - 1$)])
})
