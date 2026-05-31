// EM algorithm loop — Expectation-Maximization (Dempster, Laird & Rubin 1977).
// Standard ML-course schematic: two alternating steps run in a cycle until convergence.
//   E-step: with parameters θ fixed, compute the posterior over latent variables z
//           (the "responsibilities" q(z) = p(z | x, θ)).
//   M-step: with q(z) fixed, update θ to maximize the expected complete-data
//           log-likelihood  Q(θ) = E_{q(z)}[ log p(x, z | θ) ].
// The two steps monotonically increase the data log-likelihood; a convergence test on
// its change decides whether to iterate again or stop. Built from textbook knowledge
// (Bishop PRML, Murphy, Barber) in mlatlas's print-first house style — no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

#let garnet = rgb("#73000A")

// ── the cycle, as an explicit IR graph ──────────────────────────────────────
// Single vertical column (u = 0); v grows downward:
//     init θ⁽⁰⁾
//        │
//      E-step                  (posterior over latents — responsibilities)
//        │  q(z)
//      M-step                  (re-estimate parameters)
//        │  θ⁽ᵗ⁺¹⁾
//     converged?  ◄── focal test
//        │  yes
//       θ*
// The "no" branch is a control back-edge that wraps up the LEFT gutter to the E-step.
#let g = graph(
  nodes: (
    ir-node("init", label: [initialize  $bold(theta)^((0))$], role: "data", pos: (0, 0)),
    ir-node(
      "e",
      label: [*E-step*\ #text(size: 8pt, fill: rgb("#5C5C5C"))[posterior over latents]\ #v(1pt) $q(bold(z)) = p(bold(z) thin | thin bold(x), bold(theta)^((t)))$],
      role: "op", pos: (0, 1.5), width: 46mm,
    ),
    ir-node(
      "m",
      label: [*M-step*\ #text(size: 8pt, fill: rgb("#5C5C5C"))[re-estimate parameters]\ #v(1pt) $bold(theta)^((t+1)) = arg max_(bold(theta)) thin cal(Q)(bold(theta), bold(theta)^((t)))$],
      role: "op", pos: (0, 3.0), width: 46mm,
    ),
    ir-node("conv", label: [converged?], role: "control", kind: "diamond", pos: (0, 4.5), emphasis: true),
    ir-node("out", label: [$bold(theta)^*$], role: "output", kind: "circle", pos: (0, 6.0)),
  ),
  edges: (
    ("init", "e"),
    ("e", "m", (label: [$q(bold(z))$])),
    ("m", "conv", (label: [$bold(theta)^((t+1))$])),
    // "yes": Δ log-likelihood below tolerance — emit the final parameters.
    ("conv", "out", (label: [yes])),
    // "no": not converged — loop the iteration back up to the E-step (control back-edge).
    (
      "conv", "e",
      (
        kind: "control", route: "gutter", gutter: -2.6,
        label: [no  ·  $t arrow.l t + 1$],
        style: (stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed")),
      ),
    ),
  ),
)

#render(g)
