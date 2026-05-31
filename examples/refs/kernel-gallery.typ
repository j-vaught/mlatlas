// mlatlas · Covariance / kernel function gallery (GPML, Rasmussen & Williams;
//   Murphy, "Machine Learning: A Probabilistic Perspective").
//
//   A small-multiples gallery of four stationary GP covariance kernels. For each
//   we show TWO things, stacked:
//     (top)    the kernel SHAPE  k(r)  as a function of distance r = |x − x'|,
//              normalised to k(0)=1, which controls how strongly two points covary.
//     (bottom) a few FUNCTION SAMPLES f ~ GP(0, k) the kernel induces — sampled
//              EXACTLY from a zero-mean GP via a Cholesky factor of the Gram
//              matrix K (K = L Lᵀ, f = L z, z ~ N(0,I)), so the smoothness /
//              wiggliness / periodicity you see is the real consequence of k.
//
//   Kernels (all length-scale ℓ = 1, signal variance σ_f² = 1):
//     • Squared-exponential   k = exp(−r²/2ℓ²)              — ∞-smooth, very wavy-free
//     • Matérn ν=3/2          k = (1+√3 r/ℓ) exp(−√3 r/ℓ)   — once-diff'ble, rougher
//     • Periodic              k = exp(−2 sin²(π r/p)/ℓ²)    — exactly repeating, p=2
//     • Rational-quadratic    k = (1 + r²/2αℓ²)^(−α), α=1   — scale mixture of SE
//
//   Built print-first in cetz: light panels, dark ink, sharp corners, garnet as a
//   sparse focal accent on the kernel curve. No image traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ──────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let axiscol = rgb("#363636")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid   = rgb("#ECECEC")
  let garnet = rgb("#73000A")   // kernel curve  (focal accent)
  let blue   = rgb("#466A9F")
  let green  = rgb("#65780B")
  let brown  = rgb("#A49137")
  let beige  = rgb("#FFF2E3")

  // sample colours (3 muted draws per panel)
  let scols = (blue, green, brown)

  // ── kernels  (ℓ = 1, σf² = 1) ────────────────────────────────────────────
  let r3 = calc.sqrt(3.0)
  let pp = 2.0                                  // period for the periodic kernel
  let alpha_rq = 1.0                            // rational-quadratic mixing
  let k_se(r)   = calc.exp(-r * r / 2.0)
  let k_mat(r)  = (1.0 + r3 * calc.abs(r)) * calc.exp(-r3 * calc.abs(r))
  let k_per(r)  = calc.exp(-2.0 * calc.pow(calc.sin(calc.pi * calc.abs(r) / pp), 2))
  let k_rq(r)   = calc.pow(1.0 + r * r / (2.0 * alpha_rq), -alpha_rq)

  // ── exact GP samples via Cholesky of the Gram matrix ─────────────────────
  // training grid for sampling functions
  let m = 41
  let xlo = -3.0
  let xhi = 3.0
  let xs = range(m).map(i => xlo + (xhi - xlo) * i / (m - 1))

  // build K from a kernel of |x-x'|, with a tiny jitter for SPD-ness
  let gram(kf) = range(m).map(i => range(m).map(j => {
    kf(xs.at(i) - xs.at(j)) + (if i == j { 1e-6 } else { 0.0 })
  }))

  // lower-triangular Cholesky:  K = L Lᵀ
  let chol(K) = {
    let L = range(m).map(_ => range(m).map(_ => 0.0))
    for i in range(m) {
      for j in range(i + 1) {
        let s = 0.0
        for kk in range(j) { s = s + L.at(i).at(kk) * L.at(j).at(kk) }
        if i == j {
          L.at(i).at(j) = calc.sqrt(calc.max(K.at(i).at(i) - s, 1e-12))
        } else {
          L.at(i).at(j) = (K.at(i).at(j) - s) / L.at(j).at(j)
        }
      }
    }
    L
  }

  // deterministic pseudo-Gaussian noise vector z (so the figure is reproducible).
  // a small LCG → uniform in (0,1) → Box–Muller → standard normal samples.
  let randn(seed, count) = {
    let st = seed
    let out = ()
    let need = count + calc.rem(count, 2)        // even count for Box–Muller pairs
    let us = ()
    for _ in range(need) {
      st = calc.rem(st * 1103515245 + 12345, 2147483648)
      us.push(st / 2147483648.0)
    }
    let i = 0
    while i < need {
      let u1 = calc.max(us.at(i), 1e-9)
      let u2 = us.at(i + 1)
      let radius = calc.sqrt(-2.0 * calc.ln(u1))
      out.push(radius * calc.cos(2.0 * calc.pi * u2))
      out.push(radius * calc.sin(2.0 * calc.pi * u2))
      i = i + 2
    }
    out.slice(0, count)
  }

  // f = L z
  let gp-sample(L, z) = range(m).map(i => {
    let s = 0.0
    for j in range(i + 1) { s = s + L.at(i).at(j) * z.at(j) }
    s
  })

  // ── panel geometry ───────────────────────────────────────────────────────
  // four panels in a row; each split into a kernel sub-axis (top) and a
  // samples sub-axis (bottom).
  let PW = 4.0            // panel width  (cm)
  let GAP = 0.95          // gap between panels
  let KH = 1.55           // kernel sub-axis height
  let SH = 2.15           // samples sub-axis height
  let MID = 0.62          // vertical gap between the two sub-axes

  // map r ∈ [0, rmax] to a kernel sub-axis x; k ∈ [klo,1] to its y
  let rmax = 3.0

  let kernels = (
    (name: [squared-exp.], sub: [$exp(-r^2 \/ 2 ell^2)$], kf: k_se,  seed: 101),
    (name: [Matérn #h(0.15em) $nu = 3\/2$], sub: [$(1+sqrt(3)r) e^(-sqrt(3) r)$], kf: k_mat, seed: 207),
    (name: [periodic], sub: [$exp(-2 sin^2(pi r\/p)\/ell^2)$], kf: k_per, seed: 313),
    (name: [rational-quad.], sub: [$(1+r^2\/(2 alpha))^(-alpha)$], kf: k_rq,  seed: 419),
  )

  // y-extent for the samples axis (shared so panels are comparable)
  let slo = -2.6
  let shi = 2.6

  for (idx, kd) in kernels.enumerate() {
    let ox = idx * (PW + GAP)        // panel origin x

    // sub-axis baselines (y of the bottom of each box)
    let s_y0 = 0.0
    let s_y1 = SH
    let k_y0 = SH + MID
    let k_y1 = SH + MID + KH

    // ── coordinate maps for this panel ──────────────────────────────────────
    // kernel sub-axis: r∈[0,rmax] across full width; k∈[klo,1] in box.
    let klo = -0.45                  // periodic/RQ can dip below 0
    let KX(r) = ox + (r / rmax) * PW
    let KY(kv) = k_y0 + ((kv - klo) / (1.0 - klo)) * KH
    // samples sub-axis: x∈[xlo,xhi]; y∈[slo,shi]
    let SX(xv) = ox + ((xv - xlo) / (xhi - xlo)) * PW
    let SY(yv) = s_y0 + ((yv - slo) / (shi - slo)) * SH

    // ── panel backgrounds + frames ─────────────────────────────────────────
    rect((ox, k_y0), (ox + PW, k_y1), fill: white, stroke: 0.6pt + faint)
    rect((ox, s_y0), (ox + PW, s_y1), fill: white, stroke: 0.6pt + faint)

    // faint gridlines
    // kernel: horizontal at k=0 and k=0.5, vertical at r=1,2
    line((ox, KY(0.0)), (ox + PW, KY(0.0)), stroke: 0.5pt + grid)
    line((ox, KY(0.5)), (ox + PW, KY(0.5)), stroke: 0.5pt + grid)
    for rr in (1.0, 2.0) {
      line((KX(rr), k_y0), (KX(rr), k_y1), stroke: 0.5pt + grid)
    }
    // samples: zero line + light verticals
    line((ox, SY(0.0)), (ox + PW, SY(0.0)), stroke: 0.5pt + grid)
    for xv in (-2.0, 0.0, 2.0) {
      line((SX(xv), s_y0), (SX(xv), s_y1), stroke: 0.5pt + grid)
    }

    // ── kernel curve k(r) (focal garnet) ───────────────────────────────────
    let NK = 96
    let kpts = range(NK + 1).map(i => {
      let r = rmax * i / NK
      (KX(r), KY((kd.kf)(r)))
    })
    line(..kpts, stroke: 2.0pt + garnet)
    // dot at k(0)=1
    circle((KX(0.0), KY(1.0)), radius: 0.055, fill: garnet, stroke: 0.5pt + white)

    // ── GP function samples (exact, via Cholesky) ──────────────────────────
    let K = gram(kd.kf)
    let L = chol(K)
    for (si, sc) in scols.enumerate() {
      let z = randn(kd.seed + si * 1000, m)
      let f = gp-sample(L, z)
      let fpts = range(m).map(i => (SX(xs.at(i)), SY(calc.max(calc.min(f.at(i), shi), slo))))
      line(..fpts, stroke: (paint: sc.transparentize(8%), thickness: 1.0pt))
    }

    // ── kernel sub-axis frame ticks + labels ───────────────────────────────
    // y ticks: k = 0, 1
    content((ox - 0.12, KY(0.0)), text(fill: muted, size: 6.5pt)[$0$], anchor: "east")
    content((ox - 0.12, KY(1.0)), text(fill: muted, size: 6.5pt)[$1$], anchor: "east")
    // x ticks: r = 0, 3
    content((KX(0.0), k_y0 - 0.1), text(fill: muted, size: 6.5pt)[$0$], anchor: "north")
    content((KX(3.0), k_y0 - 0.1), text(fill: muted, size: 6.5pt)[$3$], anchor: "north")
    // axis labels for the kernel box
    content((KX(rmax) - 0.08, KY(1.0) + 0.02), text(fill: muted, size: 6.5pt)[$k(r)$], anchor: "north-east")
    content((ox + PW / 2, k_y0 - 0.32), text(fill: muted, size: 6.5pt)[distance $r = |x - x'|$], anchor: "north")

    // ── samples sub-axis ticks + labels ────────────────────────────────────
    content((ox - 0.12, SY(slo)), text(fill: muted, size: 6.5pt)[$#(-2.6)$], anchor: "east")
    content((ox - 0.12, SY(0.0)), text(fill: muted, size: 6.5pt)[$0$], anchor: "east")
    content((ox - 0.12, SY(shi)), text(fill: muted, size: 6.5pt)[$2.6$], anchor: "east")
    for xv in (-2.0, 0.0, 2.0) {
      content((SX(xv), s_y0 - 0.1), text(fill: muted, size: 6.5pt)[$#xv$], anchor: "north")
    }
    content((ox + 0.12, SY(shi) - 0.04), text(fill: muted, size: 6.5pt)[$f(x)$], anchor: "north-west")
    content((ox + PW / 2, s_y0 - 0.32), text(fill: muted, size: 6.5pt)[input $x$], anchor: "north")

    // ── panel title (kernel name) + formula ────────────────────────────────
    content((ox + PW / 2, k_y1 + 0.46), text(fill: ink, size: 9pt, weight: "bold")[#kd.name], anchor: "south")
    content((ox + PW / 2, k_y1 + 0.12), text(fill: garnet, size: 7pt)[#kd.sub], anchor: "south")
  }

  // ── shared row labels on the far left ──────────────────────────────────────
  let lx = -1.05
  content((lx, SH + MID + KH / 2), angle: 90deg,
    text(fill: ink, size: 8pt, weight: "bold")[covariance #h(0.3em) $k(r)$], anchor: "south")
  content((lx, SH / 2), angle: 90deg,
    text(fill: ink, size: 8pt, weight: "bold")[samples #h(0.3em) $f tilde "GP"(0, k)$], anchor: "south")

  // ── overall caption ────────────────────────────────────────────────────────
  let total_w = kernels.len() * PW + (kernels.len() - 1) * GAP
  content((total_w / 2, SH + MID + KH + 1.2),
    text(fill: ink, size: 11pt, weight: "bold")[Gallery of GP covariance kernels], anchor: "south")
  content((total_w / 2, SH + MID + KH + 0.92),
    text(fill: muted, size: 7.5pt)[length-scale #h(0.1em) $ell = 1$, #h(0.3em) signal variance #h(0.1em) $sigma_f^2 = 1$ #h(0.4em) (period #h(0.1em) $p = 2$, #h(0.2em) RQ mixing #h(0.1em) $alpha = 1$)], anchor: "south")
})
