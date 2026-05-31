// mlatlas · MCMC sampling over a 2-D density (random-walk Metropolis).
//   The target  p(x) ∝ exp(−E(x))  is a BIMODAL mixture of two Gaussians; its
//   iso-density level sets are the concentric contours.  A Metropolis–Hastings
//   chain explores it: from the current state x⁽ᵗ⁾ a symmetric proposal
//       x' ~ 𝒩(x⁽ᵗ⁾, σ²I)
//   is drawn (dashed proposal arrow) and ACCEPTED with probability
//       α = min(1, p(x')/p(x⁽ᵗ⁾)).
//   On accept the chain MOVES (filled ● marker, solid step) — uphill moves are
//   always taken, downhill moves sometimes.  On reject it STAYS PUT and the
//   proposal is discarded (open ○ marker, ✗).  The walk diffuses out of the
//   left mode, crosses the low-density valley, and reaches the right mode.
//   Coordinates are a fixed, seeded RW-Metropolis run (σ = 1.15, 16 steps:
//   9 accepted / 7 rejected) — not faked.  Standard MacKay / Bishop / Murphy
//   teaching figure, built from scratch in mlatlas's print-first style.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent — accepted moves / the live chain
#let blue   = rgb("#466A9F")   // rejected proposals
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let grid-c = rgb("#ECECEC")
#let cont-c = rgb("#C7C7C7")   // density contour lines
#let fillc  = rgb("#73000A")   // density shading (transparentized)

// ── target density: mixture of two bivariate Gaussians ─────────────────────────
//   p(x) = Σ_k w_k 𝒩(x ; μ_k, Σ_k)
#let comps = (
  // (w, mux, muy, s11, s12, s22)
  (0.55, -1.4, -0.9, 1.1,  0.45, 1.0),
  (0.45,  1.9,  1.2, 0.9, -0.35, 1.1),
)
// precompute per-component inverse-covariance + normalizer
#let prep = comps.map(c => {
  let (w, mx, my, s11, s12, s22) = c
  let det = s11 * s22 - s12 * s12
  (mx: mx, my: my,
   i11: s22 / det, i12: -s12 / det, i22: s11 / det,
   norm: w / (2 * calc.pi * calc.sqrt(det)))
})
#let dens(x, y) = {
  let t = 0.0
  for c in prep {
    let dx = x - c.mx
    let dy = y - c.my
    let q = c.i11 * dx * dx + 2 * c.i12 * dx * dy + c.i22 * dy * dy
    t += c.norm * calc.exp(-0.5 * q)
  }
  t
}

// ── seeded RW-Metropolis run  (σ = 1.15) ───────────────────────────────────────
//   each step: (from_x, from_y, prop_x, prop_y, accepted)
#let steps = (
  (-3.000, -2.400, -4.662, -2.132, false),
  (-3.000, -2.400, -2.894, -2.267, true ),
  (-2.894, -2.267, -3.209, -0.194, false),
  (-2.894, -2.267, -4.075, -3.142, false),
  (-2.894, -2.267, -2.137, -1.287, true ),
  (-2.137, -1.287, -1.804, -1.510, true ),
  (-1.804, -1.510, -0.240, -0.718, true ),
  (-0.240, -0.718, -2.066,  0.529, true ),
  (-2.066,  0.529,  0.304,  1.480, true ),
  ( 0.304,  1.480,  3.158,  3.316, false),
  ( 0.304,  1.480,  1.221,  2.264, true ),
  ( 1.221,  2.264,  0.607,  3.745, false),
  ( 1.221,  2.264,  1.099,  1.911, true ),
  ( 1.099,  1.911,  1.565,  0.846, true ),
  ( 1.565,  0.846,  0.487,  0.103, false),
  ( 1.565,  0.846,  3.383,  1.198, false),
)

