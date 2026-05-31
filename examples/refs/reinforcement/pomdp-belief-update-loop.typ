// POMDP belief-update loop — the belief-MDP control cycle of a partially observable
// Markov decision process (Kaelbling, Littman & Cassandra 1998; Kochenderfer,
// "Algorithms for Decision Making", Ch. on POMDPs; Thrun, Burgard & Fox,
// "Probabilistic Robotics").
//
// In a POMDP the agent never sees the true (hidden) state s. Instead it maintains a
// BELIEF  b(s) = P(s) — a probability distribution over the hidden states — and acts
// on that belief. One control step:
//   • the POLICY maps the current belief to an action,  a = π(b);
//   • the ENVIRONMENT executes a: the hidden state transitions s → s′ ~ T(s'|s,a),
//     a reward r ~ R(s,a) accrues, and the agent receives only a noisy OBSERVATION
//       o ~ O(o | s', a)   (it does NOT see s′);
//   • the BELIEF UPDATER (a Bayes / recursive filter) folds the action and the new
//     observation into the prior belief to produce the posterior belief b′:
//       b'(s') = η · O(o | s', a) · Σ_s  T(s' | s, a) · b(s),
//     with η = 1 / Σ_{s'} O(o|s',a) Σ_s T(s'|s,a) b(s)  the normaliser (Bayes filter).
// b′ becomes the prior for the next step — this recasts the POMDP as a fully observed
// "belief-MDP" whose state is the belief simplex Δ(S). Hand-composed in raw cetz so the
// belief glyph + loop routing are exact; built from textbook knowledge in mlatlas's
// print-first house style — no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

