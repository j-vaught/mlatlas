// mlatlas · Principal Component Analysis — variance-maximizing projection axes.
// A tilted 2-D point cloud is summarized by its sample covariance Σ = (1/N) Σ (xₙ-μ̄)(xₙ-μ̄)ᵀ.
// The eigenvectors of Σ are the principal axes (orthonormal); the eigenvalues λ₁ ≥ λ₂ are the
// variances along them. PC1 (garnet) is the direction of MAXIMUM variance — the line minimizing
// the sum of squared orthogonal distances. Each arrow is centered at the mean μ̄ and scaled by
// √λ (one standard deviation along that axis). For a few sample points the dashed segment is the
// orthogonal projection foot onto the PC1 line; its length is the reconstruction error PCA discards
// when it keeps only the first component. A scree bar shows the variance explained per component.
// Standard ESL / ISLP / MML teaching figure, built from scratch in mlatlas's print-first style.
// Data, mean, eigenvectors and eigenvalues were computed numerically; no image was traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette (garnet accent on a monochrome base) ─────────────────────────────
#let garnet = rgb("#73000A") // PC1 — focal accent
#let blue   = rgb("#466A9F") // PC2
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let grid-c = rgb("#ECECEC")
#let dotc   = rgb("#5C5C5C")

// ── PCA result (numerically computed) ────────────────────────────────────────
#let mu    = (5.354, 4.228)              // sample mean μ̄
#let pc1   = (0.8656, 0.5008)            // 1st eigenvector  (λ₁ = 4.115)
#let pc2   = (-0.5008, 0.8656)           // 2nd eigenvector  (λ₂ = 0.771)
#let s1    = 2.028                        // √λ₁  (std along PC1)
#let s2    = 0.878                        // √λ₂  (std along PC2)
#let ratio = (0.842, 0.158)              // variance explained per component

// the point cloud (x, y)
#let pts = (
  (8.431, 5.606), (5.110, 4.612), (3.771, 3.542), (5.841, 3.091), (6.822, 5.693),
  (4.131, 3.580), (6.210, 4.606), (5.293, 3.066), (6.158, 4.919), (6.256, 3.513),
  (8.131, 5.995), (3.756, 5.325), (5.649, 3.257), (5.304, 2.334), (7.252, 5.023),
  (3.463, 4.324), (2.015, 3.080), (1.706, 1.857), (2.485, 4.148), (8.517, 5.773),
  (6.788, 4.985), (6.504, 4.328), (2.768, 1.414), (5.070, 6.217), (5.880, 4.198),
  (8.574, 6.304), (5.291, 4.572), (5.074, 3.959), (2.419, 3.264), (4.592, 5.030),
  (5.231, 2.632), (4.397, 5.375), (4.832, 3.318), (3.424, 2.428), (5.089, 3.198),
  (8.014, 5.547), (4.870, 5.395), (7.999, 5.600), (5.532, 5.126), (5.502, 2.890),
)

// the handful of points that get a drawn orthogonal projection onto PC1
//   (point, foot-on-PC1)
#let drops = (
  ((2.419, 3.264), (2.737, 2.714)),
  ((3.756, 5.325), (4.632, 3.811)),
  ((5.841, 3.091), (5.226, 4.154)),
  ((6.210, 4.606), (6.159, 4.694)),
  ((8.131, 5.995), (8.201, 5.875)),
)

