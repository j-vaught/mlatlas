// Gaussian Mixture Model — EM responsibilities as soft cluster colouring.
//   p(x) = Σ_k π_k 𝒩(x | μ_k, Σ_k)
// Each datum is shaded by its posterior responsibility  r_{nk} = π_k 𝒩(x_n|μ_k,Σ_k) / Σ_j (...)
// — a convex blend of the three component colours, so points on a boundary appear mixed.
// One covariance ellipse per Gaussian (eigen-axis scaled, drawn at 1σ and 2σ) is centred on
// its mean μ_k, which is marked with a cross. Standard PRML/Murphy/ESL teaching figure,
// built from scratch in mlatlas's print-first house style. No image was traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── component colours (garnet accent + brand blue + dark-green) ──────────────
#let c0 = rgb("#73000A") // garnet  — component 1 (focal accent)
#let c1 = rgb("#466A9F") // blue    — component 2
#let c2 = rgb("#65780B") // green   — component 3
#let ink   = rgb("#222222")
#let muted = rgb("#5C5C5C")
#let grid-c = rgb("#ECECEC")

// data world → canvas: x∈[0,7], y∈[1,9] mapped onto a square-ish plot box.
#let X0 = -0.4
#let X1 = 7.4
#let Y0 = 0.9
#let Y1 = 9.1
#let PW = 8.4   // plot width  (cm)
#let PH = 7.6   // plot height (cm)
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH

// linear blend of the three component colours by responsibility (r0,r1,r2 sum→1)
#let blend(r0, r1, r2) = color.mix(
  (c0, r0 * 100%), (c1, r1 * 100%), (c2, r2 * 100%), space: rgb,
)

// ── the data: (x, y, r0, r1, r2)  responsibilities from one EM E-step ────────
#let pts = (
  (1.757, 5.835, 1.000, 0.000, 0.000), (1.786, 5.314, 1.000, 0.000, 0.000),
  (1.118, 5.120, 1.000, 0.000, 0.000), (3.055, 6.283, 1.000, 0.000, 0.000),
  (2.984, 6.143, 1.000, 0.000, 0.000), (2.375, 5.865, 1.000, 0.000, 0.000),
  (0.419, 5.536, 1.000, 0.000, 0.000), (2.480, 6.108, 1.000, 0.000, 0.000),
  (0.395, 3.854, 0.996, 0.000, 0.004), (1.156, 4.971, 1.000, 0.000, 0.000),
  (2.290, 5.683, 1.000, 0.000, 0.000), (2.494, 5.379, 1.000, 0.000, 0.000),
  (2.293, 5.967, 1.000, 0.000, 0.000), (1.373, 6.461, 1.000, 0.000, 0.000),
  (2.528, 6.575, 1.000, 0.000, 0.000), (1.412, 4.895, 1.000, 0.000, 0.000),
  (1.674, 5.405, 1.000, 0.000, 0.000), (2.600, 5.993, 1.000, 0.000, 0.000),
  (1.576, 4.819, 1.000, 0.000, 0.000), (1.506, 6.193, 1.000, 0.000, 0.000),
  (1.234, 5.459, 1.000, 0.000, 0.000), (2.405, 4.799, 0.998, 0.000, 0.002),
  (5.436, 7.367, 0.003, 0.997, 0.000), (3.906, 7.377, 0.218, 0.782, 0.000),
  (5.321, 5.841, 0.001, 0.999, 0.000), (5.769, 6.051, 0.000, 1.000, 0.000),
  (4.314, 7.920, 0.017, 0.983, 0.000), (5.896, 6.715, 0.000, 1.000, 0.000),
  (6.468, 5.802, 0.000, 1.000, 0.000), (5.488, 5.337, 0.000, 1.000, 0.000),
  (5.856, 5.560, 0.000, 1.000, 0.000), (5.064, 5.710, 0.003, 0.997, 0.000),
  (4.682, 6.582, 0.031, 0.969, 0.000), (6.356, 4.068, 0.000, 0.751, 0.249),
  (4.319, 7.467, 0.044, 0.956, 0.000), (6.470, 5.965, 0.000, 1.000, 0.000),
  (3.991, 5.632, 0.887, 0.113, 0.000), (5.665, 5.622, 0.000, 1.000, 0.000),
  (4.570, 7.825, 0.012, 0.988, 0.000), (6.217, 5.851, 0.000, 1.000, 0.000),
  (5.582, 6.582, 0.001, 0.999, 0.000), (6.582, 5.905, 0.000, 1.000, 0.000),
  (5.785, 6.503, 0.000, 1.000, 0.000), (4.237, 8.329, 0.007, 0.993, 0.000),
  (5.289, 3.036, 0.000, 0.000, 1.000), (1.949, 2.005, 0.000, 0.000, 1.000),
  (5.160, 1.469, 0.000, 0.000, 1.000), (3.990, 3.262, 0.000, 0.000, 1.000),
  (2.705, 3.556, 0.013, 0.000, 0.987), (4.829, 2.549, 0.000, 0.000, 1.000),
  (4.570, 3.061, 0.000, 0.000, 1.000), (4.337, 3.372, 0.000, 0.000, 1.000),
  (3.446, 2.266, 0.000, 0.000, 1.000), (5.388, 2.709, 0.000, 0.000, 1.000),
  (3.196, 3.152, 0.000, 0.000, 1.000), (5.871, 2.433, 0.000, 0.000, 1.000),
  (2.627, 2.389, 0.000, 0.000, 1.000), (4.030, 2.389, 0.000, 0.000, 1.000),
  (5.802, 2.040, 0.000, 0.000, 1.000), (5.637, 1.867, 0.000, 0.000, 1.000),
  (3.303, 2.951, 0.000, 0.000, 1.000), (5.487, 3.270, 0.000, 0.001, 0.999),
  (4.594, 2.725, 0.000, 0.000, 1.000), (4.374, 2.996, 0.000, 0.000, 1.000),
  (3.999, 2.769, 0.000, 0.000, 1.000), (4.853, 2.651, 0.000, 0.000, 1.000),
  (5.071, 3.043, 0.000, 0.000, 1.000), (6.492, 2.992, 0.000, 0.016, 0.984),
)

