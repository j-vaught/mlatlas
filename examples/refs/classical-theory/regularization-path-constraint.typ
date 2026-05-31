// mlatlas · Regularization paths and the constraint geometry of ℓ1 / ℓ2 penalties.
//  (a) The LASSO coefficient path:  β̂(λ) = argmin ‖y − Xβ‖² + λ‖β‖₁, plotted as
//      each coefficient shrinks toward 0 as the penalty λ grows. ℓ1 drives
//      coefficients to EXACTLY zero one after another (a sparse path) — here the
//      paths are a real coordinate-descent lasso fit on a synthetic design.
//  (b) The constraint view (ESL Fig 3.11 / ISLR §6.2 / MML): the RSS is an
//      elliptical bowl centred at the OLS solution β̂; the budget ‖β‖₁ ≤ t (the
//      ℓ1 DIAMOND) and ‖β‖₂ ≤ t (the ℓ2 CIRCLE) are constraint regions. The
//      penalised optimum is where the lowest RSS contour first TOUCHES the
//      region. The diamond's corners on the axes make ℓ1 hit them → sparsity;
//      the circle has no corners → ℓ2 only shrinks.
//  Print-first house style: light fills, dark ink, sharp corners, stealth arrows,
//  garnet as the sparse accent. Built from first principles; no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let grid-c = rgb("#ECECEC")
#let cont-c = rgb("#C7C7C7")
#let garnet = rgb("#73000A")   // ℓ1 / lasso — the sparse focal accent
#let blue   = rgb("#466A9F")   // ℓ2 / ridge
#let green  = rgb("#65780B")
#let redx   = rgb("#CC2E40")
#let brown  = rgb("#A49137")
#let beige  = rgb("#FFF2E3")

