// Monte Carlo Tree Search (MCTS) — a STANDARD reinforcement-learning / planning concept.
//
// MCTS builds an ASYMMETRIC search tree by repeating four phases per iteration:
//   1. SELECTION    — from the root, descend by the tree (UCB1 / UCT) policy,
//                     always taking arg-max of  Q + c sqrt(ln N_parent / n),
//                     until a node with unexpanded children is reached.
//   2. EXPANSION    — add one new leaf (a previously untried action) to the tree.
//   3. SIMULATION   — run a fast random/default-policy rollout from the new leaf to
//                     a terminal state, producing a return  Δ  (the rollout reward).
//   4. BACKUP       — propagate Δ back up the visited path, incrementing each visit
//                     count N and accumulating value, so Q = W / N is refreshed.
// The tree grows DEEPER where promising (high Q) and stays shallow elsewhere — the
// asymmetry is the whole point. Each node is annotated with its visit count N and
// mean value Q (= W / N), the two statistics that drive the UCB selection rule.
//
// Original mlatlas figure built from knowledge (Kochenderfer; Sutton & Barto;
// AlphaGo lineage / Spinning Up) in the print-first house style: light fills, dark
// text, sharp orthogonal corners, stealth arrowheads, garnet as a sparse accent on
// the selected path. A thin reusable mini-tree renderer drives the four-phase strip.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ───────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#000000")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let gline  = rgb("#C7C7C7")
#let panel  = rgb("#ECECEC")
#let blue   = rgb("#466A9F")
#let scoretx = rgb("#5C5C5C")

