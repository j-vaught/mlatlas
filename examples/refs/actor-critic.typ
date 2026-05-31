// Actor–Critic architecture — the standard policy-gradient + value-baseline agent
// (Sutton & Barto, Ch. 13; OpenAI Spinning Up; Kochenderfer; Prince UDL).
//
// One agent network with a SHARED feature trunk that fans out to two heads:
//   Actor  π(a | s; θ)  — outputs a policy / action distribution over actions
//   Critic V(s; w)      — estimates the state-value (a learned baseline)
// The agent acts in the environment; observing reward r and next state s′, the critic
// forms the one-step TD-error
//       δ = r + γ V(s′) − V(s).
// δ is the single learning signal: it is the critic's regression residual AND the
// advantage that scales the actor's policy-gradient step, so δ drives gradient updates
// into BOTH heads (dashed grad back-edges). Hand-composed in raw cetz so every port and
// orthogonal route is exact; built from textbook knowledge in mlatlas's print-first
// house style — no figure traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

// ── brand palette ──────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── geometry ──────────────────────────────────────────────────────────
  // columns (x) and rows (y, top → bottom)
  let xC =  0.0     // centre trunk
  let xL = -3.6     // left lane  (actor / action / environment)
  let xR =  3.6     // right lane (critic / value / delta)

  let yS  =  5.4    // state
  let yPh =  3.7    // shared features
  let yHd =  1.6    // heads (actor / critic)
  let yOut = -0.4   // head outputs (action / V(s))
  let yBot = -2.3   // environment / delta

  // box half-sizes
  let bw = 1.55     // standard box half-width
  let bh = 0.62     // standard box half-height
  let bhh = 0.78    // taller box (heads)

  // ── styles ────────────────────────────────────────────────────────────
  let fwd   = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.75))
  let gradC = (stroke: (paint: ink,    thickness: 1.0pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
  let gradA = (stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))

  // ── box helper: sharp corners, light fill, dark text ──────────────────
  let box(cx, cy, body, hw: bw, hh: bh, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  // edge-anchor helpers
  let N(cx, cy, hh: bh) = (cx, cy + hh)
  let S(cx, cy, hh: bh) = (cx, cy - hh)
  let E(cx, cy, hw: bw) = (cx + hw, cy)
  let W(cx, cy, hw: bw) = (cx - hw, cy)

  // ════════════════════════ NODES ════════════════════════════════════════
  // state s (centre, top)
  box(xC, yS, text(fill: ink)[state  $bold(s)$], hw: 1.15, fill: beige)

  // shared features φ(s) (centre)
  box(
    xC, yPh,
    align(center)[shared features\ #text(size: 8.5pt, fill: muted)[$phi(bold(s))$]],
    hw: 1.7,
  )

  // Actor head (left) — focal garnet outline
  box(
    xL, yHd,
    align(center)[*Actor*\ #text(size: 8pt, fill: muted)[policy net]\ #v(1pt) #text(size: 9.5pt)[$pi(a thin mid(|) thin bold(s) thin\; thin bold(theta))$]],
    hw: 1.7, hh: bhh, fill: b10, bstroke: 2.2pt + garnet,
  )
  // Critic head (right)
  box(
    xR, yHd,
    align(center)[*Critic*\ #text(size: 8pt, fill: muted)[value net]\ #v(1pt) #text(size: 9.5pt)[$V(bold(s) thin\; thin bold(w))$]],
    hw: 1.7, hh: bhh,
  )

  // action a (left)
  box(xL, yOut, text(fill: ink)[action  $a$], hw: 1.2, fill: beige)
  // V(s) (right)
  box(xR, yOut, text(fill: ink)[$V(bold(s))$], hw: 1.2, fill: beige)

  // Environment (bottom-left)
  box(
    xL, yBot,
    align(center)[*Environment*\ #text(size: 8pt, fill: muted)[$p(bold(s)' thin mid(|) thin bold(s), a)$]],
    hw: 1.7, hh: bhh,
  )

  // δ — TD-error (bottom-right), focal garnet circle
  let dr = 0.66
  circle((xR, yBot), radius: dr, fill: white, stroke: 2.2pt + garnet)
  content((xR, yBot), text(size: 12pt, fill: garnet)[$delta$])

  // ════════════════════════ FORWARD / INTERACTION (solid) ════════════════
  // state → shared features
  line(S(xC, yS, hh: 0.62), N(xC, yPh), ..fwd)

  // shared features → Actor  (down, then left along the head row top — L corner)
  line(W(xC, yPh, hw: 1.7), (xL, yPh), (xL, yHd + bhh), ..fwd)
  // shared features → Critic (down, then right — L corner)
  line(E(xC, yPh, hw: 1.7), (xR, yPh), (xR, yHd + bhh), ..fwd)
  content((xC - 1.95, yPh + 0.02), text(size: 8pt, fill: muted)[$phi$], anchor: "east")
  content((xC + 1.95, yPh + 0.02), text(size: 8pt, fill: muted)[$phi$], anchor: "west")

  // Actor → action a
  line(S(xL, yHd, hh: bhh), N(xL, yOut), ..fwd)
  content((xL - 0.18, (yHd - bhh + yOut + bh) / 2), text(size: 7.5pt, fill: muted)[sample], anchor: "east")
  // Critic → V(s)
  line(S(xR, yHd, hh: bhh), N(xR, yOut), ..fwd)

  // action a → Environment
  line(S(xL, yOut), N(xL, yBot, hh: bhh), ..fwd)

  // V(s) → δ : forward baseline value. Run it down a LEFT track (xR − off) into δ's
  // top, kept separate from the antiparallel grad edge so they don't overlap.
  let trk = 0.30
  line((xR - trk, yOut - bh), (xR - trk, yBot + dr - 0.04), ..fwd)
  content((xR - trk - 0.22, (yOut - bh + yBot + dr) / 2), text(size: 8pt, fill: muted)[$-V(bold(s))$], anchor: "east")

  // Environment → δ : reward + bootstrapped next-state value (along the bottom)
  line(E(xL, yBot, hw: 1.7), (xR - dr, yBot), ..fwd)
  content((xC, yBot + 0.30), text(size: 8.5pt, fill: ink)[$r + gamma V(bold(s)')$])

  // ════════════════════════ LEARNING SIGNAL (dashed grad) ════════════════
  // δ → Critic : value-loss gradient, up a RIGHT track (xR + off), antiparallel to V(s)↓.
  line((xR + trk, yBot + dr - 0.04), (xR + trk, yOut - bh), ..gradC)
  content((xR + trk + 0.18, (yBot + dr + yOut - bh) / 2), text(size: 7.5pt, fill: ink)[$nabla_(bold(w)) (1 slash 2) delta^2$], anchor: "west")

  // δ → Actor : policy-gradient feedback. Wrap up the FAR-LEFT outer gutter (garnet).
  let xGut = xL - 2.55
  // explicit garnet feedback polyline: δ.west → down a touch → far-left gutter → up → actor.west
  let yfb = yBot - 1.15
  line(
    (xR - dr - 0.02, yBot),
    (xR - dr - 0.4, yBot),
    (xR - dr - 0.4, yfb),
    (xGut, yfb),
    (xGut, yHd),
    W(xL, yHd, hw: 1.7),
    ..gradA,
  )
  content((xGut - 0.12, (yfb + yHd) / 2), anchor: "east", text(size: 7.5pt, fill: garnet)[$delta thin nabla_(bold(theta)) log pi$])

  // ════════════════════════ SPAN BRACKETS (agent vs world) ═══════════════
  // an "Agent" bracket spanning the network heads, and an environment tag.
  let topY = yS + 0.95
  let bx0 = xGut - 0.45
  let bx1 = xR + 1.55
  let drop = 0.18
  line((bx0, topY - drop), (bx0, topY), (bx1, topY), (bx1, topY - drop), stroke: 1.0pt + muted)
  content(((bx0 + bx1) / 2, topY + 0.28), text(size: 9pt, weight: "bold", fill: muted)[Actor–Critic agent])

  // δ legend (sharp, sparse) — centred well below the loop so it clears all edges.
  content(
    (xC + 0.4, yfb - 0.85),
    text(size: 8.5pt, fill: garnet)[TD-error:  $delta = r + gamma V(bold(s)') - V(bold(s))$],
  )
})
