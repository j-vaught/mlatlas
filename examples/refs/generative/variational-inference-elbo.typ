// Variational inference / ELBO — the geometry of approximating an intractable posterior.
//   The true posterior  p(z|x) = p(x,z) / p(x)  is intractable because the evidence
//   p(x) = ∫ p(x,z) dz cannot be computed. Variational inference picks the member q*
//   of a tractable family  𝒬  (e.g. mean-field / Gaussian) that is CLOSEST in KL to the
//   posterior. The log-evidence decomposes exactly as
//        log p(x) = ELBO(q) + KL( q(z) ‖ p(z|x) ),     KL ≥ 0,
//   so for any fixed x the ELBO is a LOWER BOUND on log p(x), and the slack is precisely
//   the KL gap. Maximizing the ELBO over q ∈ 𝒬  ⇔  minimizing that KL gap, pulling q*
//   as close to p(z|x) as the family allows. We draw the family 𝒬 as a region, the
//   true posterior as a region outside it, the chosen q*, the residual KL gap, and the
//   exact log p(x) = ELBO + KL decomposition as a stacked bar.
//   Built from textbook knowledge (Bishop PRML §10, Murphy book2 §10, Barber BRML) in
//   mlatlas's print-first house style. No image was traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ─────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent — the true posterior / the KL gap
#let blue   = rgb("#466A9F")   // the variational approximation q*
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let grid-c = rgb("#ECECEC")
#let beige  = rgb("#FFF2E3")

