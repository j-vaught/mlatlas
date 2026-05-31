// mlatlas · Structural Risk Minimization — the generalization-bound gap.
// (Vapnik; Mohri, Rostamizadeh & Talwalkar §3; Understanding Machine Learning §6–7.)
//
// A generalization bound certifies the TRUE (population) risk R(h) from the
// EMPIRICAL risk R̂(h) plus a CAPACITY PENALTY that grows with the richness of
// the hypothesis class H:
//
//     R(h)  ≤  R̂(h)  +  Ω(H, n, δ)        (w.p. ≥ 1−δ)
//                ^          ^
//          empirical   complexity penalty   ~ √( (VC-dim · log n) / n )
//
//   • Empirical risk  R̂  FALLS as the class grows richer (it fits the sample
//     better) — monotone decreasing in capacity.
//   • Penalty  Ω      RISES with capacity (VC-dimension / Rademacher complexity).
//   • The BOUND  R̂ + Ω  is U-SHAPED → its trough is the Structural-Risk-Minimizing
//     class size h*. Picking H there minimizes the guaranteed risk.
//   • The GAP between the bound and the true risk is the slack of the inequality.
//   • A nested structure  H_1 ⊂ H_2 ⊂ ··· (ticks on the x-axis) is searched: SRM
//     trades fit against capacity rather than just minimizing training error.
//
// Curves are closed-form, sampled in Typst, drawn in cetz (print-first house
// style: light panel, dark ink, sharp corners, garnet bound curve as the accent).
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
  let garnet  = rgb("#73000A")   // the bound  R̂ + Ω  (focal accent)
  let blue    = rgb("#466A9F")   // capacity penalty Ω
  let green    = rgb("#65780B")  // empirical risk R̂
  let redx    = rgb("#CC2E40")   // true risk R (unknown)
  let beige   = rgb("#FFF2E3")

  // ── plot frame in cetz units ──────────────────────────────────────────────
  // capacity c ∈ [0,1] on x; risk on y ∈ [0,1] mapped to the box.
  let W = 9.8
  let H = 6.3
  let x0 = 0
  let y0 = 0
  let N  = 121

  let X(c) = x0 + c * W
  let Y(e) = y0 + e * H

  // ── component curves (closed form on c ∈ [0,1]) ───────────────────────────
  let rmin = 0.10                                       // Bayes / approximation floor
  // empirical risk R̂ : high at low capacity, decays toward ~0 (fits the sample)
  let remp(c) = 0.66 * calc.pow(2.718281828, -3.1 * c) + 0.012
  // capacity penalty Ω : grows with capacity (∝ √(VCdim/n) flavour, accelerating)
  let pen(c) = 0.05 + 0.74 * calc.pow(c, 1.7)
  // bound on true risk = R̂ + Ω  (U-shaped)
  let bound(c) = remp(c) + pen(c)
  // true (population) risk R : also U-shaped but LOWER than the bound — the gap.
  // sits just above the empirical floor, troughs slightly right of the bound.
  let rtrue(c) = rmin + 0.40 * calc.pow(2.718281828, -3.4 * c) + 0.34 * calc.pow(c, 1.9)

  let samp(f) = range(N + 1).map(i => {
    let c = i / N
    (X(c), Y(f(c)))
  })

  // optimum of the BOUND  → the SRM class size h*
  let copt = 0
  let best = 1e9
  for i in range(N + 1) {
    let c = i / N
    let v = bound(c)
    if v < best { best = v; copt = c }
  }

  // ── panel + faint gridlines ────────────────────────────────────────────────
  rect((X(0), Y(0)), (X(1), Y(1)), fill: white, stroke: none)
  for k in range(1, 5) {
    let e = k / 5
    line((X(0), Y(e)), (X(1), Y(e)), stroke: 0.4pt + grid)
  }

  // ── nested-structure ticks on the x-axis: H_1 ⊂ H_2 ⊂ ··· ⊂ H_k ───────────
  let kticks = 5
  for j in range(1, kticks + 1) {
    let c = j / (kticks + 1)
    line((X(c), Y(0)), (X(c), Y(0) - 0.13), stroke: 0.8pt + faint)
  }

  // helper to draw a curve as a polyline
  let curve(f, col, w: 1.4pt, dash: none) = {
    let pts = samp(f)
    line(..pts, stroke: (paint: col, thickness: w, dash: dash))
  }

  // ── the GAP between bound and true risk (shaded sliver) ───────────────────
  let gapfill = range(N + 1).map(i => { let c = i / N; (X(c), Y(bound(c))) })
  let gaplow  = range(N + 1).map(i => { let c = (N - i) / N; (X(c), Y(rtrue(c))) })
  line(..gapfill, ..gaplow, close: true, fill: beige, stroke: none)

  // ── component curves ───────────────────────────────────────────────────────
  curve(remp, green, w: 1.4pt)                          // empirical risk
  curve(pen,  blue,  w: 1.4pt)                           // capacity penalty
  curve(rtrue, redx, w: 1.5pt, dash: "dashed")          // true risk (unknown)
  curve(bound, garnet, w: 2.3pt)                        // the bound (focal, U-shaped)

  // ── optimum marker: vertical line + dot at the bound's trough (h*) ─────────
  line(
    (X(copt), Y(0)), (X(copt), Y(bound(copt))),
    stroke: (paint: garnet, dash: "dotted", thickness: 0.9pt),
  )
  circle((X(copt), Y(bound(copt))), radius: 0.085, fill: garnet, stroke: 0.6pt + white)
  // small caret on the x-axis at h*
  line((X(copt), Y(0)), (X(copt), Y(0) - 0.18), stroke: 1.2pt + garnet)

  // ── under/over-capacity zone labels ────────────────────────────────────────
  content(
    (X(copt / 2), Y(0.95)),
    text(fill: muted, size: 8pt, style: "italic")[underfit],
  )
  content(
    (X(copt / 2), Y(0.885)),
    text(fill: faint, size: 6.8pt)[(class too small)],
  )
  content(
    (X(copt + (1 - copt) / 2 + 0.02), Y(0.95)),
    text(fill: muted, size: 8pt, style: "italic")[overfit],
  )
  content(
    (X(copt + (1 - copt) / 2 + 0.02), Y(0.885)),
    text(fill: faint, size: 6.8pt)[(class too rich)],
  )

  // optimum tick labels under the axis
  content(
    (X(copt), Y(0) - 0.36),
    text(fill: garnet, size: 8pt, weight: "bold")[$h^*$ (SRM)],
    anchor: "north",
  )
  content(
    (X(copt), Y(0) - 0.72),
    text(fill: garnet, size: 6.8pt)[optimal capacity],
    anchor: "north",
  )

  // ── gap annotation (arrow between true risk and bound at mid-right) ─────────
  let cg = 0.78
  line(
    (X(cg), Y(rtrue(cg))), (X(cg), Y(bound(cg))),
    stroke: (paint: axiscol, thickness: 0.8pt),
    mark: (start: "stealth", end: "stealth", scale: 0.4),
  )
  content(
    (X(cg) + 0.16, Y((rtrue(cg) + bound(cg)) / 2)),
    text(fill: axiscol, size: 7pt, style: "italic")[bound gap],
    anchor: "west",
  )

  // ── inline curve labels (near each curve's right end) ──────────────────────
  // the bound  R̂ + Ω  (topmost at the right edge) — lift its label clear of the penalty
  content(
    (X(1.0) + 0.20, Y(bound(1.0)) + 0.30),
    text(fill: garnet, size: 8.5pt, weight: "bold")[bound $hat(R) + Omega$],
    anchor: "west",
  )
  // capacity penalty — sits just below the bound at c=1; nudge its label down a touch
  content(
    (X(1.0) + 0.20, Y(pen(1.0)) - 0.26),
    text(fill: blue, size: 8pt)[penalty $Omega$],
    anchor: "west",
  )
  // true risk
  content(
    (X(1.0) + 0.20, Y(rtrue(1.0))),
    text(fill: redx, size: 8pt)[true risk $R$],
    anchor: "west",
  )
  // empirical risk — label near its left where it dominates / above the curve
  content(
    (X(0.42), Y(remp(0.42)) - 0.30),
    text(fill: green, size: 8pt)[empirical $hat(R)$],
    anchor: "west",
  )

  // ── axes (drawn last, on top) ──────────────────────────────────────────────
  line((X(0), Y(0)), (X(0), Y(1)), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))
  line((X(0), Y(0)), (X(1) + 0.05, Y(0)), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))

  // axis titles
  content(
    (X(0.5), Y(0) - 1.12),
    text(fill: ink, size: 9.5pt)[
      hypothesis-class capacity #h(0.3em)
      #text(fill: faint, size: 7pt)[$H_1 subset H_2 subset dots.h.c subset H_k$ #sym.space (VC-dim / complexity)]
    ],
    anchor: "north",
  )
  content(
    (X(0) - 0.66, Y(0.5)),
    angle: 90deg,
    text(fill: ink, size: 9.5pt)[risk],
    anchor: "south",
  )
})
