// Support Vector Machine — the maximum-margin separating hyperplane.
//   decision boundary  w·x + b = 0 ;  margin boundaries  w·x + b = ±1
//   geometric margin  M = 1 / ‖w‖ on each side  (total width 2/‖w‖).
// Two linearly (almost) separable class clouds (garnet +1, blue −1) are split by the
// solid hyperplane. The two dashed lines are the canonical margins; the points that
// sit exactly on them — the support vectors — are ringed (they alone fix the solution).
// Two soft-margin violators carry a slack arrow ξ_i, the functional distance by which
// they intrude past their own margin. Standard ESL / ISLR / Mohri / MML teaching figure,
// built from scratch in mlatlas's print-first house style. No image was traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ──────────────────────────────────────────────────────────────────
#let c-pos = rgb("#73000A") // garnet — class +1 (focal accent)
#let c-neg = rgb("#466A9F") // blue   — class −1
#let ink   = rgb("#222222")
#let muted = rgb("#5C5C5C")
#let grid-c = rgb("#ECECEC")
#let band   = rgb("#FFF2E3") // beige — the margin band fill

// ── world → canvas mapping.  world x∈[0,10], y∈[0,8] ─────────────────────────
#let X0 = 0.0
#let X1 = 10.0
#let Y0 = 0.0
#let Y1 = 8.0
#let PW = 9.6  // plot width  (cm)
#let PH = 7.0  // plot height (cm)
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH
#let P(p) = (sx(p.at(0)), sy(p.at(1))) // world tuple → canvas tuple

// ── the hyperplane:  f(x,y) = m·x − y + c  (so w = (m,−1), b = c) ────────────
//   decision boundary  f = 0   →  y = m x + c
//   +1 margin          f = +1  →  y = m x + (c−1)   (garnet side)
//   −1 margin          f = −1  →  y = m x + (c+1)   (blue side)
#let m = 0.65
#let c = 1.4
#let wn = calc.sqrt(m * m + 1.0) // ‖w‖
#let f(x, y) = m * x - y + c
#let yline(x, off) = m * x + c + off // decision off=0, margins off=∓1

// ── data clouds  (x, y) ──────────────────────────────────────────────────────
#let pos = (
  (3.791, 1.341), (6.407, 0.8), (5.487, 2.823), (1.759, 0.926),
  (5.817, 3.037), (8.068, 2.298), (2.354, 1.113), (6.311, 2.87),
  (5.582, 0.733), (6.643, 3.25), (4.825, 2.368),
)
#let neg = (
  (5.402, 6.338), (4.545, 5.524), (1.514, 4.911), (1.685, 5.14),
  (6.377, 7.152), (1.381, 3.486), (1.672, 5.601), (4.328, 6.313),
  (5.596, 6.395), (4.07, 6.401), (2.028, 4.677),
)
// support vectors lie exactly on the margins (f = ±1)
#let sv-pos = ((3.0, 2.35), (6.6, 4.69))   // on the +1 margin
#let sv-neg = ((2.2, 3.83), (5.8, 6.17))   // on the −1 margin
// soft-margin violators (intrude past their own margin) with slack ξ_i
#let viol-pos = (7.0, 5.65) // garnet point inside the band, correct side (0<ξ<1, f≈0.30)
#let viol-neg = (4.6, 3.94) // blue point on the WRONG side — misclassified (ξ>1, f≈0.45)