// data world → canvas mapping (square-ish plot box)
#let X0 = 1.2
#let X1 = 9.0
#let Y0 = 1.0
#let Y1 = 6.8
#let PW = 8.2
#let PH = 6.1
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH
#let SP(p) = (sx(p.at(0)), sy(p.at(1)))   // map a data point to canvas coords

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── plot frame + light grid ────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)
  for gx in range(2, 10) {
    line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c)
  }
  for gy in range(1, 7) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c)
  }

  // ── orthogonal projection drops onto the PC1 line (dashed, behind points) ───
  for d in drops {
    let p = SP(d.at(0))
    let f = SP(d.at(1))
    line(p, f, stroke: (paint: muted, thickness: 0.7pt, dash: "dashed"))
    // small foot tick on the line
    circle(f, radius: 0.055, fill: garnet, stroke: 0.5pt + white)
  }

  // ── the data points ─────────────────────────────────────────────────────────
  for p in pts {
    circle(SP(p), radius: 0.085, fill: dotc.transparentize(15%),
      stroke: 0.4pt + ink.transparentize(30%))
  }

  // ── PC1 line through the mean (thin guide, full extent) ─────────────────────
  let line-len = 3.6
  let l1a = (mu.at(0) - pc1.at(0) * line-len, mu.at(1) - pc1.at(1) * line-len)
  let l1b = (mu.at(0) + pc1.at(0) * line-len, mu.at(1) + pc1.at(1) * line-len)
  line(SP(l1a), SP(l1b), stroke: (paint: garnet.transparentize(55%), thickness: 0.8pt, dash: "dash-dotted"))

  // ── principal-component arrows: centered at μ̄, length √λ each direction ─────
  // PC1 (garnet, longest), drawn both ways from the mean
  let a1p = (mu.at(0) + pc1.at(0) * s1, mu.at(1) + pc1.at(1) * s1)
  let a1m = (mu.at(0) - pc1.at(0) * s1, mu.at(1) - pc1.at(1) * s1)
  line(SP(mu), SP(a1p), stroke: 2.2pt + garnet, mark: (end: "stealth", scale: 0.7))
  line(SP(mu), SP(a1m), stroke: 2.2pt + garnet, mark: (end: "stealth", scale: 0.7))
  // PC2 (blue, shorter, orthogonal)
  let a2p = (mu.at(0) + pc2.at(0) * s2, mu.at(1) + pc2.at(1) * s2)
  let a2m = (mu.at(0) - pc2.at(0) * s2, mu.at(1) - pc2.at(1) * s2)
  line(SP(mu), SP(a2p), stroke: 2.0pt + blue, mark: (end: "stealth", scale: 0.7))
  line(SP(mu), SP(a2m), stroke: 2.0pt + blue, mark: (end: "stealth", scale: 0.7))

  // ── mean marker (cross) ─────────────────────────────────────────────────────
  let m = SP(mu)
  let h = 0.16
  line((m.at(0) - h, m.at(1)), (m.at(0) + h, m.at(1)), stroke: 2pt + white)
  line((m.at(0), m.at(1) - h), (m.at(0), m.at(1) + h), stroke: 2pt + white)
  line((m.at(0) - h, m.at(1)), (m.at(0) + h, m.at(1)), stroke: 1.3pt + ink)
  line((m.at(0), m.at(1) - h), (m.at(0), m.at(1) + h), stroke: 1.3pt + ink)

  // ── axis arrow-tip labels ───────────────────────────────────────────────────
  // PC1 label near its positive tip
  content((SP(a1p).at(0) + 0.42, SP(a1p).at(1) + 0.16),
    text(size: 9pt, weight: "bold", fill: garnet)[$bold(u)_1$])
  content((SP(a1p).at(0) + 0.44, SP(a1p).at(1) - 0.22),
    text(size: 6.5pt, fill: garnet)[$sqrt(lambda_1)$])
  // PC2 label near its positive tip
  content((SP(a2p).at(0) - 0.42, SP(a2p).at(1) + 0.20),
    text(size: 9pt, weight: "bold", fill: blue)[$bold(u)_2$])
  content((SP(a2p).at(0) - 0.44, SP(a2p).at(1) - 0.20),
    text(size: 6.5pt, fill: blue)[$sqrt(lambda_2)$])
  // mean label
  content((m.at(0) + 0.02, m.at(1) - 0.40),
    text(size: 7.5pt, fill: ink)[$macron(bold(x))$])

  // annotate one projection foot so the construction is unambiguous
  let dd = drops.at(1)
  let dp = SP(dd.at(0))
  let df = SP(dd.at(1))
  let midd = ((dp.at(0) + df.at(0)) / 2 - 0.36, (dp.at(1) + df.at(1)) / 2 + 0.06)
  content(midd, anchor: "east",
    text(size: 6.5pt, fill: muted, style: "italic")[orthogonal])

  // ── axis ticks + labels ─────────────────────────────────────────────────────
  for gx in range(2, 10) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    content((sx(gx), -0.32), text(size: 7pt, fill: muted)[#gx])
  }
  for gy in range(1, 7) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    content((-0.30, sy(gy)), text(size: 7pt, fill: muted)[#gy])
  }
  content((PW / 2, -0.80), text(size: 9pt, fill: ink)[$x_1$])
  content((-0.86, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title + subtitle ────────────────────────────────────────────────────────
  content((PW / 2, PH + 0.80),
    text(size: 11pt, weight: "bold", fill: ink)[Principal component analysis — variance-maximizing axes])
  content((PW / 2, PH + 0.38),
    text(size: 8pt, fill: muted)[$bold(Sigma) = 1/N sum_n (bold(x)_n - macron(bold(x)))(bold(x)_n - macron(bold(x)))^top, quad bold(Sigma) bold(u)_k = lambda_k bold(u)_k$])

  // ══════════════════════════════════════════════════════════════════════════
  //  Scree / variance-explained bar (companion, to the right of the scatter)
  // ══════════════════════════════════════════════════════════════════════════
  let bx = PW + 1.05          // left edge of scree panel
  let bw = 2.05               // panel inner width
  let bh = 3.5                // panel height (= 100% of variance)
  let by = 0.4                // bottom

  // panel frame
  rect((bx - 0.0, by), (bx + bw, by + bh), fill: white, stroke: 1pt + ink)
  // horizontal grid at 25/50/75/100 %
  for f in (0.25, 0.5, 0.75, 1.0) {
    line((bx, by + f * bh), (bx + bw, by + f * bh), stroke: 0.5pt + grid-c)
    content((bx - 0.14, by + f * bh), anchor: "east",
      text(size: 6pt, fill: muted)[#{calc.round(f * 100)}%])
  }

  // two bars: λ₁ and λ₂ proportions
  let barw = 0.62
  let gap  = 0.34
  let cols = (garnet, blue)
  let labs = ($lambda_1$, $lambda_2$)
  for i in (0, 1) {
    let r = ratio.at(i)
    let x0 = bx + gap + i * (barw + gap + 0.18)
    rect((x0, by), (x0 + barw, by + r * bh),
      fill: cols.at(i).transparentize(20%), stroke: 1pt + cols.at(i))
    // percent label above bar
    content((x0 + barw / 2, by + r * bh + 0.22),
      text(size: 7pt, weight: "bold", fill: cols.at(i))[#{calc.round(r * 100)}%])
    // component label below axis
    content((x0 + barw / 2, by - 0.26),
      text(size: 8pt, fill: cols.at(i))[#labs.at(i)])
  }
  // panel title + axis label
  content((bx + bw / 2, by + bh + 0.78),
    text(size: 8.5pt, weight: "bold", fill: ink)[Scree])
  content((bx + bw / 2, by + bh + 0.42),
    text(size: 7pt, fill: muted)[variance explained])
  content((bx + bw / 2, by - 0.66),
    text(size: 6.5pt, fill: muted)[$lambda_k slash sum_j lambda_j$])
})
