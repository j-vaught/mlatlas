// Gaussian process regression — posterior predictive band.
//   Given a few noisy observations, a GP with an RBF (squared-exponential) kernel
//   gives a closed-form posterior over functions: a predictive MEAN curve m(x*) and
//   a predictive VARIANCE v(x*). We shade the ±2σ credible band (≈95 %), draw the
//   mean (garnet), the observed points, and a few posterior SAMPLE functions.
//
//   The defining qualitative feature — the band PINCHES at the data and WIDENS in the
//   gaps / extrapolation regions — is computed here from the exact GP equations, not
//   faked: posterior mean   m* = K*ᵀ (K+σ²I)⁻¹ y
//           posterior cov   Σ* = K** − K*ᵀ (K+σ²I)⁻¹ K*
//   so the geometry is the real thing, just authored in mlatlas's print-first style.
//   Original schematic built from GPML (Rasmussen & Williams) knowledge; no image traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#import "@preview/lilaq:0.6.0" as lq
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ───────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#222222")
#let blue   = rgb("#466A9F")
#let band   = rgb("#C7C7C7")   // 30 % black — the ±2σ band fill
#let band2  = rgb("#A2A2A2")   // 50 % black — inner ±1σ band fill
#let muted  = rgb("#5C5C5C")

// ── exact GP posterior with an RBF kernel ────────────────────────────────────
// kernel k(a,b) = sf² · exp(−(a−b)²/(2ℓ²))
#let sf2   = 1.0           // signal variance
#let ell   = 1.1          // length-scale
#let noise = 0.03         // observation-noise variance σ²
#let k(a, b) = sf2 * calc.exp(-calc.pow(a - b, 2) / (2.0 * ell * ell))

// training observations (x, y) — a wavy latent sampled noisily, deliberately
// leaving a wide gap in the middle and unobserved tails so the band can flare.
#let xtr = (-4.4, -3.6, -2.9, -2.1, 0.7, 1.4, 3.4, 4.2)
#let ytr = (-0.55, 0.65, 0.95, 0.15, -0.85, -0.55, 0.75, 0.25)
#let n   = xtr.len()

// ── small dense linear algebra (Gaussian elimination) ────────────────────────
// build K + σ²I
#let A = range(n).map(i => range(n).map(j => {
  k(xtr.at(i), xtr.at(j)) + (if i == j { noise } else { 0.0 })
}))

// solve A · z = b  for a single right-hand side via Gauss elimination w/ partial pivot
#let solve(Amat, b) = {
  let m = Amat.map(row => row)            // copy
  let v = b
  let nn = b.len()
  // augment
  let M = range(nn).map(i => m.at(i) + (v.at(i),))
  // forward elimination
  for col in range(nn) {
    // partial pivot
    let piv = col
    let best = calc.abs(M.at(col).at(col))
    for r in range(col + 1, nn) {
      let val = calc.abs(M.at(r).at(col))
      if val > best { best = val; piv = r }
    }
    if piv != col {
      let tmp = M.at(col); M.at(col) = M.at(piv); M.at(piv) = tmp
    }
    let pivval = M.at(col).at(col)
    for r in range(col + 1, nn) {
      let factor = M.at(r).at(col) / pivval
      M.at(r) = range(nn + 1).map(c => M.at(r).at(c) - factor * M.at(col).at(c))
    }
  }
  // back substitution
  let x = range(nn).map(_ => 0.0)
  for ii in range(nn) {
    let i = nn - 1 - ii
    let s = M.at(i).at(nn)
    for j in range(i + 1, nn) { s = s - M.at(i).at(j) * x.at(j) }
    x.at(i) = s / M.at(i).at(i)
  }
  x
}

// alpha = (K+σ²I)⁻¹ y  → posterior mean weights
#let alpha = solve(A, ytr)

// test grid
#let xlo = -5.2
#let xhi = 5.2
#let ng  = 121
#let xs  = range(ng).map(i => xlo + (xhi - xlo) * i / (ng - 1))

// per-test-point posterior mean and variance
#let post = xs.map(xstar => {
  // k* vector
  let kstar = range(n).map(i => k(xstar, xtr.at(i)))
  // mean = k*ᵀ alpha
  let mean = range(n).fold(0.0, (acc, i) => acc + kstar.at(i) * alpha.at(i))
  // variance = k** − k*ᵀ (K+σ²I)⁻¹ k*
  let w = solve(A, kstar)            // (K+σ²I)⁻¹ k*
  let quad = range(n).fold(0.0, (acc, i) => acc + kstar.at(i) * w.at(i))
  let varr = calc.max(sf2 - quad, 0.0)
  (mean: mean, sd: calc.sqrt(varr))
})

#let ys-mean = post.map(p => p.mean)
#let ys-up2  = post.map(p => p.mean + 2.0 * p.sd)
#let ys-lo2  = post.map(p => p.mean - 2.0 * p.sd)
#let ys-up1  = post.map(p => p.mean + 1.0 * p.sd)
#let ys-lo1  = post.map(p => p.mean - 1.0 * p.sd)

// ── a couple of posterior SAMPLE functions ───────────────────────────────────
// cheap "sample": mean + smooth deterministic perturbation scaled by the local sd,
// so each sample hugs the data and wanders inside the band away from it.
#let sample(phase, amp) = range(ng).map(i => {
  let xv = xs.at(i)
  let p  = post.at(i)
  p.mean + amp * p.sd * calc.sin(1.7 * xv + phase)
})
#let s1 = sample(0.0, 0.9)
#let s2 = sample(2.1, -0.8)
#let s3 = sample(4.0, 0.7)

// ─────────────────────────────────────────────────────────────────────────────
#align(center)[
#lq.diagram(
  width: 11cm, height: 6.2cm,
  xlim: (xlo, xhi),
  ylim: (-2.6, 2.6),
  xlabel: $x$,
  ylabel: $f(x)$,
  legend: (position: top + right),

  // ±2σ outer band (≈95 % credible region)
  lq.fill-between(
    xs, ys-lo2, y2: ys-up2,
    fill: band.transparentize(35%), stroke: none,
    label: [$plus.minus 2 sigma$ (95%)],
  ),
  // ±1σ inner band
  lq.fill-between(
    xs, ys-lo1, y2: ys-up1,
    fill: band2.transparentize(45%), stroke: none,
    label: [$plus.minus 1 sigma$],
  ),

  // posterior sample functions (thin, blue)
  lq.plot(xs, s1, mark: none, stroke: 0.5pt + blue.transparentize(20%)),
  lq.plot(xs, s2, mark: none, stroke: 0.5pt + blue.transparentize(20%)),
  lq.plot(xs, s3, mark: none, stroke: (paint: blue.transparentize(20%), thickness: 0.5pt),
          label: [posterior samples]),

  // predictive mean (garnet, focal)
  lq.plot(xs, ys-mean, mark: none, stroke: 1.7pt + garnet, label: [predictive mean]),

  // observed data
  lq.scatter(
    xtr, ytr,
    size: 5pt, color: ink, mark: "o", stroke: 0.8pt + ink,
    label: [observations],
  ),
)
]