// ── world → canvas mapping ──────────────────────────────────────────────────────
#let X0 = -5.2
#let X1 = 4.6
#let Y0 = -3.9
#let Y1 = 4.3
#let PW = 9.4
#let PH = 7.85
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── plot frame ────────────────────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)
  // light interior grid (every world unit)
  for gx in range(-5, 5) {
    if gx > -5 { line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c) }
  }
  for gy in range(-3, 5) {
    if gy > -3 { line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c) }
  }

  // ── filled density contours via marching-squares level sets ───────────────────
  //   sample dens on a grid, then draw each cell's iso-segment at fixed levels.
  let GN = 120                       // grid resolution
  let gxs = range(GN + 1).map(i => X0 + (X1 - X0) * i / GN)
  let gys = range(GN + 1).map(j => Y0 + (Y1 - Y0) * j / GN)
  let grid = gys.map(yy => gxs.map(xx => dens(xx, yy)))

  // density levels (low → high); inner rings are denser
  let levels = (0.006, 0.018, 0.038, 0.064, 0.094)
  // light garnet shading: deeper fill toward higher density
  let shades = (
    fillc.transparentize(95%),
    fillc.transparentize(91%),
    fillc.transparentize(86%),
    fillc.transparentize(80%),
    fillc.transparentize(73%),
  )

  // interpolate crossing point on an edge between (xa,va)-(xb,vb) at level L
  let lerp(a, b, va, vb, L) = a + (b - a) * (L - va) / (vb - va)

  // marching squares: emit line segments for one level over the grid
  let iso-segments(L) = {
    let segs = ()
    for j in range(GN) {
      for i in range(GN) {
        let x0 = gxs.at(i)
        let x1 = gxs.at(i + 1)
        let y0 = gys.at(j)
        let y1 = gys.at(j + 1)
        let v00 = grid.at(j).at(i)
        let v10 = grid.at(j).at(i + 1)
        let v11 = grid.at(j + 1).at(i + 1)
        let v01 = grid.at(j + 1).at(i)
        // case index from corner signs (>= L)
        let c = 0
        if v00 >= L { c += 1 }
        if v10 >= L { c += 2 }
        if v11 >= L { c += 4 }
        if v01 >= L { c += 8 }
        if c == 0 or c == 15 { continue }
        // edge crossings (bottom, right, top, left)
        let eB = (lerp(x0, x1, v00, v10, L), y0)
        let eR = (x1, lerp(y0, y1, v10, v11, L))
        let eT = (lerp(x0, x1, v01, v11, L), y1)
        let eL = (x0, lerp(y0, y1, v00, v01, L))
        // connect crossings per standard MS case table (ambiguous 5/10 split)
        let pairs = ()
        if c == 1 or c == 14 { pairs = ((eL, eB),) }
        else if c == 2 or c == 13 { pairs = ((eB, eR),) }
        else if c == 3 or c == 12 { pairs = ((eL, eR),) }
        else if c == 4 or c == 11 { pairs = ((eT, eR),) }
        else if c == 6 or c == 9  { pairs = ((eB, eT),) }
        else if c == 7 or c == 8  { pairs = ((eL, eT),) }
        else if c == 5  { pairs = ((eL, eT), (eB, eR)) }
        else if c == 10 { pairs = ((eL, eB), (eT, eR)) }
        for p in pairs { segs.push(p) }
      }
    }
    segs
  }

  // draw contour rings (light, sharp) for each level
  for (k, L) in levels.enumerate() {
    let segs = iso-segments(L)
    let sw = if k == levels.len() - 1 { 1.2pt } else { 0.7pt }
    for (p, q) in segs {
      line((sx(p.at(0)), sy(p.at(1))), (sx(q.at(0)), sy(q.at(1))),
        stroke: sw + cont-c)
    }
  }

  // mode markers (×) at the two component means, drawn faint behind the chain
  for c in comps {
    let mx = c.at(1)
    let my = c.at(2)
    let h = 0.13
    line((sx(mx) - h, sy(my) - h), (sx(mx) + h, sy(my) + h), stroke: 1pt + faint)
    line((sx(mx) - h, sy(my) + h), (sx(mx) + h, sy(my) - h), stroke: 1pt + faint)
  }
  content((sx(comps.at(0).at(1)), sy(comps.at(0).at(2)) - 0.42), anchor: "north",
    text(size: 7pt, fill: faint, style: "italic")[mode 1])
  content((sx(comps.at(1).at(1)) + 0.30, sy(comps.at(1).at(2)) + 0.34), anchor: "south-west",
    text(size: 7pt, fill: faint, style: "italic")[mode 2])

  // ── rejected proposals: dashed blue arrow + open ○ marker + ✗ ─────────────────
  //   drawn first so the accepted chain (garnet) reads on top.
  for s in steps {
    let (fx, fy, px, py, acc) = s
    if acc { continue }
    let a = (sx(fx), sy(fy))
    let b = (sx(px), sy(py))
    line(a, b, stroke: (paint: blue, thickness: 0.8pt, dash: "dashed"),
      mark: (end: "stealth", fill: blue, scale: 0.42))
    // open circle at the discarded proposal
    circle(b, radius: 0.105, fill: white, stroke: 0.9pt + blue)
    // small ✗ inside-ish (offset)
    let h = 0.075
    line((b.at(0) - h, b.at(1) - h), (b.at(0) + h, b.at(1) + h), stroke: 0.7pt + blue)
    line((b.at(0) - h, b.at(1) + h), (b.at(0) + h, b.at(1) - h), stroke: 0.7pt + blue)
  }

  // ── accepted moves: solid garnet step + filled ● state ────────────────────────
  // build the ordered list of visited (accepted) states
  let visited = (steps.at(0).at(0), steps.at(0).at(1))
  let path = ((steps.at(0).at(0), steps.at(0).at(1)),)
  for s in steps {
    if s.at(4) {
      path.push((s.at(2), s.at(3)))
    }
  }
  // solid step arrows between consecutive accepted states
  for i in range(path.len() - 1) {
    let p = (sx(path.at(i).at(0)),     sy(path.at(i).at(1)))
    let q = (sx(path.at(i + 1).at(0)), sy(path.at(i + 1).at(1)))
    line(p, q, stroke: 1.3pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.5))
  }
  // filled state markers (skip the start; drawn separately)
  for i in range(1, path.len()) {
    let p = (sx(path.at(i).at(0)), sy(path.at(i).at(1)))
    circle(p, radius: 0.115, fill: garnet, stroke: 0.6pt + garnet)
  }

  // ── start state x⁽⁰⁾ (ringed) ─────────────────────────────────────────────────
  let s0 = (sx(path.at(0).at(0)), sy(path.at(0).at(1)))
  circle(s0, radius: 0.16, fill: white, stroke: 1.4pt + ink)
  circle(s0, radius: 0.07, fill: ink, stroke: none)
  content((s0.at(0) - 0.20, s0.at(1) + 0.10), anchor: "east",
    text(size: 8pt, fill: ink)[$bold(x)^((0))$])

  // ── final state label x⁽ᵀ⁾ ────────────────────────────────────────────────────
  let sT = path.at(path.len() - 1)
  content((sx(sT.at(0)) + 0.26, sy(sT.at(1)) - 0.10), anchor: "west",
    box(fill: white.transparentize(12%), inset: 1.2pt,
      text(size: 8pt, fill: garnet)[$bold(x)^((T))$]))

  // annotate one accept and one reject inline (white plates for legibility)
  // accept event: tag the long uphill move into the valley crossing
  content((sx(-3.55), sy(0.55)), anchor: "west",
    box(fill: white.transparentize(8%), inset: 1.8pt, stroke: 0.3pt + garnet.transparentize(40%),
      text(size: 6.5pt, fill: garnet)[uphill: always accept]))
  // reject event: a proposal flung past the right mode is discarded
  content((sx(2.55), sy(3.62)), anchor: "east",
    box(fill: white.transparentize(8%), inset: 1.8pt, stroke: 0.3pt + blue.transparentize(40%),
      text(size: 6.5pt, fill: blue)[reject $arrow.r$ stay put]))

  // ── axis ticks + labels ────────────────────────────────────────────────────────
  for gx in range(-5, 5) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    if calc.rem(gx, 2) == 0 {
      content((sx(gx), -0.34), text(size: 7pt, fill: muted)[#gx])
    }
  }
  for gy in range(-3, 5) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    if calc.rem(gy, 2) == 0 {
      content((-0.32, sy(gy)), text(size: 7pt, fill: muted)[#gy])
    }
  }
  content((PW / 2, -0.78), text(size: 9pt, fill: ink)[$x_1$])
  content((-0.96, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title + defining rule ──────────────────────────────────────────────────────
  content((PW / 2, PH + 1.18),
    text(size: 11pt, weight: "bold", fill: ink)[MCMC sampling over a density — random-walk Metropolis])
  content((PW / 2, PH + 0.64),
    text(size: 8.5pt, fill: ink)[propose $bold(x)' tilde cal(N)(bold(x)^((t)), sigma^2 bold(I))$, #h(0.4em) accept w.p. $alpha = min(1, p(bold(x)') \/ p(bold(x)^((t))))$])
  content((PW / 2, PH + 0.24),
    text(size: 7.5pt, fill: muted)[target $p(bold(x)) prop exp(-E(bold(x)))$ — a bimodal mixture; the chain crosses the low-density valley])

  // ── side legend ─────────────────────────────────────────────────────────────────
  let lx = PW + 0.62
  let ly = PH - 0.25

  // accepted move
  line((lx, ly), (lx + 0.72, ly), stroke: 1.3pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.5))
  circle((lx + 0.72, ly), radius: 0.115, fill: garnet, stroke: 0.6pt + garnet)
  content((lx + 1.0, ly), anchor: "west", text(size: 8pt, weight: "bold", fill: garnet)[accepted move])
  content((lx, ly - 0.38), anchor: "west", text(size: 7pt, fill: muted)[chain advances: $bold(x)^((t+1)) = bold(x)'$])

  // rejected proposal
  let ry = ly - 1.15
  line((lx, ry), (lx + 0.72, ry), stroke: (paint: blue, thickness: 0.8pt, dash: "dashed"),
    mark: (end: "stealth", fill: blue, scale: 0.42))
  circle((lx + 0.72, ry), radius: 0.105, fill: white, stroke: 0.9pt + blue)
  let hh = 0.075
  line((lx + 0.72 - hh, ry - hh), (lx + 0.72 + hh, ry + hh), stroke: 0.7pt + blue)
  line((lx + 0.72 - hh, ry + hh), (lx + 0.72 + hh, ry - hh), stroke: 0.7pt + blue)
  content((lx + 1.0, ry), anchor: "west", text(size: 8pt, weight: "bold", fill: blue)[rejected proposal])
  content((lx, ry - 0.38), anchor: "west", text(size: 7pt, fill: muted)[discarded: $bold(x)^((t+1)) = bold(x)^((t))$])

  // start state key
  let ky = ry - 1.15
  circle((lx + 0.16, ky), radius: 0.16, fill: white, stroke: 1.4pt + ink)
  circle((lx + 0.16, ky), radius: 0.07, fill: ink, stroke: none)
  content((lx + 1.0, ky), anchor: "west", text(size: 8pt, fill: ink)[start $bold(x)^((0))$])

  // density key
  let dy = ky - 0.78
  rect((lx, dy - 0.13), (lx + 0.32, dy + 0.13), fill: fillc.transparentize(70%), stroke: 0.7pt + cont-c)
  content((lx + 1.0, dy), anchor: "west", text(size: 8pt, fill: ink)[target $p(bold(x))$])
  content((lx, dy - 0.40), anchor: "west", text(size: 7pt, fill: muted)[contours = iso-density])

  // tally
  let ty = dy - 1.0
  content((lx, ty), anchor: "north-west",
    text(size: 7.5pt, fill: ink)[run: 16 proposals])
  content((lx, ty - 0.42), anchor: "north-west",
    text(size: 7.5pt, fill: garnet)[9 accepted])
  content((lx, ty - 0.80), anchor: "north-west",
    text(size: 7.5pt, fill: blue)[7 rejected])
  content((lx, ty - 1.34), anchor: "north-west",
    text(size: 7pt, fill: muted, style: "italic")[$arrow.r$ samples concentrate])
  content((lx, ty - 1.70), anchor: "north-west",
    text(size: 7pt, fill: muted, style: "italic")[where $p(bold(x))$ is large])
})
