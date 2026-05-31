// Gaussian covariance contour ellipses — the geometry of a bivariate normal.
//   The density of  x ~ 𝒩(μ, Σ)  is constant on the ellipses  (x−μ)ᵀ Σ⁻¹ (x−μ) = c².
//   These iso-probability contours are CENTERED at the mean μ; their shape and tilt are
//   fixed entirely by the covariance Σ. Eigendecompose  Σ = U Λ Uᵀ  with eigenpairs
//   (λ₁,u₁),(λ₂,u₂): the ellipse axes point along the eigenvectors u_i and have
//   half-lengths  c·√λ_i. We draw the c = 1,2,3 Mahalanobis rings (≈ the 1σ/2σ/3σ
//   contours), mark μ, and draw the eigen-axis arrows scaled by √λ_i.
//   Reusable leaf for GMM components, LDA/QDA boundaries, and PCA. Standard
//   MML / ESL teaching figure, built from scratch in mlatlas's print-first style.
//   The eigendecomposition is computed here from Σ, not faked. No image was traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ─────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent — the principal (largest) eigen-axis
#let blue   = rgb("#466A9F")   // second eigen-axis
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let grid-c = rgb("#ECECEC")
#let fillc  = rgb("#73000A")   // ellipse fill (transparentized)

// ── the Gaussian: mean μ and covariance Σ (a correlated 2×2) ───────────────────
#let mux = 0.0
#let muy = 0.0
// Σ = [[s11, s12],[s12, s22]]  — positive correlation, anisotropic.
#let s11 = 2.4
#let s12 = 1.5
#let s22 = 1.6

// ── closed-form eigendecomposition of a symmetric 2×2 matrix ───────────────────
//   eigenvalues  λ = (tr ± √(tr² − 4det)) / 2 ;  eigenvectors from (Σ − λI)u = 0.
#let tr  = s11 + s22
#let det = s11 * s22 - s12 * s12
#let disc = calc.sqrt(tr * tr - 4 * det)
#let lam1 = (tr + disc) / 2     // larger eigenvalue  (major axis)
#let lam2 = (tr - disc) / 2     // smaller eigenvalue (minor axis)
// eigenvector for λ1: solve (s11 − λ1) ex + s12 ey = 0  →  (s12, λ1 − s11)
#let raw1x = s12
#let raw1y = lam1 - s11
#let nrm1  = calc.sqrt(raw1x * raw1x + raw1y * raw1y)
#let u1x   = raw1x / nrm1
#let u1y   = raw1y / nrm1
// u2 ⟂ u1
#let u2x = -u1y
#let u2y = u1x
// principal-axis tilt angle (of the major axis, for reporting)
#let ang  = calc.atan2(u1x, u1y)   // cetz atan2(x, y) returns an angle
#let sq1  = calc.sqrt(lam1)        // √λ1  — major semi-axis at c = 1
#let sq2  = calc.sqrt(lam2)        // √λ2  — minor semi-axis at c = 1