// ── a smooth closed blob through control points (Catmull-Rom → cetz beziers) ───
// Returns a list of (point, control-in, control-out) usable with hobby-free beziers.
#let blob(cx, cy, pts) = {
  // pts: list of (angle_frac, radius). Build world points around (cx,cy).
  let n = pts.len()
  let P = pts.map(p => {
    let t = p.at(0) * 2 * calc.pi
    (cx + p.at(1) * calc.cos(t), cy + p.at(1) * calc.sin(t))
  })
  P
}

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ===========================================================================
  //  LEFT PANEL — the space of distributions, with the approximating family 𝒬
  // ===========================================================================

  // background card
  let X0 = 0
  let X1 = 8.6
  let Y0 = 0
  let Y1 = 7.4
  rect((X0, Y0), (X1, Y1), fill: white, stroke: 0.8pt + faint)

  // faint label for the ambient space (all distributions over z) — bottom-left corner
  content((X0 + 0.20, Y0 + 0.22), anchor: "south-west",
    text(size: 7.5pt, fill: faint, style: "italic")[space of distributions over $bold(z)$])

  // ── the tractable variational family 𝒬 (a broad rounded region) ────────────
  // drawn as a smooth closed curve via a polygon of many points, sharp-free fill
  let fam = range(73).map(i => {
    let t = i / 72 * 2 * calc.pi
    // gentle lobed boundary
    let r = 2.95 + 0.30 * calc.cos(3 * t) + 0.18 * calc.sin(2 * t)
    (2.95 + r * 0.92 * calc.cos(t), 3.45 + r * 0.74 * calc.sin(t))
  })
  line(..fam, close: true,
    fill: blue.transparentize(92%),
    stroke: (paint: blue, thickness: 1.1pt, dash: "dashed"))
  content((1.15, 5.55), anchor: "west",
    box(fill: white.transparentize(12%), inset: 1.6pt,
      text(size: 11pt, weight: "bold", fill: blue)[$cal(Q)$]))
  content((1.15, 5.05), anchor: "west",
    box(fill: white.transparentize(20%), inset: 1.2pt,
      text(size: 7pt, fill: muted)[tractable family]))

  // ── the true posterior p(z|x): a region OUTSIDE 𝒬 (intractable) ────────────
  let postc = (6.65, 5.55)
  let post = range(61).map(i => {
    let t = i / 60 * 2 * calc.pi
    let r = 1.05 + 0.20 * calc.cos(2 * t + 0.7) + 0.12 * calc.sin(3 * t)
    (postc.at(0) + r * 1.18 * calc.cos(t), postc.at(1) + r * 0.92 * calc.sin(t))
  })
  line(..post, close: true,
    fill: garnet.transparentize(86%),
    stroke: (paint: garnet, thickness: 1.6pt))
  // a small × at the posterior "center" (the target)
  let h = 0.16
  line((postc.at(0) - h, postc.at(1) - h), (postc.at(0) + h, postc.at(1) + h), stroke: 1.6pt + garnet)
  line((postc.at(0) - h, postc.at(1) + h), (postc.at(0) + h, postc.at(1) - h), stroke: 1.6pt + garnet)
  content((postc.at(0) + 0.10, postc.at(1) + 1.55), anchor: "south",
    box(fill: white.transparentize(8%), inset: 1.6pt,
      text(size: 9.5pt, weight: "bold", fill: garnet)[$p(bold(z) thin | thin bold(x))$]))
  content((postc.at(0) + 0.10, postc.at(1) + 1.18), anchor: "south",
    box(fill: white.transparentize(20%), inset: 1.2pt,
      text(size: 7pt, fill: muted)[true posterior  (intractable)]))

  // ── the chosen approximation q* ∈ 𝒬 (closest point in family to posterior) ─
  // sits inside 𝒬, on the boundary nearest the posterior
  let qc = (4.95, 4.55)
  let qstar = range(49).map(i => {
    let t = i / 48 * 2 * calc.pi
    let r = 0.74 + 0.10 * calc.cos(2 * t)
    (qc.at(0) + r * 1.05 * calc.cos(t), qc.at(1) + r * 0.95 * calc.sin(t))
  })
  line(..qstar, close: true,
    fill: blue.transparentize(72%),
    stroke: (paint: blue, thickness: 1.6pt))
  let h2 = 0.14
  line((qc.at(0) - h2, qc.at(1)), (qc.at(0) + h2, qc.at(1)), stroke: 1.6pt + blue)
  line((qc.at(0), qc.at(1) - h2), (qc.at(0), qc.at(1) + h2), stroke: 1.6pt + blue)
  content((qc.at(0) - 0.95, qc.at(1) - 0.55), anchor: "north-east",
    box(fill: white.transparentize(8%), inset: 1.6pt,
      text(size: 9.5pt, weight: "bold", fill: blue)[$q^*_phi (bold(z))$]))
  content((qc.at(0) - 0.95, qc.at(1) - 0.92), anchor: "north-east",
    box(fill: white.transparentize(20%), inset: 1.2pt,
      text(size: 7pt, fill: muted)[best in $cal(Q)$])  )

  // ── the KL gap: double-headed arrow between q* and the posterior ────────────
  // shorten endpoints so the arrow sits in the gap, not inside the blobs
  let ax = (qc.at(0) + 0.78, qc.at(1) + 0.46)
  let bx = (postc.at(0) - 1.02, postc.at(1) - 0.55)
  line(ax, bx,
    stroke: (paint: garnet, thickness: 1.6pt),
    mark: (start: "stealth", end: "stealth", fill: garnet, scale: 0.85))
  // KL label on a plate at the arrow midpoint
  let mx = ((ax.at(0) + bx.at(0)) / 2, (ax.at(1) + bx.at(1)) / 2)
  content((mx.at(0) + 0.05, mx.at(1) + 0.40), anchor: "south",
    box(fill: beige.transparentize(6%), inset: (x: 3pt, y: 2pt), stroke: 0.7pt + garnet,
      text(size: 8pt, weight: "bold", fill: garnet)[$"KL"(q^*_phi bar.v.double p)$]))

  // ── optimization sweep: faded q's flowing toward q* (VI minimizes the gap) ──
  for (i, c) in ((2.35, 2.30), (3.10, 3.55), (3.85, 4.10)).enumerate() {
    let rr = 0.50 - i * 0.04
    let qi = range(33).map(j => {
      let t = j / 32 * 2 * calc.pi
      (c.at(0) + rr * 1.05 * calc.cos(t), c.at(1) + rr * 0.95 * calc.sin(t))
    })
    line(..qi, close: true, fill: blue.transparentize(94%),
      stroke: (paint: faint, thickness: 0.7pt, dash: "dotted"))
  }
  line((3.30, 3.30), (4.55, 4.25),
    stroke: (paint: blue, thickness: 1.0pt, dash: "dashed"),
    mark: (end: "stealth", fill: blue, scale: 0.7))
  content((2.55, 2.95), anchor: "north",
    text(size: 6.5pt, fill: faint, style: "italic")[maximize ELBO\ over $q in cal(Q)$])

  // panel title
  content((X1 / 2, Y1 + 0.62),
    text(size: 11pt, weight: "bold", fill: ink)[Variational inference: project $p(bold(z) | bold(x))$ onto $cal(Q)$])

  // ===========================================================================
  //  RIGHT PANEL — the exact decomposition  log p(x) = ELBO + KL  (stacked bar)
  // ===========================================================================
  let bx0 = X1 + 1.55       // bar left edge
  let bw  = 1.35            // bar width
  let baseY = 0.55          // bar bottom
  // heights (in cm) — ELBO is the bound, KL is the slack on top
  let hE = 4.05            // ELBO height
  let hK = 1.55            // KL gap height
  let topY = baseY + hE + hK

  // axis line for log p(x)
  line((bx0 - 0.55, baseY), (bx0 - 0.55, topY), stroke: 1.0pt + ink,
    mark: (end: "stealth", fill: ink, scale: 0.8))
  content((bx0 - 0.55, topY + 0.30), anchor: "south",
    text(size: 8.5pt, fill: ink)[$log p(bold(x))$])
  content((bx0 - 0.55, baseY - 0.02), anchor: "north-east", text(size: 7pt, fill: muted)[ ])

  // ELBO segment (blue) — the lower bound
  rect((bx0, baseY), (bx0 + bw, baseY + hE),
    fill: blue.transparentize(80%), stroke: 1.2pt + blue)
  content((bx0 + bw / 2, baseY + hE / 2), text(size: 9pt, weight: "bold", fill: blue)[ELBO])
  content((bx0 + bw / 2, baseY + hE / 2 - 0.42),
    text(size: 7pt, fill: muted)[$cal(L)(phi)$])

  // KL segment (garnet) — the slack / gap, stacked above
  rect((bx0, baseY + hE), (bx0 + bw, topY),
    fill: garnet.transparentize(86%), stroke: 1.2pt + garnet)
  content((bx0 + bw / 2, baseY + hE + hK / 2), text(size: 8pt, weight: "bold", fill: garnet)[KL])
  content((bx0 + bw / 2, baseY + hE + hK / 2 - 0.36),
    text(size: 6.5pt, fill: garnet)[gap $gt.eq 0$])

  // total brace for log p(x) (the fixed evidence)
  line((bx0 + bw + 0.18, baseY), (bx0 + bw + 0.18, topY), stroke: 0.9pt + muted)
  line((bx0 + bw + 0.18, baseY), (bx0 + bw + 0.30, baseY), stroke: 0.9pt + muted)
  line((bx0 + bw + 0.18, topY), (bx0 + bw + 0.30, topY), stroke: 0.9pt + muted)
  content((bx0 + bw + 0.42, (baseY + topY) / 2), anchor: "west",
    text(size: 7pt, fill: muted)[fixed\ (data)])

  // raising-the-bound arrow: maximizing the ELBO pushes the ELBO/KL boundary UP,
  // shrinking the KL gap. Drawn just inside the ELBO column near the interface.
  line((bx0 + bw - 0.30, baseY + hE - 0.62), (bx0 + bw - 0.30, baseY + hE - 0.02),
    stroke: (paint: garnet, thickness: 1.3pt),
    mark: (end: "stealth", fill: garnet, scale: 0.8))

  // panel title
  content((bx0 + bw / 2, topY + 1.05),
    text(size: 11pt, weight: "bold", fill: ink)[Evidence decomposition])

  // ===========================================================================
  //  BOTTOM STRIP — the governing equations
  // ===========================================================================
  let eqY = -1.05
  let cx = (X1 + bx0 + bw) / 2 - 0.4
  content((cx, eqY), anchor: "center",
    text(size: 10pt, fill: ink)[
      $underbrace(log p(bold(x)), "log-evidence (fixed)")
       = underbrace(cal(L)(phi), "ELBO")
       + underbrace("KL"(q_phi (bold(z)) bar.v.double p(bold(z) | bold(x))), gt.eq 0)$
    ])
  content((cx, eqY - 1.30), anchor: "center",
    text(size: 9pt, fill: muted)[
      $cal(L)(phi) = EE_(q_phi) [log p(bold(x), bold(z))] - EE_(q_phi)[log q_phi (bold(z))]
       = EE_(q_phi)[log p(bold(x), bold(z))] + cal(H)[q_phi]$
    ])
  content((cx, eqY - 2.45), anchor: "center",
    text(size: 8.5pt, fill: garnet)[
      $arg max_(q in cal(Q)) thick cal(L)(phi) thick <==> thick arg min_(q in cal(Q)) thick "KL"(q bar.v.double p(bold(z) | bold(x)))$
    ])
})