// ── component ellipses: mean μ, semi-axes (eigenvalue^½ of Σ) and tilt angle ──
//   (a, b) are 1σ semi-axes along the eigen-directions; outer ring is 2σ.
#let ells = (
  (mean: (2.000, 5.600), a: 1.057, b: 0.578, ang: 31.717,  col: c0, name: $bold(mu)_1$),
  (mean: (5.400, 6.400), a: 1.115, b: 0.508, ang: -56.981, col: c1, name: $bold(mu)_2$),
  (mean: (4.200, 2.600), a: 1.145, b: 0.662, ang: 6.620,   col: c2, name: $bold(mu)_3$),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── plot frame ─────────────────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)

  // light interior grid (every world unit), sharp, behind everything
  for gx in range(0, 8) {
    if gx > 0 and gx < 8 {
      line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c)
    }
  }
  for gy in range(1, 10) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c)
  }

  // ── covariance ellipses (drawn first, sit under the points) ────────────────
  let n-seg = 64
  for E in ells {
    let cx = E.mean.at(0)
    let cy = E.mean.at(1)
    let th = E.ang * calc.pi / 180
    let ct = calc.cos(th)
    let st = calc.sin(th)
    // build the two rings: 1σ (solid) and 2σ (dashed)
    for (sigma, dash, sw, fillc) in (
      (2.0, "dashed", 0.8pt, none),
      (1.0, none,     1.4pt, E.col.transparentize(90%)),
    ) {
      let ring = range(n-seg + 1).map(i => {
        let t = i / n-seg * 2 * calc.pi
        // point on axis-aligned ellipse, then rotate by θ
        let ex = sigma * E.a * calc.cos(t)
        let ey = sigma * E.b * calc.sin(t)
        let wx = cx + ex * ct - ey * st
        let wy = cy + ex * st + ey * ct
        (sx(wx), sy(wy))
      })
      line(..ring, close: true,
        stroke: (paint: E.col, thickness: sw, dash: dash),
        fill: fillc)
    }
  }

  // ── data points, filled by responsibility blend ────────────────────────────
  for p in pts {
    let (x, y, r0, r1, r2) = p
    circle((sx(x), sy(y)), radius: 0.085,
      fill: blend(r0, r1, r2), stroke: 0.4pt + ink.transparentize(35%))
  }

  // ── component means: cross marker + label ──────────────────────────────────
  for E in ells {
    let mx = sx(E.mean.at(0))
    let my = sy(E.mean.at(1))
    let h = 0.22
    line((mx - h, my), (mx + h, my), stroke: 2pt + white)
    line((mx, my - h), (mx, my + h), stroke: 2pt + white)
    line((mx - h, my), (mx + h, my), stroke: 1.3pt + E.col)
    line((mx, my - h), (mx, my + h), stroke: 1.3pt + E.col)
    // label with a small white plate so it stays legible over the shaded ellipse
    let lp = (mx + 0.46, my + 0.40)
    rect((lp.at(0) - 0.24, lp.at(1) - 0.18), (lp.at(0) + 0.24, lp.at(1) + 0.18),
      fill: white.transparentize(15%), stroke: none)
    content(lp, text(size: 9pt, weight: "bold", fill: E.col)[#E.name])
  }

  // ── axis ticks + labels ────────────────────────────────────────────────────
  for gx in range(0, 8) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    content((sx(gx), -0.34), text(size: 7pt, fill: muted)[#gx])
  }
  for gy in range(1, 10) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    content((-0.32, sy(gy)), text(size: 7pt, fill: muted)[#gy])
  }
  content((PW / 2, -0.85), text(size: 9pt, fill: ink)[$x_1$])
  content((-0.95, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title ──────────────────────────────────────────────────────────────────
  content((PW / 2, PH + 0.78),
    text(size: 11pt, weight: "bold", fill: ink)[Gaussian mixture model — EM responsibilities])
  content((PW / 2, PH + 0.36),
    text(size: 8pt, fill: muted)[$p(bold(x)) = sum_(k=1)^3 pi_k thin cal(N)(bold(x) | bold(mu)_k, bold(Sigma)_k)$])

  // ── legend (right side), incl. the colour = responsibility note ────────────
  let lx = PW + 0.55
  let ly = PH - 0.4
  let row(i, col, lbl) = {
    let yy = ly - i * 0.62
    circle((lx, yy), radius: 0.12, fill: col, stroke: 0.4pt + ink.transparentize(35%))
    content((lx + 0.32, yy), anchor: "west", text(size: 8pt, fill: ink)[#lbl])
  }
  row(0, c0, $k = 1$)
  row(1, c1, $k = 2$)
  row(2, c2, $k = 3$)

  // responsibility key: a small gradient bar between two component colours
  let by = ly - 3.35
  content((lx - 0.12, by + 0.78), anchor: "west",
    text(size: 7.5pt, fill: muted)[soft assignment])
  let nb = 24
  let bw = 1.9
  for i in range(nb) {
    let f = i / (nb - 1)
    let x0 = lx - 0.12 + f * bw
    rect((x0, by), (x0 + bw / nb + 0.02, by + 0.4),
      fill: color.mix((c0, (1 - f) * 100%), (c1, f * 100%), space: rgb), stroke: none)
  }
  rect((lx - 0.12, by), (lx - 0.12 + bw, by + 0.4), stroke: 0.6pt + ink)
  content((lx - 0.12, by - 0.26), anchor: "west", text(size: 6.5pt, fill: muted)[$r_(n 1) = 1$])
  content((lx - 0.12 + bw, by - 0.26), anchor: "east", text(size: 6.5pt, fill: muted)[$r_(n 2) = 1$])
  content((lx - 0.12, by - 0.66), anchor: "west",
    text(size: 7pt, fill: muted)[colour $= sum_k r_(n k) bold(c)_k$])

  // ellipse-meaning note (lower right)
  content((lx - 0.12, by - 1.5), anchor: "west",
    text(size: 7pt, fill: muted)[— 1$sigma$ ellipse])
  content((lx - 0.12, by - 1.92), anchor: "west",
    text(size: 7pt, fill: muted)[-- 2$sigma$ ellipse])
  content((lx - 0.12, by - 2.34), anchor: "west",
    text(size: 7pt, fill: muted)[$+$  mean $bold(mu)_k$])
})
