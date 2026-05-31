// mlatlas · CTC alignment lattice and the collapse (squash) operation.
//
// Connectionist Temporal Classification turns a per-frame softmax over an
// extended alphabet  {symbols} ∪ {blank ε}  into a string. The acoustic model
// emits, for each input frame t, a distribution over labels — drawn here as a
// frame × symbol heatmap (columns = frames t, rows = symbols incl. blank ε,
// cell shaded by emission probability p_t(s), beige → garnet).
//
// A frame-level ALIGNMENT is a monotonic left-to-right path that picks one
// symbol per frame. MANY distinct paths COLLAPSE to the same output string
// under B( · ): first merge runs of identical adjacent symbols, then delete
// every blank ε. The CTC probability of an output is the SUM over all paths
// that collapse to it. Here three valid alignments all collapse to "CAT".
//
// Original mlatlas figure of a standard speech/sequence concept (Graves 2006;
// Jurafsky & Martin SLP3). Built from knowledge, not traced. The emission
// matrix and the three highlighted paths are internally consistent: every
// highlighted path follows the high-probability cells and B(path) = CAT.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// ── palette ─────────────────────────────────────────────────────────────────
#let p = (
  ink:    rgb("#1A1A1A"),
  text:   rgb("#222222"),
  muted:  rgb("#5C5C5C"),
  edge:   rgb("#363636"),
  grid:   rgb("#C7C7C7"),
  beige:  rgb("#FFF2E3"),   // ramp lo
  garnet: rgb("#73000A"),   // ramp hi + focal path
  blue:   rgb("#466A9F"),   // 2nd alignment
  green:  rgb("#65780B"),   // 3rd alignment
)

// sequential ramp: beige (t=0) → garnet (t=1), interpolated in oklab.
#let ramp(t) = {
  let t = calc.max(0.0, calc.min(1.0, t))
  p.beige.mix((p.garnet, t * 100%), space: oklab)
}
#let on-fill(t) = if t > 0.58 { white } else { p.ink }

// ── data ────────────────────────────────────────────────────────────────────
// Rows are the extended alphabet for target "CAT": blank ε on top, then C A T.
// Columns are T = 6 input frames. P[row][t] = emission prob p_t(symbol).
// Each COLUMN is a valid softmax (sums to 1). Row order top→bottom: ε, C, A, T.
#let syms = ([ε], [C], [A], [T])
#let P = (
  // t:   1     2     3     4     5     6
  (0.55, 0.10, 0.10, 0.50, 0.10, 0.55),  // ε  (blank)
  (0.30, 0.75, 0.65, 0.10, 0.05, 0.10),  // C
  (0.10, 0.10, 0.20, 0.30, 0.20, 0.10),  // A
  (0.05, 0.05, 0.05, 0.10, 0.65, 0.25),  // T
)

#let nR = syms.len()         // 4 rows
#let nT = P.at(0).len()      // 6 frames
#let cell = 1.35

#let W = nT * cell
#let H = nR * cell