// ── world → canvas mapping (data coords centered on μ) ─────────────────────────
#let X0 = -6.4
#let X1 = 6.4
#let Y0 = -5.6
#let Y1 = 5.6
#let PW = 9.2
#let PH = 8.05
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── plot frame ───────────────────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)

  // light interior grid (every world unit), sharp, behind everything
  for gx in range(-6, 7) {
    if gx > -6 and gx < 7 {
      line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c)
    }
  }
  for gy in range(-5, 6) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c)
  }
  // central axes through the mean (slightly darker)
  line((sx(X0), sy(0)), (sx(X1), sy(0)), stroke: 0.6pt + rgb("#C7C7C7"))
  line((sx(0), sy(Y0)), (sx(0), sy(Y1)), stroke: 0.6pt + rgb("#C7C7C7"))

  // ── iso-probability ellipses at Mahalanobis radius c = 1,2,3 ─────────────────
  //   point on ring c:  μ + c·√λ1·cos t · u1 + c·√λ2·sin t · u2
  let n-seg = 96
  let rings = (
    (c: 3, dash: "dotted", sw: 0.8pt, fill: none),
    (c: 2, dash: "dashed", sw: 1.0pt, fill: fillc.transparentize(94%)),
    (c: 1, dash: none,     sw: 1.7pt, fill: fillc.transparentize(86%)),
  )
  for R in rings {
    let ring = range(n-seg + 1).map(i => {
      let t = i / n-seg * 2 * calc.pi
      let a = R.c * sq1 * calc.cos(t)
      let b = R.c * sq2 * calc.sin(t)
      let wx = mux + a * u1x + b * u2x
      let wy = muy + a * u1y + b * u2y
      (sx(wx), sy(wy))
    })
    line(..ring, close: true,
      stroke: (paint: garnet, thickness: R.sw, dash: R.dash),
      fill: R.fill)
  }

  // ── mean marker μ (cross with white halo), drawn under the eigen-arrows ──────
  let me = (sx(mux), sy(muy))
  let h = 0.20
  line((me.at(0) - h, me.at(1)), (me.at(0) + h, me.at(1)), stroke: 2.8pt + white)
  line((me.at(0), me.at(1) - h), (me.at(0), me.at(1) + h), stroke: 2.8pt + white)
  line((me.at(0) - h, me.at(1)), (me.at(0) + h, me.at(1)), stroke: 1.5pt + ink)
  line((me.at(0), me.at(1) - h), (me.at(0), me.at(1) + h), stroke: 1.5pt + ink)

  // ── eigen-axis arrows from the mean, length √λ_i (the 1σ semi-axes) ──────────
  // major axis (u1, garnet)
  let p1 = (sx(mux + sq1 * u1x), sy(muy + sq1 * u1y))
  line(me, p1, stroke: 2pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.9))
  // minor axis (u2, blue)
  let p2 = (sx(mux + sq2 * u2x), sy(muy + sq2 * u2y))
  line(me, p2, stroke: 2pt + blue, mark: (end: "stealth", fill: blue, scale: 0.9))

  // ── eigen-axis labels on small white plates ──────────────────────────────────
  let plate(pos, body, col) = {
    content(pos, anchor: "center", padding: 0.04, box(
      fill: white.transparentize(8%), inset: 1.6pt,
      text(size: 8pt, weight: "bold", fill: col, body),
    ))
  }
  // place labels just beyond each arrow tip, offset perpendicular for clarity
  plate((sx(mux + sq1 * u1x * 1.32 + 0.10), sy(muy + sq1 * u1y * 1.32 + 0.55)),
        $sqrt(lambda_1) thin bold(u)_1$, garnet)
  plate((sx(mux + sq2 * u2x * 1.55 - 0.65), sy(muy + sq2 * u2y * 1.55 + 0.10)),
        $sqrt(lambda_2) thin bold(u)_2$, blue)

  // ── mean label μ (cross itself drawn above, beneath the arrows) ──────────────
  content((me.at(0) - 0.30, me.at(1) - 0.38), anchor: "north-east",
    box(fill: white.transparentize(8%), inset: 1.4pt,
      text(size: 9pt, weight: "bold", fill: ink, $bold(mu)$)))

  // ── ring labels (c = 1,2,3): tag each ring along the −u2 (lower-right) flank ──
  //   parameter t chosen on the −u2 side so labels sit just outside each ring.
  for (c, t, lbl) in (
    (1, -1.05, $c = 1$),
    (2, -0.95, $c = 2$),
    (3, -0.88, $c = 3$),
  ) {
    let a = c * sq1 * calc.cos(t)
    let b = c * sq2 * calc.sin(t)
    let wx = mux + a * u1x + b * u2x
    let wy = muy + a * u1y + b * u2y
    content((sx(wx) + 0.34, sy(wy) - 0.18), anchor: "north-west",
      box(fill: white.transparentize(15%), inset: 1.2pt,
        text(size: 7pt, fill: muted, lbl)))
  }

  // ── axis ticks + labels ───────────────────────────────────────────────────────
  for gx in range(-6, 7) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    if calc.rem(gx, 2) == 0 {
      content((sx(gx), -0.34), text(size: 7pt, fill: muted)[#gx])
    }
  }
  for gy in range(-5, 6) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    if calc.rem(gy, 2) == 0 {
      content((-0.32, sy(gy)), text(size: 7pt, fill: muted)[#gy])
    }
  }
  content((PW / 2, -0.78), text(size: 9pt, fill: ink)[$x_1$])
  content((-0.92, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title + defining equation ─────────────────────────────────────────────────
  content((PW / 2, PH + 1.18),
    text(size: 11pt, weight: "bold", fill: ink)[Gaussian covariance contours])
  content((PW / 2, PH + 0.66),
    text(size: 8.5pt, fill: ink)[$(bold(x) - bold(mu))^top bold(Sigma)^(-1) (bold(x) - bold(mu)) = c^2$])
  content((PW / 2, PH + 0.26),
    text(size: 7.5pt, fill: muted)[iso-probability ellipses of $cal(N)(bold(mu), bold(Sigma))$])

  // ── side panel: Σ, its eigendecomposition, and the geometry key ───────────────
  let lx = PW + 0.62
  let ly = PH - 0.15

  // build the Σ matrix as a math string so the row-separator ';' is parsed in
  // math context (interpolating with '#' inside mat() would eat the ';').
  let r11 = calc.round(s11, digits: 1)
  let r12 = calc.round(s12, digits: 1)
  let r22 = calc.round(s22, digits: 1)
  let sigma-mat = eval(
    "bold(Sigma) = mat(" + str(r11) + ", " + str(r12) + "; "
      + str(r12) + ", " + str(r22) + ")",
    mode: "math",
  )
  content((lx, ly), anchor: "north-west",
    text(size: 8pt, fill: ink, sigma-mat))

  content((lx, ly - 1.35), anchor: "north-west",
    text(size: 8pt, fill: ink)[$bold(Sigma) = bold(U) bold(Lambda) bold(U)^top$])

  content((lx, ly - 2.0), anchor: "north-west",
    text(size: 7.5pt, fill: garnet)[$lambda_1 = #calc.round(lam1, digits: 2)$])
  content((lx, ly - 2.5), anchor: "north-west",
    text(size: 7.5pt, fill: blue)[$lambda_2 = #calc.round(lam2, digits: 2)$])

  content((lx, ly - 3.25), anchor: "north-west",
    text(size: 7pt, fill: muted)[semi-axes $= c sqrt(lambda_i)$])
  content((lx, ly - 3.72), anchor: "north-west",
    text(size: 7pt, fill: muted)[directions $= bold(u)_i$])

  // legend rows
  let leg(yy, dash, sw, lbl) = {
    line((lx, yy), (lx + 0.7, yy), stroke: (paint: garnet, thickness: sw, dash: dash))
    content((lx + 0.86, yy), anchor: "west", text(size: 7pt, fill: muted)[#lbl])
  }
  leg(ly - 4.55, none,     1.7pt, $c = 1 thin (approx 39%)$)
  leg(ly - 5.02, "dashed", 1.0pt, $c = 2 thin (approx 86%)$)
  leg(ly - 5.49, "dotted", 0.8pt, $c = 3 thin (approx 99%)$)
})