// ── LASSO coefficient path (real coordinate-descent fit, hard-coded) ────────────
//   x-axis is log10(λ); each tuple is one coefficient's value along the grid.
#let loglam = (-2.300, -2.226, -2.077, -2.003, -1.854, -1.779, -1.631, -1.556, -1.408, -1.259, -1.185, -1.036, -0.962, -0.813, -0.738, -0.590, -0.515, -0.367, -0.218, -0.144, 0.005, 0.079, 0.228, 0.303, 0.451, 0.600)
#let paths = (
  (col: garnet, lbl: $beta_1$, v: (+2.616, +2.615, +2.614, +2.613, +2.610, +2.608, +2.603, +2.599, +2.591, +2.579, +2.572, +2.552, +2.540, +2.507, +2.486, +2.431, +2.396, +2.319, +2.225, +2.165, +2.008, +1.907, +1.624, +1.424, +0.886, +0.307)),
  (col: blue,   lbl: $beta_2$, v: (-1.787, -1.786, -1.784, -1.783, -1.780, -1.778, -1.772, -1.769, -1.760, -1.747, -1.739, -1.718, -1.705, -1.670, -1.648, -1.589, -1.552, -1.470, -1.371, -1.307, -1.141, -1.034, -0.742, -0.543, -0.005, +0.000)),
  (col: green,  lbl: $beta_3$, v: (+1.036, +1.035, +1.034, +1.033, +1.032, +1.030, +1.027, +1.025, +1.020, +1.013, +1.009, +0.997, +0.989, +0.969, +0.957, +0.923, +0.902, +0.842, +0.753, +0.696, +0.547, +0.452, +0.223, +0.090, +0.000, +0.000)),
  (col: brown,  lbl: $beta_4$, v: (+0.636, +0.636, +0.635, +0.634, +0.633, +0.632, +0.629, +0.627, +0.623, +0.617, +0.613, +0.603, +0.597, +0.580, +0.569, +0.541, +0.523, +0.470, +0.391, +0.340, +0.207, +0.121, +0.000, +0.000, +0.000, +0.000)),
  (col: redx,   lbl: $beta_5$, v: (-0.269, -0.268, -0.266, -0.265, -0.262, -0.260, -0.255, -0.251, -0.243, -0.231, -0.223, -0.202, -0.189, -0.155, -0.133, -0.076, -0.040, +0.000, +0.000, +0.000, +0.000, +0.000, +0.000, +0.000, +0.000, +0.000)),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL (a) — coefficient paths vs log λ
  // ══════════════════════════════════════════════════════════════════════════
  // data → canvas mapping for panel (a)
  let aPW = 7.6
  let aPH = 6.0
  let aLX0 = -2.4    // log λ at left
  let aLX1 = 0.7     // log λ at right
  let aY0  = -2.1    // coeff min
  let aY1  = 2.9     // coeff max
  let ax(l) = (l - aLX0) / (aLX1 - aLX0) * aPW
  let ay(b) = (b - aY0) / (aY1 - aY0) * aPH

  // frame + faint grid
  rect((0, 0), (aPW, aPH), fill: white, stroke: 1pt + ink)
  for gl in (-2, -1, 0) {
    line((ax(gl), 0), (ax(gl), aPH), stroke: 0.5pt + grid-c)
  }
  for gb in (-2, -1, 0, 1, 2) {
    line((0, ay(gb)), (aPW, ay(gb)), stroke: 0.5pt + grid-c)
  }
  // β = 0 reference line (where lasso sends coefficients)
  line((0, ay(0)), (aPW, ay(0)), stroke: (paint: faint, thickness: 0.7pt, dash: "dashed"))

  // the coefficient paths
  for pth in paths {
    let pts = range(loglam.len()).map(i => (ax(loglam.at(i)), ay(pth.v.at(i))))
    line(..pts, stroke: (paint: pth.col, thickness: 1.7pt))
    // mark the kink where the coefficient first reaches exactly 0 (sparsity event)
    for i in range(1, pth.v.len()) {
      if pth.v.at(i) == 0 and pth.v.at(i - 1) != 0 {
        circle((ax(loglam.at(i)), ay(0)), radius: 0.075, fill: pth.col, stroke: 0.5pt + white)
      }
    }
    // inline label at the left end (large coefficients, no penalty)
    content((ax(loglam.at(0)) - 0.22, ay(pth.v.at(0))), anchor: "east",
      box(fill: white.transparentize(8%), inset: 1pt,
        text(size: 8.5pt, fill: pth.col, weight: "bold", pth.lbl)))
  }

  // axis ticks + labels
  for gl in (-2, -1, 0) {
    line((ax(gl), 0), (ax(gl), -0.12), stroke: 0.8pt + ink)
    content((ax(gl), -0.34), text(size: 7pt, fill: muted)[$#gl$])
  }
  for gb in (-2, -1, 0, 1, 2) {
    line((0, ay(gb)), (-0.12, ay(gb)), stroke: 0.8pt + ink)
    content((-0.30, ay(gb)), anchor: "east", text(size: 7pt, fill: muted)[$#gb$])
  }
  content((aPW / 2, -0.76),
    text(size: 9pt, fill: ink)[$log_10 lambda$ #h(0.35em) #text(size: 7pt, fill: faint)[(less penalty #sym.arrow.l #h(0.2em) #sym.arrow.r more)]])
  content((-0.98, aPH / 2), angle: 90deg, anchor: "south",
    text(size: 9pt, fill: ink)[coefficient $hat(beta)_j (lambda)$])

  // direction-of-shrinkage annotation
  line((ax(0.05), ay(2.55)), (ax(0.55), ay(2.55)),
    stroke: 1pt + muted, mark: (end: "stealth", scale: 0.6))
  content((ax(0.55), ay(2.55) + 0.26), anchor: "south-east",
    text(size: 6.8pt, fill: muted, style: "italic")[stronger penalty])
  content((ax(0.05), ay(0.30)), anchor: "west",
    text(size: 6.8pt, fill: garnet, style: "italic")[all $hat(beta)_j #sym.arrow.r 0$])

  // panel title + objective
  content((aPW / 2, aPH + 1.02),
    text(size: 10.5pt, weight: "bold", fill: ink)[(a) Lasso regularization path])
  content((aPW / 2, aPH + 0.54),
    text(size: 8pt, fill: muted)[$hat(bold(beta))(lambda) = arg min_(bold(beta)) thin norm(bold(y) - bold(X) bold(beta))_2^2 + lambda norm(bold(beta))_1$])
  content((aPW / 2, aPH + 0.16),
    text(size: 7pt, fill: garnet)[$ell_1$ sends coefficients to #emph[exactly] zero (sparse) #sym.dot.c marks: entry leaves the model])

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL (b) — constraint geometry: ℓ1 diamond vs ℓ2 circle vs RSS contours
  // ══════════════════════════════════════════════════════════════════════════
  // offset to the right of panel (a)
  let OX = aPW + 3.0
  let bPW = 7.4
  let bPH = 6.0
  // β-space coordinate frame (β1 horizontal, β2 vertical)
  let bX0 = -1.7
  let bX1 = 3.95
  let bY0 = -1.55
  let bY1 = 3.35
  let bx(x) = OX + (x - bX0) / (bX1 - bX0) * bPW
  let by(y) = (y - bY0) / (bY1 - bY0) * bPH

  // frame
  rect((bx(bX0), by(bY0)), (bx(bX1), by(bY1)), fill: white, stroke: 1pt + ink)

  // OLS solution β̂ (centre of the RSS ellipses) and the anisotropic RSS quad form.
  //  β̂ and the ellipse shape are chosen (verified) so the lowest RSS contour is
  //  TANGENT to the ℓ1 diamond exactly at its β₁-axis corner (→ β₂ = 0, sparse)
  //  and to the ℓ2 circle at an interior-quadrant point (→ both shrunk, nonzero).
  let bhx = 2.10
  let bhy = 1.20
  // RSS contour:  (β−β̂)ᵀ A (β−β̂) = c,  A = R diag(a1,a2) Rᵀ (tilted ellipse)
  let a1 = 1.0       // curvature along principal axis 1
  let a2 = 0.42      // along axis 2
  let th = 35deg     // tilt of the ellipse
  let ct = calc.cos(th)
  let st = calc.sin(th)
  // draw a few RSS level sets (kept inside the frame)
  let n-seg = 96
  let levels = (0.18, 0.65, 1.30, 2.02)
  for (k, c) in levels.enumerate() {
    let ring = range(n-seg + 1).map(i => {
      let t = i / n-seg * 2 * calc.pi
      // unit circle scaled by 1/√a along each principal axis, then rotated
      let u = calc.sqrt(c / a1) * calc.cos(t)
      let w = calc.sqrt(c / a2) * calc.sin(t)
      let dx = ct * u - st * w
      let dy = st * u + ct * w
      (bx(bhx + dx), by(bhy + dy))
    })
    let sw = if k == 0 { 1.1pt } else { 0.8pt }
    line(..ring, close: true, stroke: sw + cont-c)
  }
  // RSS contour label
  content((bx(3.78), by(3.05)), anchor: "north-east",
    box(fill: white.transparentize(20%), inset: 1pt,
      text(size: 6.8pt, fill: faint, style: "italic")[RSS$(bold(beta))$ contours]))

  // axes through the origin (β-space)
  line((bx(bX0), by(0)), (bx(bX1), by(0)), stroke: 0.9pt + rgb("#9a9a9a"),
    mark: (end: "stealth", scale: 0.5))
  line((bx(0), by(bY0)), (bx(0), by(bY1)), stroke: 0.9pt + rgb("#9a9a9a"),
    mark: (end: "stealth", scale: 0.5))
  content((bx(bX1) - 0.05, by(0) - 0.28), anchor: "north-east",
    text(size: 8.5pt, fill: ink)[$beta_1$])
  content((bx(0) - 0.22, by(bY1) - 0.05), anchor: "north-east",
    text(size: 8.5pt, fill: ink)[$beta_2$])

  // ── constraint budget t (same ℓ-ball "radius" for both) ─────────────────────
  let t = 1.25
  // ℓ2 circle  ‖β‖₂ ≤ t
  let circ = range(n-seg + 1).map(i => {
    let a = i / n-seg * 2 * calc.pi
    (bx(t * calc.cos(a)), by(t * calc.sin(a)))
  })
  line(..circ, close: true, stroke: 1.6pt + blue, fill: blue.transparentize(90%))
  // ℓ1 diamond  ‖β‖₁ ≤ t  (corners on the axes)
  line(
    (bx(t), by(0)), (bx(0), by(t)), (bx(-t), by(0)), (bx(0), by(-t)),
    close: true, stroke: 1.8pt + garnet, fill: garnet.transparentize(91%),
  )

  // ── tangency / constrained solutions ─────────────────────────────────────────
  // ℓ1 lasso solution: the ellipse touches the diamond at its β₁-axis CORNER
  //   → β₂ = 0 exactly (sparse). Solved so the contour is tangent at (t, 0).
  let lasso = (t, 0.0)
  // ℓ2 ridge solution: ellipse touches the circle on its boundary (no corner)
  //   → both coefficients nonzero, just shrunk. Verified tangent point.
  let ridge = (1.061, 0.66)

  // RSS contour passing through a constrained solution (= the tangent level set)
  let level-through(px, py) = {
    let dx = px - bhx
    let dy = py - bhy
    let u = ct * dx + st * dy
    let w = -st * dx + ct * dy
    a1 * u * u + a2 * w * w
  }
  let tangent-ring(c, paint) = {
    let ring = range(n-seg + 1).map(i => {
      let tt = i / n-seg * 2 * calc.pi
      let u = calc.sqrt(c / a1) * calc.cos(tt)
      let w = calc.sqrt(c / a2) * calc.sin(tt)
      let dx = ct * u - st * w
      let dy = st * u + ct * w
      (bx(bhx + dx), by(bhy + dy))
    })
    line(..ring, close: true, stroke: (paint: paint, thickness: 1.0pt, dash: "dashed"))
  }
  // ridge tangent contour (blue) then lasso tangent contour (garnet, on top)
  tangent-ring(level-through(ridge.at(0), ridge.at(1)), blue)
  tangent-ring(level-through(lasso.at(0), lasso.at(1)), garnet)

  // OLS solution β̂ (cross with white halo)
  let me = (bx(bhx), by(bhy))
  let h = 0.16
  line((me.at(0) - h, me.at(1)), (me.at(0) + h, me.at(1)), stroke: 3pt + white)
  line((me.at(0), me.at(1) - h), (me.at(0), me.at(1) + h), stroke: 3pt + white)
  line((me.at(0) - h, me.at(1)), (me.at(0) + h, me.at(1)), stroke: 1.6pt + ink)
  line((me.at(0), me.at(1) - h), (me.at(0), me.at(1) + h), stroke: 1.6pt + ink)
  content((me.at(0) + 0.20, me.at(1) + 0.18), anchor: "south-west",
    box(fill: white.transparentize(10%), inset: 1.4pt,
      text(size: 9pt, weight: "bold", fill: ink)[$hat(bold(beta))^("OLS")$]))

  // lasso solution dot (garnet, on the diamond corner → β₂ = 0)
  circle((bx(lasso.at(0)), by(lasso.at(1))), radius: 0.11, fill: garnet, stroke: 0.6pt + white)
  content((bx(lasso.at(0)) + 0.16, by(lasso.at(1)) - 0.14), anchor: "north-west",
    box(fill: white.transparentize(12%), inset: 1.2pt,
      text(size: 8pt, weight: "bold", fill: garnet)[$hat(bold(beta))^("lasso")$]))

  // ridge solution dot (blue, on the circle → both nonzero)
  circle((bx(ridge.at(0)), by(ridge.at(1))), radius: 0.10, fill: blue, stroke: 0.6pt + white)
  content((bx(ridge.at(0)) - 0.14, by(ridge.at(1)) + 0.16), anchor: "south-east",
    box(fill: white.transparentize(12%), inset: 1.2pt,
      text(size: 8pt, weight: "bold", fill: blue)[$hat(bold(beta))^("ridge")$]))

  // constraint-region labels
  content((bx(-t) + 0.30, by(0) + 0.32), anchor: "south-east",
    text(size: 8pt, weight: "bold", fill: garnet)[$norm(bold(beta))_1 <= t$])
  content((bx(0) - 0.18, by(-t) - 0.04), anchor: "north-east",
    text(size: 8pt, weight: "bold", fill: blue)[$norm(bold(beta))_2 <= t$])

  // callout: the diamond corner forces β₂ = 0
  content((bx(lasso.at(0)) + 0.05, by(lasso.at(1)) - 0.66), anchor: "north",
    text(size: 6.6pt, fill: garnet, style: "italic")[corner #sym.arrow.r $beta_2 = 0$])

  // panel title + caption
  content((bx((bX0 + bX1) / 2), bPH + 1.02),
    text(size: 10.5pt, weight: "bold", fill: ink)[(b) Constraint geometry])
  content((bx((bX0 + bX1) / 2), bPH + 0.54),
    text(size: 8pt, fill: muted)[lowest RSS contour first touches the budget region])
  content((bx((bX0 + bX1) / 2), bPH + 0.16),
    text(size: 7pt, fill: muted)[$ell_1$ diamond has corners on the axes; $ell_2$ circle is smooth])

  // ── shared legend strip under panel (b) ─────────────────────────────────────
  let ly = -1.42
  let lx = OX + 0.1
  // ℓ1
  line((lx, ly), (lx + 0.5, ly), stroke: 1.8pt + garnet)
  content((lx + 0.62, ly), anchor: "west",
    text(size: 7.5pt, fill: muted)[$ell_1$ (lasso) #sym.arrow.r sparse])
  // ℓ2
  line((lx + 3.0, ly), (lx + 3.5, ly), stroke: 1.6pt + blue)
  content((lx + 3.62, ly), anchor: "west",
    text(size: 7.5pt, fill: muted)[$ell_2$ (ridge) #sym.arrow.r shrink])
})