// ── brand palette ────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")
#let b30    = rgb("#C7C7C7")
#let b50    = rgb("#A2A2A2")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── geometry: three blocks on a horizontal spine, belief glyph below the updater ──
  let xUpd =  0.0    // belief-updater column (focal, left)
  let xPol =  6.2    // policy column (centre)
  let xEnv = 11.6    // environment column (right)
  let ySpine = 0.0   // main signal-flow row

  // box half-sizes
  let bh = 0.95      // standard half-height

  // ── styles ──────────────────────────────────────────────────────────────
  let fwd = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.85))
  let obs = (stroke: (paint: garnet, thickness: 1.5pt, dash: none), mark: (end: "stealth", scale: 0.85))

  // ── box helper: sharp corners, light fill, dark text ─────────────────────
  let box(cx, cy, body, hw: 2.1, hh: bh, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  let E(cx, hw) = (cx + hw, ySpine)
  let W(cx, hw) = (cx - hw, ySpine)

  // ════════════════════════ BELIEF GLYPH (a tiny bar chart over the simplex) ═══
  // A small categorical distribution over 5 hidden states — the belief b ∈ Δ(S).
  // Drawn as a sharp-cornered bar chart sitting just below the Belief-Updater,
  // the "output port" of the filter. Bars are garnet to mark the focal quantity.
  let belief(cx, cy, probs, lab) = {
    let n = probs.len()
    let bw = 0.40       // bar width
    let gap = 0.16      // gap between bars
    let hmax = 1.35     // height of the tallest possible bar (p = 1)
    let totw = n * bw + (n - 1) * gap
    let x0 = cx - totw / 2
    // baseline + light frame
    let topY = cy + hmax + 0.18
    rect((x0 - 0.28, cy - 0.06), (x0 + totw + 0.28, topY), fill: white, stroke: 0.8pt + b50, radius: 0pt)
    // axis line (probability baseline)
    line((x0 - 0.18, cy), (x0 + totw + 0.18, cy), stroke: 0.9pt + ink)
    // p = 1 tick + grid
    line((x0 - 0.18, cy + hmax), (x0 + totw + 0.18, cy + hmax), stroke: (paint: b30, thickness: 0.6pt, dash: "dotted"))
    content((x0 - 0.40, cy + hmax), text(size: 6.5pt, fill: muted)[$1$], anchor: "east")
    content((x0 - 0.40, cy), text(size: 6.5pt, fill: muted)[$0$], anchor: "east")
    // bars
    for (i, p) in probs.enumerate() {
      let bx = x0 + i * (bw + gap)
      rect((bx, cy), (bx + bw, cy + p * hmax), fill: garnet, stroke: 0.7pt + garnet, radius: 0pt)
      content((bx + bw / 2, cy - 0.18), text(size: 6pt, fill: muted)[$s_#(i + 1)$], anchor: "north")
    }
    // label below the chart so nothing collides with the boxes/edges above
    content((cx, cy - 0.55), text(size: 8pt, fill: ink)[#lab], anchor: "north")
  }

  // ════════════════════════ BLOCK NODES ═══════════════════════════════════
  // Belief Updater — the recursive Bayes filter, the focal (garnet) block.
  box(
    xUpd, ySpine,
    align(center)[
      *Belief updater* \
      #text(size: 7.5pt, fill: muted)[Bayes filter] \
      #v(1pt)
      #text(size: 8pt)[$b'(s') = eta thin O(o | s', a) sum_s T(s'|s,a) b(s)$]
    ],
    hw: 2.95, hh: 1.05, fill: b10, bstroke: 2.3pt + garnet,
  )
  // Policy — maps belief to action.
  box(
    xPol, ySpine,
    align(center)[
      *Policy* \
      #text(size: 7.5pt, fill: muted)[acts on the belief] \
      #v(1pt)
      #text(size: 9pt)[$a = pi(b)$]
    ],
    hw: 1.95, hh: 1.05, fill: white, bstroke: 1.2pt + ink,
  )
  // Environment — hidden-state dynamics; emits reward + observation, hides s′.
  box(
    xEnv, ySpine,
    align(center)[
      *Environment* \
      #text(size: 7.5pt, fill: muted)[hidden state $s$ \(unobserved\)] \
      #v(2pt)
      #text(size: 8pt)[$s' tilde T(s'|s,a)$] \
      #text(size: 8pt)[$o tilde O(o | s', a)$] \
      #text(size: 8pt)[$r tilde R(s, a)$]
    ],
    hw: 2.25, hh: 1.32, fill: beige, bstroke: 1.2pt + ink,
  )

  // belief distribution glyph, hung below the updater (offset left of the gutter
  // back-edge) as its output b. Baseline at cyB; chart frame top = cyB + hmax + 0.18.
  let cyB = -3.55
  let xB = xUpd - 0.7
  belief(xB, cyB, (0.10, 0.22, 0.46, 0.14, 0.08), [belief  $b in Delta(S)$  over hidden states])
  // dotted tie from the updater's bottom-left port down to the belief chart frame
  let frameTop = cyB + 1.35 + 0.18
  line(
    (xUpd - 1.4, ySpine - 1.05),
    (xUpd - 1.4, frameTop),
    (xB, frameTop),
    stroke: (paint: b50, thickness: 0.8pt, dash: "dotted"),
    mark: (end: "stealth", scale: 0.7),
  )
  content((xUpd - 1.4 - 0.1, (ySpine - 1.05 + frameTop) / 2), text(size: 7pt, fill: muted)[output $b$], anchor: "east")

  // ════════════════════════ FORWARD SPINE (solid) ═════════════════════════
  // belief updater → policy : the current belief b feeds the policy.
  line(E(xUpd, 2.95), W(xPol, 1.95), ..fwd)
  content(((xUpd + 2.95 + xPol - 1.95) / 2, ySpine + 0.30), text(size: 8.5pt, fill: ink)[belief $b$])

  // policy → environment : the chosen action is applied to the world.
  line(E(xPol, 1.95), W(xEnv, 2.15), ..fwd)
  content(((xPol + 1.95 + xEnv - 2.15) / 2, ySpine + 0.30), text(size: 8.5pt, fill: ink)[action $a = pi(b)$])

  // ════════════════════════ OBSERVATION BACK-EDGE (garnet) ════════════════
  // Environment → belief updater : ONLY a noisy observation o (and reward r) returns —
  // the true next state s′ is never revealed. Routed through the bottom gutter,
  // closing the loop. Garnet = the partial-observability signal that drives the filter.
  let yGut = -1.95
  line(
    (xEnv, ySpine - 1.05),
    (xEnv, yGut),
    (xUpd, yGut),
    (xUpd, ySpine - 1.05),
    ..obs,
  )
  content(((xUpd + xEnv) / 2, yGut - 0.30), text(size: 8.5pt, fill: garnet)[
    observation  $o tilde O(o | s', a)$   ·   reward  $r$   #h(4pt) #text(fill: muted)[(state $s'$ hidden)]
  ], anchor: "north")

  // the action also conditions the belief update (the "a" in the Bayes filter).
  // a thin tap off the ACTION edge, dropping down to a lane above the observation
  // gutter and entering the updater's bottom-right port — dotted, secondary.
  let yTap = yGut + 0.62
  let xTap = (xPol + 1.95 + xEnv - 2.25) / 2   // a point on the policy→env action edge
  line(
    (xTap, ySpine),
    (xTap, yTap),
    (xUpd + 1.5, yTap),
    (xUpd + 1.5, ySpine - 1.05),
    stroke: (paint: muted, thickness: 0.8pt, dash: "dotted"),
    mark: (end: "stealth", scale: 0.7),
  )
  content(((xUpd + 1.5 + xTap) / 2, yTap + 0.02), text(size: 7pt, fill: muted)[last action $a$ conditions the filter], anchor: "south")

  // ════════════════════════ TITLE / OBJECTIVE STRIP ═══════════════════════
  let yTitle = 2.55
  content(
    ((xUpd + xEnv) / 2, yTitle),
    text(size: 12.5pt, weight: "bold", fill: ink)[POMDP belief-update loop  ·  the belief-MDP],
  )
  content(
    ((xUpd + xEnv) / 2, yTitle - 0.62),
    text(size: 8.5pt, fill: muted)[
      The belief $b in Delta(S)$ is a sufficient statistic of history — acting on $b$ recasts the POMDP as a fully observed MDP over beliefs.
    ],
  )
})
