// Full causal attention vs sliding-window attention — two seq×seq mask grids.
// Lower-triangular (causal) vs banded (sliding window, w = 2). Built from
// architectural knowledge in mlatlas's print-first style.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ───────────────────────────────────────────────────────────────
#let garnet   = rgb("#73000A")
#let ink      = rgb("#000000")
#let attend   = rgb("#466A9F").transparentize(72%)   // attended (=1) cells
#let attend-s = rgb("#466A9F")                         // attend stroke
#let masked   = rgb("#ECECEC")                         // masked (=0) cells
#let dropped  = rgb("#CC2E40").transparentize(78%)     // window-dropped cells
#let dropped-s= rgb("#CC2E40")
#let gridln   = rgb("#5C5C5C")

#let tokens = ("The", "cat", "sat", "on", "the")
#let n = tokens.len()
#let cell = 0.74          // cell edge (cm)
#let win = 2             // sliding window size: attend to self + (win-1) prev

// Draw one mask grid. `keep(i,j)` -> true if query row i attends key col j.
// `dropreg(i,j)` -> true if causally-allowed but cut by the window (only
// meaningful for the sliding-window panel; otherwise always false).
#let mask-grid(ox, oy, keep, dropreg, title) = {
  import cetz.draw: *

  // panel title bar — fixed half-width so longer titles still fit, centered on grid
  let cx = ox + n * cell / 2
  let bar-hw = 2.15
  rect(
    (cx - bar-hw, oy + cell + 0.32),
    (cx + bar-hw, oy + cell + 1.02),
    fill: garnet, stroke: none,
  )
  content(
    (cx, oy + cell + 0.67),
    text(fill: white, weight: "bold", size: 9pt, title),
  )

  for i in range(n) {
    // key labels (columns, across the top)
    content(
      (ox + i * cell + cell / 2, oy + cell + 0.07),
      text(fill: ink, size: 8.5pt, tokens.at(i)),
    )
    // query labels (rows, down the left).  row 0 is the top row.
    content(
      (ox - 0.52, oy - i * cell + cell / 2),
      text(fill: ink, size: 8.5pt, tokens.at(i)),
    )
  }

  for i in range(n) {           // query row (top -> bottom)
    for j in range(n) {         // key column (left -> right)
      let x0 = ox + j * cell
      let y0 = oy - i * cell
      let on = keep(i, j)
      let drp = dropreg(i, j)
      let fil = if on { attend } else if drp { dropped } else { masked }
      let str = if on { 0.6pt + attend-s.transparentize(20%) }
                else if drp { 0.7pt + dropped-s }
                else { 0.5pt + gridln }
      rect((x0, y0), (x0 + cell, y0 + cell), fill: fil, stroke: str)
      content(
        (x0 + cell / 2, y0 + cell / 2),
        text(
          fill: if on { rgb("#1F414D") } else if drp { dropped-s } else { rgb("#A2A2A2") },
          size: 8pt,
          weight: if on { "bold" } else { "regular" },
          if on { [1] } else { [0] },
        ),
      )
    }
  }
}

// causal: attend to all j <= i
#let causal-keep = (i, j) => j <= i
#let no-drop = (i, j) => false

// sliding window (w): attend to i-w+1 <= j <= i
#let window-keep = (i, j) => (j <= i) and (j > i - win)
// causally allowed but cut by the window -> highlight in red
#let window-drop = (i, j) => (j <= i) and (j <= i - win)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  let gap = 2.35
  let left-x = 0
  let right-x = n * cell + gap

  mask-grid(left-x, 0, causal-keep, no-drop,
    [Full causal attention])
  mask-grid(right-x, 0, window-keep, window-drop,
    [Sliding window (w = 2)])

  // ── captions ──────────────────────────────────────────────────────────
  let cap-y = -n * cell - 0.65
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
      Each query attends only within a fixed\
      window — banded mask saves computation.
    ],
  )

  // legend — centered under the full figure span
  let total-w = right-x + n * cell
  let lx = (total-w - 7.6) / 2
  let ly = cap-y - 1.25
  let sw = 0.34
  rect((lx, ly), (lx + sw, ly + sw), fill: attend, stroke: 0.6pt + attend-s)
  content((lx + sw + 0.12, ly + sw / 2), anchor: "west",
    text(size: 8pt, fill: rgb("#363636"))[attended (1)])
  let lx2 = lx + 2.4
  rect((lx2, ly), (lx2 + sw, ly + sw), fill: masked, stroke: 0.5pt + gridln)
  content((lx2 + sw + 0.12, ly + sw / 2), anchor: "west",
    text(size: 8pt, fill: rgb("#363636"))[masked, causal (0)])
  let lx3 = lx2 + 3.05
  rect((lx3, ly), (lx3 + sw, ly + sw), fill: dropped, stroke: 0.7pt + dropped-s)
  content((lx3 + sw + 0.12, ly + sw / 2), anchor: "west",
    text(size: 8pt, fill: rgb("#363636"))[dropped by window])
})
