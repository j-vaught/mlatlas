// Agent–environment interaction loop — the core cycle of reinforcement learning
// (Sutton & Barto, "Reinforcement Learning: An Introduction"; OpenAI Spinning Up;
//  Kochenderfer, "Algorithms for Decision Making"; UDL deep-RL chapter).
//
// Standard ML-course schematic of the MDP control loop. At each discrete step t:
//   • the Agent observes the current state S_t and reward R_t,
//   • it selects an action  A_t = π(·|S_t)  according to its policy π,
//   • the Environment receives A_t and, governed by its dynamics
//       p(s', r | s, a) = P[S_{t+1}=s', R_{t+1}=r | S_t=s, A_t=a],
//     emits the next state S_{t+1} and the scalar reward R_{t+1},
//   • these are fed back to the Agent — closing the loop — and t advances.
// The agent's objective is to maximize the expected discounted return
//   G_t = Σ_{k≥0} γ^k R_{t+k+1}.
// Built from textbook knowledge in mlatlas's print-first house style — no image traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

#let garnet = rgb("#73000A")
#let grey = rgb("#5C5C5C")

// ── the interaction loop, as an explicit IR graph ───────────────────────────
//   Two blocks on one horizontal row (v = 0); u grows rightward:
//
//        ┌──────────┐   action A_t = π(·|S_t)   ┌──────────────┐
//        │  AGENT   │  ───────────────────────► │ ENVIRONMENT  │
//        │  policy π│                           │ dynamics p   │
//        └──────────┘  ◄─────────────────────── └──────────────┘
//                       state S_{t+1}, reward R_{t+1}   (feedback gutter)
//
//   The forward edge (top) carries the action; the curved control back-edge
//   routed through the BOTTOM gutter carries the next state and reward,
//   closing the cycle. The Environment is the focal (garnet) block.
#let g = graph(
  nodes: (
    ir-node(
      "agent",
      label: [
        *Agent*
        #v(1pt)
        #text(size: 8pt, fill: grey)[policy $pi(a | s)$]
      ],
      role: "op", pos: (0, 0), width: 34mm,
    ),
    ir-node(
      "env",
      label: [
        *Environment*
        #v(1pt)
        #text(size: 8pt, fill: grey)[dynamics $p(s', r | s, a)$]
      ],
      role: "op", pos: (3.4, 0), width: 40mm, emphasis: true,
    ),
  ),
  edges: (
    // forward: the agent commits an action chosen by its policy.
    ("agent", "env", (label: [action  $A_t = pi(dot.c | S_t)$])),
    // feedback: the environment returns the consequence — next state + reward —
    // looping back through the bottom gutter and advancing the time index.
    // A solid garnet data edge: this carries real signals (S_{t+1}, R_{t+1}).
    (
      "env", "agent",
      (
        kind: "data", route: "gutter", gutter: 2.2,
        label: [state $S_(t+1)$ ,  reward $R_(t+1)$],
        style: (stroke: (paint: garnet, thickness: 1.4pt, dash: none)),
      ),
    ),
  ),
)

#align(center)[
  #render(g)
  #v(6pt)
  #text(size: 8.5pt, fill: grey)[
    Objective: maximize expected return $G_t = sum_(k >= 0) gamma^k R_(t+k+1)$
  ]
]
