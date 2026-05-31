// Generalized policy iteration (GPI) cycle — the interleaved loop at the heart of
// dynamic-programming control (Sutton & Barto, "Reinforcement Learning: An
// Introduction", ch. 4; Kochenderfer, "Algorithms for Decision Making").
//
// Standard ML-course schematic. Two processes alternate and pull the policy and the
// value function toward mutual consistency:
//   • Policy evaluation — make the value function V consistent with the current policy π
//       by (iteratively) applying the Bellman expectation backup until V ≈ V^π:
//         V(s) ← Σ_a π(a|s) Σ_{s',r} p(s',r | s,a) [ r + γ V(s') ].
//   • Policy improvement — make π greedy with respect to the freshly evaluated V,
//       acting one step better than before:
//         π'(s) ← argmax_a Σ_{s',r} p(s',r | s,a) [ r + γ V(s') ].
// Each improvement that changes the policy strictly increases V (policy-improvement
// theorem). The two operations chase each other — "evaluation" drives V up to the line
// V = V^π, "improvement" drives π up to the line π = greedy(V) — and they meet only at
// the joint fixed point, the optimal pair (π*, V*) satisfying the Bellman optimality
// equation. When an improvement step leaves π unchanged, the loop has converged.
// Built from textbook knowledge in mlatlas's print-first house style — no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

#let garnet = rgb("#73000A")
#let grey = rgb("#5C5C5C")

// ── the GPI cycle, as an explicit IR graph ──────────────────────────────────
//   Two process blocks on one horizontal row (v = 0); u grows rightward:
//
//     init π⁰,V⁰        EVALUATION  ──── V ≈ V^π ───►  IMPROVEMENT  ──── stable? ──► (π*,V*)
//                          ▲                                │
//                          └──────── π ← greedy(V) ─────────┘   (control back-edge)
//
//   Top forward edge carries the freshly evaluated value V into improvement.
//   The bottom control back-edge carries the improved (greedy) policy π back to be
//   re-evaluated, closing the loop. A solid garnet data edge ("evaluated V") is the
//   focal signal; the convergence node (π*, V*) is the focal target.
#let g = graph(
  nodes: (
    ir-node(
      "init",
      label: [initialize\ $pi^((0)) , thin V^((0))$],
      role: "data", pos: (0, 0), width: 22mm,
    ),
    ir-node(
      "eval",
      label: [
        *Policy evaluation*
        #v(1pt)
        #text(size: 8pt, fill: grey)[make $V$ consistent with $pi$]
        #v(1pt)
        $V(s) <- sum_a pi(a | s) sum_(s', r) p(s', r | s, a) [r + gamma V(s')]$
      ],
      role: "op", pos: (1.9, 0), width: 62mm,
    ),
    ir-node(
      "improve",
      label: [
        *Policy improvement*
        #v(1pt)
        #text(size: 8pt, fill: grey)[make $pi$ greedy w.r.t. $V$]
        #v(1pt)
        $pi'(s) <- arg max_a sum_(s', r) p(s', r | s, a) [r + gamma V(s')]$
      ],
      role: "op", pos: (5.7, 0), width: 62mm,
    ),
    ir-node("stable", label: [policy\ stable?], role: "control", kind: "diamond", pos: (9.0, 0), emphasis: true),
    ir-node(
      "star",
      label: [$pi^* , thin V^*$],
      role: "output", kind: "circle", pos: (10.6, 0), emphasis: true,
    ),
  ),
  edges: (
    ("init", "eval", (route: "straight")),
    // forward: the converged value of the current policy flows into improvement.
    // The focal signal — drawn as a solid garnet data edge.
    (
      "eval", "improve",
      (
        kind: "data", route: "straight",
        label: [evaluated $V approx V^pi$],
        style: (stroke: (paint: garnet, thickness: 1.4pt, dash: none)),
      ),
    ),
    ("improve", "stable", (route: "straight", label: [$pi' = "greedy"(V)$])),
    // "yes": improvement left the policy unchanged — we have reached the joint
    // fixed point (Bellman optimality). Emit the optimal pair.
    ("stable", "star", (route: "straight", label: [yes])),
    // "no": the policy changed — loop the new greedy policy back to be re-evaluated.
    // Control back-edge routed through the bottom gutter, advancing the iteration k.
    (
      "stable", "eval",
      (
        kind: "control", route: "gutter", gutter: 2.4,
        label: [no  ·  $pi <- pi'$ ,  $k <- k + 1$],
        style: (stroke: (paint: grey, thickness: 1.2pt, dash: "dashed")),
      ),
    ),
  ),
)

#align(center)[
  #render(g)
  #v(7pt)
  #text(size: 8.5pt, fill: grey)[
    Generalized policy iteration: evaluation drives $V arrow.r V^pi$, improvement drives
    $pi arrow.r "greedy"(V)$ — they meet only at the optimal pair $(pi^*, V^*)$.
  ]
]
