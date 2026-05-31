// mlatlas · Trellis / lattice for sequence decoding (Viterbi & forward-backward).
// Time runs left-to-right; the K discrete states (HMM hidden states / CRF tags) are
// stacked on y. Every state at step t connects to every state at t+1 by a light
// transition edge — the full lattice. The single best (Viterbi / MAP) path is the
// bold garnet trace through one state per column. Emission arrows rise from the
// observed token row below into the active state of each column.
//
//   transition:  a_{ij} = P(s_t = j | s_{t-1} = i)    (CRF: ψ_t(y_{t-1}, y_t))
//   emission:    b_j(o_t) = P(o_t | s_t = j)           (CRF: φ_t(y_t, x))
//   Viterbi:     δ_t(j) = max_i [ δ_{t-1}(i) · a_{ij} ] · b_j(o_t)
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- palette: print-first, garnet as the sparse focal accent ----------------
  let p = (
    garnet: rgb("#73000A"),     // best (Viterbi) path
    node: rgb("#FFFFFF"),       // lattice node fill
    nodeOn: rgb("#FFF2E3"),     // node on the best path (beige)
    edge: rgb("#C7C7C7"),       // light full-lattice transitions
    emit: rgb("#5C5C5C"),       // emission arrows
    text: rgb("#1A1A1A"),
    muted: rgb("#5C5C5C"),
    token: rgb("#ECECEC"),      // observed-token chips
  )

  // ---- trellis geometry -------------------------------------------------------
  let T = 5                     // time steps / columns
  let states = ("N", "V", "D")  // 3 stacked states (Noun, Verb, Det)
  let K = states.len()
  let dx = 2.4                  // column spacing
  let dy = 1.6                  // row spacing
  let r = 0.34                  // node radius
  let y0 = 0.0                  // baseline of the lowest state row

  // node centre for column t (0-based), state row k (0 = bottom)
  let nx(t) = t * dx
  let ny(k) = y0 + k * dy
  let pos(t, k) = (nx(t), ny(k))

  // the highlighted best path: one state index per column
  let best = (0, 1, 2, 0, 1)    // N -> V -> D -> N -> V

  let token-y = y0 - 1.9        // observed token row
  let topY = ny(K - 1)          // top state row y

  // ---- helpers ----------------------------------------------------------------
  let arr(a, b, color: p.emit, w: 1.1pt, s: 0.6) = draw.line(
    a, b, stroke: w + color, mark: (end: "stealth", scale: s),
  )

  // ===========================================================================
  // (1) full inter-column lattice — light transitions from every i to every j
  // ===========================================================================
  for t in range(T - 1) {
    for i in range(K) {
      for j in range(K) {
        let a = pos(t, i)
        let b = pos(t + 1, j)
        // shorten endpoints so edges meet node rims, not centres
        let dxe = b.at(0) - a.at(0)
        let dye = b.at(1) - a.at(1)
        let L = calc.sqrt(dxe * dxe + dye * dye)
        let ux = dxe / L
        let uy = dye / L
        draw.line(
          (a.at(0) + ux * r, a.at(1) + uy * r),
          (b.at(0) - ux * r, b.at(1) - uy * r),
          stroke: 0.6pt + p.edge,
        )
      }
    }
  }

  // ===========================================================================
  // (2) the bold garnet best (Viterbi) path on top of the lattice
  // ===========================================================================
  for t in range(T - 1) {
    let a = pos(t, best.at(t))
    let b = pos(t + 1, best.at(t + 1))
    let dxe = b.at(0) - a.at(0)
    let dye = b.at(1) - a.at(1)
    let L = calc.sqrt(dxe * dxe + dye * dye)
    let ux = dxe / L
    let uy = dye / L
    arr(
      (a.at(0) + ux * r, a.at(1) + uy * r),
      (b.at(0) - ux * r, b.at(1) - uy * r),
      color: p.garnet, w: 2.4pt, s: 0.7,
    )
  }

  // ===========================================================================
  // (3) trellis nodes — circles at every (t, k); best-path nodes filled beige
  //     with a garnet rim
  // ===========================================================================
  for t in range(T) {
    for k in range(K) {
      let onpath = best.at(t) == k
      let fill = if onpath { p.nodeOn } else { p.node }
      let stroke = if onpath { 1.6pt + p.garnet } else { 1.0pt + p.muted }
      draw.circle(pos(t, k), radius: r, fill: fill, stroke: stroke)
      let tx = if onpath { p.garnet } else { p.text }
      draw.content(pos(t, k), text(size: 8pt, fill: tx)[#states.at(k)])
    }
  }

  // ===========================================================================
  // (4) observed-token row + emission arrows into each column's active state
  // ===========================================================================
  let tokens = ([the], [dog], [bites], [the], [cat])
  let tw = 0.9
  let th = 0.52
  for t in range(T) {
    let cx = nx(t)
    // token chip
    draw.rect(
      (cx - tw / 2, token-y - th / 2),
      (cx + tw / 2, token-y + th / 2),
      fill: p.token, stroke: 0.9pt + p.muted, radius: 0pt,
    )
    draw.content((cx, token-y), text(size: 8pt, fill: p.text)[#tokens.at(t)])
    // emission arrow: token -> active (best-path) state of this column
    let k = best.at(t)
    let ny0 = ny(k)
    arr(
      (cx, token-y + th / 2 + 0.04),
      (cx, ny0 - r - 0.04),
      color: p.emit, w: 1.0pt, s: 0.55,
    )
  }

  // ===========================================================================
  // (5) axes, labels, legend
  // ===========================================================================
  // state-row labels on the left
  let states-long = ("Noun", "Verb", "Det")
  for k in range(K) {
    draw.content(
      (nx(0) - r - 0.55, ny(k)),
      anchor: "east",
      text(size: 8.5pt, fill: p.muted)[#states-long.at(k)],
    )
  }
  // y-axis caption (states)
  draw.content(
    (nx(0) - 1.9, (ny(0) + topY) / 2),
    anchor: "center",
    text(size: 9pt, fill: p.text)[#rotate(-90deg)[states $s_t$]],
  )

  // time axis arrow along the bottom
  let axisY = token-y - 1.0
  arr((nx(0) - 0.4, axisY), (nx(T - 1) + 0.4, axisY), color: p.muted, w: 1.2pt, s: 0.7)
  draw.content(
    (nx(T - 1) + 0.55, axisY), anchor: "west",
    text(size: 9pt, fill: p.text)[time $t$],
  )
  // step ticks t = 1..T
  for t in range(T) {
    draw.content(
      (nx(t), axisY - 0.06), anchor: "north",
      text(size: 8pt, fill: p.muted)[$t#sub[#(t + 1)]$],
    )
  }

  // labels: one transition fan + one emission, called out once
  draw.content(
    (nx(0) + dx / 2 + 0.15, topY + 0.55), anchor: "center",
    text(size: 7.5pt, fill: p.muted)[transitions $a_(i j)$],
  )
  // emission callout on the t2 (dog -> Verb) arrow, in the clear gap below
  // the bottom state row so it never collides with a node or the lattice
  draw.content(
    (nx(1) + 0.18, (token-y + th / 2 + ny(0) - r) / 2), anchor: "west",
    text(size: 7.5pt, fill: p.emit)[emission $b_j (o_t)$],
  )

  // title
  draw.content(
    ((nx(0) + nx(T - 1)) / 2, topY + 1.25), anchor: "center",
    text(size: 12pt, weight: "bold", fill: p.text)[Trellis decoding · Viterbi best path],
  )

  // legend for the garnet path
  let lgx = nx(T - 1) - 1.3
  let lgy = topY + 0.6
  draw.line((lgx, lgy), (lgx + 0.7, lgy), stroke: 2.4pt + p.garnet, mark: (end: "stealth", scale: 0.7))
  draw.content((lgx + 0.85, lgy), anchor: "west", text(size: 7.5pt, fill: p.garnet)[best path $hat(s)_(1:T)$])

  // caption: the Viterbi recursion
  draw.content(
    ((nx(0) + nx(T - 1)) / 2, axisY - 0.85), anchor: "center",
    text(size: 8.5pt, fill: p.muted)[
      $delta_t (j) = max_i [ delta_(t-1)(i) thin a_(i j) ] thin b_j (o_t)$
      #h(0.8em) (full lattice: every state $arrow.r$ every state)
    ],
  )
})
