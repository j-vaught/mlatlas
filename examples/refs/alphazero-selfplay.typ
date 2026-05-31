// AlphaGo Zero / AlphaZero self-play loop — a STANDARD ML concept taught across RL.
// (Silver et al. 2017, "Mastering the game of Go without human knowledge"; OpenAI
// Spinning Up; Kochenderfer, "Algorithms for Decision Making").
//
// One dual-head network f_θ(s) = (p, v) maps a board state s to a policy prior p over
// moves and a scalar value v ≈ expected outcome. Inside each move, MCTS uses f_θ as its
// guide: it expands a search tree using PUCT (prior p biases exploration, value v
// replaces rollouts at the leaves) and returns an improved policy π — the normalized
// root visit counts N(s,a)^{1/τ}. The agent plays π in self-play, generating games
// stored as (s, π, z) triples in a replay buffer (z = the final game outcome ±1).
// Training samples those triples and pushes f_θ toward the SEARCH targets:
//       ℓ = (z − v)² − π·log p + c‖θ‖².
// This closes the loop: search (MCTS+π) improves the net, and the better net improves
// the next search. Hand-composed in raw cetz so every port and orthogonal route is
// exact; built from textbook knowledge in mlatlas's print-first house style — no figure
// traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 10pt)

// ── brand palette ────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let gline  = rgb("#C7C7C7")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")
#let blue   = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ── styles ──────────────────────────────────────────────────────────────
  let fwd  = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.7))
  let weak = (stroke: 1.0pt + muted, mark: (end: "stealth", scale: 0.65))
  let grad = (stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.75))

  // box helper: sharp corners, light fill, dark text
  let box(cx, cy, body, hw: 1.55, hh: 0.62, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  // edge-anchor helpers
  let N(cx, cy, hh: 0.62) = (cx, cy + hh)
  let S(cx, cy, hh: 0.62) = (cx, cy - hh)
  let E(cx, cy, hw: 1.55) = (cx + hw, cy)
  let W(cx, cy, hw: 1.55) = (cx - hw, cy)

  // =========================================================================
  //  LAYOUT — three columns × loop. Net (left), MCTS (centre), play→buffer.
  // =========================================================================
  let xNet  = -6.1     // dual-head network column
  let xMcts =  0.4     // MCTS search tree column
  let xPlay =  6.2     // self-play game column

  let yMid  =  1.4     // main row (net / mcts / play)
  let yBuf  = -3.2     // replay buffer row (bottom)

  // ── board state s (top-left input) ───────────────────────────────────────
  let yTop = 4.9
  // a little 3x3 board glyph as the input state
  let bx = xNet - 0.62
  let by = yTop - 0.62
  let cell = 0.41
  for i in range(4) {
    line((bx + i * cell, by), (bx + i * cell, by + 3 * cell), stroke: 0.7pt + muted)
    line((bx, by + i * cell), (bx + 3 * cell, by + i * cell), stroke: 0.7pt + muted)
  }
  // a couple of stones
  circle((bx + 0.5 * cell, by + 2.5 * cell), radius: 0.13, fill: ink, stroke: none)
  circle((bx + 1.5 * cell, by + 1.5 * cell), radius: 0.13, fill: white, stroke: 0.9pt + ink)
  circle((bx + 2.5 * cell, by + 0.5 * cell), radius: 0.13, fill: ink, stroke: none)
  content((xNet, yTop - 1.55), text(size: 9pt, fill: ink)[state $bold(s)$])

  // ════════════════════════ DUAL-HEAD NETWORK f_θ ═════════════════════════
  // shared residual trunk
  let yTrunk = yMid + 1.5
  box(
    xNet, yTrunk,
    align(center)[*$f_(bold(theta))$* trunk\ #text(size: 7.5pt, fill: muted)[residual conv tower]],
    hw: 1.85, hh: 0.66, fill: b10,
  )
  // two heads (fan out)
  let xPh = xNet - 1.7    // policy head (left)
  let xVh = xNet + 1.7    // value head (right)
  let yHd = yMid - 0.55
  box(
    xPh, yHd,
    align(center)[*policy head*\ #text(size: 8pt)[$bold(p) = P(a | bold(s))$]],
    hw: 1.35, hh: 0.74, fill: white,
  )
  box(
    xVh, yHd,
    align(center)[*value head*\ #text(size: 8pt)[$v approx EE[z]$]],
    hw: 1.35, hh: 0.74, fill: white,
  )
  // network bracket label
  content((xNet, yMid - 1.7), text(size: 8.5pt, weight: "bold", fill: muted)[network  $f_(bold(theta))(bold(s)) = (bold(p), v)$])

  // s → trunk
  line((xNet, yTop - 2.1), N(xNet, yTrunk, hh: 0.66), ..fwd)
  // trunk → policy head, trunk → value head (fan)
  line((xNet - 0.7, yTrunk - 0.66), (xPh, yHd + 0.74), ..fwd)
  line((xNet + 0.7, yTrunk - 0.66), (xVh, yHd + 0.74), ..fwd)

  // =========================================================================
  //  MCTS SEARCH TREE (drawn small) — the net GUIDES this search.
  // =========================================================================
  // mini-renderer: a 3-level tree centred at (ox, oy). Root garnet (focal).
  let yRoot = yMid + 1.95
  let ox = xMcts
  let oy = yRoot
  // panel behind the tree
  rect((ox - 2.2, oy - 4.55), (ox + 2.2, oy + 0.7), fill: rgb("#FAFAFA"), stroke: 0.8pt + gline, radius: 0pt)
  content((ox, oy + 0.42), text(size: 9.5pt, weight: "bold", fill: garnet)[MCTS])

  // node positions
  let nr  = 0.20
  let root = (ox, oy - 0.45)
  let l1 = ((ox - 1.45, oy - 1.7), (ox - 0.0, oy - 1.7), (ox + 1.45, oy - 1.7))
  let l2 = ((ox - 1.95, oy - 3.0), (ox - 0.95, oy - 3.0), (ox + 0.95, oy - 3.0), (ox + 1.95, oy - 3.0))

  // edges root → level1 (selected branch garnet/bold = PUCT-chosen path)
  line(root, l1.at(0), stroke: 0.9pt + faint)
  line(root, l1.at(1), stroke: 1.6pt + garnet)        // selected (highest PUCT)
  line(root, l1.at(2), stroke: 0.9pt + faint)
  // level1 → level2
  line(l1.at(1), l2.at(1), stroke: 1.6pt + garnet)    // continue down the selected path
  line(l1.at(1), l2.at(2), stroke: 0.9pt + faint)
  line(l1.at(0), l2.at(0), stroke: 0.9pt + faint)
  line(l1.at(2), l2.at(3), stroke: 0.9pt + faint)

  // nodes
  circle(root, radius: nr + 0.04, fill: white, stroke: 1.8pt + garnet)   // root state (focal)
  for p in l1 { circle(p, radius: nr, fill: white, stroke: 1.0pt + ink) }
  for p in l2 { circle(p, radius: nr - 0.03, fill: b10, stroke: 0.9pt + muted) }
  // value-bootstrap leaf (instead of rollout): garnet-ringed leaf evaluated by v
  circle(l2.at(1), radius: nr - 0.01, fill: white, stroke: 1.5pt + garnet)
  content((l2.at(1).at(0) + 0.02, l2.at(1).at(1) - 0.62), text(size: 7pt, fill: garnet)[leaf $-> v$])

  // PUCT annotation on the selected root edge
  content((ox + 0.12, oy - 1.05), anchor: "west", text(size: 7pt, fill: garnet)[PUCT])

  // root visit counts → improved policy π (output of search)
  content((ox, oy - 4.18), text(size: 8pt, fill: ink)[$bold(pi) prop N(bold(s), dot)^(1 slash tau)$])

  // ── net → MCTS : the net supplies priors p and leaf values v (one guide edge) ──
  // from the heads' right side into the search panel's left side
  let xGuideA = xVh + 1.35
  let xGuideB = ox - 2.2
  line((xGuideA, yHd), (xGuideB, yHd), ..weak)
  content(((xGuideA + xGuideB) / 2, yHd + 0.30), text(size: 8pt, fill: muted)[$bold(p), v$])
  content((xGuideA + 0.04, yHd - 0.30), anchor: "west", text(size: 7pt, fill: muted)[guide search])

  // =========================================================================
  //  SELF-PLAY GAME (right) — play the improved policy π in self-play.
  // =========================================================================
  let ySp = yMid + 0.2
  box(
    xPlay, ySp,
    align(center)[*self-play*\ #text(size: 7.5pt, fill: muted)[play $bold(pi)$ vs. itself]\ #text(size: 8pt)[game $-> z = plus.minus 1$]],
    hw: 1.7, hh: 0.95, fill: beige,
  )
  // MCTS (π) → self-play
  line((ox + 2.2, yRoot - 2.0), (xPlay - 1.7, ySp), ..fwd)
  content(((ox + 2.2 + xPlay - 1.7) / 2, ySp + 0.62), text(size: 8pt, fill: ink)[play $bold(pi)$])

  // =========================================================================
  //  REPLAY BUFFER (bottom) — store the search-improved training triples.
  // =========================================================================
  box(
    xMcts, yBuf,
    align(center)[*self-play buffer*  #text(size: 7.5pt, fill: muted)[(replay memory)]\ #v(1pt) #text(size: 8.5pt)[examples  $(bold(s), bold(pi), z)$]],
    hw: 2.8, hh: 0.72, fill: white, bstroke: 1.3pt + ink,
  )
  // stacked-tape glyph at the buffer's right (memory feel)
  for k in range(3) {
    let xo = xMcts + 2.5 + k * 0.12
    rect((xo, yBuf - 0.42), (xo + 0.34, yBuf + 0.42), fill: b10, stroke: 0.7pt + muted, radius: 0pt)
  }

  // self-play game → buffer (s, π, z)
  line((xPlay, ySp - 0.95), (xPlay, yBuf), (xMcts + 2.8, yBuf), ..fwd)
  content((xPlay + 0.15, (ySp - 0.95 + yBuf) / 2), anchor: "west", text(size: 8pt, fill: muted)[$(bold(s), bold(pi), z)$])

  // =========================================================================
  //  TRAINING (dashed garnet) — buffer → loss → gradient into f_θ.
  // =========================================================================
  // loss node between buffer and net
  let xL = xNet
  let yL = yBuf
  box(
    xL, yL,
    align(center)[*train* $f_(bold(theta))$\ #text(size: 7.5pt, fill: garnet)[fit search targets]],
    hw: 1.7, hh: 0.72, fill: rgb("#F4E9EA"), bstroke: 1.6pt + garnet,
  )
  // buffer → train (sample a minibatch)
  line(W(xMcts, yBuf, hw: 2.8), E(xL, yL, hw: 1.7), ..fwd)
  content(((xMcts - 2.8 + xL + 1.7) / 2, yBuf + 0.3), text(size: 7.5pt, fill: muted)[sample batch])

  // train → net (gradient back-edge up the far-left gutter into the trunk)
  let xGut = xNet - 2.45
  line(
    W(xL, yL, hw: 1.7),
    (xGut, yL),
    (xGut, yTrunk),
    W(xNet, yTrunk, hw: 1.85),
    ..grad,
  )
  content((xGut - 0.16, (yL + yTrunk) / 2), anchor: "east", text(size: 8.5pt, fill: garnet)[$nabla_(bold(theta)) thin ℓ$])

  // loss equation under the train node
  content(
    (xL + 0.1, yL - 1.25),
    text(size: 8.5pt, fill: garnet)[$ℓ = (z - v)^2 - bold(pi) dot.c log bold(p) + c norm(bold(theta))^2$],
  )

  // =========================================================================
  //  OUTER LOOP BRACKET / TITLE
  // =========================================================================
  // big closing arc cue: net improves search, search improves net
  content(
    (xMcts, yRoot + 1.55),
    text(size: 8.5pt, fill: muted)[*search improves the net*  ·  *the net improves the search*],
  )

  // legend (sparse): edge meanings
  let lx = xPlay - 0.2
  let ly = yBuf - 1.0
  line((lx, ly), (lx + 0.7, ly), ..fwd)
  content((lx + 0.85, ly), anchor: "west", text(size: 7.5pt, fill: ink)[forward / play])
  line((lx, ly - 0.55), (lx + 0.7, ly - 0.55), stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"))
  content((lx + 0.85, ly - 0.55), anchor: "west", text(size: 7.5pt, fill: garnet)[gradient (train)])
})
