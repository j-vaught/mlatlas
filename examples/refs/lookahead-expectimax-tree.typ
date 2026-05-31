// Expectimax / online-planning lookahead tree — a STANDARD decision-making concept.
//
//   A finite-horizon lookahead tree that alternates two kinds of layer:
//     - DECISION (MAX) node  = SQUARE.  The agent controls the choice; it takes the
//       action whose child has the largest backed-up value.   v = max_a Q(a)
//     - CHANCE (EXPECTATION) node = CIRCLE.  Nature/the environment resolves the
//       outcome; the node's value is the probability-weighted average of its
//       children.   Q = sum_o p(o) * v(child_o)
//   LEAF values (from an evaluation function / horizon cutoff) are backed UP the tree:
//   expectations average, decisions maximise, until the root yields the value of the
//   best first action — exactly Expectimax / one online-planning lookahead.
//
//   Original mlatlas figure built from knowledge (Kochenderfer DMU; Sutton & Barto;
//   Russell & Norvig) in the print-first house style: light fills, dark text, sharp
//   orthogonal corners, stealth arrowheads, garnet as the sparse focal accent. The
//   bold garnet path is the chosen (argmax) action threaded from root to leaf.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let gline  = rgb("#C7C7C7")
#let panel  = rgb("#ECECEC")
#let beige  = rgb("#FFF2E3")
#let blue   = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ───────────────────────────── geometry ─────────────────────────────
  // layer y-coordinates (top = root decision, leaves at the bottom)
  let y0 = 9.0    // root  : DECISION (max)
  let y1 = 6.6    // chance: EXPECTATION
  let y2 = 4.2    // DECISION (max)
  let y3 = 1.8    // chance: EXPECTATION
  let y4 = -0.4   // leaves: evaluation-function values

  let hs = 0.42   // decision square half-side
  let cr = 0.40   // chance circle radius

  // glyph drawers — `on` => on the chosen (argmax) garnet path
  let decision(p, val, on: false, root: false) = {
    let sc = if on { 1.7pt + garnet } else { 1.25pt + ink }
    rect((p.at(0) - hs, p.at(1) - hs), (p.at(0) + hs, p.at(1) + hs),
         fill: if root { beige } else { panel }, stroke: sc, radius: 0pt)
    content(p, text(size: 8.5pt, fill: if on { garnet } else { ink },
                    weight: if on { "bold" } else { "regular" })[#val])
  }
  let chance(p, val, on: false) = {
    let sc = if on { 1.7pt + garnet } else { 1.25pt + ink }
    circle(p, radius: cr, fill: white, stroke: sc)
    content(p, text(size: 8.5pt, fill: if on { garnet } else { ink },
                    weight: if on { "bold" } else { "regular" })[#val])
  }
  // leaf: small evaluation value (rounded-free token)
  let leaf(p, val, on: false) = {
    rect((p.at(0) - 0.30, p.at(1) - 0.26), (p.at(0) + 0.30, p.at(1) + 0.26),
         fill: white, stroke: (if on { 1.3pt + garnet } else { 0.8pt + faint }), radius: 0pt)
    content(p, text(size: 8pt, fill: if on { garnet } else { muted },
                    weight: if on { "bold" } else { "regular" })[#val])
  }
  // edge between two layer points, trimmed to the glyph rims by `gap-a`,`gap-b`
  let edge(a, b, on: false, gap-a: hs, gap-b: cr) = {
    // unit direction a->b
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let L  = calc.sqrt(dx * dx + dy * dy)
    let ux = dx / L
    let uy = dy / L
    let p1 = (a.at(0) + ux * gap-a, a.at(1) + uy * gap-a)
    let p2 = (b.at(0) - ux * gap-b, b.at(1) - uy * gap-b)
    line(p1, p2, stroke: (if on { 1.7pt + garnet } else { 1.0pt + gline }))
  }

  // ───────────────────────── node coordinates ─────────────────────────
  // ROOT decision at center top
  let R = (4.5, y0)

  // layer-1 chance nodes (2 actions a1, a2 from root)
  let C = ((1.6, y1), (7.4, y1))           // C0 <- a1 (chosen), C1 <- a2

  // layer-2 decision nodes — 2 outcomes under each chance node
  let D = (
    (0.2, y2), (3.0, y2),                  // under C0
    (6.0, y2), (8.8, y2),                  // under C1
  )

  // layer-3 chance nodes — 1 action expanded per decision (the kept branch shown)
  let E = (
    (0.2, y3), (3.0, y3),
    (6.0, y3), (8.8, y3),
  )

  // layer-4 leaves — 2 outcomes per layer-3 chance node
  let leaf-x = (-0.55, 0.95,  2.25, 3.75,  5.25, 6.75,  8.05, 9.55)
  let Lp = leaf-x.map(x => (x, y4))

  // leaf evaluation values (from a heuristic / horizon cutoff)
  let lvals = (3, 9,  6, 2,  8, 4,  5, 1)
  // probabilities on the layer-3 -> leaf chance edges (pairs sum to 1)
  let lprob = (0.6, 0.4,  0.5, 0.5,  0.3, 0.7,  0.5, 0.5)

  // ── backed-up values (computed by hand from the leaves for honesty) ──
  // layer-3 expectations:  E = sum p*leaf
  //   E0 = .6*3 + .4*9 = 5.4    E1 = .5*6 + .5*2 = 4.0
  //   E2 = .3*8 + .7*4 = 5.2    E3 = .5*5 + .5*1 = 3.0
  let evals = (5.4, 4.0, 5.2, 3.0)
  // layer-2 decisions: max over its single expanded child here -> equals that child
  let dvals = (5.4, 4.0, 5.2, 3.0)
  // layer-1 chance (expectation over the 2 outcome decisions), p shown on edges
  //   C0: .5*5.4 + .5*4.0 = 4.7     C1: .5*5.2 + .5*3.0 = 4.1
  let cvals = (4.7, 4.1)
  // root decision: max(4.7, 4.1) = 4.7  -> choose a1  (the garnet path)
  let rootval = 4.7

  // probabilities on the layer-1 chance -> layer-2 decision edges
  let cprob = (0.5, 0.5,  0.5, 0.5)

  // ─────────────────────────── draw edges first ───────────────────────────
  // root -> chance (actions a1,a2).  a1 (index 0) is the chosen path.
  edge(R, C.at(0), on: true,  gap-a: hs, gap-b: cr)
  edge(R, C.at(1), on: false, gap-a: hs, gap-b: cr)

  // chance -> decision (outcomes).  on-path: C0 -> D0 then continue to E0/leaves
  for ci in range(2) {
    for k in range(2) {
      let di = ci * 2 + k
      let on = (ci == 0 and k == 0)        // chosen outcome thread (illustrative)
      edge(C.at(ci), D.at(di), on: on, gap-a: cr, gap-b: hs)
    }
  }
  // decision -> chance (the kept / expanded action). on-path through D0->E0
  for di in range(4) {
    let on = (di == 0)
    edge(D.at(di), E.at(di), on: on, gap-a: hs, gap-b: cr)
  }
  // chance -> leaves (outcomes). on-path: E0 -> leaf index 1 (value 9, the better)
  for ei in range(4) {
    for k in range(2) {
      let li = ei * 2 + k
      let on = (ei == 0 and k == 1)        // argmax leaf under chosen thread
      edge(E.at(ei), Lp.at(li), on: on, gap-a: cr, gap-b: 0.26)
    }
  }

  // ──────────────── probability / action labels on edges ────────────────
  // root action labels a1 / a2 (midpoints)
  content(((R.at(0) + C.at(0).at(0)) / 2 - 0.30, (y0 + y1) / 2 + 0.18),
          text(size: 8pt, fill: garnet, weight: "bold")[$a_1$])
  content(((R.at(0) + C.at(1).at(0)) / 2 + 0.30, (y0 + y1) / 2 + 0.18),
          text(size: 8pt, fill: muted)[$a_2$])

  // probabilities on chance->decision edges (layer 1)
  for ci in range(2) {
    for k in range(2) {
      let di = ci * 2 + k
      let mp = ((C.at(ci).at(0) + D.at(di).at(0)) / 2,
                (y1 + y2) / 2 + 0.02)
      let on = (ci == 0 and k == 0)
      content((mp.at(0) + 0.24, mp.at(1)),
              text(size: 6.8pt, fill: if on { garnet } else { faint })[$p = #cprob.at(di)$])
    }
  }
  // probabilities on chance->leaf edges (layer 3)
  for ei in range(4) {
    for k in range(2) {
      let li = ei * 2 + k
      let mp = ((E.at(ei).at(0) + Lp.at(li).at(0)) / 2,
                (y3 + y4) / 2)
      let on = (ei == 0 and k == 1)
      content((mp.at(0) + 0.24, mp.at(1) + 0.04),
              text(size: 6.3pt, fill: if on { garnet } else { faint })[#lprob.at(li)])
    }
  }

  // ─────────────────────────── draw nodes ───────────────────────────
  // leaves
  for (li, p) in Lp.enumerate() {
    let on = (li == 1)
    leaf(p, lvals.at(li), on: on)
  }
  // layer-3 chance (expectations)
  for (ei, p) in E.enumerate() {
    chance(p, evals.at(ei), on: (ei == 0))
  }
  // layer-2 decisions (max)
  for (di, p) in D.enumerate() {
    decision(p, dvals.at(di), on: (di == 0))
  }
  // layer-1 chance
  chance(C.at(0), cvals.at(0), on: true)
  chance(C.at(1), cvals.at(1), on: false)
  // root decision
  decision(R, rootval, on: true, root: true)

  // ──────────────────────── layer / axis labels (left rail) ────────────────────────
  let railx = -2.1
  let rail(y, title, sub, focal: false) = {
    content((railx, y), anchor: "west",
            text(size: 9pt, fill: if focal { garnet } else { ink },
                 weight: "bold")[#title])
    content((railx, y - 0.40), anchor: "west",
            text(size: 6.8pt, fill: muted)[#sub])
  }
  rail(y0, [decision], [agent: $max$], focal: true)
  rail(y1, [chance], [nature: $bb(E)$])
  rail(y2, [decision], [agent: $max$])
  rail(y3, [chance], [nature: $bb(E)$])
  rail(y4, [leaves], [eval / horizon])

  // dotted layer guide lines
  for y in (y0, y1, y2, y3, y4) {
    line((railx - 0.05, y), (10.3, y), stroke: (paint: gline, thickness: 0.5pt, dash: "dotted"))
  }

  // ──────────────────── upward "back-up" arrow on the right ────────────────────
  let bx = 11.0
  line((bx, y4 - 0.1), (bx, y0 + 0.1),
       stroke: 1.4pt + garnet, mark: (end: "stealth", scale: 1.0))
  content((bx + 0.18, (y0 + y4) / 2), anchor: "west",
          box(width: 1.7cm)[#text(size: 7.5pt, fill: garnet)[values\ *backed up*\ to the root]])

  // ─────────────────────────── recursion / backup rules ───────────────────────────
  let eqx = -2.1
  let eqy = -2.0
  line((eqx, eqy + 0.55), (12.9, eqy + 0.55), stroke: 0.7pt + gline)
  content((eqx, eqy), anchor: "west",
          text(size: 9.5pt, fill: ink)[
            $V(s) = max_a Q(s,a), quad Q(s,a) = sum_(s') p(s' | s,a) thin V(s')$
          ])
  content((eqx, eqy - 0.78), anchor: "west",
          text(size: 7.5pt, fill: muted)[#sym.square *decision* layers take the $max$ over actions; #sym.circle *chance* layers take the $bb(E)$ (probability-weighted average) over outcomes. Recurse to the horizon, then back up.])

  // ─────────────────────────── legend (bottom strip) ───────────────────────────
  let ly = -3.95
  let lx = -2.1
  rect((lx, ly - hs), (lx + 2 * hs, ly + hs), fill: panel, stroke: 1.25pt + ink, radius: 0pt)
  content((lx + 2 * hs + 0.22, ly), anchor: "west",
          text(size: 8pt, fill: ink)[decision node ($max$)])

  circle((lx + 4.55, ly), radius: cr, fill: white, stroke: 1.25pt + ink)
  content((lx + 4.55 + cr + 0.18, ly), anchor: "west",
          text(size: 8pt, fill: ink)[chance node ($bb(E)$)])

  rect((lx + 8.15, ly - 0.26), (lx + 8.15 + 0.6, ly + 0.26), fill: white, stroke: 0.8pt + faint, radius: 0pt)
  content((lx + 8.15 + 0.6 + 0.18, ly), anchor: "west",
          text(size: 8pt, fill: ink)[leaf value])

  line((lx + 11.5, ly - 0.22), (lx + 11.5, ly + 0.22),
       stroke: 1.7pt + garnet, mark: (end: "stealth", scale: 0.8))
  content((lx + 11.5 + 0.2, ly), anchor: "west",
          text(size: 8pt, fill: garnet)[chosen ($arg max$) path])
})