// ── shared node radii ───────────────────────────────────────────────────────
#let R   = 0.34   // main-tree node radius
#let r   = 0.16   // mini-tree node radius

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ════════════════════════════════════════════════════════════════════════
  //  PANEL A — the asymmetric MCTS tree with N/Q annotations
  // ════════════════════════════════════════════════════════════════════════
  //
  // node id -> (x, y, N, Q, kind)   kind: "root" | "path" | "node" | "leaf"
  //   "path" nodes lie on the most-visited (principal) path, drawn garnet.
  //   The tree is deliberately asymmetric: the left/garnet subtree is deep and
  //   well-visited; the right subtree is shallow and lightly explored.
  let A = (
    "r":   (0.0,   3.0,  100, 0.62, "root"),
    // depth 1
    "a":   (-2.4,  1.6,   64, 0.71, "path"),
    "b":   ( 0.6,  1.6,   22, 0.48, "node"),
    "c":   ( 2.9,  1.6,   14, 0.35, "node"),
    // depth 2  (under a — the promising subtree)
    "a1":  (-3.6,  0.1,   41, 0.78, "path"),
    "a2":  (-1.5,  0.1,   23, 0.59, "node"),
    // depth 2 (under b)
    "b1":  ( 0.6,  0.1,   13, 0.52, "node"),
    // depth 3  (under a1 — deepest, principal variation)
    "a1a": (-4.3, -1.4,   27, 0.81, "path"),
    "a1b": (-2.9, -1.4,   14, 0.66, "node"),
    // depth 4 (frontier leaf reached by selection)
    "leaf":(-4.3, -2.9,   12, 0.84, "leaf"),
  )
  let Aedge = (
    ("r","a"), ("r","b"), ("r","c"),
    ("a","a1"), ("a","a2"),
    ("b","b1"),
    ("a1","a1a"), ("a1","a1b"),
    ("a1a","leaf"),
  )
  // which edges are on the principal (garnet) path
  let onpath = (("r","a"), ("a","a1"), ("a1","a1a"), ("a1a","leaf"))
  let is-on(f, t) = onpath.any(e => e.at(0) == f and e.at(1) == t)

  // edges (under nodes)
  for (f, t) in Aedge {
    let (x0, y0, ..) = A.at(f)
    let (x1, y1, ..) = A.at(t)
    let on = is-on(f, t)
    line((x0, y0 - R), (x1, y1 + R),
      stroke: if on { 1.7pt + garnet } else { 1.0pt + muted })
  }

  // nodes + N/Q annotation
  for (id, d) in A {
    let (x, y, N, Q, kind) = d
    let stk = if kind == "root" { 1.6pt + ink }
              else if kind == "path" { 1.6pt + garnet }
              else if kind == "leaf" { 1.6pt + garnet }
              else { 1.1pt + muted }
    let fil = if kind == "leaf" { garnet.transparentize(86%) } else { white }
    circle((x, y), radius: R, fill: fil, stroke: stk)
    // node label inside
    let lbl = if kind == "root" { text(size: 8pt, weight: "bold", fill: ink)[$s_0$] } else { none }
    if lbl != none { content((x, y), lbl) }
    // N / Q annotation to the side. Deep left-spine (garnet path) nodes annotate
    // to the LEFT so the label clears the sibling on their right; others to the right.
    let antx = if kind == "path" or kind == "leaf" or kind == "root" { garnet } else { scoretx }
    let left-side = ("a", "a1", "a1a", "leaf").contains(id)
    let ax = if left-side { x - R - 0.14 } else { x + R + 0.14 }
    let aanch = if left-side { "east" } else { "west" }
    content((ax, y),
      anchor: aanch,
      text(size: 6.5pt, fill: antx)[
        $N = #N$\
        $Q = #Q$
      ])
  }

  // root marker label
  content((A.at("r").at(0), A.at("r").at(1) + R + 0.46),
    text(size: 8.5pt, weight: "bold", fill: ink)[root state])

  // dashed rollout arrow from the selected leaf to a terminal outcome (down-left,
  // label set to the side so it clears the strip divider below)
  let (lx, ly, ..) = A.at("leaf")
  line((lx, ly - R), (lx - 0.55, ly - 0.95),
    stroke: (paint: blue, thickness: 1.2pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.8))
  content((lx - 0.65, ly - 1.05), anchor: "east",
    text(size: 7.5pt, fill: blue)[rollout $arrow.r Delta$])

  // principal-variation annotation (right side)
  content((3.7, 0.1), anchor: "west",
    text(size: 7.5pt, fill: garnet, style: "italic")[
      principal\
      variation\
      (UCB-best\
      descent)
    ])

  // panel A title
  content((0.0, 4.35),
    text(size: 11pt, weight: "bold", fill: ink)[Monte Carlo Tree Search — asymmetric search tree])

  // UCB rule box (top-right)
  content((4.6, 3.5), anchor: "north-west", box(
    inset: 5pt, stroke: 0.7pt + gline, fill: panel.lighten(40%), radius: 0pt,
    text(size: 7.5pt, fill: ink)[
      *tree (UCT) policy*\
      #v(1pt)
      $a^* = arg max_a underbrace(Q(a), "exploit") + c underbrace(sqrt(ln N / n_a), "explore")$\
      #v(1pt)
      #text(fill: muted)[$Q = W \/ N$ #h(0.4em) $N$: visits #h(0.4em) $W$: total value]
    ],
  ))

  // ── divider between panel A and the four-phase strip ──────────────────────
  line((-5.4, -4.5), (6.6, -4.5), stroke: 0.8pt + gline)

  // ════════════════════════════════════════════════════════════════════════
  //  thin mini-tree renderer for one phase panel
  // ════════════════════════════════════════════════════════════════════════
  // A fixed 7-node skeleton (root, 2 children, 3 grandchildren-ish) drawn at an
  // origin (ox, oy). `path` = list of node-ids drawn garnet (the highlighted
  // descent). `newleaf` = id of a freshly expanded leaf (garnet dashed outline).
  // `rollout` = true -> dashed rollout arrow off `rollfrom`. `up` = true -> garnet
  // up-arrows along `path` (the backup). Pure geometry computed in Typst.
  //
  // mini skeleton layout (relative to origin), y grows up:
  let M = (
    "R":  (0.0,   1.5),
    "L":  (-0.95, 0.6),
    "Rt": ( 0.95, 0.6),
    "LL": (-1.5, -0.35),
    "LR": (-0.5, -0.35),
    "RR": ( 1.45, -0.35),
  )
  let Medge = (("R","L"), ("R","Rt"), ("L","LL"), ("L","LR"), ("Rt","RR"))

  let mini(ox, oy, title, path: (), newleaf: none, rollfrom: none, up: false, extra: none) = {
    let pos(id) = (ox + M.at(id).at(0), oy + M.at(id).at(1))
    let on-path(id) = path.contains(id)
    let edge-on(f, t) = on-path(f) and on-path(t)

    // edges
    for (f, t) in Medge {
      let p0 = pos(f)
      let p1 = pos(t)
      let e-on = edge-on(f, t)
      line((p0.at(0), p0.at(1) - r), (p1.at(0), p1.at(1) + r),
        stroke: if e-on { 1.6pt + garnet } else { 0.9pt + muted })
    }
    // new-leaf edge (R-skeleton has no child slot for the new leaf; draw bespoke)
    if newleaf != none {
      let par = pos("LR")
      let np  = (par.at(0) + 0.0, par.at(1) - 0.95)
      line((par.at(0), par.at(1) - r), (np.at(0), np.at(1) + r),
        stroke: 1.4pt + garnet)
      circle(np, radius: r, fill: garnet.transparentize(80%), stroke: 1.5pt + garnet)
      content((np.at(0) + r + 0.14, np.at(1) + 0.12), anchor: "west",
        text(size: 6.5pt, fill: garnet)[new])
      // store new-leaf position for rollout
    }
    // nodes
    for (id, _) in M {
      let p = pos(id)
      let on = on-path(id)
      circle(p, radius: r, fill: white,
        stroke: if on { 1.5pt + garnet } else { 0.9pt + muted })
    }
    // backup up-arrows along the path
    if up {
      // path is ordered root..leaf; draw arrows leaf->root
      let seq = path
      for i in range(seq.len() - 1) {
        let child = pos(seq.at(seq.len() - 1 - i))
        let par   = pos(seq.at(seq.len() - 2 - i))
        line((child.at(0), child.at(1) + r), (par.at(0), par.at(1) - r),
          stroke: 1.5pt + garnet, mark: (start: "stealth", scale: 0.7))
      }
      // also from new leaf if expansion present chained below LR — handled by extra
    }
    // rollout arrow
    if rollfrom != none {
      let from = if rollfrom == "new" {
        let par = pos("LR")
        (par.at(0), par.at(1) - 0.95)
      } else { pos(rollfrom) }
      line((from.at(0), from.at(1) - r),
        (from.at(0) + 0.55, from.at(1) - 1.05),
        stroke: (paint: blue, thickness: 1.1pt, dash: "dashed"),
        mark: (end: "stealth", scale: 0.7))
      content((from.at(0) + 0.62, from.at(1) - 1.18), anchor: "west",
        text(size: 6.5pt, fill: blue)[$Delta$])
    }
    if extra != none { extra(ox, oy) }
    // panel title
    content((ox, oy + 2.05), text(size: 9pt, weight: "bold", fill: ink)[#title])
  }

  // strip origins (evenly spaced)
  let sy = -7.6
  let sx0 = -3.2
  let dxp = 3.25

  // 1 — SELECTION: garnet descent root -> LR (no expansion yet)
  mini(sx0 + 0 * dxp, sy, [1. Selection],
    path: ("R", "L", "LR"))
  // 2 — EXPANSION: same descent + a new leaf added under LR
  mini(sx0 + 1 * dxp, sy, [2. Expansion],
    path: ("R", "L", "LR"), newleaf: "x")
  // 3 — SIMULATION: rollout from the new leaf to a terminal return Δ
  mini(sx0 + 2 * dxp, sy, [3. Simulation],
    path: ("R", "L", "LR"), newleaf: "x", rollfrom: "new")
  // 4 — BACKUP: Δ propagated up the visited path (garnet up-arrows)
  mini(sx0 + 3 * dxp, sy, [4. Backpropagation],
    path: ("R", "L", "LR"), up: true)

  // per-phase captions (one line under each)
  let cy = sy - 1.95
  let caps = (
    [descend by UCB to a\ non-fully-expanded node],
    [add one untried\ action as a leaf],
    [random rollout to\ terminal, return $Delta$],
    [along the path:\ $N arrow.l N {+} 1$,#h(0.3em) $W arrow.l W {+} Delta$],
  )
  for i in range(4) {
    content((sx0 + i * dxp + 0.0, cy),
      align(center, text(size: 7pt, fill: muted)[#caps.at(i)]))
  }

  // strip section title
  content((sx0 + 1.5 * dxp, sy + 2.85),
    text(size: 10pt, weight: "bold", fill: ink)[One iteration — four phases (repeat until budget exhausted)])

  // ── legend (bottom) ───────────────────────────────────────────────────────
  let ly = sy - 3.0
  let lx = sx0 - 0.2
  // garnet path swatch
  line((lx, ly), (lx + 0.55, ly), stroke: 1.6pt + garnet)
  content((lx + 0.66, ly), anchor: "west", text(size: 7.5pt, fill: muted)[selected / on-tree path])
  // rollout swatch
  let lx2 = lx + 4.2
  line((lx2, ly), (lx2 + 0.55, ly),
    stroke: (paint: blue, thickness: 1.1pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
  content((lx2 + 0.66, ly), anchor: "west", text(size: 7.5pt, fill: muted)[default-policy rollout])
  // new-leaf swatch
  let lx3 = lx + 8.0
  circle((lx3 + 0.2, ly), radius: r, fill: garnet.transparentize(80%), stroke: 1.5pt + garnet)
  content((lx3 + 0.5, ly), anchor: "west", text(size: 7.5pt, fill: muted)[newly expanded leaf])
})