// square marker for a data point
#let pmark(pt, col, r: 0.13) = {
  import cetz.draw: *
  let q = P(pt)
  rect((q.at(0) - r, q.at(1) - r), (q.at(0) + r, q.at(1) + r),
    fill: col.transparentize(8%), stroke: 0.5pt + ink.transparentize(30%))
}

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── plot frame + faint grid ────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)
  for gx in range(1, 10) { line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c) }
  for gy in range(1, 8) { line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c) }

  // ── the margin band (between the two dashed margins), filled beige ─────────
  // clip the lines to the plot box by sampling x at the frame edges.
  let xL = X0
  let xR = X1
  // +1 margin endpoints (garnet side, lower) and −1 margin (blue side, upper)
  let pmL = (xL, yline(xL, -1)) // +1 margin left
  let pmR = (xR, yline(xR, -1)) // +1 margin right
  let nmL = (xL, yline(xL, 1))  // −1 margin left
  let nmR = (xR, yline(xR, 1))  // −1 margin right
  line(P(pmL), P(pmR), P(nmR), P(nmL), close: true, stroke: none, fill: band)

  // ── margin boundaries (dashed) ─────────────────────────────────────────────
  line(P(pmL), P(pmR), stroke: (paint: c-pos, thickness: 1.0pt, dash: "dashed"))
  line(P(nmL), P(nmR), stroke: (paint: c-neg, thickness: 1.0pt, dash: "dashed"))

  // ── the decision hyperplane (solid garnet — the focal line) ────────────────
  line(P((xL, yline(xL, 0))), P((xR, yline(xR, 0))), stroke: 2pt + c-pos)

  // ── perpendicular margin-width arrow (along the normal w, between margins) ──
  // anchor near a clear spot; step along unit normal n = (m,−1)/‖w‖ by 1/‖w‖.
  let ax = 3.95 // world x where we plant the foot on the +1 margin
  let foot = (ax, yline(ax, -1))                 // on +1 margin
  let nx = m / wn
  let ny = -1 / wn
  // geometric gap between the two margins = 2/‖w‖ along n
  let head = (foot.at(0) + (2 / wn) * nx, foot.at(1) + (2 / wn) * ny)
  let mid  = (foot.at(0) + (1 / wn) * nx, foot.at(1) + (1 / wn) * ny)
  // double-headed arrow drawn on top of a white halo for legibility
  line(P(foot), P(head), stroke: 3pt + white)
  line(P(foot), P(head), stroke: 1.2pt + ink, mark: (start: "stealth", end: "stealth"))
  // margin label beside the arrow
  content((sx(mid.at(0)) + 0.62, sy(mid.at(1)) - 0.18),
    text(size: 9pt, fill: ink)[$ frac(2, norm(bold(w))) $])

  // ── data points ────────────────────────────────────────────────────────────
  for p in pos { pmark(p, c-pos) }
  for p in neg { pmark(p, c-neg) }

  // ── slack offsets ξ_i for the two soft-margin violators ────────────────────
  // ξ_i is the functional distance past the point's own margin, measured along n.
  let slack(pt, col, sign) = {
    // project pt onto its own margin (f = sign) along the normal.
    // current functional value:
    let fv = f(pt.at(0), pt.at(1))
    // step needed so that f reaches `sign` : Δf = sign − fv, step = Δf/‖w‖² · w
    let dfac = (sign - fv) / (wn * wn)
    let onmarg = (pt.at(0) + dfac * m, pt.at(1) + dfac * (-1))
    line(P(pt), P(onmarg), stroke: 3pt + white) // halo for legibility over the band
    line(P(pt), P(onmarg), stroke: 1.7pt + col.darken(8%),
      mark: (end: "stealth", scale: 0.85))
  }
  slack(viol-pos, c-pos, 1)   // garnet violator → its +1 margin
  slack(viol-neg, c-neg, -1)  // blue   violator → its −1 margin
  pmark(viol-pos, c-pos)
  pmark(viol-neg, c-neg)
  // ξ labels
  content((sx(viol-pos.at(0)) + 0.46, sy(viol-pos.at(1)) + 0.02),
    text(size: 9pt, fill: c-pos)[$xi_i$])
  content((sx(viol-neg.at(0)) - 0.50, sy(viol-neg.at(1)) + 0.34),
    text(size: 9pt, fill: c-neg)[$xi_j$])

  // ── support vectors: ring the on-margin points ─────────────────────────────
  let ring(pt, col) = {
    let q = P(pt)
    circle(q, radius: 0.265, stroke: 1.6pt + col, fill: none)
    pmark(pt, col, r: 0.13)
  }
  for p in sv-pos { ring(p, c-pos) }
  for p in sv-neg { ring(p, c-neg) }

  // ── boundary / margin labels along the lines (right edge) ──────────────────
  content((sx(9.55), sy(yline(9.55, 0)) - 0.34),
    text(size: 8pt, fill: c-pos)[$bold(w) dot bold(x) + b = 0$])
  content((sx(8.7), sy(yline(8.7, -1)) - 0.30),
    text(size: 7.5pt, fill: c-pos)[$= +1$])
  content((sx(7.55), sy(yline(7.55, 1)) + 0.30),
    text(size: 7.5pt, fill: c-neg)[$= -1$])

  // ── axes ticks + labels ────────────────────────────────────────────────────
  for gx in range(0, 11) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    content((sx(gx), -0.34), text(size: 7pt, fill: muted)[#gx])
  }
  for gy in range(0, 9) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    content((-0.30, sy(gy)), text(size: 7pt, fill: muted)[#gy])
  }
  content((PW / 2, -0.82), text(size: 9pt, fill: ink)[$x_1$])
  content((-0.92, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title ──────────────────────────────────────────────────────────────────
  content((PW / 2, PH + 0.86),
    text(size: 11pt, weight: "bold", fill: ink)[Maximum-margin hyperplane (SVM)])
  content((PW / 2, PH + 0.42),
    text(size: 8pt, fill: muted)[
      $min_(bold(w), b) thin 1 / 2 norm(bold(w))^2 + C sum_i xi_i
       quad "s.t." quad y_i (bold(w) dot bold(x)_i + b) >= 1 - xi_i$])

  // ── legend (right side) ────────────────────────────────────────────────────
  let lx = PW + 0.55
  let ly = PH - 0.35
  // class +1
  rect((lx - 0.13, ly - 0.13), (lx + 0.13, ly + 0.13),
    fill: c-pos.transparentize(8%), stroke: 0.5pt + ink.transparentize(30%))
  content((lx + 0.34, ly), anchor: "west", text(size: 8pt, fill: ink)[class $y_i = +1$])
  // class −1
  rect((lx - 0.13, ly - 0.62 - 0.13), (lx + 0.13, ly - 0.62 + 0.13),
    fill: c-neg.transparentize(8%), stroke: 0.5pt + ink.transparentize(30%))
  content((lx + 0.34, ly - 0.62), anchor: "west", text(size: 8pt, fill: ink)[class $y_i = -1$])
  // support vector
  circle((lx, ly - 1.24), radius: 0.18, stroke: 1.4pt + ink, fill: none)
  rect((lx - 0.1, ly - 1.24 - 0.1), (lx + 0.1, ly - 1.24 + 0.1),
    fill: muted.transparentize(35%), stroke: 0.5pt + ink.transparentize(30%))
  content((lx + 0.34, ly - 1.24), anchor: "west", text(size: 8pt, fill: ink)[support vector])
  // decision boundary
  line((lx - 0.18, ly - 1.86), (lx + 0.18, ly - 1.86), stroke: 2pt + c-pos)
  content((lx + 0.34, ly - 1.86), anchor: "west", text(size: 8pt, fill: ink)[hyperplane])
  // margin lines
  line((lx - 0.18, ly - 2.42), (lx + 0.18, ly - 2.42),
    stroke: (paint: muted, thickness: 1pt, dash: "dashed"))
  content((lx + 0.34, ly - 2.42), anchor: "west", text(size: 8pt, fill: ink)[margins])
  // slack
  line((lx - 0.18, ly - 2.98), (lx + 0.18, ly - 2.98),
    stroke: 1.5pt + muted, mark: (end: "stealth", scale: 0.7))
  content((lx + 0.34, ly - 2.98), anchor: "west", text(size: 8pt, fill: ink)[slack $xi_i$])
})
