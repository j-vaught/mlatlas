// mlatlas · Alpha-vectors & the PWLC POMDP value function (Kochenderfer, DMU/AFDM).
//
// For a POMDP, the optimal value function over the belief simplex is
// PIECEWISE-LINEAR and CONVEX (PWLC). With |S| = 2 states, a belief is fully
// described by a single scalar  b = P(s = s₁) ∈ [0,1]  (x-axis); b = 0 puts all
// mass on s₀, b = 1 puts all mass on s₁. Each alpha-vector α is a hyperplane —
// here a straight line —
//
//     V_α(b) = (1 − b)·α(s₀) + b·α(s₁),
//
// tied to one action a. The value function is the UPPER ENVELOPE of these lines:
//
//     V*(b) = max_α  V_α(b)            (max of linear → piecewise-linear convex).
//
// Each linear segment of the envelope is contributed by one dominant alpha-vector
// and so names the best action over that slice of belief space. The breakpoints
// partition [0,1] into ACTION REGIONS — the induced (greedy) policy.
//
// Lines are closed-form and sampled in Typst, then drawn in cetz (print-first
// house style: light panel, dark ink, sharp corners, garnet envelope accent).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ───────────────────────────────────────────────────────────────
  let ink     = rgb("#1A1A1A")
  let axiscol = rgb("#363636")
  let muted   = rgb("#5C5C5C")
  let faint   = rgb("#A2A2A2")
  let grid    = rgb("#ECECEC")
  let garnet  = rgb("#73000A")   // value function V*(b) = upper envelope (focal)
  let blue    = rgb("#466A9F")
  let green   = rgb("#65780B")
  let redx    = rgb("#CC2E40")
  let brown   = rgb("#A49137")
  let beige   = rgb("#FFF2E3")

  // ── plot frame in cetz units ──────────────────────────────────────────────
  // belief b ∈ [0,1] on x; value v on y, mapped to the panel box.
  let W  = 9.8           // panel width  (cm)
  let H  = 6.4           // panel height (cm)
  let x0 = 0
  let y0 = 0
  let N  = 200           // samples along b

  // value range shown on the y-axis
  let vlo = 0.0
  let vhi = 10.0
  let X(b) = x0 + b * W
  let Y(v) = y0 + ((v - vlo) / (vhi - vlo)) * H

  // ── alpha-vectors : (label, action-name, color, α(s₀), α(s₁)) ─────────────
  // Each line V_α(b) = (1−b)·a0 + b·a1.  Coefficients chosen so that THREE of
  // the four vectors each dominate over a distinct slice of belief, while the
  // fourth (a3) is everywhere dominated (pruned — never part of the envelope).
  let avecs = (
    (name: [$alpha_1$], act: [$a_1$], col: blue,  a0: 9.2, a1: 1.0),
    (name: [$alpha_2$], act: [$a_2$], col: green, a0: 6.4, a1: 6.6),
    (name: [$alpha_3$], act: [$a_3$], col: redx,  a0: 1.0, a1: 9.4),
    (name: [$alpha_4$], act: [], col: brown, a0: 3.3, a1: 3.1),  // dominated
  )
  let vval(av, b) = (1 - b) * av.a0 + b * av.a1

  // upper envelope value at belief b
  let env(b) = {
    let m = -1e9
    for av in avecs { let v = vval(av, b); if v > m { m = v } }
    m
  }
  // index of the dominant alpha-vector at belief b
  let argmax-idx(b) = {
    let m = -1e9
    let idx = 0
    for i in range(avecs.len()) {
      let v = vval(avecs.at(i), b)
      if v > m { m = v; idx = i }
    }
    idx
  }

  // ── find region breakpoints (where the dominant vector changes) ───────────
  // Scan a fine grid; record b where argmax flips → region boundaries.
  let bps = ()
  let prev = argmax-idx(0.0)
  let regs = ()                 // (b-left, b-right, dominant-idx)
  let bstart = 0.0
  for i in range(1, N + 1) {
    let b = i / N
    let cur = argmax-idx(b)
    if cur != prev {
      // boundary between samples (i-1)/N and i/N — refine by bisection.
      let lo = (i - 1) / N
      let hi = i / N
      for _ in range(40) {
        let mid = (lo + hi) / 2
        if argmax-idx(mid) == prev { lo = mid } else { hi = mid }
      }
      let bb = (lo + hi) / 2
      bps.push(bb)
      regs.push((bstart, bb, prev))
      bstart = bb
      prev = cur
    }
  }
  regs.push((bstart, 1.0, prev))

  // region shade tints (light, low-saturation washes behind the envelope)
  let region-fill = (
    blue.lighten(82%),
    green.lighten(82%),
    redx.lighten(82%),
    brown.lighten(82%),
  )

  // ── panel background + faint grid ─────────────────────────────────────────
  rect((X(0), Y(vlo)), (X(1), Y(vhi)), fill: white, stroke: none)

  // ── shaded action regions (vertical bands under the envelope) ─────────────
  for r in regs {
    let (bl, br, idx) = r
    rect(
      (X(bl), Y(vlo)), (X(br), Y(vhi)),
      fill: region-fill.at(idx), stroke: none,
    )
  }
  // horizontal gridlines (light, over the bands)
  for k in range(1, 5) {
    let v = vlo + (vhi - vlo) * k / 5
    line((X(0), Y(v)), (X(1), Y(v)), stroke: 0.4pt + grid)
  }
  // dashed vertical separators at the breakpoints
  for bb in bps {
    line(
      (X(bb), Y(vlo)), (X(bb), Y(vhi)),
      stroke: (paint: faint, dash: "dashed", thickness: 0.6pt),
    )
  }

  // ── the alpha-vector lines (full lines, thin) ─────────────────────────────
  for av in avecs {
    let dom = av.act != []
    line(
      (X(0), Y(vval(av, 0.0))), (X(1), Y(vval(av, 1.0))),
      stroke: (
        paint: av.col,
        thickness: if dom { 1.2pt } else { 1.1pt },
        dash: if dom { none } else { "dotted" },
      ),
    )
  }

  // ── upper envelope V*(b) — sampled polyline, garnet, thick (focal) ────────
  let env-pts = range(N + 1).map(i => {
    let b = i / N
    (X(b), Y(env(b)))
  })
  line(..env-pts, stroke: (paint: garnet, thickness: 2.4pt))

  // breakpoint kinks: small garnet dots where segments meet
  for bb in bps {
    circle((X(bb), Y(env(bb))), radius: 0.075, fill: garnet, stroke: 0.5pt + white)
  }

  // ── alpha-vector labels at the right edge of each line ────────────────────
  for av in avecs {
    content(
      (X(1.0) + 0.16, Y(vval(av, 1.0))),
      text(fill: av.col, size: 8.5pt)[#av.name],
      anchor: "west",
    )
  }

  // ── action-region labels + braces along the bottom ────────────────────────
  for r in regs {
    let (bl, br, idx) = r
    let mid = (bl + br) / 2
    let act = avecs.at(idx).act
    // action name inside the band, near the top
    content(
      (X(mid), Y(vhi) - 0.30),
      text(fill: avecs.at(idx).col, size: 8.5pt, weight: "bold")[#act],
      anchor: "north",
    )
    // tick + region span just below the axis
    line((X(bl), Y(vlo)), (X(bl), Y(vlo) - 0.12), stroke: 0.8pt + axiscol)
    line((X(br), Y(vlo)), (X(br), Y(vlo) - 0.12), stroke: 0.8pt + axiscol)
    line(
      (X(bl) + 0.05, Y(vlo) - 0.30), (X(br) - 0.05, Y(vlo) - 0.30),
      stroke: 0.7pt + muted, mark: (start: "|", end: "|", scale: 0.35),
    )
    content(
      (X(mid), Y(vlo) - 0.30),
      box(fill: white, inset: (x: 2pt))[#text(fill: muted, size: 7pt)[do #act]],
    )
  }

  // ── label for the envelope curve (with a leader to the garnet line) ───────
  // placed in open space below-left of the descending a₁ segment.
  let blab = 0.115
  let lab-anchor = (X(blab) + 0.30, Y(env(blab)) - 1.55)
  content(
    lab-anchor,
    box(fill: white, inset: (x: 1pt))[#text(fill: garnet, size: 9.5pt, weight: "bold")[$V^*(b)$]],
    anchor: "north",
  )
  content(
    (lab-anchor.at(0), lab-anchor.at(1) - 0.40),
    box(fill: white, inset: (x: 1pt))[#text(fill: garnet, size: 7pt)[upper envelope]],
    anchor: "north",
  )
  line(
    (X(blab), Y(env(blab))), (lab-anchor.at(0), lab-anchor.at(1) + 0.02),
    stroke: 0.6pt + garnet, mark: (start: "o", scale: 0.18),
  )

  // dominated-vector callout (placed under the α₄ line, away from the envelope)
  let bd = 0.30
  content(
    (X(bd), Y(vval(avecs.at(3), bd)) - 0.16),
    box(fill: white, inset: (x: 1.5pt))[#text(fill: brown, size: 6.8pt, style: "italic")[$alpha_4$: dominated (pruned)]],
    anchor: "north-west",
  )

  // ── axes (drawn last) ─────────────────────────────────────────────────────
  line((X(0), Y(vlo)), (X(0), Y(vhi) + 0.05), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))
  line((X(0), Y(vlo)), (X(1) + 0.05, Y(vlo)), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))

  // x ticks at the simplex endpoints
  content((X(0), Y(vlo) - 0.96), text(fill: ink, size: 8pt)[$b = 0$], anchor: "north")
  content((X(0), Y(vlo) - 1.34), text(fill: faint, size: 6.8pt)[($P(s_0) = 1$)], anchor: "north")
  content((X(1), Y(vlo) - 0.96), text(fill: ink, size: 8pt)[$b = 1$], anchor: "north")
  content((X(1), Y(vlo) - 1.34), text(fill: faint, size: 6.8pt)[($P(s_1) = 1$)], anchor: "north")

  // axis titles
  content(
    (X(0.5), Y(vlo) - 1.86),
    text(fill: ink, size: 9.5pt)[belief #h(0.2em) $b = P(s = s_1)$ #h(0.4em) #text(fill: faint, size: 7.5pt)[(belief simplex, $|S| = 2$)]],
    anchor: "north",
  )
  content(
    (X(0) - 0.66, Y((vlo + vhi) / 2 / vhi * vhi)),
    angle: 90deg,
    text(fill: ink, size: 9.5pt)[value #h(0.2em) $V(b)$],
    anchor: "south",
  )
})
