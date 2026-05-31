// mlatlas · Particle filter (sequential Monte Carlo).
//   A bootstrap particle filter approximates the filtering distribution
//   p(x_t | y_{1:t}) by a cloud of N weighted samples {x_t^i, w_t^i}. Each
//   time step runs the SMC cycle:
//     (1) PREDICT   x_t^i ~ p(x_t | x_{t-1}^i)        propagate through dynamics
//     (2) WEIGHT    w_t^i ∝ p(y_t | x_t^i)            score by the likelihood
//     (3) RESAMPLE  draw N particles ∝ w_t^i          duplicate heavy, kill light
//   Particles are dots on a 1-D state axis; DOT SIZE encodes the weight. Light
//   propagation arrows carry a particle forward; converging/duplicating garnet
//   arrows show resampling (high-weight survivors spawn copies, low-weight die).
//   The observation y_t and its likelihood band anchor the weighting.
//
// Standard teaching figure (Murphy, ML book 2; Barber BRML §27; MacKay), built
// from first principles in mlatlas's print-first house style. Not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── brand palette: print-first, garnet a sparse focal accent ───────────────
  let p = (
    garnet: rgb("#73000A"),   // resampling links + heaviest particle
    blue:   rgb("#466A9F"),   // observation / likelihood
    ink:    rgb("#1A1A1A"),
    edge:   rgb("#363636"),
    muted:  rgb("#5C5C5C"),
    faint:  rgb("#A2A2A2"),
    band:   rgb("#ECECEC"),   // likelihood band fill
    dot:    rgb("#C7C7C7"),   // ordinary particle fill
    dotstk: rgb("#5C5C5C"),
  )

  // ── geometry ───────────────────────────────────────────────────────────────
  // Three stages laid out left→right per timestep; the resampled set of one step
  // is the prior of the next. We show ONE full SMC cycle (t-1 ▸ t) in detail,
  // with a compressed continuation column for t+1.
  let colx = (0.0, 4.4, 8.8, 13.2)   // x of stage columns
  let ax-lo = 0.4                      // bottom of state axis
  let ax-hi = 7.2                      // top of state axis
  let axh = ax-hi - ax-lo

  // map a state value s∈[0,6] to a y on the column axis
  let sy(s) = ax-lo + (s / 6.0) * axh

  // particle radius from a (normalized) weight.
  // baseline keeps equal-weight (1/7) dots compact so the WEIGHT column's
  // likelihood-scaled spread is the visual contrast.
  let prad(w) = 0.11 + 0.74 * calc.sqrt(w)

  // ── stage data (deterministic toy 1-D filter, N = 7) ───────────────────────
  // positions on the 0..6 state line; weights are normalized likelihoods.
  // PREDICT column: propagated prior particles (uniform-ish weight)
  let pos-pred = (0.8, 1.6, 2.3, 3.0, 3.8, 4.6, 5.4)
  let wt-flat = (1, 1, 1, 1, 1, 1, 1).map(x => 1.0 / 7.0)
  // WEIGHT column: same positions, weight ∝ N(y; x, σ) around observation y=3.2
  let wt-lik = (0.017, 0.085, 0.203, 0.299, 0.255, 0.114, 0.027)
  let obs = 3.2
  // RESAMPLE column: survivors (systematic resampling indices 1,2,3,3,4,4,5)
  // → particle 3 (heaviest) duplicated; tails 0 and 6 killed. Reset to uniform w.
  let resamp-idx = (1, 2, 3, 3, 4, 4, 5)
  // y-position of each survivor = position of its SOURCE particle (with a small
  // split so the two copies of the heaviest read as two distinct dots).
  let resamp-pos = (
    pos-pred.at(1),
    pos-pred.at(2),
    pos-pred.at(3) - 0.40,   // copy A of the heaviest particle (idx 3)
    pos-pred.at(3) + 0.40,   // copy B of the heaviest particle (idx 3)
    pos-pred.at(4) - 0.30,   // copy A of the 2nd-heaviest (idx 4)
    pos-pred.at(4) + 0.30,   // copy B of the 2nd-heaviest (idx 4)
    pos-pred.at(5),
  )

  // ── helpers ────────────────────────────────────────────────────────────────
  let arr(a, b, color: p.muted, w: 1.0pt, s: 0.6, dash: none) = draw.line(
    a, b,
    stroke: (paint: color, thickness: w, dash: dash),
    mark: (end: "stealth", scale: s, fill: color),
  )

  // a particle dot at column x, state s, weight w
  let particle(x, s, w, focal: false) = {
    let r = prad(w)
    draw.circle(
      (x, sy(s)), radius: r,
      fill: if focal { p.garnet } else { p.dot },
      stroke: (paint: if focal { p.garnet } else { p.dotstk },
               thickness: if focal { 1.2pt } else { 0.8pt }),
    )
  }

  // vertical state axis for a column (light)
  let col-axis(x, lbl) = {
    draw.line((x, ax-lo - 0.25), (x, ax-hi + 0.25),
      stroke: (paint: p.faint, thickness: 0.8pt))
    // little tick at midline
    draw.content((x, ax-hi + 0.62), anchor: "center",
      text(size: 9.5pt, weight: "bold", fill: p.ink)[#lbl])
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  state-axis label (left)
  // ═══════════════════════════════════════════════════════════════════════════
  draw.content((colx.at(0) - 1.15, (ax-lo + ax-hi) / 2), anchor: "center",
    text(size: 9pt, fill: p.ink)[#rotate(-90deg)[state $x$]])
  // axis arrow on the far left to set the "state" direction
  arr((colx.at(0) - 0.78, ax-lo - 0.1), (colx.at(0) - 0.78, ax-hi + 0.1),
    color: p.faint, w: 1.0pt, s: 0.6)

  // ═══════════════════════════════════════════════════════════════════════════
  //  COLUMN 0 — PREDICT  (propagated prior, flat weights)
  // ═══════════════════════════════════════════════════════════════════════════
  col-axis(colx.at(0), [predict])
  draw.content((colx.at(0), ax-hi + 1.12), anchor: "center",
    text(size: 7.5pt, fill: p.muted)[$x_t^i tilde p(x_t | x_(t-1)^i)$])
  for i in range(7) {
    particle(colx.at(0), pos-pred.at(i), wt-flat.at(i))
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROPAGATION arrows  predict → weight   (dynamics carry each particle over;
  //  here positions are unchanged in-frame, so light horizontal carriers)
  // ═══════════════════════════════════════════════════════════════════════════
  for i in range(7) {
    let r0 = prad(wt-flat.at(i))
    let r1 = prad(wt-lik.at(i))
    arr(
      (colx.at(0) + r0 + 0.05, sy(pos-pred.at(i))),
      (colx.at(1) - r1 - 0.06, sy(pos-pred.at(i))),
      color: p.faint, w: 0.8pt, s: 0.5,
    )
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  COLUMN 1 — WEIGHT  (likelihood band + dots sized by w_t^i)
  // ═══════════════════════════════════════════════════════════════════════════
  // likelihood band: a soft Gaussian envelope around the observation, drawn as a
  // filled lobe to the RIGHT of the column so heavy dots sit where it is widest.
  let sig = 0.9
  let bw = 1.25                       // max band half-width
  let nb = 28
  let band-pts = ()
  for k in range(nb + 1) {
    let s = (k / nb) * 6.0
    let g = calc.exp(-0.5 * calc.pow((s - obs) / sig, 2))
    band-pts.push((colx.at(1) + bw * g, sy(s)))
  }
  // close the lobe down the column line
  band-pts.push((colx.at(1), sy(6.0)))
  band-pts.push((colx.at(1), sy(0.0)))
  draw.line(..band-pts, close: true,
    fill: p.band, stroke: (paint: p.faint, thickness: 0.6pt))

  col-axis(colx.at(1), [weight])
  draw.content((colx.at(1), ax-hi + 1.12), anchor: "center",
    text(size: 7.5pt, fill: p.muted)[$w_t^i prop p(y_t | x_t^i)$])
  // observation: blue dashed guide at level y_t, drawn into the OPEN gap to the
  // left of the weight column so the label clears the particle dots. A short
  // solid blue tick on the column marks the exact measured level.
  let yt-x0 = (colx.at(0) + colx.at(1)) / 2 + 0.7
  draw.line((yt-x0, sy(obs)), (colx.at(1) - 0.05, sy(obs)),
    stroke: (paint: p.blue, thickness: 1.0pt, dash: "dashed"))
  draw.line((colx.at(1) - 0.05, sy(obs) - 0.30), (colx.at(1) - 0.05, sy(obs) + 0.30),
    stroke: (paint: p.blue, thickness: 2.2pt))
  draw.content((yt-x0 - 0.12, sy(obs)), anchor: "east",
    text(size: 9pt, fill: p.blue)[$y_t$])
  // particles, heaviest one in garnet
  for i in range(7) {
    particle(colx.at(1), pos-pred.at(i), wt-lik.at(i), focal: (i == 3))
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RESAMPLING arrows  weight → resample
  //  Survivors fan from heavy particles (duplicating); light particles have no
  //  outgoing arrow (they die). Garnet = focal duplication of the heaviest.
  // ═══════════════════════════════════════════════════════════════════════════
  for j in range(7) {
    let src = resamp-idx.at(j)        // which weighted particle this survivor comes from
    let s-src = pos-pred.at(src)
    let s-dst = resamp-pos.at(j)      // survivor position (duplicates split for clarity)
    let r1 = prad(wt-lik.at(src))
    let r2 = prad(1.0 / 7.0)
    let dup = (src == 3)              // copies of the heaviest particle (focal)
    arr(
      (colx.at(1) + r1 + 0.05, sy(s-src)),
      (colx.at(2) - r2 - 0.06, sy(s-dst)),
      color: if dup { p.garnet } else { p.edge },
      w: if dup { 1.6pt } else { 0.9pt },
      s: 0.55,
    )
  }
  // mark the two killed (zero-weight-survivor) particles with a faint ✗
  for i in (0, 6) {
    let r1 = prad(wt-lik.at(i))
    draw.content((colx.at(1) + r1 + 0.42, sy(pos-pred.at(i))), anchor: "center",
      text(size: 8pt, fill: p.faint)[$times$])
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  COLUMN 2 — RESAMPLE  (equal-weight survivors; duplicates clustered at mode)
  // ═══════════════════════════════════════════════════════════════════════════
  col-axis(colx.at(2), [resample])
  draw.content((colx.at(2), ax-hi + 1.12), anchor: "center",
    text(size: 7.5pt, fill: p.muted)[$x_t^i ~ {w_t^j}, thick w_t^i <- 1\/N$])
  for j in range(7) {
    let src = resamp-idx.at(j)
    let dup = (src == 3)
    particle(colx.at(2), resamp-pos.at(j), 1.0 / 7.0, focal: dup)
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PROPAGATION to next step  resample → predict (t+1)
  //  Compressed continuation column showing the cycle repeats.
  // ═══════════════════════════════════════════════════════════════════════════
  for j in range(7) {
    let r2 = prad(1.0 / 7.0)
    arr(
      (colx.at(2) + r2 + 0.05, sy(resamp-pos.at(j))),
      (colx.at(3) - 0.55, sy(resamp-pos.at(j))),
      color: p.faint, w: 0.8pt, s: 0.5, dash: "dashed",
    )
  }
  // ghost continuation column
  col-axis(colx.at(3), [predict])
  draw.content((colx.at(3), ax-hi + 1.12), anchor: "center",
    text(size: 7.5pt, fill: p.muted)[$t + 1 dots$])
  for j in range(7) {
    draw.circle((colx.at(3), sy(resamp-pos.at(j))), radius: prad(1.0 / 7.0),
      fill: white, stroke: (paint: p.faint, thickness: 0.7pt, dash: "dashed"))
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP bracket: one SMC cycle spans the three detailed columns
  // ═══════════════════════════════════════════════════════════════════════════
  let bry = ax-hi + 1.78
  draw.line((colx.at(0) - 0.2, bry), (colx.at(2) + 0.2, bry),
    stroke: (paint: p.muted, thickness: 1.0pt))
  draw.line((colx.at(0) - 0.2, bry), (colx.at(0) - 0.2, bry - 0.18),
    stroke: (paint: p.muted, thickness: 1.0pt))
  draw.line((colx.at(2) + 0.2, bry), (colx.at(2) + 0.2, bry - 0.18),
    stroke: (paint: p.muted, thickness: 1.0pt))
  draw.content(((colx.at(0) + colx.at(2)) / 2, bry + 0.34), anchor: "center",
    text(size: 9pt, weight: "bold", fill: p.ink)[
      one SMC step: $hat(p)(x_(t-1) | y_(1:t-1)) arrow.r hat(p)(x_t | y_(1:t))$
    ])

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM — legend + governing relations
  // ═══════════════════════════════════════════════════════════════════════════
  let ly = ax-lo - 1.35
  // dot-size = weight key
  draw.circle((colx.at(0) - 0.45, ly), radius: prad(0.04),
    fill: p.dot, stroke: (paint: p.dotstk, thickness: 0.8pt))
  draw.circle((colx.at(0) + 0.30, ly), radius: prad(0.30),
    fill: p.dot, stroke: (paint: p.dotstk, thickness: 0.8pt))
  draw.content((colx.at(0) + 0.95, ly), anchor: "west",
    text(size: 8pt, fill: p.ink)[dot size $=$ weight $w_t^i$])

  // killed key
  draw.content((colx.at(1) + 0.55, ly), anchor: "west",
    text(size: 8pt, fill: p.faint)[$times$ = killed])

  // garnet survivor key
  arr((colx.at(1) + 2.35, ly), (colx.at(1) + 3.15, ly), color: p.garnet, w: 1.6pt, s: 0.55)
  draw.content((colx.at(1) + 3.3, ly), anchor: "west",
    text(size: 8pt, fill: p.garnet)[resample: duplicate heavy particle])

  // posterior estimator line
  draw.content(((colx.at(0) + colx.at(3)) / 2, ly - 0.78), anchor: "center",
    box(inset: 0pt)[
      #set text(size: 8.5pt, fill: p.ink)
      #grid(columns: 3, column-gutter: 1.6em, align: horizon,
        text(fill: p.ink)[$hat(p)(x_t | y_(1:t)) = sum_(i=1)^N w_t^i thin delta(x_t - x_t^i)$],
        text(fill: p.muted)[$sum_i w_t^i = 1$],
        text(fill: p.blue)[$N = 7$ particles],
      )
    ])

  // ═══════════════════════════════════════════════════════════════════════════
  //  TITLE
  // ═══════════════════════════════════════════════════════════════════════════
  draw.content((colx.at(1) + 0.6, bry + 1.0), anchor: "center",
    text(size: 12pt, weight: "bold", fill: p.ink)[
      Particle filter · sequential Monte Carlo
    ])
})
