// World-model agent loop (Dreamer / RSSM) — the standard model-based RL schematic
// (OpenAI Spinning Up, "model-based RL"; Kochenderfer, "Algorithms for Decision Making";
//  Hafner et al., Dreamer / RSSM). Built from textbook knowledge in mlatlas's print-first
// house style — no figure traced.
//
// Three coupled processes, drawn as one diagram:
//
//  (1) REAL-ENV DATA COLLECTION (thin top loop). The agent acts in the true environment;
//      transitions (o, a, r) are stored in a replay buffer. This is the ONLY real
//      interaction — it is rare and only used to gather data.
//
//  (2) WORLD-MODEL LEARNING (centre). Sampled sequences are encoded and folded by a
//      RECURRENT latent state (RSSM): a deterministic recurrent carry h_t plus a
//      stochastic latent z_t. Three heads decode the latent: an observation decoder
//      (reconstruct ô_t), a REWARD head (r̂_t) and a CONTINUE head (γ̂_t = P[not done]).
//      The model is trained to reconstruct / predict, by gradient descent on these heads.
//
//  (3) IMAGINATION (dashed garnet loop, bottom). With the env frozen, the PRIOR rolls the
//      latent forward purely in the model: the POLICY (actor) π picks an imagined action
//      â, the RSSM prior predicts the next latent, and the reward / continue heads supply
//      r̂, γ̂. A learned VALUE (critic) V bootstraps the return. The policy + value are
//      trained ENTIRELY on these imagined rollouts — no real-env steps are consumed.
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
#let blue   = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── styles ────────────────────────────────────────────────────────────────
  let fwd   = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.8))
  let thin  = (stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.7))
  let imag  = (stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.8))
  let grad  = (stroke: (paint: blue, thickness: 1.2pt, dash: "dashed"), mark: (end: "stealth", scale: 0.75))

  // ── box helper: sharp corners, light fill, dark text ────────────────────────
  let box(cx, cy, body, hw: 1.45, hh: 0.6, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  // edge-anchor helpers
  let E(cx, cy, hw: 1.45) = (cx + hw, cy)
  let W(cx, cy, hw: 1.45) = (cx - hw, cy)
  let N(cx, cy, hh: 0.6) = (cx, cy + hh)
  let S(cx, cy, hh: 0.6) = (cx, cy - hh)

  // ════════════════════════════════════════════════════════════════════════
  //  ROW GEOMETRY  (y, top → bottom)
  // ════════════════════════════════════════════════════════════════════════
  let yEnv  =  6.0    // real environment data-collection loop
  let yCore =  2.6    // encoder → recurrent latent → heads
  let yHead =  2.6    // decoder / reward / continue heads (same row, right side)
  let yImag = -1.6    // imagination rollout loop

  // column x-positions for the centre world-model row
  let xBuf  = -7.3    // replay buffer
  let xEnc  = -3.8    // encoder
  let xRSSM = -0.2    // recurrent latent state (focal)
  let xDec  =  4.9    // decoder / heads column
  let xRew  =  4.9    // reward head (stacked above/below decoder via y offsets)

  // ════════════════════════════════════════════════════════════════════════
  //  (1) REAL-ENV DATA-COLLECTION LOOP  (thin, top)
  // ════════════════════════════════════════════════════════════════════════
  // Environment (left) and Agent-act (right) exchange action / observation; the
  // collected transition is dropped into the replay buffer below.
  let xActEnv = -4.6
  let xActAg  =  0.6
  box(xActEnv, yEnv, align(center)[*Environment*\ #text(size: 7.5pt, fill: muted)[true dynamics $p(o' | o, a)$]],
      hw: 1.95, hh: 0.66, fill: white, bstroke: 1.0pt + muted)
  box(xActAg, yEnv, align(center)[*Act in env*\ #text(size: 7.5pt, fill: muted)[$a tilde pi(dot.c | s_t)$]],
      hw: 1.6, hh: 0.66, fill: white, bstroke: 1.0pt + muted)
  // env → act : observation
  line(E(xActEnv, yEnv, hw: 1.95), W(xActAg, yEnv, hw: 1.6), ..thin)
  content(((xActEnv + 1.95 + xActAg - 1.6) / 2, yEnv + 0.30), text(size: 7.5pt, fill: muted)[obs $o_t$])
  // act → env : action (back-edge, slightly below the row, closing the real loop)
  line((xActAg, yEnv - 0.66), (xActAg, yEnv - 1.15), (xActEnv, yEnv - 1.15), (xActEnv, yEnv - 0.66), ..thin)
  content(((xActEnv + xActAg) / 2, yEnv - 1.15), anchor: "north", text(size: 7.5pt, fill: muted)[action $a_t$])

  // store transition → replay buffer (down the left)
  line((xActEnv, yEnv - 1.15), (xActEnv, yEnv - 1.15), stroke: none)
  line((xActEnv - 1.95, yEnv), (xBuf + 0.0, yEnv), (xBuf, yEnv - 1.55), ..thin)
  content(((xActEnv - 1.95 + xBuf) / 2, yEnv - 0.28), anchor: "north", text(size: 7.5pt, fill: muted)[store $(o_t, a_t, r_t)$])

  // thin-loop annotation
  content((xActAg + 2.85, yEnv), anchor: "west", text(size: 7.5pt, fill: muted)[
    #set par(leading: 3pt)
    rare *real* steps\ (data only)
  ])

  // ════════════════════════════════════════════════════════════════════════
  //  REPLAY BUFFER (cylinder, left column)
  // ════════════════════════════════════════════════════════════════════════
  let cw = 1.25
  let ch = 1.65
  let cap = 0.42
  let cyB = (yEnv - 1.55 + yCore) / 2 - 0.1
  rect((xBuf - cw, cyB - ch), (xBuf + cw, cyB + ch), fill: b10, stroke: 1.1pt + ink, radius: 0pt)
  merge-path(close: true, fill: b30, stroke: 1.1pt + ink, {
    bezier((xBuf - cw, cyB + ch), (xBuf + cw, cyB + ch), (xBuf - cw, cyB + ch + cap), (xBuf + cw, cyB + ch + cap))
    bezier((xBuf + cw, cyB + ch), (xBuf - cw, cyB + ch), (xBuf + cw, cyB + ch - cap), (xBuf - cw, cyB + ch - cap))
  })
  bezier((xBuf - cw, cyB - ch), (xBuf + cw, cyB - ch), (xBuf - cw, cyB - ch - cap), (xBuf + cw, cyB - ch - cap), stroke: 1.1pt + ink)
  for i in range(3) {
    let yy = cyB + 0.7 - i * 0.78
    line((xBuf - cw + 0.2, yy), (xBuf + cw - 0.2, yy), stroke: 0.6pt + b30)
  }
  content((xBuf - cw - 0.15, cyB), anchor: "east", text(size: 9pt, weight: "bold", fill: ink)[
    #set par(leading: 3pt)
    Replay\ buffer $cal(D)$
  ])
  content((xBuf, cyB - ch - 0.70), text(size: 7.5pt, fill: muted)[sampled sequences])

  // ════════════════════════════════════════════════════════════════════════
  //  (2) WORLD-MODEL LEARNING  (centre row)
  // ════════════════════════════════════════════════════════════════════════
  // Encoder
  box(xEnc, yCore, align(center)[*Encoder*\ #text(size: 7.5pt, fill: muted)[$o_t arrow.r e_t$]],
      hw: 1.35, hh: 0.74, fill: b10, bstroke: 1.1pt + ink)
  // Recurrent latent state — FOCAL (garnet). RSSM: deterministic h_t + stochastic z_t.
  box(xRSSM, yCore,
      align(center)[*Recurrent latent state*\ #text(size: 7.5pt, fill: ink)[(RSSM cell)]\ #v(1pt)
        #text(size: 7.5pt)[$h_t = f(h_(t-1), z_(t-1), a_(t-1))$]\ #text(size: 7.5pt)[$z_t tilde q(z_t | h_t, e_t)$]],
      hw: 2.0, hh: 1.02, fill: beige, bstroke: 2.2pt + garnet)

  // recurrent self-loop carry on the RSSM (h_{t-1} → h_t), top arc
  let rl = 1.55
  line((xRSSM - 0.9, yCore + 1.02), (xRSSM - 0.9, yCore + rl), (xRSSM + 0.9, yCore + rl), (xRSSM + 0.9, yCore + 1.02), ..fwd)
  content((xRSSM, yCore + rl), anchor: "south", text(size: 7.5pt, fill: ink)[recurrent carry $h_(t-1) arrow.r h_t$])

  // buffer → encoder
  line((xBuf + cw, yCore), W(xEnc, yCore, hw: 1.35), ..fwd)
  content(((xBuf + cw + xEnc - 1.35) / 2, yCore + 0.30), text(size: 7.5pt, fill: ink)[$o_(1:T)$])
  // encoder → RSSM
  line(E(xEnc, yCore, hw: 1.35), W(xRSSM, yCore, hw: 2.0), ..fwd)
  content(((xEnc + 1.35 + xRSSM - 2.0) / 2, yCore + 0.28), text(size: 7.5pt, fill: muted)[$e_t$])

  // ── three decoding heads (branch out of the RSSM latent s_t = (h_t, z_t)) ──
  let yDecO = yCore + 1.35   // observation decoder (top)
  let yDecR = yCore - 0.0    // reward head (mid)
  let yDecC = yCore - 1.35   // continue head (bottom)
  box(xDec, yDecO, align(center)[*Decoder*\ #text(size: 7.5pt, fill: muted)[reconstruct $hat(o)_t$]],
      hw: 1.5, hh: 0.6, fill: white, bstroke: 1.0pt + ink)
  box(xDec, yDecR, align(center)[*Reward head*\ #text(size: 7.5pt, fill: muted)[$hat(r)_t = p(r | s_t)$]],
      hw: 1.5, hh: 0.6, fill: white, bstroke: 1.0pt + ink)
  box(xDec, yDecC, align(center)[*Continue head*\ #text(size: 7.5pt, fill: muted)[$hat(gamma)_t = p("not done")$]],
      hw: 1.5, hh: 0.6, fill: white, bstroke: 1.0pt + ink)

  // branch fan-out from the RSSM east port to the three heads
  let xFan = xRSSM + 2.0 + 0.5
  line(E(xRSSM, yCore, hw: 2.0), (xFan, yCore), stroke: 1.1pt + ink)
  content((xFan + 0.1, (yDecO + yDecR) / 2 + 0.28), anchor: "west", text(size: 7pt, fill: ink)[latent\ $s_t = (h_t, z_t)$])
  for yy in (yDecO, yDecR, yDecC) {
    line((xFan, yCore), (xFan, yy), stroke: 1.1pt + ink)
    line((xFan, yy), W(xDec, yy, hw: 1.5), ..fwd)
  }

  // reconstruction / prediction gradient: heads → world model (train the model).
  // Routed up the FAR RIGHT, across the top of the heads, then into the RSSM north
  // port — kept clear of the env row above.
  let xGcol = xDec + 1.5 + 1.0
  let yGmod = yDecO + 0.6 + 0.35
  line((xDec, yDecO + 0.6), (xGcol, yDecO + 0.6), (xGcol, yGmod), (xRSSM, yGmod), N(xRSSM, yCore, hh: 1.02), ..grad)
  content(((xRSSM + xGcol) / 2, yGmod + 0.25), text(size: 7.5pt, fill: blue)[
    train world model: $nabla$ (recon + reward + continue) loss
  ])

  // ════════════════════════════════════════════════════════════════════════
  //  (3) IMAGINATION ROLLOUT  (dashed garnet loop, bottom)
  // ════════════════════════════════════════════════════════════════════════
  // A dashed plate enclosing the in-model rollout: PRIOR predicts next latent,
  // POLICY (actor) picks imagined action, reward/continue heads + VALUE bootstrap.
  let plL = -6.6
  let plR =  6.7
  let plT = -0.2
  let plB = -3.5
  rect((plL, plB), (plR, plT), stroke: (paint: garnet, thickness: 1.1pt, dash: "dashed"), fill: none, radius: 0pt)
  content((plL + 0.2, plT - 0.2), anchor: "north-west", text(size: 8.5pt, weight: "bold", fill: garnet)[
    Imagination  ·  rollout *inside* the learned model (env frozen)
  ])

  // imagination row nodes
  let xPol  = -4.4   // policy / actor
  let xPri  = -0.2   // RSSM prior (next-latent prediction)
  let xRhat =  4.2   // reward + continue (imagined) feeding value
  box(xPol, yImag, align(center)[*Policy* (actor)\ #text(size: 7.5pt, fill: muted)[$hat(a)_t tilde pi(dot.c | s_t)$]],
      hw: 1.6, hh: 0.66, fill: white, bstroke: 1.1pt + ink)
  box(xPri, yImag, align(center)[*RSSM prior*\ #text(size: 7.5pt, fill: muted)[$hat(z)_(t+1) tilde p(z | h_(t+1))$]],
      hw: 1.7, hh: 0.66, fill: beige, bstroke: 1.4pt + garnet)
  box(xRhat, yImag, align(center)[*Value* (critic)\ #text(size: 7.5pt, fill: muted)[$V(s_t) approx EE[sum gamma^k hat(r)]$]],
      hw: 1.7, hh: 0.66, fill: white, bstroke: 1.1pt + ink)

  // policy → prior : imagined action advances the latent
  line(E(xPol, yImag, hw: 1.6), W(xPri, yImag, hw: 1.7), ..imag)
  content(((xPol + 1.6 + xPri - 1.7) / 2, yImag + 0.30), text(size: 7.5pt, fill: garnet)[$hat(a)_t$])
  // prior → value : imagined reward / continue → return estimate
  line(E(xPri, yImag, hw: 1.7), W(xRhat, yImag, hw: 1.7), ..imag)
  content(((xPri + 1.7 + xRhat - 1.7) / 2, yImag + 0.30), text(size: 7.5pt, fill: garnet)[$hat(r)_t, hat(gamma)_t$])

  // imagined latent back-edge: prior's next latent loops back to the policy (the rollout).
  // Kept inside the plate; label sits above the back-edge line so it stays clear.
  let yLoop = yImag - 1.15
  line(S(xPri, yImag, hh: 0.66), (xPri, yLoop), (xPol, yLoop), N(xPol, yImag, hh: 0.66), ..imag)
  content(((xPol + xPri) / 2, yLoop - 0.06), anchor: "north", text(size: 7.5pt, fill: garnet)[imagined next latent $hat(s)_(t+1)$  ·  $t arrow.r t+1$])

  // value → policy : the imagined return trains the actor (and critic). Blue grad.
  // Routed BELOW the plate so it does not collide with the rollout back-edge.
  let yTrain = plB - 0.55
  line((xRhat, yImag - 0.66), (xRhat, yTrain), (xPol, yTrain), (xPol, yImag - 0.66), ..grad)
  content(((xPol + xRhat) / 2, yTrain - 0.02), anchor: "north", text(size: 7.5pt, fill: blue)[train policy + value on imagined return  $hat(R)_t$])

  // ── couple the world model to imagination: the heads / prior are shared ──
  // RSSM (real) → RSSM prior (imagination): same learned dynamics, used for rollout.
  line((xRSSM, yCore - 1.02), (xRSSM, plT), ..fwd)
  content((xRSSM + 0.2, (yCore - 1.02 + plT) / 2), anchor: "west", text(size: 7.5pt, fill: muted)[
    #set par(leading: 3pt)
    learned dynamics\ used to *imagine*
  ])

  // ════════════════════════════════════════════════════════════════════════
  //  TITLE + LEGEND
  // ════════════════════════════════════════════════════════════════════════
  content((xRSSM, yEnv + 1.95), text(size: 13pt, weight: "bold", fill: ink)[World-model agent loop  (Dreamer / RSSM)])

  // legend (bottom strip), below the imagined-return training loop
  let lx = plL
  let ly = plB - 1.35
  let seg = 0.85
  // solid = forward (model)
  line((lx, ly), (lx + seg, ly), stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.7))
  content((lx + seg + 0.15, ly), anchor: "west", text(size: 7.5pt, fill: ink)[model forward])
  // thin = real env
  line((lx + 3.7, ly), (lx + 3.7 + seg, ly), stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.7))
  content((lx + 3.7 + seg + 0.15, ly), anchor: "west", text(size: 7.5pt, fill: muted)[real-env data])
  // dashed garnet = imagination
  line((lx + 7.0, ly), (lx + 7.0 + seg, ly), stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
  content((lx + 7.0 + seg + 0.15, ly), anchor: "west", text(size: 7.5pt, fill: garnet)[imagined rollout])
  // dashed blue = gradient / training
  line((lx + 10.5, ly), (lx + 10.5 + seg, ly), stroke: (paint: blue, thickness: 1.2pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
  content((lx + 10.5 + seg + 0.15, ly), anchor: "west", text(size: 7.5pt, fill: blue)[training signal])
})
