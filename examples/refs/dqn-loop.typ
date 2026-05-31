// Deep Q-Network (DQN) learning loop — the standard off-policy value-learning diagram
// (OpenAI Spinning Up "DQN"; Sutton & Barto, Ch. 6 & 16; Kochenderfer, "Algorithms for
//  Decision Making"; Mnih et al. 2015, Atari DQN).
//
// Off-policy value learning, drawn as one update step:
//   • the agent's transitions (s, a, r, s′, done) are stored in an EXPERIENCE-REPLAY
//     buffer D (the cylinder), which is sampled to form an i.i.d. minibatch — this
//     decorrelates the data;
//   • the ONLINE Q-network Q(s,a; θ) scores the taken action a → Q(s,a; θ);
//   • a frozen TARGET network Q(s′,a′; θ⁻) scores the next state. Its weights are a
//     PERIODIC COPY of the online net (dashed garnet edge, every C steps: θ⁻ ← θ),
//     which stabilises the regression target;
//   • the TD-TARGET op forms  y = r + γ · max_{a′} Q(s′,a′; θ⁻)  (zeroed when done);
//   • the MSE / Huber LOSS  L = (y − Q(s,a; θ))²  is minimised, and the gradient flows
//     back to the ONLINE net ONLY (dashed grad edge) — the target net is not trained.
// Hand-composed in raw cetz so every port + orthogonal route is exact; built from
// textbook knowledge in mlatlas's print-first house style — no figure traced.
#import "../../lib.typ": *
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

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── geometry: a left memory column, two stacked network rows, a target chain ──
  let xBuf = -6.3   // replay buffer column
  let xQ   = -1.7   // online Q-net column
  let xTgt =  3.0   // TD-target op column
  let xLoss = 7.0   // loss column

  let yTop =  2.3   // online row (taken-action branch)
  let yBot = -2.3   // target row  (next-state / max branch)

  // box half-sizes
  let bh = 0.66
  let bhh = 0.92

  // ── styles ──────────────────────────────────────────────────────────────
  let fwd  = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.8))
  let copy = (stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.8))
  let grad = (stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.8))

  // ── box helper: sharp corners, light fill, dark text ─────────────────────
  let box(cx, cy, body, hw: 1.7, hh: bh, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  let E(cx, cy, hw: 1.7) = (cx + hw, cy)
  let W(cx, cy, hw: 1.7) = (cx - hw, cy)
  let N(cx, cy, hh: bh) = (cx, cy + hh)
  let S(cx, cy, hh: bh) = (cx, cy - hh)

  // ════════════════════════ REPLAY BUFFER (cylinder) ══════════════════════
  // Experience-replay memory D, drawn as a database cylinder.
  let cw = 1.45        // half-width
  let ch = 2.05        // half-height of the barrel
  let cap = 0.50       // ellipse cap half-height
  let cyTop = (yTop + yBot) / 2 + 0.0   // centre between the two rows
  // barrel body
  rect((xBuf - cw, cyTop - ch), (xBuf + cw, cyTop + ch), fill: b10, stroke: 1.2pt + ink, radius: 0pt)
  // mask the rounded top/bottom with white then draw caps so the rect's flat edges read as a cylinder
  // top cap (front + back arcs of an ellipse)
  line((xBuf - cw, cyTop + ch), (xBuf - cw, cyTop + ch), stroke: none)
  // draw the top ellipse cap
  merge-path(close: true, fill: b30, stroke: 1.2pt + ink, {
    bezier((xBuf - cw, cyTop + ch), (xBuf + cw, cyTop + ch), (xBuf - cw, cyTop + ch + cap), (xBuf + cw, cyTop + ch + cap))
    bezier((xBuf + cw, cyTop + ch), (xBuf - cw, cyTop + ch), (xBuf + cw, cyTop + ch - cap), (xBuf - cw, cyTop + ch - cap))
  })
  // bottom front arc (the visible curved base of the barrel)
  bezier((xBuf - cw, cyTop - ch), (xBuf + cw, cyTop - ch), (xBuf - cw, cyTop - ch - cap), (xBuf + cw, cyTop - ch - cap), stroke: 1.2pt + ink)
  // stored-transition "stripes" inside the barrel
  for i in range(3) {
    let yy = cyTop + 0.9 - i * 0.95
    line((xBuf - cw + 0.22, yy), (xBuf + cw - 0.22, yy), stroke: 0.6pt + b30)
  }
  // labels
  content((xBuf, cyTop + ch + 0.95), text(size: 9.5pt, weight: "bold", fill: ink)[Replay buffer $cal(D)$])
  content((xBuf, cyTop + ch - 0.30), text(size: 8pt, fill: muted)[$(s, a, r, s', d)$])
  content((xBuf, cyTop - ch - 0.95), text(size: 8pt, fill: muted)[experience replay])

  // ════════════════════════ NETWORK + OP NODES ════════════════════════════
  // Online Q-network (top) — focal garnet outline (the only trained network)
  box(
    xQ, yTop,
    align(center)[*Online* Q-net\ #text(size: 8.5pt)[$Q(s, a thin\; thin bold(theta))$]],
    hw: 1.85, hh: bhh, fill: b10, bstroke: 2.2pt + garnet,
  )
  // Target Q-network (bottom) — frozen
  box(
    xTgt - 2.6, yBot,
    align(center)[*Target* Q-net\ #text(size: 8.5pt)[$Q(s', a' thin\; thin bold(theta)^-)$]\ #text(size: 7.5pt, fill: muted)[frozen]],
    hw: 1.85, hh: bhh, fill: white, bstroke: 1.1pt + muted,
  )

  // max_a′ op (bottom, circle)
  let mr = 0.62
  let xMax = xTgt + 0.0
  circle((xMax, yBot), radius: mr, fill: white, stroke: 1.2pt + ink)
  content((xMax, yBot), text(size: 10pt, fill: ink)[max])
  content((xMax, yBot - mr - 0.30), text(size: 7.5pt, fill: muted)[over $a'$])

  // TD-target op  y = r + γ·max  (centre)
  let xY = xTgt + 0.0
  let yY = (yTop + yBot) / 2 + 0.0
  let yr = 0.66
  box(
    xY, yY,
    align(center)[TD-target\ #text(size: 8.5pt)[$y = r + gamma thin max_(a') Q$]],
    hw: 1.85, hh: 0.74, fill: beige,
  )

  // Loss (right)
  box(
    xLoss, yY,
    align(center)[*Loss*\ #text(size: 8.5pt)[$L = (y - Q(s,a\;bold(theta)))^2$]],
    hw: 2.1, hh: 0.86, fill: b10, bstroke: 1.4pt + ink,
  )

  // ════════════════════════ FORWARD EDGES (solid) ═════════════════════════
  // buffer → online Q-net (the (s,a) of the sampled minibatch), top branch
  line(
    (xBuf + cw, yTop),
    (xQ - 1.85, yTop),
    ..fwd,
  )
  content(((xBuf + cw + xQ - 1.85) / 2, yTop + 0.34), text(size: 8pt, fill: ink)[minibatch $(s, a)$], anchor: "center")

  // buffer → target Q-net (the s′ of the sampled minibatch), bottom branch
  line(
    (xBuf + cw, yBot),
    (xTgt - 2.6 - 1.85, yBot),
    ..fwd,
  )
  content(((xBuf + cw + xTgt - 2.6 - 1.85) / 2, yBot + 0.30), text(size: 8pt, fill: ink)[next state $s'$])

  // online Q-net → loss : Q(s,a;θ) prediction, routed along the top then down into loss
  line(
    E(xQ, yTop, hw: 1.85),
    (xLoss, yTop),
    (xLoss, yY + 0.86),
    ..fwd,
  )
  content(((xQ + 1.85 + xLoss) / 2, yTop + 0.30), text(size: 8pt, fill: muted)[$Q(s, a\; bold(theta))$])

  // target Q-net → max op
  line(E(xTgt - 2.6, yBot, hw: 1.85), (xMax - mr, yBot), ..fwd)
  content((xTgt - 2.6 + 1.85 + 0.30, yBot + 0.34), text(size: 8pt, fill: muted)[$Q(s', dot.c)$], anchor: "west")

  // max op → TD-target (up the centre, into the bottom of the y box)
  line((xMax, yBot + mr), (xY, yY - 0.74), ..fwd)
  content((xY + 0.62, (yBot + mr + yY - 0.74) / 2), text(size: 8pt, fill: muted)[$max_(a') Q$], anchor: "west")
  // reward r enters the TD-target from the left (from the sampled transition in D):
  // branch off the buffer at mid-height, run right then up into the y box's left port.
  let yRwd = yY - 0.30
  line(
    (xBuf + cw, yRwd),
    (xY - 1.85, yRwd),
    ..fwd,
  )
  content((xBuf + cw + 0.9, yRwd + 0.30), text(size: 8pt, fill: ink)[reward $r$])

  // TD-target → loss : the regression target y, into loss from the left
  line(E(xY, yY, hw: 1.85), W(xLoss, yY, hw: 2.1), ..fwd)
  content(((xY + 1.85 + xLoss - 2.1) / 2, yY + 0.30), text(size: 8pt, fill: ink)[target $y$])

  // ════════════════════════ PERIODIC TARGET SYNC (dashed garnet) ══════════
  // online net θ → target net θ⁻, copied every C steps. Routed straight DOWN the
  // gutter between the two network columns so it reads as the periodic "freeze /
  // copy" control edge linking the trained net to its frozen twin.
  let xTgtN = xTgt - 2.6
  let xSync = (xQ + xTgtN) / 2 - 0.2
  line(
    S(xQ, yTop, hh: bhh),
    (xQ, yTop - bhh - 0.45),
    (xSync, yTop - bhh - 0.45),
    (xSync, yBot + bhh + 0.45),
    (xTgtN, yBot + bhh + 0.45),
    N(xTgtN, yBot, hh: bhh),
    ..copy,
  )
  content((xSync + 0.2, (yTop + yBot) / 2), anchor: "west", text(size: 8pt, fill: garnet)[
    #set par(leading: 3pt)
    every $C$ steps:\ $bold(theta)^- arrow.l bold(theta)$
  ])

  // ════════════════════════ GRADIENT TO ONLINE NET ONLY (dashed garnet) ════
  // ∇_θ L flows from the loss back to the ONLINE network only. Routed up over the top.
  let yGrad = yTop + bhh + 0.95
  line(
    (xLoss, yY + 0.86),
    (xLoss, yGrad),
    (xQ, yGrad),
    N(xQ, yTop, hh: bhh),
    ..grad,
  )
  content(((xQ + xLoss) / 2, yGrad + 0.28), text(size: 8.5pt, fill: garnet)[
    gradient step  $bold(theta) arrow.l bold(theta) - alpha thin nabla_(bold(theta)) L$
  ])
  // explicit "only the online net is trained" cue: a small ✕ on the target net's grad
  content((xTgt - 2.6, yBot - bhh - 0.55), text(size: 7.5pt, fill: muted)[no gradient — weights copied, not trained])

  // ════════════════════════ TITLE / OBJECTIVE STRIP ═══════════════════════
  content(
    (xY + 0.2, yGrad + 0.95),
    text(size: 12pt, weight: "bold", fill: ink)[Deep Q-Network (DQN) update],
  )
})
