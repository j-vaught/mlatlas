// Attention with sink tokens (GPT-OSS style) — two seq×seq mask grids.
// Left: plain causal attention (lower-triangular). Right: causal attention where
// EVERY query additionally attends to the first "sink" token (column 0), so the
// sink column is always on. Built from architectural knowledge in mlatlas's
// print-first style; the reference is used only to confirm the mechanism (a
// learned sink the softmax can dump probability mass onto).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ───────────────────────────────────────────────────────────────
#let garnet    = rgb("#73000A")
#let ink       = rgb("#000000")
#let attend    = rgb("#466A9F").transparentize(72%)   // attended (=1) cells
#let attend-s  = rgb("#466A9F")                         // attend stroke
#let attend-tx = rgb("#1F414D")
#let masked    = rgb("#ECECEC")                         // masked (=0) cells
#let sink-fill = garnet.transparentize(74%)             // sink-driven attention
#let sink-s    = garnet
#let gridln    = rgb("#5C5C5C")

#let tokens = ("The", "cat", "sat", "on", "the")
#let n = tokens.len()
#let cell = 0.74          // cell edge (cm)

// Draw one mask grid at origin (ox, oy).
//   keep(i,j)     -> query row i attends key col j  (blue, value 1)
//   sinkcol(i,j)  -> cell is "on" specifically because j is a sink (garnet)
//   title         -> panel header text
#let mask-grid(ox, oy, keep, sinkcol, title) = {
  import cetz.draw: *

  // panel title bar
  rect(
    (ox - 0.15, oy + cell + 0.32),
    (ox + n * cell + 0.15, oy + cell + 1.02),
    fill: garnet, stroke: none,
  )
  content(
    (ox + n * cell / 2, oy + cell + 0.67),
    text(fill: white, weight: "bold", size: 9.5pt, title),
  )

  for i in range(n) {
    // key labels (columns, across the top)
    content(
      (ox + i * cell + cell / 2, oy + cell + 0.07),
      text(fill: ink, size: 8.5pt, tokens.at(i)),
    )
    // query labels (rows, down the left). row 0 is the top row.
    content(
      (ox - 0.52, oy - i * cell + cell / 2),
      text(fill: ink, size: 8.5pt, tokens.at(i)),
    )
  }

  for i in range(n) {           // query row (top -> bottom)
    for j in range(n) {         // key column (left -> right)
      let x0 = ox + j * cell
      let y0 = oy - i * cell
      let on  = keep(i, j)
      let snk = sinkcol(i, j)
      let fil = if snk { sink-fill } else if on { attend } else { masked }
      let str = if snk { 0.8pt + sink-s }
                else if on { 0.6pt + attend-s.transparentize(20%) }
                else { 0.5pt + gridln }
      rect((x0, y0), (x0 + cell, y0 + cell), fill: fil, stroke: str)
      content(
        (x0 + cell / 2, y0 + cell / 2),
        text(
          fill: if snk { garnet } else if on { attend-tx } else { rgb("#A2A2A2") },
          size: 8pt,
          weight: if on or snk { "bold" } else { "regular" },
          if on or snk { [1] } else { [0] },
        ),
      )
    }
  }
}

// plain causal: attend to all j <= i
#let causal-keep = (i, j) => j <= i
#let no-sink     = (i, j) => false

// with sink: causal OR the sink column (j == 0)
#let sink-keep = (i, j) => (j <= i) or (j == 0)
// a cell counts as "sink-driven" when it is the sink column but would NOT be
// reachable by the plain causal mask of THAT row (i.e. j == 0 and j > i is
// impossible, so the sink only adds cells where j==0 and i==0 is already causal).
// Visually we mark the WHOLE sink column garnet to show it is always attended.
#let sink-mark = (i, j) => j == 0

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  let gap = 2.6
  let left-x = 0
  let right-x = n * cell + gap

  mask-grid(left-x, 0, causal-keep, no-sink,
    [Causal attention])
  mask-grid(right-x, 0, sink-keep, sink-mark,
    [Attention + sink token])

  // callout for the sink column: a stealth arrow coming up from below the grid
  // into the bottom of the sink column (column 0), kept clear of labels.
  let scx = right-x + cell / 2
  let bot-y = -n * cell + 0.02
  line(
    (scx, bot-y - 0.62), (scx, bot-y),
    stroke: 1.0pt + garnet, mark: (end: "stealth", scale: 0.7),
  )
  content(
    (scx, bot-y - 0.84),
    text(fill: garnet, weight: "bold", size: 8.5pt)[sink token],
  )

  // ── captions (one per panel, sat below each grid) ───────────────────────
  let cap-y = -n * cell - 1.55
  content(
    (left-x + n * cell / 2, cap-y),
    text(fill: rgb("#363636"), size: 8.5pt)[
      Each query attends to *every* previous\
      token and itself — lower-triangular mask.
    ],
  )
  content(
    (right-x + n * cell / 2, cap-y),
    text(fill: rgb("#363636"), size: 8.5pt)[
      *Every* query also attends the first (sink)\
      token — the softmax dumps spare mass there.
    ],
  )

  // ── mechanism note: a learned per-head sink logit ───────────────────────
  let note-y = cap-y - 1.0
  content(
    ((left-x + right-x + n * cell) / 2, note-y),
    text(fill: rgb("#5C5C5C"), size: 8pt, style: "italic")[
      softmax(\[ q·k#sub[0] $dots.h.c$ q·k#sub[i] , #text(fill: garnet)[s] \])
      — #text(fill: garnet)[s] is a learned per-head sink logit (no value vector)
    ],
  )

  // ── legend ──────────────────────────────────────────────────────────────
  let ly = note-y - 0.95
  let lx = left-x + 0.4
  let sw = 0.34
  rect((lx, ly), (lx + sw, ly + sw), fill: attend, stroke: 0.6pt + attend-s)
  content((lx + sw + 0.12, ly + sw / 2), anchor: "west",
    text(size: 8pt, fill: rgb("#363636"))[attended (1)])
  let lx2 = lx + 2.35
  rect((lx2, ly), (lx2 + sw, ly + sw), fill: sink-fill, stroke: 0.8pt + sink-s)
  content((lx2 + sw + 0.12, ly + sw / 2), anchor: "west",
    text(size: 8pt, fill: rgb("#363636"))[sink column (always on)])
  let lx3 = lx2 + 3.55
  rect((lx3, ly), (lx3 + sw, ly + sw), fill: masked, stroke: 0.5pt + gridln)
  content((lx3 + sw + 0.12, ly + sw / 2), anchor: "west",
    text(size: 8pt, fill: rgb("#363636"))[masked (0)])
})
