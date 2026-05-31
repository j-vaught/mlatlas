// Dyna — integrated model-based planning, acting, and learning
// (Sutton & Barto, "Reinforcement Learning: An Introduction", 2nd ed., Ch. 8 "Planning
//  and Learning with Tabular Methods"; the classic "Dyna architecture" schematic).
//
// Dyna unifies model-free and model-based RL in a single loop. Real experience from the
// ENVIRONMENT is used two ways simultaneously:
//   • DIRECT RL  — the transition (s, a, r, s′) updates the value function / policy
//                  directly (e.g. one-step Q-learning), exactly as in model-free RL;
//   • MODEL LEARNING — the same transition trains a MODEL of the environment,
//                  Model(s, a) → (r̂, ŝ′), so dynamics can be replayed offline.
// PLANNING then mines the learned model: SEARCH CONTROL picks a previously-seen (s, a),
// the model returns SIMULATED experience (r̂, ŝ′), and the SAME update rule is applied
// — n planning steps per real step. Planning updates and direct updates are identical
// in form; only the *source* of experience differs (real vs simulated). The improved
// value/policy selects the next ACTION, closing the acting loop with the environment.
//
// Two arrow families are distinguished: "direct" (solid, real experience) and
// "planning" (dashed garnet, simulated experience). Hand-composed in raw cetz so every
// port and orthogonal route is exact; built from textbook knowledge in mlatlas's
// print-first house style — no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── column / row geometry ────────────────────────────────────────────────
  let xL = 0.0      // real-experience column (left)
  let xC = 5.6      // value/policy column (centre)
  let xR = 11.2     // model / planning column (right)

  let yVP   =  4.6  // value / policy  (top centre — shared update target)
  let yEnv  =  2.3  // environment (left) / planning update (right)
  let yExp  =  0.3  // experience (left) / simulated experience (right)
  let yLow  = -1.7  // direct RL (left) / model (right)
  let ySearch = -4.0 // search control (right, below model)

  // ── edge styles: two families ───────────────────────────────────────────
  // DIRECT family — solid black, real experience.
  let direct = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.85))
  // PLANNING family — dashed garnet, simulated experience.
  let plan = (stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.85))

  // ── box helper: sharp corners, light fill, dark text ─────────────────────
  let box(cx, cy, body, hw: 1.9, hh: 0.78, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  // data-token helper — a beige rectangle (sharp corners, on-brand) used for the
  // "experience" tokens so the real vs simulated streams read as data, not ops.
  let pill(cx, cy, body, hw: 2.0, hh: 0.62, fill: beige) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: 1.0pt + muted, radius: 0pt)
    content((cx, cy), body)
  }
  // port helpers (box edges)
  let E(cx, cy, hw: 1.9) = (cx + hw, cy)
  let W(cx, cy, hw: 1.9) = (cx - hw, cy)
  let N(cx, cy, hh: 0.78) = (cx, cy + hh)
  let S(cx, cy, hh: 0.78) = (cx, cy - hh)

  // ════════════════════════ NODES ═════════════════════════════════════════
  // Focal node: shared target of BOTH update families (garnet outline).
  box(
    xC, yVP,
    align(center)[*Value / Policy*\ #text(size: 8.5pt, fill: muted)[$Q(s,a)$ ,  $pi(a | s)$]],
    hw: 2.35, hh: 0.86, fill: b10, bstroke: 2.2pt + garnet,
  )

  // Left column — real experience.
  box(
    xL, yEnv,
    align(center)[*Environment*\ #text(size: 8pt, fill: muted)[true dynamics]],
    hw: 1.95, hh: 0.78,
  )
  pill(
    xL, yExp,
    align(center)[experience\ #text(size: 8pt, fill: muted)[$(s, a, r, s')$]],
    hw: 1.95, hh: 0.66,
  )
  box(
    xL, yLow,
    align(center)[*Direct RL*\ #text(size: 8pt, fill: muted)[one-step Q-learning]],
    hw: 1.95, hh: 0.78,
  )

  // Right column — model & planning.
  box(
    xR, yEnv,
    align(center)[*Planning update*\ #text(size: 8pt, fill: muted)[same rule, $n$ steps]],
    hw: 2.05, hh: 0.78, fill: white,
  )
  pill(
    xR, yExp,
    align(center)[simulated experience\ #text(size: 8pt, fill: muted)[$(s, a, hat(r), hat(s)')$]],
    hw: 2.25, hh: 0.66,
  )
  box(
    xR, yLow,
    align(center)[*Model*\ #text(size: 8pt, fill: muted)[$"Model"(s,a) -> (hat(r), hat(s)')$]],
    hw: 2.25, hh: 0.78,
  )
  // search control — a diamond below the model.
  let sd = 1.05
  line(
    (xR, ySearch + sd), (xR + 1.9, ySearch), (xR, ySearch - sd), (xR - 1.9, ySearch),
    close: true, fill: white, stroke: 1.0pt + muted,
  )
  content((xR, ySearch), align(center)[search control\ #text(size: 8pt, fill: muted)[pick $(s,a)$]])

  // ════════════════════════ ACTING LOOP (solid, real) ═════════════════════
  // policy → action → environment.  Route from VP's left edge, down the centre-left,
  // into the Environment's top.
  let xAct = (xL + xC) / 2 - 0.4
  line(
    W(xC, yVP, hw: 2.35),
    (xAct, yVP),
    (xAct, yEnv + 0.78 + 0.0),
    N(xL, yEnv, hh: 0.78),
    ..direct,
  )
  content((xAct - 0.15, (yVP + yEnv) / 2 + 0.2), anchor: "east", text(size: 8.5pt, fill: ink)[action $a$])

  // environment → experience  (observe the transition).
  line(S(xL, yEnv, hh: 0.78), N(xL, yExp, hh: 0.66), ..direct)
  content((xL + 0.18, (yEnv - 0.78 + yExp + 0.66) / 2), anchor: "west", text(size: 8pt, fill: muted)[observe])

  // ════════════════════════ DIRECT family (solid, real) ═══════════════════
  // experience → Direct RL.
  line(S(xL, yExp, hh: 0.66), N(xL, yLow, hh: 0.78), ..direct)
  content((xL + 0.18, (yExp - 0.66 + yLow + 0.78) / 2), anchor: "west", text(size: 8pt, fill: ink)[direct])

  // Direct RL → Value/Policy  (the update).  Route out the LEFT, up the far-left
  // gutter, across the top into VP's top-left.
  let xGdir = xL - 2.55
  line(
    W(xL, yLow, hw: 1.95),
    (xGdir, yLow),
    (xGdir, yVP + 1.25),
    (xC - 1.1, yVP + 1.25),
    (xC - 1.1, yVP + 0.86),
    ..direct,
  )
  content((xGdir + 0.18, (yLow + yVP) / 2 + 0.1), anchor: "west", text(size: 8.5pt, fill: ink)[
    #set par(leading: 3pt)
    direct\ update
  ])

  // experience → Model  (model learning): the SAME real transition trains the model.
  // Route from the experience token's EAST edge across at the experience level, then
  // drop into the Model's WEST edge — so the source reads unambiguously as real
  // experience (not the Direct-RL update), and it avoids the model's busy north port.
  let xMin = xR - 2.25 - 0.0  // model west edge x
  line(
    E(xL, yExp, hw: 1.95),
    (xMin - 0.9, yExp),
    (xMin - 0.9, yLow),
    W(xR, yLow, hw: 2.25),
    ..direct,
  )
  content(((xL + 1.95 + xMin - 0.9) / 2, yExp + 0.30), text(size: 8.5pt, fill: ink)[model learning])

  // ════════════════════════ PLANNING family (dashed garnet, simulated) ════
  // search control → Model  (query a stored (s,a) to roll forward).
  line(N(xR, ySearch, hh: sd), S(xR, yLow, hh: 0.78), ..plan)
  content((xR + 0.18, (ySearch + sd + yLow - 0.78) / 2), anchor: "west", text(size: 8pt, fill: garnet)[query $(s,a)$])

  // Model → simulated experience  (simulate).
  line(N(xR, yLow, hh: 0.78), S(xR, yExp, hh: 0.66), ..plan)
  content((xR + 0.18, (yLow + 0.78 + yExp - 0.66) / 2), anchor: "west", text(size: 8pt, fill: garnet)[simulate])

  // simulated experience → Planning update.
  line(N(xR, yExp, hh: 0.66), S(xR, yEnv, hh: 0.78), ..plan)
  content((xR + 0.18, (yExp + 0.66 + yEnv - 0.78) / 2), anchor: "west", text(size: 8pt, fill: garnet)[planning])

  // Planning update → Value/Policy  (the update).  Route out the RIGHT-of-VP top,
  // up the right gutter, across the top into VP's top-right.
  line(
    N(xR, yEnv, hh: 0.78),
    (xR, yVP + 1.25),
    (xC + 1.1, yVP + 1.25),
    (xC + 1.1, yVP + 0.86),
    ..plan,
  )
  content(((xC + 1.1 + xR) / 2 + 0.6, yVP + 1.25 + 0.28), text(size: 8.5pt, fill: garnet)[planning update])

  // ════════════════════════ TITLE ═════════════════════════════════════════
  content(
    (xC, yVP + 2.85),
    text(size: 13pt, weight: "bold", fill: ink)[The Dyna architecture],
  )
  content(
    (xC, yVP + 2.35),
    text(size: 8.5pt, fill: muted)[planning, acting, and learning, integrated],
  )
})

// ── legend: the two arrow families ──────────────────────────────────────────
#v(10pt)
#align(center)[
  #box(stroke: 0.7pt + muted, inset: 8pt, radius: 0pt)[
    #set text(size: 8.5pt)
    #grid(
      columns: (auto, auto),
      column-gutter: 22pt, row-gutter: 5pt,
      align: (left, left),
      [#box(baseline: -1pt, cetz.canvas(length: 1cm, {
        import cetz.draw: *
        line((0, 0), (0.95, 0), stroke: 1.1pt + rgb("#1A1A1A"), mark: (end: "stealth", scale: 0.75))
      })) #h(4pt) *direct* — real experience #text(fill: rgb("#5C5C5C"))[(model-free path)]],
      [#box(baseline: -1pt, cetz.canvas(length: 1cm, {
        import cetz.draw: *
        line((0, 0), (0.95, 0), stroke: (paint: rgb("#73000A"), thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.75))
      })) #h(4pt) #text(fill: rgb("#73000A"))[*planning*] — simulated experience #text(fill: rgb("#5C5C5C"))[(from the model)]],
    )
  ]
  #v(4pt)
  #text(size: 8.5pt, fill: rgb("#5C5C5C"))[
    Both families apply the *same* update to $Q$ / $pi$ — they differ only in the source of experience.
  ]
]
