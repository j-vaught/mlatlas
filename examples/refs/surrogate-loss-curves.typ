// mlatlas · Convex surrogate losses for binary classification (UML §12; Mohri ch.4).
// Loss plotted against the (signed) MARGIN  m = y·f(x):
//
//   • 0-1 loss     ℓ₀₁(m) = 𝟙[m ≤ 0]        — the TRUE classification error.
//                                              Non-convex, discontinuous step;
//                                              NP-hard to minimise directly.
//   • Hinge        ℓ_hinge(m) = max(0, 1-m)  — SVM. Convex, piecewise linear.
//   • Logistic     ℓ_log(m)   = log₂(1+e^{-m}) — logistic regression / cross-entropy
//                                              (base-2 so ℓ_log(0)=1, a tight bound).
//   • Squared      ℓ_sq(m)    = (1-m)²        — least-squares classification.
//
//   Each convex surrogate UPPER-BOUNDS the 0-1 loss (all pass through (0,1)),
//   so minimising the surrogate drives the 0-1 error down while staying
//   tractable. Note: only hinge & logistic are MONOTONE non-increasing — the
//   squared loss turns up again for m>1 (penalises "too-correct" margins).
//
// Curves are closed-form, sampled in Typst, drawn in cetz (print-first house
// style: light panel, dark ink, sharp corners, garnet 0-1 step as the accent).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ───────────────────────────────────────────────────────────────
  let ink     = rgb("#1A1A1A")
  let axiscol = rgb("#363636")
  let muted   = rgb("#5C5C5C")
  let faint   = rgb("#A2A2A2")
  let grid    = rgb("#ECECEC")
  let garnet  = rgb("#73000A")   // 0-1 loss  (focal accent — the target)
  let blue    = rgb("#466A9F")   // hinge
  let green    = rgb("#65780B")  // logistic
  let redx    = rgb("#CC2E40")   // squared
  let beige   = rgb("#FFF2E3")

  // ── plot frame ────────────────────────────────────────────────────────────
  // margin  m ∈ [mlo, mhi] on x ;  loss ∈ [0, ehi] on y.
  let mlo = -2.0
  let mhi = 2.0
  let ehi = 3.0
  let W = 9.6           // panel width  (cm)
  let H = 6.2           // panel height (cm)
  let N  = 240          // samples per curve

  // map (m, e) → canvas coords
  let X(m) = (m - mlo) / (mhi - mlo) * W
  let Y(e) = e / ehi * H

  // ── surrogate losses (closed form on m) ───────────────────────────────────
  let e = 2.718281828
  let hinge(m) = calc.max(0, 1 - m)
  let logist(m) = calc.log(1 + calc.pow(e, -m), base: 2)   // base-2 ⇒ passes (0,1)
  let squared(m) = calc.pow(1 - m, 2)

  // sample a curve f over the visible window, clipped to [0, ehi]
  let samp(f) = range(N + 1).map(i => {
    let m = mlo + (mhi - mlo) * i / N
    (X(m), Y(calc.min(f(m), ehi)))
  })

  // ── panel + faint gridlines ───────────────────────────────────────────────
  rect((X(mlo), Y(0)), (X(mhi), Y(ehi)), fill: white, stroke: none)
  for k in range(1, 3) {                       // horizontal at e = 1, 2
    line((X(mlo), Y(k)), (X(mhi), Y(k)), stroke: 0.4pt + grid)
  }
  for mk in (-1, 1) {                           // vertical at m = -1, 1
    line((X(mk), Y(0)), (X(mk), Y(ehi)), stroke: 0.4pt + grid)
  }

  // ── correct / incorrect half-plane shading (split at the margin m = 0) ─────
  rect((X(mlo), Y(0)), (X(0), Y(ehi)), fill: beige, stroke: none)
  line((X(0), Y(0)), (X(0), Y(ehi)), stroke: (paint: faint, dash: "dashed", thickness: 0.6pt))
  content(
    (X(-1.0), Y(0.42)),
    text(fill: muted, size: 7.5pt)[#text(style: "italic")[misclassified] $(y f < 0)$],
  )
  content(
    (X(1.45), Y(2.42)),
    text(fill: faint, size: 7.5pt)[#text(style: "italic")[correct] $(y f > 0)$],
  )

  // ── a curve as a polyline ─────────────────────────────────────────────────
  let curve(f, col, w: 1.6pt, dash: none) = {
    let pts = samp(f)
    line(..pts, stroke: (paint: col, thickness: w, dash: dash))
  }

  // convex surrogates (drawn under the 0-1 step)
  curve(squared, redx,  w: 1.4pt, dash: "dashed")
  curve(logist,  green, w: 1.6pt)
  curve(hinge,   blue,  w: 1.6pt)

  // ── the 0-1 step loss (garnet, focal) ─────────────────────────────────────
  // ℓ₀₁ = 1 for m ≤ 0, 0 for m > 0.
  line((X(mlo), Y(1)), (X(0), Y(1)), stroke: (paint: garnet, thickness: 2.4pt))
  line((X(0), Y(0)),  (X(mhi), Y(0)), stroke: (paint: garnet, thickness: 2.4pt))
  line((X(0), Y(0)),  (X(0), Y(1)),   stroke: (paint: garnet, thickness: 2.4pt, dash: "dotted"))
  // open / closed endpoint dots at the jump
  circle((X(0), Y(1)), radius: 0.075, fill: white,  stroke: 1pt + garnet)   // open at m=0
  circle((X(0), Y(0)), radius: 0.075, fill: garnet, stroke: 1pt + garnet)   // closed at m=0

  // ── inline curve labels ───────────────────────────────────────────────────
  content((X(-1.96), Y(1.42)), text(fill: garnet, size: 8.5pt, weight: "bold")[0–1 loss], anchor: "south-west")
  content((X(-1.96), Y(1.12)), text(fill: garnet, size: 6.8pt)[$bb(1)[m <= 0]$], anchor: "south-west")

  // squared label near its left/upper arm
  content((X(-0.62), Y(2.94)), text(fill: redx, size: 8pt)[squared $(1-m)^2$], anchor: "south-west")
  // hinge label along its sloped segment
  content((X(-0.55), Y(hinge(-0.55)) - 0.08), text(fill: blue, size: 8pt)[hinge $max(0, 1-m)$], anchor: "south-west")
  // logistic label to the right where it's separated from hinge
  content((X(0.62), Y(logist(0.62)) + 0.12), text(fill: green, size: 8pt)[logistic $log_2(1 + e^(-m))$], anchor: "south-west")

  // marker: all surrogates pass through (0, 1) — the tight upper bound point
  circle((X(0), Y(1)), radius: 0.05, fill: white, stroke: 0.8pt + axiscol)
  content((X(0.06), Y(1) + 0.30), text(fill: muted, size: 6.8pt)[all bound $= 1$ at $m = 0$], anchor: "south-west")

  // ── axes (drawn last) ─────────────────────────────────────────────────────
  line((X(mlo), Y(0)), (X(mlo), Y(ehi) + 0.05), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))
  line((X(mlo), Y(0)), (X(mhi) + 0.05, Y(0)),   stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))

  // x ticks
  for mk in (-2, -1, 0, 1, 2) {
    line((X(mk), Y(0)), (X(mk), Y(0) - 0.12), stroke: 1pt + axiscol)
    content((X(mk), Y(0) - 0.20), text(fill: muted, size: 7.5pt)[#mk], anchor: "north")
  }
  // y ticks
  for ek in (1, 2, 3) {
    line((X(mlo), Y(ek)), (X(mlo) - 0.12, Y(ek)), stroke: 1pt + axiscol)
    content((X(mlo) - 0.20, Y(ek)), text(fill: muted, size: 7.5pt)[#ek], anchor: "east")
  }

  // axis titles
  content(
    (X(0.5 * (mlo + mhi)), Y(0) - 0.78),
    text(fill: ink, size: 9.5pt)[margin #h(0.2em) $m = y dot f(x)$],
    anchor: "north",
  )
  content(
    (X(mlo) - 0.66, Y(0.5 * ehi)),
    angle: 90deg,
    text(fill: ink, size: 9.5pt)[loss #h(0.3em) $ell(m)$],
    anchor: "south",
  )
})
