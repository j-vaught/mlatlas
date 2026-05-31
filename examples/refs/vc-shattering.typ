// mlatlas · VC-dimension shattering — linear classifiers in the plane.
//
//   A hypothesis class H "shatters" a set of m points if, for EVERY one of the
//   2^m label assignments (dichotomies), some h ∈ H realises it. The VC
//   dimension VCdim(H) is the size of the LARGEST set H can shatter.
//
//   Here H = half-planes (linear classifiers in R²), the canonical example.
//   ─ TOP: 3 points in general position. We enumerate all 2³ = 8 dichotomies;
//          every one is realised by a separating line ⇒ the set is SHATTERED.
//   ─ BOTTOM: any 4 points fail. The diagonal "XOR" labelling (the marked
//          dichotomy) is NOT linearly separable ⇒ no 4-point set is shattered.
//   Together: VCdim(half-planes in R²) = 3.   (Mohri, Foundations of ML; UML.)
//
//   Built print-first in cetz: light panels, dark ink, sharp corners, garnet as
//   the sparse focal accent on the non-realizable dichotomy. No image traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ────────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let edge   = rgb("#363636")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid   = rgb("#ECECEC")
  let garnet = rgb("#73000A")     // focal accent — the non-realizable dichotomy
  let blue   = rgb("#466A9F")     // class  +  (positive)
  let pink   = rgb("#CC2E40")
  let cellbg = white

  // class fills: + = blue solid disc, − = open ring
  let posfill = blue
  let negfill = white

  // ── a single dichotomy CELL ────────────────────────────────────────────────
  //   pts  : list of (x, y) in cell-local [0,1]² coords
  //   labs : list of +1 / -1 (one per point)
  //   line : optional (a, b) endpoints of a separating line in [0,1]² coords
  //   The cell is a unit square placed with its lower-left corner at `org`.
  let cell-w = 2.05               // cell side (canvas units)
  let pr = 0.115                  // point radius
  let cell(org, pts, labs, sepline: none, accent: false, badge: none) = {
    let ox = org.at(0)
    let oy = org.at(1)
    let L(p) = (ox + p.at(0) * cell-w, oy + p.at(1) * cell-w)

    // frame
    let fcol = if accent { garnet } else { edge }
    let fw   = if accent { 1.6pt } else { 0.9pt }
    rect((ox, oy), (ox + cell-w, oy + cell-w),
      fill: cellbg, stroke: fw + fcol, radius: 0pt)

    // separating line (drawn behind the points), clipped to the cell visually
    if sepline != none {
      let a = L(sepline.at(0))
      let b = L(sepline.at(1))
      let lc = if accent { garnet } else { muted }
      let ld = if accent { none } else { "dashed" }
      let lw = if accent { 1.4pt } else { 0.9pt }
      line(a, b, stroke: (paint: lc, thickness: lw, dash: ld))
    }

    // points: + = filled blue disc, − = open ring
    for (i, p) in pts.enumerate() {
      let c = L(p)
      if labs.at(i) > 0 {
        circle(c, radius: pr, fill: posfill, stroke: 0.8pt + edge)
      } else {
        circle(c, radius: pr, fill: negfill, stroke: 1.3pt + edge)
      }
    }

    // optional corner badge (e.g. the ✗ mark)
    if badge != none {
      content((ox + cell-w - 0.02, oy + cell-w + 0.30), anchor: "east", badge)
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  PART A — 3 points are SHATTERED by half-planes (all 2³ = 8 dichotomies)
  // ════════════════════════════════════════════════════════════════════════════
  // three points in general position inside the unit cell (a wide triangle)
  let P3 = ((0.24, 0.30), (0.76, 0.26), (0.50, 0.78))

  // For each of the 8 labelings, a max-margin line that separates + from −
  // (each computed offline so it provably cuts the cell correctly; see header).
  // sep convention: blue (+) discs on one side, open (−) rings on the other.
  // labelings ordered by # of positives so the structure reads cleanly.
  // Each entry: (labels for P1,P2,P3 ; separating-line endpoints in [0,1]²).
  let dich3 = (
    // all negative  (trivial: line outside, everything is −)
    ((-1, -1, -1), ((0.10, 1.04), (0.40, 1.10))),
    // single positive (cut off one vertex)
    (( 1, -1, -1), ((0.653, -0.04), (0.126, 1.04))),  // P1 +
    ((-1,  1, -1), ((0.332, -0.04), (0.906, 1.04))),  // P2 +
    ((-1, -1,  1), ((-0.04, 0.569), (1.04, 0.493))),  // P3 +
    // single negative (cut off one vertex the other way)
    ((-1,  1,  1), ((0.653, -0.04), (0.126, 1.04))),  // P1 −
    (( 1, -1,  1), ((0.332, -0.04), (0.906, 1.04))),  // P2 −
    (( 1,  1, -1), ((-0.04, 0.569), (1.04, 0.493))),  // P3 −
    // all positive (trivial: line outside, everything is +)
    (( 1,  1,  1), ((0.60, 1.10), (0.90, 1.04))),
  )

  // grid layout: 8 cells in a 4×2 block
  let gap = 0.42
  let cols-a = 4
  // origin of the 3-point block (top of the canvas)
  let ax0 = 0.0
  // total block width for centering the bottom block later
  let block-w = cols-a * cell-w + (cols-a - 1) * gap

  // top heading
  content((block-w / 2, 14.35),
    text(size: 13pt, weight: "bold", fill: ink)[VC dimension via shattering])
  content((block-w / 2, 13.80),
    text(size: 9pt, fill: muted)[
      hypothesis class $cal(H)$ = half-planes (linear classifiers) in $RR^2$])

  // sub-heading A
  content((block-w / 2, 13.10),
    text(size: 10pt, weight: "bold", fill: blue)[
      3 points are shattered: all $2^3 = 8$ dichotomies are realizable])

  // rows of the 4×2 grid (top row y high)
  let row-y = (10.40, 7.93)
  for (k, d) in dich3.enumerate() {
    let r = calc.div-euclid(k, cols-a)
    let c = calc.rem-euclid(k, cols-a)
    let ox = ax0 + c * (cell-w + gap)
    let oy = row-y.at(r)
    cell((ox, oy), P3, d.at(0), sepline: d.at(1))
  }

  // ── divider ──────────────────────────────────────────────────────────────
  let dy = 7.35
  line((0, dy), (block-w, dy), stroke: 0.7pt + faint)

  // ════════════════════════════════════════════════════════════════════════════
  //  PART B — 4 points are NOT shattered: the XOR dichotomy fails
  // ════════════════════════════════════════════════════════════════════════════
  content((block-w / 2, 6.78),
    text(size: 10pt, weight: "bold", fill: garnet)[
      4 points are NOT shattered: the diagonal (XOR) labelling fails])

  // four points: a convex quadrilateral (diamond). Opposite corners share a label.
  let P4 = ((0.50, 0.16), (0.86, 0.50), (0.50, 0.84), (0.14, 0.50))

  // three example panels along the bottom:
  //   (1) a realizable 4-point dichotomy (one-vs-rest)  ✓
  //   (2) a realizable 4-point dichotomy (a half split) ✓
  //   (3) the XOR dichotomy — NOT realizable            ✗  (garnet, focal)
  let bw = 3                                   // three bottom cells
  let bgap = 0.95
  let bblock = bw * cell-w + (bw - 1) * bgap
  let bx0 = (block-w - bblock) / 2             // center under the top block
  let by  = 3.05

  // (1) one point + (top), rest − : separable (horizontal cut below the top vertex)
  cell((bx0 + 0 * (cell-w + bgap), by),
    P4, (-1, -1, 1, -1),
    sepline: ((-0.04, 0.67), (1.04, 0.67)))
  // (2) two adjacent + (bottom & left), two − : separable (an anti-diagonal cut)
  cell((bx0 + 1 * (cell-w + bgap), by),
    P4, (1, -1, -1, 1),
    sepline: ((-0.04, 1.0), (1.04, 0.0)))
  // (3) XOR: opposite corners share a label  →  NOT linearly separable
  cell((bx0 + 2 * (cell-w + bgap), by),
    P4, (1, -1, 1, -1),
    accent: true)
  // draw BOTH lines a separator would need (and still fail) — illustrate failure
  {
    let ox = bx0 + 2 * (cell-w + bgap)
    let L(p) = (ox + p.at(0) * cell-w, by + p.at(1) * cell-w)
    // the two diagonals cross between same-label points — no single line works
    line(L((0.07, 0.79)), L((0.93, 0.21)),
      stroke: (paint: garnet, thickness: 0.9pt, dash: "dashed"))
    line(L((0.07, 0.21)), L((0.93, 0.79)),
      stroke: (paint: garnet, thickness: 0.9pt, dash: "dashed"))
    // big garnet ✗ over the cell
    content((ox + cell-w + 0.46, by + cell-w / 2),
      text(size: 22pt, weight: "bold", fill: garnet)[$times$])
  }

  // captions under the three bottom cells
  let caps = (
    [realizable #sym.checkmark],
    [realizable #sym.checkmark],
    text(fill: garnet, weight: "bold")[not realizable #sym.crossmark],
  )
  for i in range(3) {
    let ox = bx0 + i * (cell-w + bgap)
    content((ox + cell-w / 2, by - 0.36),
      text(size: 8pt, fill: muted)[#caps.at(i)])
  }

  // ── conclusion bar ─────────────────────────────────────────────────────────
  let cy = 1.85
  line((0, cy), (block-w, cy), stroke: 0.7pt + faint)
  content((block-w / 2, 1.30),
    box(fill: rgb("#FFF2E3"), inset: (x: 9pt, y: 6pt), stroke: 1.1pt + garnet, radius: 0pt,
      text(size: 11pt, fill: ink)[
        some 3-set is shattered, no 4-set is $#h(2pt) ==> #h(2pt)$
        $bold("VCdim")(cal(H)) = 3$]))

  // ── legend (class encoding) ─────────────────────────────────────────────────
  let lx = 0.0
  let lyc = 0.45
  circle((lx + 0.16, lyc), radius: pr, fill: posfill, stroke: 0.8pt + edge)
  content((lx + 0.40, lyc), anchor: "west",
    text(size: 8pt, fill: muted)[class $+1$])
  circle((lx + 2.35, lyc), radius: pr, fill: negfill, stroke: 1.3pt + edge)
  content((lx + 2.59, lyc), anchor: "west",
    text(size: 8pt, fill: muted)[class $-1$])
  line((lx + 4.55, lyc), (lx + 5.35, lyc),
    stroke: (paint: muted, thickness: 0.9pt, dash: "dashed"))
  content((lx + 5.55, lyc), anchor: "west",
    text(size: 8pt, fill: muted)[separating line $h$])
})
