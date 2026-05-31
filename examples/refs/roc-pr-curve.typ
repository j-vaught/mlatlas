// mlatlas · ROC curve and Precision–Recall curve (ESL §9.2; ISLR/ISLP §4.4.3).
//
//   A binary classifier outputs a score s(x); sweeping a decision threshold τ
//   from +∞ down to −∞ traces out two complementary characteristic curves.
//
//   ROC :  TPR = TP/(TP+FN)   on y   vs   FPR = FP/(FP+TN)   on x.
//          The chance diagonal TPR = FPR is a coin-flip classifier; a good model
//          bows toward the top-left. The shaded area under it is AUC ∈ [0.5,1].
//
//   PR  :  Precision = TP/(TP+FP)  on y  vs  Recall = TP/(TP+FN)  on x.
//          The no-skill baseline is the horizontal prevalence line P/(P+N);
//          the curve bows toward the top-right and AP = area under it.
//
//   Both curves are GENUINELY derived here: we model the score densities of the
//   positive and negative classes as two Gaussians, then for a sweep of thresholds
//   compute TP/FP/FN/TN by integrating the densities — so the curve shapes and the
//   AUC/AP areas are the real thing, authored in mlatlas's print-first house style.
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
  let garnet  = rgb("#73000A")   // the focal classifier curve + AUC fill
  let blue    = rgb("#466A9F")
  let beige    = rgb("#FFF2E3")

  // ── score model: P(s | positive) and P(s | negative) as Gaussians ──────────
  // separable but overlapping → a realistic, non-trivial classifier.
  let mu_n = 0.0;  let sd_n = 1.0      // negative class scores
  let mu_p = 1.6;  let sd_p = 1.0      // positive class scores
  let prevalence = 0.32                // fraction of positives, P/(P+N)

  // standard-normal CDF via the erf approximation (Abramowitz & Stegun 7.1.26)
  let erf(x) = {
    let s = if x < 0 { -1.0 } else { 1.0 }
    let z = calc.abs(x)
    let t = 1.0 / (1.0 + 0.3275911 * z)
    let y = 1.0 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * calc.exp(-z * z)
    s * y
  }
  let Phi(x) = 0.5 * (1.0 + erf(x / calc.sqrt(2.0)))

  // at threshold τ (predict positive iff s ≥ τ):
  //   TPR(τ) = P(s ≥ τ | pos) = 1 − Φ((τ−μ_p)/σ_p)
  //   FPR(τ) = P(s ≥ τ | neg) = 1 − Φ((τ−μ_n)/σ_n)
  let tpr(tau) = 1.0 - Phi((tau - mu_p) / sd_p)
  let fpr(tau) = 1.0 - Phi((tau - mu_n) / sd_n)

  // sweep thresholds from high (top-right corner is τ=−∞) to low.
  let Nt   = 200
  let tlo  = -4.5
  let thi  = 6.0
  // ordered so recall/fpr increase from 0 → 1
  let taus = range(Nt + 1).map(i => thi - (thi - tlo) * i / Nt)

  // ── per-threshold confusion counts (as rates), then ROC and PR points ──────
  let roc = taus.map(tau => (fpr(tau), tpr(tau)))
  // precision = TP / (TP + FP)
  //   TP ∝ prevalence · TPR ,  FP ∝ (1−prevalence) · FPR
  let pr = taus.map(tau => {
    let rc = tpr(tau)
    let tpv = prevalence * tpr(tau)
    let fpv = (1.0 - prevalence) * fpr(tau)
    let prec = if (tpv + fpv) <= 0 { 1.0 } else { tpv / (tpv + fpv) }
    (rc, prec)
  })

  // trapezoidal areas: AUC under ROC (x=fpr), AP under PR (x=recall)
  let area(pts) = {
    let a = 0.0
    for i in range(pts.len() - 1) {
      let (x0, y0) = pts.at(i)
      let (x1, y1) = pts.at(i + 1)
      a = a + (x1 - x0) * (y0 + y1) / 2.0
    }
    calc.abs(a)
  }
  let auc = area(roc)
  let ap  = area(pr)

  // ── one square panel: frame, grid, fill, curve, baseline, labels ───────────
  let S = 5.4                          // panel side (cm)
  let panel(ox, title, pts, baseline, fillpts, xlab, ylab, areaval, arealab) = {
    let X(u) = ox + u * S
    let Y(v) = v * S

    // shaded area region (polygon down to the x-axis)
    let poly = fillpts.map(p => (X(p.at(0)), Y(p.at(1))))
    let poly2 = poly + ((X(1), Y(0)), (X(0), Y(0)))
    line(..poly2, close: true, fill: garnet.transparentize(86%), stroke: none)

    // faint grid at 0.25 steps
    for k in range(0, 5) {
      let g = k / 4
      line((X(0), Y(g)), (X(1), Y(g)), stroke: 0.4pt + grid)
      line((X(g), Y(0)), (X(g), Y(1)), stroke: 0.4pt + grid)
    }

    // baseline (chance diagonal for ROC / prevalence line for PR)
    line(..baseline.map(p => (X(p.at(0)), Y(p.at(1)))),
         stroke: (paint: faint, dash: "dashed", thickness: 0.9pt))

    // the classifier curve (focal garnet)
    line(..pts.map(p => (X(p.at(0)), Y(p.at(1)))), stroke: 2.0pt + garnet)

    // panel border (sharp corners)
    rect((X(0), Y(0)), (X(1), Y(1)), stroke: 1pt + axiscol, fill: none)

    // axis ticks + numeric labels (0, .5, 1)
    for k in (0, 2, 4) {
      let g = k / 4
      line((X(g), Y(0)), (X(g), Y(0) - 0.12), stroke: 0.9pt + axiscol)
      content((X(g), Y(0) - 0.26), text(fill: muted, size: 7pt)[#g], anchor: "north")
      line((X(0), Y(g)), (X(0) - 0.12, Y(g)), stroke: 0.9pt + axiscol)
      content((X(0) - 0.22, Y(g)), text(fill: muted, size: 7pt)[#g], anchor: "east")
    }

    // axis titles
    content((X(0.5), Y(0) - 0.62), text(fill: ink, size: 9pt)[#xlab], anchor: "north")
    content((X(0) - 0.78, Y(0.5)), angle: 90deg, text(fill: ink, size: 9pt)[#ylab], anchor: "south")

    // panel title
    content((X(0.5), Y(1) + 0.34), text(fill: ink, size: 10.5pt, weight: "bold")[#title], anchor: "south")

    // area readout chip inside the panel (low corner that the curve avoids)
    let cx = if title == [ROC curve] { X(0.66) } else { X(0.30) }
    let cy = if title == [ROC curve] { Y(0.20) } else { Y(0.20) }
    content((cx, cy),
      box(fill: white, inset: 4pt, stroke: 0.7pt + garnet)[
        #text(fill: garnet, size: 8.5pt, weight: "bold")[#arealab = #calc.round(areaval, digits: 2)]
      ])
  }

  // ── ROC panel (left) ────────────────────────────────────────────────────────
  panel(
    0, [ROC curve], roc,
    ((0, 0), (1, 1)),                       // chance diagonal
    roc,
    [false-positive rate #text(fill: faint, size: 7pt)[(FPR)]],
    [true-positive rate #text(fill: faint, size: 7pt)[(TPR)]],
    auc, [AUC],
  )

  // ── PR panel (right) ─────────────────────────────────────────────────────────
  let xoff = S + 2.0
  panel(
    xoff, [PR curve], pr,
    ((0, prevalence), (1, prevalence)),     // no-skill prevalence baseline
    pr,
    [recall],
    [precision],
    ap, [AP],
  )

  // ── annotate the two baselines & the "ideal corners" ──────────────────────────
  let Xr(u) = u * S
  let Xp(u) = xoff + u * S
  let Y(v) = v * S

  // ROC: chance label + ideal corner arrow
  content((Xr(0.62), Y(0.50)),
    text(fill: muted, size: 7pt, style: "italic")[chance], anchor: "west")
  content((Xr(0.075), Y(0.93)),
    text(fill: faint, size: 6.5pt, style: "italic")[ideal], anchor: "west")

  // PR: prevalence baseline label
  content((Xp(0.50), Y(prevalence) - 0.22),
    text(fill: muted, size: 7pt, style: "italic")[no-skill (prevalence #calc.round(prevalence, digits: 2))],
    anchor: "north")

  // ── shared caption strip beneath both panels ─────────────────────────────────
  content(
    ((Xr(0) + Xp(1)) / 2, Y(0) - 1.18),
    text(fill: muted, size: 8pt)[
      threshold $tau$ swept #sym.arrow.r each point is one operating point #h(0.6em)#sym.bullet#h(0.6em)
      garnet fill = area under the curve
    ],
    anchor: "north",
  )
})
