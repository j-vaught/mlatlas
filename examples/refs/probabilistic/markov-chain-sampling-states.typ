// Markov-chain (MCMC) sampling — state diagram.
//   A finite Markov chain whose states are the sampler's discrete positions
//   s ∈ {s1,s2,s3}. Directed transition edges s→s' carry the Metropolis–Hastings
//   move probability T(s'|s) = q(s'|s)·α(s,s'), with acceptance
//   α(s,s') = min(1, π(s')q(s|s')/π(s)q(s'|s)). Each state also has a SELF-LOOP
//   T(s|s) — the lump of probability from REJECTED proposals (the chain stays put).
//   Run long enough the chain forgets where it started and the fraction of time
//   spent in each state converges to the target π (detailed balance:
//   π(s)T(s'|s) = π(s')T(s|s)). The state-graph counterpart to the geometric
//   "mcmc-sampling-density" view.
//
// Standard teaching figure (Bishop §11; Goodfellow et al. §17), built from first
// principles in mlatlas's print-first house style. Not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ───────────────────────────────────────────────────────────
#let garnet = rgb("#73000A") // sparse accent — focal state / accepted move
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let edge   = rgb("#363636")
#let statef = rgb("#ECECEC") // 10% black — state fill
#let focalf = rgb("#FFF2E3") // beige — focal state fill
#let barf   = rgb("#C7C7C7") // 30% black — empirical bars
#let blue   = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let rs = 0.66 // state circle radius

  // ── helpers ─────────────────────────────────────────────────────────────
  let uvec(a, b) = {
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let l = calc.sqrt(dx * dx + dy * dy)
    (dx / l, dy / l)
  }
  let along(p, u, d) = (p.at(0) + u.at(0) * d, p.at(1) + u.at(1) * d)

  // state node: shaded circle with a math label and a small π weight underneath
  let state(p, lbl, pi, focal: false) = {
    circle(p, radius: rs, fill: if focal { focalf } else { statef },
      stroke: (paint: if focal { garnet } else { edge },
               thickness: if focal { 1.9pt } else { 1.2pt }))
    content((p.at(0), p.at(1) + 0.12), text(size: 12pt, fill: ink)[#lbl])
    content((p.at(0), p.at(1) - 0.26),
      text(size: 7.5pt, fill: if focal { garnet } else { muted })[#pi])
  }

  let arr(a, b, accent: false, thick: 1.1pt) = {
    line(a, b, stroke: (paint: if accent { garnet } else { edge }, thickness: thick),
      mark: (end: "stealth", scale: 0.8, fill: if accent { garnet } else { edge }))
  }

  // a curved directed transition s→t, bowed sideways so the two opposite-direction
  // edges between a pair don't overlap. dir = +1 bows left of travel, -1 right.
  // The probability tag sits at the apex, nudged by tag-off.
  // `normal` (a world-space unit vector) fixes the bow side regardless of travel
  // direction, so both arrows of a pair can bow to the SAME outer side.
  let trans(s, t, lbl, bow: 0.9, dir: 1, normal: none, accent: false,
            tag-off: (0.0, 0.0), tag-anchor: "center", tag-margin: 0.42) = {
    let u = uvec(s, t)
    let a = along(s, u, rs)
    let b = along(t, u, -rs)
    let mx = (a.at(0) + b.at(0)) / 2
    let my = (a.at(1) + b.at(1)) / 2
    // bow normal: explicit world-space side if given, else perpendicular to travel
    let nx = if normal == none { -u.at(1) * dir } else { normal.at(0) }
    let ny = if normal == none { u.at(0) * dir } else { normal.at(1) }
    let c = (mx + nx * bow, my + ny * bow)
    line(a, c, b,
      stroke: (paint: if accent { garnet } else { edge },
               thickness: if accent { 1.6pt } else { 1.1pt }),
      mark: (end: "stealth", scale: 0.8, fill: if accent { garnet } else { edge }))
    // place the label just BEYOND the apex along the same perpendicular, so it
    // always sits on the outer side of its own arc
    let lp = (c.at(0) + nx * tag-margin + tag-off.at(0),
              c.at(1) + ny * tag-margin + tag-off.at(1))
    content(lp, anchor: tag-anchor,
      text(size: 7.5pt, fill: if accent { garnet } else { muted })[#lbl])
  }

  // self-loop hanging off the rim of state at p in a chosen direction (degrees),
  // representing the rejected-proposal "stay" probability.
  let selfloop(p, ang, lbl, lbl-anchor: "center", lbl-off: (0.0, 0.0)) = {
    let a = ang * calc.pi / 180
    let dirx = (calc.cos(a), calc.sin(a))
    let lr = 0.36
    // hug the node: loop centre just outside the rim
    let lc = (p.at(0) + dirx.at(0) * (rs + lr - 0.06), p.at(1) + dirx.at(1) * (rs + lr - 0.06))
    let n = 30
    // sweep the ~290° arc that faces AWAY from the node (through the outward
    // direction `ang`), leaving a ~70° gap toward the node where it attaches
    let a-start = ang - 145
    let a-end   = ang + 145
    let pts = range(n + 1).map(i => {
      let t = (a-start + (a-end - a-start) * i / n) * calc.pi / 180
      (lc.at(0) + lr * calc.cos(t), lc.at(1) + lr * calc.sin(t))
    })
    line(..pts, stroke: (paint: edge, thickness: 1.0pt),
      mark: (end: "stealth", scale: 0.7, fill: edge))
    let lp = (lc.at(0) + dirx.at(0) * (lr + 0.10) + lbl-off.at(0),
              lc.at(1) + dirx.at(1) * (lr + 0.10) + lbl-off.at(1))
    content(lp, anchor: lbl-anchor, text(size: 7pt, fill: muted)[#lbl])
  }

  // ════════════════════════════════════════════════════════════════════════
  //  TOP — the Markov-chain state graph
  // ════════════════════════════════════════════════════════════════════════
  // three states in a triangle (wide, low triangle leaves room for self-loops
  // pointing into empty space on each outer side)
  let S1 = (1.2, 6.7)
  let S2 = (8.0, 7.5)
  let S3 = (4.8, 5.0)

  // transition edges. The two arrows of each pair bow to OPPOSITE sides (dir =
  // +1 / -1) so their apexes — and thus their labels — sit on opposite sides of
  // the connecting line and never overlap. Each label rides its own arc's apex.
  // Both arrows of a pair bow to the SAME (outer) world-space side, NESTED at
  // different depths so they read as two distinct arcs, labels stacked on the
  // outer side. This keeps the triangle interior completely clear.
  let n-top   = (0.0, 1.0)      // top edge bows UP
  let n-right = (0.97, -0.24)   // right edge bows RIGHT (slightly down, clears s2)
  let n-left  = (-0.97, -0.10)  // left edge bows LEFT
  // s1 <-> s2  (top edge): outer arc + inner arc, labels above
  trans(S1, S2, [$T(s_2|s_1)$], bow: 1.35, normal: n-top, tag-anchor: "south",
        tag-margin: 0.16)
  trans(S2, S1, [$T(s_1|s_2)$], bow: 0.62, normal: n-top, tag-anchor: "north",
        tag-margin: -0.16)
  // s2 <-> s3  (right edge — ACCEPTED focal move s2->s3 in garnet): outer garnet
  // arc + inner arc, labels to the right
  trans(S2, S3, [$T(s_3|s_2)$], bow: 1.30, normal: n-right, accent: true,
        tag-anchor: "west", tag-margin: 0.16, tag-off: (0.06, 0.0))
  trans(S3, S2, [$T(s_2|s_3)$], bow: 0.62, normal: n-right, tag-anchor: "east",
        tag-margin: -0.16, tag-off: (-0.04, 0.0))
  // s3 <-> s1  (left edge): outer arc + inner arc, labels to the left
  trans(S3, S1, [$T(s_1|s_3)$], bow: 1.30, normal: n-left, tag-anchor: "east",
        tag-margin: 0.16)
  trans(S1, S3, [$T(s_3|s_1)$], bow: 0.60, normal: n-left, tag-anchor: "west",
        tag-margin: -0.16)

  // self-loops (rejected proposals — "chain stays put"), each pointing outward
  // into the open side of the triangle
  selfloop(S1, 178, [$T(s_1|s_1)$], lbl-anchor: "east", lbl-off: (-0.06, 0.0))
  selfloop(S2,  10, [$T(s_2|s_2)$], lbl-anchor: "west", lbl-off: (0.06, 0.0))
  selfloop(S3, -90, [$T(s_3|s_3)$], lbl-anchor: "north", lbl-off: (0.0, -0.04))

  // states on top (s3 is the focal accepted-into target mode)
  state(S1, [$s_1$], [$pi_1$])
  state(S2, [$s_2$], [$pi_2$])
  state(S3, [$s_3$], [$pi_3$], focal: true)

  // section heading + the move/acceptance definition
  content((-1.2, 10.15), anchor: "west",
    text(size: 11.5pt, weight: "bold", fill: ink)[Markov chain over sampler states])
  content((-1.2, 9.62), anchor: "west", text(size: 8pt, fill: muted)[
    transition $T(s' | s) = q(s' | s) thin alpha(s, s')$,
    accept $alpha(s, s') = min(1, thin (pi(s') thin q(s | s')) / (pi(s) thin q(s' | s)))$
  ])
  content((-1.2, 9.18), anchor: "west", text(size: 8pt, fill: muted)[
    self-loop $T(s | s)$ collects the probability of REJECTED proposals (chain stays)
  ])

  // ── divider ──────────────────────────────────────────────────────────────
  line((-1.5, 2.95), (12.9, 2.95),
    stroke: (paint: rgb("#C7C7C7"), thickness: 0.7pt, dash: "dotted"))

  // ════════════════════════════════════════════════════════════════════════
  //  BOTTOM-LEFT — a realized sample trajectory s^(0), s^(1), … wandering
  // ════════════════════════════════════════════════════════════════════════
  let bx = -0.7       // left edge of trajectory panel
  let bw = 6.6        // width
  let by = 0.4        // baseline (state row s1)
  let row = 0.95      // vertical gap between state rows
  let T = 13          // number of drawn iterations
  // the realized chain (0-based state index per iteration); repeats = rejections
  let chain = (0, 0, 1, 2, 2, 2, 0, 1, 2, 2, 1, 2, 2)
  let stepx = bw / (T - 1)
  let cx(t) = bx + t * stepx
  let cy(k) = by + k * row
  let nr = 0.18       // small node radius

  // faint horizontal guide rows for each state
  for k in range(3) {
    line((bx - 0.25, cy(k)), (bx + bw + 0.25, cy(k)),
      stroke: (paint: rgb("#ECECEC"), thickness: 0.7pt))
    content((bx - 0.42, cy(k)), anchor: "east",
      text(size: 8pt, fill: muted)[$s_#(k + 1)$])
  }

  // trajectory poly-line with small nodes; rejected (horizontal, same-state) steps
  // are drawn lighter to read as "stayed put"
  for t in range(T - 1) {
    let a = (cx(t), cy(chain.at(t)))
    let b = (cx(t + 1), cy(chain.at(t + 1)))
    let stayed = chain.at(t) == chain.at(t + 1)
    line(a, b, stroke: (paint: if stayed { rgb("#A2A2A2") } else { blue },
      thickness: if stayed { 1.0pt } else { 1.4pt }))
  }
  for t in range(T) {
    circle((cx(t), cy(chain.at(t))), radius: nr, fill: blue,
      stroke: (paint: edge, thickness: 0.6pt))
  }

  // iteration axis
  let axisY = by - 0.78
  arr((bx - 0.25, axisY), (bx + bw + 0.45, axisY), thick: 1.1pt)
  content((bx + bw + 0.6, axisY), anchor: "west",
    text(size: 8.5pt, fill: ink)[iteration $t$])
  content((bx + bw * 0.5, axisY - 0.40), anchor: "north",
    text(size: 7pt, fill: muted)[flat segments = rejections (self-loop)])

  content((bx - 0.42, cy(2) + 0.78), anchor: "west",
    text(size: 9.5pt, weight: "bold", fill: ink)[Realized trajectory $s^((0)), s^((1)), dots$])

  // ════════════════════════════════════════════════════════════════════════
  //  BOTTOM-RIGHT — empirical occupancy converges to the target π
  // ════════════════════════════════════════════════════════════════════════
  let hx = 8.4        // left edge of histogram panel
  let hbase = 0.4     // baseline
  let hgap = 1.25     // spacing between the three state bars
  let hbw = 0.46      // bar half-width
  let hscale = 3.1    // pixels(cm) per unit prob
  let target = (0.50, 0.20, 0.30)   // target π over s1,s2,s3
  let emp    = (0.46, 0.24, 0.30)   // empirical frequency from the run
  let labels = ([$s_1$], [$s_2$], [$s_3$])

  // baseline + y ticks
  line((hx - 0.5, hbase), (hx + 3 * hgap - 0.2, hbase),
    stroke: (paint: edge, thickness: 1.0pt))
  for v in (0.0, 0.25, 0.5) {
    let yy = hbase + v * hscale
    line((hx - 0.5, yy), (hx - 0.40, yy), stroke: (paint: muted, thickness: 0.8pt))
    content((hx - 0.55, yy), anchor: "east", text(size: 7pt, fill: muted)[#v])
  }
  // y-axis line
  line((hx - 0.5, hbase), (hx - 0.5, hbase + 0.5 * hscale + 0.25),
    stroke: (paint: edge, thickness: 1.0pt))
  content((hx - 0.95, hbase + 0.28 * hscale), anchor: "center",
    text(size: 8pt, fill: ink)[#rotate(-90deg)[probability]])

  for i in range(3) {
    let cxi = hx + i * hgap
    // empirical bar (grey, solid)
    let he = emp.at(i) * hscale
    rect((cxi - hbw, hbase), (cxi + hbw, hbase + he),
      fill: barf, stroke: (paint: edge, thickness: 0.9pt), radius: 0pt)
    // target π marker (garnet line across the bar width)
    let ht = target.at(i) * hscale
    line((cxi - hbw - 0.12, hbase + ht), (cxi + hbw + 0.12, hbase + ht),
      stroke: (paint: garnet, thickness: 1.8pt))
    // state label under the bar
    content((cxi, hbase - 0.30), anchor: "north", text(size: 9pt, fill: ink)[#labels.at(i)])
  }

  content((hx - 0.6, hbase + 0.5 * hscale + 0.66), anchor: "west",
    text(size: 9.5pt, weight: "bold", fill: ink)[Empirical occupancy $arrow.r$ target $pi$])

  // mini legend to the RIGHT of the bars (clear column), vertically stacked
  let lx = hx + 2 * hgap + hbw + 0.55
  let ly = hbase + 0.42 * hscale
  // empirical swatch
  rect((lx, ly - 0.16), (lx + 0.34, ly + 0.16),
    fill: barf, stroke: (paint: edge, thickness: 0.9pt), radius: 0pt)
  content((lx + 0.46, ly), anchor: "west",
    text(size: 7.5pt, fill: ink)[empirical $hat(pi)_N (s)$])
  content((lx + 0.46, ly - 0.30), anchor: "west",
    text(size: 7pt, fill: muted)[(freq. from the run)])
  // target marker
  let ly2 = ly - 0.95
  line((lx - 0.02, ly2), (lx + 0.36, ly2), stroke: (paint: garnet, thickness: 1.8pt))
  content((lx + 0.46, ly2), anchor: "west",
    text(size: 7.5pt, fill: garnet)[target $pi(s)$])
  content((lx + 0.46, ly2 - 0.30), anchor: "west",
    text(size: 7pt, fill: muted)[(stationary dist.)])
})
