// Policy gradient / REINFORCE as a computation graph — the score-function estimator
// (Sutton & Barto, Ch. 13; OpenAI Spinning Up; Williams 1992; Prince UDL).
//
// The policy network π(a | s; θ) maps a state s (and sampled action a) to a log-
// probability  log π(a | s; θ). Per time step t this log-prob is MULTIPLIED by the
// return / advantage A_t (the credit assigned to the action), and these products are
// SUMMED / averaged over the trajectory into the surrogate objective
//        J(θ) = E[ Σ_t A_t · log π(a_t | s_t; θ) ].
// Because A_t is treated as a constant w.r.t. θ, differentiating recovers the
// score-function (REINFORCE) gradient estimator
//        ∇_θ J(θ) = E[ Σ_t A_t · ∇_θ log π(a_t | s_t; θ) ],
// which ascends to increase the probability of high-advantage actions. The dashed
// garnet edge is exactly this gradient flowing back into the policy parameters θ.
//
// Hand-composed in raw cetz so every op-node, port, and the reverse grad edge are
// placed exactly — built from textbook knowledge in mlatlas's print-first house
// style; no figure traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

// ── brand palette ──────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: ink)[Policy gradient (REINFORCE): the score-function estimator]

  #v(2pt)
  #text(size: 9.5pt, fill: muted)[
    $J(theta) = EE[ sum_t A_t dot.c log pi(a_t mid(|) s_t\; theta) ]$,
    #h(10pt)
    $nabla_theta J(theta) = EE[ sum_t A_t dot.c nabla_theta log pi(a_t mid(|) s_t\; theta) ]$
  ]

  #v(16pt)

  #cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // ── geometry ───────────────────────────────────────────────────────────
    let spy   = 0          // main spine y (the op chain lives here)
    let leafy = 1.95       // leaf-input row (state / action), above the spine
    let gy    = -2.05      // gradient-tape y, below the spine

    let R  = 0.46          // op-node radius

    // x positions along the spine
    let x-pol = 0.0        // policy network block (center x)
    let x-log = 3.5        // log-prob node
    let x-mul = 6.4        // multiply op
    let x-sum = 9.1        // sum / expectation op
    let x-obj = 11.9       // objective J(theta)

    // leaf x positions (inputs feeding the policy net)
    let x-s = x-pol - 1.7  // state s_t
    let x-a = x-pol + 1.7  // action a_t (sampled)
    // advantage leaf feeds the multiply node from above
    let x-A = x-mul

    // ── styles ───────────────────────────────────────────────────────────────
    let fwd  = (stroke: 1pt + ink, mark: (end: "stealth", scale: 0.7))
    let grad = (stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))

    // op node: light circle, dark glyph
    let op(x, glyph, r: R, fill: white, sz: 13pt, stroke: 1.1pt + ink) = {
      circle((x, spy), radius: r, fill: fill, stroke: stroke)
      content((x, spy), text(size: sz, fill: ink)[#glyph])
    }
    // leaf node: small tinted rounded-free box
    let leaf(x, y, body, accent, hw: 0.62) = {
      rect((x - hw, y - 0.42), (x + hw, y + 0.42), fill: beige, stroke: 1.3pt + accent, radius: 0pt)
      content((x, y), body)
    }

    // ════════════════════════ FORWARD DATA EDGES (solid) ════════════════════
    // state s_t → policy net   (down into top-left of the policy block)
    line((x-s, leafy - 0.42), (x-pol - 0.55, spy + 0.66), ..fwd)
    // action a_t → policy net  (the action whose log-prob we score)
    line((x-a, leafy - 0.42), (x-pol + 0.55, spy + 0.66), ..fwd)

    // policy net → log-prob node
    line((x-pol + 1.45, spy), (x-log - R - 0.02, spy), ..fwd)
    // log-prob → multiply
    line((x-log + R + 0.02, spy), (x-mul - R - 0.02, spy), ..fwd)
    // advantage A_t → multiply (from above)
    line((x-A, leafy - 0.42), (x-mul, spy + R + 0.02), ..fwd)
    // multiply → sum
    line((x-mul + R + 0.02, spy), (x-sum - R - 0.02, spy), ..fwd)
    // sum → objective
    line((x-sum + R + 0.02, spy), (x-obj - 1.05, spy), ..fwd)

    // forward intermediate-value tags above the spine wires
    let tag(x, y, s) = content((x, y), text(size: 8pt, fill: muted)[#s])
    tag((x-log + x-mul) / 2, spy + 0.32, [$log pi$])
    tag((x-mul + x-sum) / 2, spy + 0.32, [$A_t log pi$])

    // ════════════════════════ NODES ═════════════════════════════════════════
    // leaf inputs
    leaf(x-s, leafy, text(size: 9.5pt, fill: ink)[state $s_t$], ink)
    leaf(x-a, leafy, align(center)[#text(size: 9.5pt, fill: ink)[action $a_t$]\ #text(size: 7pt, fill: muted)[sampled]], ink, hw: 0.78)
    // advantage leaf — the credit signal (focal-adjacent; outlined garnet, treated as const wrt θ)
    leaf(x-A, leafy, align(center)[#text(size: 9.5pt, fill: ink)[advantage $A_t$]\ #text(size: 7pt, fill: muted)[return / baseline]], garnet, hw: 1.05)

    // policy network block (the parameterized module — garnet focal outline)
    rect((x-pol - 1.45, spy - 0.78), (x-pol + 1.45, spy + 0.78), fill: b10, stroke: 2.2pt + garnet, radius: 0pt)
    content((x-pol, spy + 0.30), text(size: 9.5pt, weight: "bold", fill: ink)[policy net])
    content((x-pol, spy - 0.18), text(size: 9.5pt, fill: ink)[$pi(a mid(|) s\; theta)$])
    content((x-pol, spy - 0.56), text(size: 7pt, fill: muted)[parameters $theta$])

    // log-prob node (a function node, drawn as a sharp box on the spine)
    rect((x-log - 0.92, spy - 0.5), (x-log + 0.92, spy + 0.5), fill: white, stroke: 1.2pt + ink, radius: 0pt)
    content((x-log, spy), text(size: 9.5pt, fill: ink)[$log pi$])

    // multiply op-node
    op(x-mul, $times$, sz: 14pt)
    // sum / expectation op-node
    op(x-sum, $sum$, sz: 14pt)

    // objective J(theta) — the scalar output
    rect((x-obj - 1.05, spy - 0.55), (x-obj + 1.05, spy + 0.55), fill: beige, stroke: 1.5pt + ink, radius: 0pt)
    content((x-obj, spy + 0.16), text(size: 10pt, fill: ink)[$J(theta)$])
    content((x-obj, spy - 0.24), text(size: 7pt, fill: muted)[objective])

    // ════════════════════════ REVERSE GRAD EDGE (dashed garnet) ═════════════
    // ∇_θ J seeds at the objective, runs LEFT along the tape, and rises back into
    // the policy net's parameters θ. The score-function: A_t is a constant scale,
    // so only ∇_θ log π flows — i.e. the gradient lands on θ inside the policy net.
    line(
      (x-obj, spy - 0.55),                 // drop from objective bottom
      (x-obj, gy),
      (x-pol, gy),                          // run left along the gradient tape
      (x-pol, spy - 0.78),                  // rise into the policy net (params θ)
      ..grad,
    )
    // seed label at the objective
    content((x-obj + 0.12, (spy - 0.55 + gy) / 2 + 0.1), anchor: "west",
            text(size: 7.5pt, fill: garnet)[$(partial J)/(partial J) = 1$])
    // the score-function gradient carried back along the tape
    content(((x-obj + x-pol) / 2, gy - 0.34),
            text(size: 8.5pt, fill: garnet)[$nabla_theta J = EE[sum_t A_t thin nabla_theta log pi(a_t mid(|) s_t\; theta)]$])
    // landing annotation: gradient ascent update on θ
    content((x-pol - 1.55, spy - 0.78 - 0.18), anchor: "east",
            text(size: 7.5pt, fill: garnet)[$theta arrow.l theta + alpha nabla_theta J$])

    // a small tick noting A_t is detached (stop-gradient) on the multiply path
    content((x-mul + 0.04, spy - R - 0.30), anchor: "north",
            text(size: 7pt, fill: muted)[$A_t$: stop-grad])
  })

  #v(14pt)
  // legend ----------------------------------------------------------------------
  #cetz.canvas(length: 1cm, {
    import cetz.draw: *
    line((0, 0), (1.1, 0), stroke: 1pt + ink, mark: (end: "stealth", scale: 0.7))
    content((1.3, 0), anchor: "west", text(size: 8.5pt, fill: ink)[forward (sample, score, weight, sum)])
    line((7.3, 0), (8.4, 0), stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
    content((8.6, 0), anchor: "west", text(size: 8.5pt, fill: garnet)[backward (policy gradient, ascent on $theta$)])
  })

  #v(6pt)
  #box(width: 16cm, [
    #set par(justify: false)
    #set align(center)
    #text(size: 8.5pt, fill: muted)[
      The estimator weights each action's log-probability by its advantage #text(fill: garnet)[$A_t$]
      and sums over the trajectory. Differentiating the surrogate $J(theta)$ — with $A_t$ held
      constant (a stop-gradient) — yields the *score function* $A_t thin nabla_theta log pi$:
      ascending it raises the probability of actions with positive advantage and lowers it for
      negative ones.
    ]
  ])
]