// map (row index i from top, frame t from 1) → cell-center coordinates.
// canvas y grows up; row 0 (ε) is at the TOP, so flip the row index.
#let cx(t) = (t - 1) * cell + cell / 2
#let cy(i) = (nR - 1 - i) * cell + cell / 2

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── heatmap cells ──────────────────────────────────────────────────────────
  for i in range(nR) {
    for t in range(nT) {
      let v = P.at(i).at(t)
      let xx = t * cell
      let yy = (nR - 1 - i) * cell
      draw.rect(
        (xx, yy), (xx + cell, yy + cell),
        fill: ramp(v), stroke: 0.6pt + p.grid, radius: 0pt,
      )
      // print the probability in the upper-left corner so the alignment
      // polylines (which run through cell centers) never cover the numbers.
      draw.content(
        (xx + 0.20, yy + cell - 0.20),
        anchor: "north-west",
        text(size: 8pt, fill: on-fill(v))[#v],
      )
    }
  }

  // outer frame
  draw.rect((0, 0), (W, H), fill: none, stroke: 1.2pt + p.edge, radius: 0pt)
  // blank row gets a subtle separating rule below it (ε sits on top row)
  draw.line((0, H - cell), (W, H - cell), stroke: 1.0pt + p.edge)

  // ── three valid alignment paths (each picks one row per frame) ──────────────
  // path = list of row indices, one per frame t = 1..6.  Row idx: 0=ε,1=C,2=A,3=T
  // All three collapse under B to "CAT":
  //   garnet: ε C C ε A T   → C C → C, drop ε → C A T
  //   blue:   C C ε A A T   → C A T  (alt spread of A)
  //   green:  ε C ε A T T   → C A T
  let paths = (
    ((0, 1, 1, 0, 2, 3), p.garnet, "focal"),
    ((1, 1, 0, 2, 2, 3), p.blue,   "alt"),
    ((0, 1, 0, 2, 3, 3), p.green,  "alt"),
  )

  // small per-path vertical jitter so coincident segments stay distinguishable
  let jit = (0.16, 0.0, -0.16)

  for (pi, pdata) in paths.enumerate() {
    let (rows, col, kind) = pdata
    let dy = jit.at(pi)
    let lw = if kind == "focal" { 2.6pt } else { 1.6pt }
    // build vertex list
    let verts = ()
    for t in range(nT) {
      verts.push((cx(t + 1), cy(rows.at(t)) + dy))
    }
    // polyline
    for k in range(nT - 1) {
      draw.line(
        verts.at(k), verts.at(k + 1),
        stroke: (paint: col, thickness: lw),
      )
    }
    // vertex dots
    for vtx in verts {
      draw.circle(vtx, radius: if kind == "focal" { 0.085 } else { 0.065 },
        fill: col, stroke: none)
    }
  }

  // ── axis labels ────────────────────────────────────────────────────────────
  // frame indices across the bottom
  for t in range(nT) {
    draw.content(
      (t * cell + cell / 2, -0.30),
      text(size: 9.5pt, fill: p.text)[$t #sym.eq.triple #(t + 1)$],
    )
  }
  // symbol labels down the left (row 0 = ε on top)
  for i in range(nR) {
    let lbl = syms.at(i)
    let isblank = i == 0
    draw.content(
      (-0.28, (nR - 1 - i) * cell + cell / 2),
      anchor: "east",
      text(
        size: 11pt,
        fill: if isblank { p.muted } else { p.ink },
        weight: "bold",
        style: if isblank { "italic" } else { "normal" },
      )[#lbl],
    )
  }
  // axis captions
  draw.content((W / 2, -0.92),
    text(size: 11pt, fill: p.ink, weight: "bold")[input frame $t$ (time #sym.arrow.r)])
  draw.content((-1.55, H / 2), angle: 90deg,
    text(size: 11pt, fill: p.ink, weight: "bold")[label (incl. blank #text(style: "italic")[ε])])

  // ── title ───────────────────────────────────────────────────────────────────
  draw.content((W / 2, H + 1.55),
    text(size: 13pt, weight: "bold", fill: p.ink)[CTC alignment lattice and collapse])
  draw.content((W / 2, H + 1.02),
    text(size: 9pt, fill: p.muted)[
      per-frame softmax over symbols #sym.union {blank #text(style: "italic")[ε]};
      monotonic paths $#sym.pi$ pick one row per frame
    ])

  // ── colorbar (emission probability legend) ─────────────────────────────────
  let bx = W + 0.55
  let bw = 0.42
  let nseg = 40
  for s in range(nseg) {
    let t0 = s / nseg
    let t1 = (s + 1) / nseg
    draw.rect((bx, t0 * H), (bx + bw, t1 * H),
      fill: ramp((t0 + t1) / 2), stroke: none)
  }
  draw.rect((bx, 0), (bx + bw, H), fill: none, stroke: 0.8pt + p.edge, radius: 0pt)
  for (frac, lbl) in ((0.0, "0"), (0.5, "0.5"), (1.0, "1")) {
    let yy = frac * H
    draw.line((bx + bw, yy), (bx + bw + 0.12, yy), stroke: 0.8pt + p.edge)
    draw.content((bx + bw + 0.20, yy), anchor: "west",
      text(size: 8pt, fill: p.muted)[#lbl])
  }
  draw.content((bx + bw / 2, H + 0.28), anchor: "south",
    text(size: 8pt, fill: p.muted)[$p_t (s)$])
})

#v(10pt)

// ── collapse panel B(·): squash repeats, then drop blanks ─────────────────────
#cetz.canvas(length: 1cm, {
  import cetz.draw

  // three example frame-paths and their reductions, colour-matched to lattice.
  // `merged` = string AFTER squashing adjacent repeats but BEFORE dropping ε.
  let rows = (
    (p.garnet, ([ε], [C], [C], [ε], [A], [T]), ([ε], [C], [ε], [A], [T]), [C A T]),
    (p.blue,   ([C], [C], [ε], [A], [A], [T]), ([C], [ε], [A], [T]),      [C A T]),
    (p.green,  ([ε], [C], [ε], [A], [T], [T]), ([ε], [C], [ε], [A], [T]), [C A T]),
  )

  let bw = 0.62           // box half-width per frame symbol
  let bh = 0.34
  let colsp = 1.32        // spacing between the 6 frame slots
  let rowsp = 1.25        // vertical spacing between the three example rows
  let x0 = 0.0
  let top = 0.0

  // header
  draw.content((x0 + 2.5 * colsp, top + 0.95),
    anchor: "south",
    text(size: 11pt, weight: "bold", fill: p.ink)[
      collapse  $B(#sym.pi)$:  merge adjacent repeats #sym.arrow.r drop blanks #text(style:"italic")[ε]
    ])

  // section captions over the three column groups
  let path-cx = x0 + 2.5 * colsp
  let path-right = x0 + 5 * colsp + bw      // right edge of last frame box
  let mid-cx = path-right + 2.05            // center of merge-repeats box
  let mid-half = 1.05                       // approx half-width of merge box
  let out-cx = mid-cx + mid-half + 1.55     // center of output box

  draw.content((path-cx, top + 0.42), text(size: 8.5pt, fill: p.muted, style: "italic")[frame path $#sym.pi$ (length $T = 6$)])
  draw.content((mid-cx, top + 0.42), text(size: 8.5pt, fill: p.muted, style: "italic")[merge repeats])
  draw.content((out-cx, top + 0.42), text(size: 8.5pt, fill: p.muted, style: "italic")[output $y$])

  for (ri, rdata) in rows.enumerate() {
    let (col, frames, merged, out) = rdata
    let yy = top - 0.30 - ri * rowsp

    // frame-path boxes
    for (fi, sym) in frames.enumerate() {
      let xx = x0 + fi * colsp
      let isblank = sym == [ε]
      draw.rect((xx - bw, yy - bh), (xx + bw, yy + bh),
        fill: if isblank { p.beige } else { white },
        stroke: if isblank { (paint: p.muted, thickness: 0.8pt, dash: "dashed") }
                else { 1.1pt + col },
        radius: 0pt)
      draw.content((xx, yy), text(size: 10pt,
        fill: if isblank { p.muted } else { p.ink },
        weight: "bold",
        style: if isblank { "italic" } else { "normal" })[#sym])
    }

    // arrow to merged
    draw.line((path-right + 0.18, yy), (mid-cx - mid-half - 0.12, yy),
      stroke: 1.0pt + p.muted, mark: (end: "stealth", scale: 0.7))
    // merged-repeats intermediate: adjacent repeats squashed, blanks ε still
    // present (greyed/italic) so the reader sees the blank-drop happen next.
    let merged-body = merged.map(s => {
      if s == [ε] { text(fill: p.muted, style: "italic", weight: "bold")[ε] }
      else { text(fill: col, weight: "bold")[#s] }
    }).join(h(0.28em))
    draw.content((mid-cx, yy),
      box(inset: (x: 4pt, y: 3pt), stroke: (paint: p.grid, thickness: 0.7pt))[
        #text(size: 9.5pt)[#merged-body]
      ])
    // arrow to output
    draw.line((mid-cx + mid-half + 0.12, yy), (out-cx - 0.66, yy),
      stroke: 1.0pt + p.muted, mark: (end: "stealth", scale: 0.7))
    // final output, boxed in the path colour
    draw.rect((out-cx - 0.62, yy - bh - 0.04), (out-cx + 0.62, yy + bh + 0.04),
      fill: col.transparentize(90%), stroke: 1.4pt + col, radius: 0pt)
    draw.content((out-cx, yy), text(size: 11pt, weight: "bold", fill: col)[#out])
  }

  // takeaway brace-line: all collapse to one string
  let by = top - 0.30 - 2 * rowsp - 0.78
  draw.content((path-cx, by), anchor: "west",
    text(size: 9pt, fill: p.garnet, style: "italic")[
      three distinct alignments #sym.arrow.r one output #sym.arrow.r
      $p(y) = sum_(pi in B^(-1)(y)) product_t p_t (pi_t)$
    ])
})
