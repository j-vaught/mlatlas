// Kalman filter — signal-flow block diagram of the predict/update recursion
// (Kalman 1960; Barber BRML §24; Murphy "Probabilistic Machine Learning" book 2).
//
// Standard control-systems schematic of the linear-Gaussian state-space estimator.
// At each step k the filter alternates two stages, with a unit-delay z^-1 closing
// the recursion:
//
//   PREDICT  (time update — push the belief forward through the dynamics):
//     state       x̂_{k|k-1} = F x̂_{k-1|k-1} + B u_k
//     covariance  P_{k|k-1}  = F P_{k-1|k-1} Fᵀ + Q
//
//   UPDATE   (measurement update — fold in the new observation z_k):
//     innovation  ỹ_k = z_k − H x̂_{k|k-1}                  (summing junction)
//     gain        K_k = P_{k|k-1} Hᵀ (H P_{k|k-1} Hᵀ + R)⁻¹
//     state       x̂_{k|k} = x̂_{k|k-1} + K_k ỹ_k            (summing junction)
//     covariance  P_{k|k}  = (I − K_k H) P_{k|k-1}
//
// The corrected estimate (x̂_{k|k}, P_{k|k}) is delayed one step by z^-1 and fed
// back as the prior for step k+1 — the feedback loop of the recursion. Built from
// textbook knowledge in mlatlas's print-first house style — no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

#let garnet = rgb("#73000A")
#let grey = rgb("#5C5C5C")

// ── the recursion, as an explicit IR signal-flow graph ──────────────────────
// Flow runs left → right (u axis); the z^-1 delay back-edge wraps the BOTTOM
// gutter from the corrected estimate to the predictor, closing the loop.
//
//   u_k          ┌─────────┐         ⊖ ─► K_k ─► ⊕ ──► x̂_{k|k} ──► z^-1
//    │           │ PREDICT │  prior  │z_k       prior         │
//    └──────────►│ x̂,P     ├────────►│innov.  gain  corr.     │
//                └─────────┘         ▲  (measurement z_k)     │
//                     ▲              feeds ⊖ summing junction │
//                     └──────────────── delayed prior ◄───────┘
#let g = graph(
  nodes: (
    // control input u_k (drives the predictor's B u_k term)
    ir-node("u", label: [control\ $bold(u)_k$], role: "data", kind: "circle", pos: (-0.4, -1.6)),

    // PREDICT — time update
    ir-node(
      "pred",
      label: [
        *Predict* #h(2pt) #text(size: 7.5pt, fill: grey)[(time update)]
        #v(2pt)
        $hat(bold(x))_(k|k-1) = bold(F) hat(bold(x))_(k-1|k-1) + bold(B) bold(u)_k$
        #v(1pt)
        $bold(P)_(k|k-1) = bold(F) bold(P)_(k-1|k-1) bold(F)^top + bold(Q)$
      ],
      role: "op", pos: (1.3, 0), width: 56mm,
    ),

    // innovation summing junction:  ỹ_k = z_k − H x̂_{k|k-1}
    ir-node("sum1", label: [$minus.o$], role: "op", kind: "circle", pos: (3.4, 0), width: 7mm, height: 7mm),

    // measurement z_k entering the innovation junction from below
    ir-node("z", label: [measure\ $bold(z)_k$], role: "data", kind: "circle", pos: (3.4, 1.6)),

    // Kalman gain — the focal node of the whole diagram
    ir-node(
      "gain",
      label: [
        *Gain*
        #v(2pt)
        $bold(K)_k = bold(P)_(k|k-1) bold(H)^top$
        #v(1pt)
        $(bold(H) bold(P)_(k|k-1) bold(H)^top + bold(R))^(-1)$
      ],
      role: "op", pos: (5.2, 0), width: 48mm, emphasis: true,
    ),

    // state-update summing junction:  x̂_{k|k} = x̂_{k|k-1} + K_k ỹ_k
    ir-node("sum2", label: [$plus.o$], role: "op", kind: "circle", pos: (7.2, 0), width: 7mm, height: 7mm),

    // corrected estimate — the filter output for step k
    ir-node(
      "corr",
      label: [
        *Update* #h(2pt) #text(size: 7.5pt, fill: grey)[(meas. update)]
        #v(2pt)
        $hat(bold(x))_(k|k) = hat(bold(x))_(k|k-1) + bold(K)_k tilde(bold(y))_k$
        #v(1pt)
        $bold(P)_(k|k) = (bold(I) - bold(K)_k bold(H)) bold(P)_(k|k-1)$
      ],
      role: "output", pos: (9.5, 0), width: 56mm,
    ),

    // unit-delay element — the memory that closes the recursion
    ir-node("delay", label: [$bold(z)^(-1)$], role: "memory", kind: "circle", pos: (11.6, 0), width: 11mm, height: 11mm),
  ),
  edges: (
    // control input feeds the predictor
    ("u", "pred", (label: [$bold(B) bold(u)_k$])),

    // predicted prior fans out: to the innovation junction (via −H x̂) and to the gain,
    // and is the baseline added back at the state-update junction.
    // route:"straight" keeps the spine a clean horizontal signal-flow line
    // (nodes are >1 grid-unit apart, which would otherwise auto-route up-and-over).
    ("pred", "sum1", (route: "straight", label: [prior $hat(bold(x))_(k|k-1)$,  $bold(P)_(k|k-1)$])),
    ("z", "sum1", (label: [$bold(z)_k$])),

    // innovation ỹ_k drives the gain
    ("sum1", "gain", (route: "straight", label: [innovation $tilde(bold(y))_k$])),

    // gain-scaled correction K_k ỹ_k into the state-update junction
    ("gain", "sum2", (route: "straight", label: [$bold(K)_k tilde(bold(y))_k$])),

    // predicted state added straight through to the update junction (the "+" baseline).
    // Routed along a clearly separated lane ABOVE the main spine so it reads as a
    // distinct feed-forward tap of the predicted state, not part of the spine.
    (
      "pred", "sum2",
      (
        kind: "data", route: "gutter", gutter: -1.5,
        label: [feed-forward predicted state  $hat(bold(x))_(k|k-1)$],
        style: (stroke: (paint: grey, thickness: 0.9pt, dash: "dotted")),
      ),
    ),

    // corrected estimate out, then through the unit delay
    ("sum2", "corr", (route: "straight")),
    ("corr", "delay", (route: "straight", label: [$hat(bold(x))_(k|k)$,  $bold(P)_(k|k)$])),

    // z^-1 FEEDBACK: delayed posterior becomes the prior for step k+1 —
    // the recursion's loop, routed through the bottom gutter (garnet control edge).
    (
      "delay", "pred",
      (
        kind: "control", route: "gutter", gutter: 2.4,
        label: [delayed prior  $hat(bold(x))_(k-1|k-1)$,  $bold(P)_(k-1|k-1)$  ·  $k arrow.l k+1$],
        style: (stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed")),
      ),
    ),
  ),
)

#align(center)[
  #render(g)
  #v(8pt)
  #text(size: 8.5pt, fill: grey)[
    Linear-Gaussian state space:  $bold(x)_k = bold(F) bold(x)_(k-1) + bold(B) bold(u)_k + bold(w)_k$,  $bold(w)_k tilde cal(N)(0, bold(Q))$
    #h(10pt) ·  #h(10pt)
    $bold(z)_k = bold(H) bold(x)_k + bold(v)_k$,  $bold(v)_k tilde cal(N)(0, bold(R))$
  ]
]
