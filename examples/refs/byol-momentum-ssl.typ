// BYOL — Bootstrap Your Own Latent (Grill et al. 2020); the canonical momentum /
// EMA self-supervised learning schematic (Foundations of Computer Vision; Prince UDL).
//
// Asymmetric self-distillation from two augmented views of ONE image:
//   ONLINE  branch (params θ, trained by SGD):  encoder f_θ → projector g_θ → predictor q_θ
//   TARGET  branch (params ξ, NOT trained):     encoder f_ξ → projector g_ξ
// The predictor's online projection q_θ(z) is regressed onto the target projection z′ —
// a normalised mean-squared error on ℓ2-normalised vectors. A STOP-GRADIENT sits on the
// target branch (no gradient flows back through ξ), and the target weights are an
// exponential-moving-average (EMA / "momentum") of the online weights:
//       ξ ← τ ξ + (1 − τ) θ.
// The asymmetry (extra predictor + stop-grad + EMA target) is what prevents collapse with
// NO negative pairs. Hand-composed in raw cetz so every port and orthogonal route is exact;
// built from textbook knowledge in mlatlas's print-first house style — no figure traced.
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
#let b30    = rgb("#C7C7C7")
#let blue   = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── geometry ──────────────────────────────────────────────────────────
  let xL = -2.7    // online lane (left)
  let xR =  2.7    // target lane (right)
  let xC =  0.0    // shared centre (image, loss)

  let yImg =  6.5  // source image x
  let yAug =  5.1  // augmented views v, v′
  let yEnc =  3.5  // encoders f
  let yPrj =  1.7  // projectors g
  let yPrd = -0.1  // predictor q  (online only) / target projection z′ (target)
  let yLos = -2.1  // loss

  // box half-sizes
  let bw  = 1.45
  let bh  = 0.60
  let bhh = 0.74

  // ── styles ────────────────────────────────────────────────────────────
  let fwd  = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.78))
  let sgd  = (stroke: (paint: blue, thickness: 1.3pt), mark: (end: "stealth", scale: 0.72))
  let ema  = (stroke: (paint: garnet, thickness: 1.5pt, dash: "dashed"), mark: (end: "stealth", scale: 0.78))

  // ── box helper: sharp corners, light fill, dark text ──────────────────
  let box(cx, cy, body, hw: bw, hh: bh, fill: white, bstroke: 1.1pt + ink) = {
    rect((cx - hw, cy - hh), (cx + hw, cy + hh), fill: fill, stroke: bstroke, radius: 0pt)
    content((cx, cy), body)
  }
  let N(cx, cy, hh: bh) = (cx, cy + hh)
  let S(cx, cy, hh: bh) = (cx, cy - hh)
  let E(cx, cy, hw: bw) = (cx + hw, cy)
  let W(cx, cy, hw: bw) = (cx - hw, cy)

  // ════════════════════════ NODES ════════════════════════════════════════
  // source image x (centre, top)
  box(xC, yImg, align(center)[image #h(3pt) $bold(x)$], hw: 1.05, fill: beige)

  // two augmentations t, t′  (views)
  box(xL, yAug, align(center)[view #h(3pt) $bold(v) = t(bold(x))$], hw: 1.55)
  box(xR, yAug, align(center)[view #h(3pt) $bold(v)' = t'(bold(x))$], hw: 1.55)

  // encoders f_θ / f_ξ
  box(
    xL, yEnc,
    align(center)[encoder #h(3pt) $f_theta$\ #text(size: 7.5pt, fill: muted)[representation #h(3pt) $bold(y)$]],
    hh: bhh, fill: b10,
  )
  box(
    xR, yEnc,
    align(center)[encoder #h(3pt) $f_xi$\ #text(size: 7.5pt, fill: muted)[representation #h(3pt) $bold(y)'$]],
    hh: bhh, fill: b10,
  )

  // projectors g_θ / g_ξ
  box(
    xL, yPrj,
    align(center)[projector #h(3pt) $g_theta$\ #text(size: 7.5pt, fill: muted)[projection #h(3pt) $bold(z)$]],
    hh: bhh, fill: b10,
  )
  box(
    xR, yPrj,
    align(center)[projector #h(3pt) $g_xi$\ #text(size: 7.5pt, fill: muted)[projection #h(3pt) $bold(z)'$]],
    hh: bhh, fill: b10,
  )

  // predictor q_θ (ONLINE only) — focal garnet outline, the symmetry-breaker
  box(
    xL, yPrd,
    align(center)[*predictor* #h(3pt) $q_theta$\ #text(size: 7.5pt, fill: muted)[prediction #h(3pt) $q_theta(bold(z))$]],
    hh: bhh, fill: white, bstroke: 2.2pt + garnet,
  )

  // ════════════════════════ FORWARD (solid) ══════════════════════════════
  // image → two views (L corners)
  line(W(xC, yImg, hw: 1.05), (xL, yImg), (xL, yAug + bh), ..fwd)
  line(E(xC, yImg, hw: 1.05), (xR, yImg), (xR, yAug + bh), ..fwd)
  content((xL + 0.18, (yImg + yAug + bh) / 2), text(size: 7.5pt, fill: muted)[$t tilde cal(T)$], anchor: "west")
  content((xR - 0.18, (yImg + yAug + bh) / 2), text(size: 7.5pt, fill: muted)[$t' tilde cal(T)$], anchor: "east")

  // online lane:  v → f_θ → g_θ → q_θ
  line(S(xL, yAug), N(xL, yEnc, hh: bhh), ..fwd)
  line(S(xL, yEnc, hh: bhh), N(xL, yPrj, hh: bhh), ..fwd)
  line(S(xL, yPrj, hh: bhh), N(xL, yPrd, hh: bhh), ..fwd)

  // target lane:  v′ → f_ξ → g_ξ → (projection z′)
  line(S(xR, yAug), N(xR, yEnc, hh: bhh), ..fwd)
  line(S(xR, yEnc, hh: bhh), N(xR, yPrj, hh: bhh), ..fwd)

  // ════════════════════════ STOP-GRADIENT marker (target) ════════════════
  // a "cut" perpendicular bar on the target lane just below g_ξ — no grad passes it.
  let ysg = (yPrj - bhh + yPrd) / 2 + 0.12
  // the target projection continues down past the stop-grad to the loss
  line(S(xR, yPrj, hh: bhh), (xR, yLos + 0.66), ..fwd)
  // stop-grad bar (double tick) + label
  let sgw = 0.42
  line((xR - sgw, ysg + 0.07), (xR + sgw, ysg + 0.07), stroke: 2.0pt + garnet)
  line((xR - sgw, ysg - 0.07), (xR + sgw, ysg - 0.07), stroke: 2.0pt + garnet)
  content((xR + sgw + 0.18, ysg), anchor: "west", text(size: 8pt, fill: garnet)[*sg* #h(1pt) #text(fill: muted)[stop-grad]])

  // ════════════════════════ LOSS node (centre, bottom) ═══════════════════
  let lw = 2.05
  box(
    xC, yLos,
    align(center)[*loss* #h(3pt) $cal(L)_(theta,xi)$\ #text(size: 7.5pt, fill: muted)[$norm(macron(q)_theta(bold(z)) - macron(bold(z))')_2^2$]],
    hw: lw, hh: bhh, fill: beige,
  )

  // q_θ(z)  →  loss   (online prediction in)
  line(S(xL, yPrd, hh: bhh), (xL, yLos), (xC - lw, yLos), ..fwd)
  // z′ (after stop-grad)  →  loss   (target projection in)
  line((xR, yLos + 0.66), (xR, yLos), (xC + lw, yLos), ..fwd)
  content((xL + 0.18, (yPrd - bhh + yLos) / 2 + 0.35), anchor: "west", text(size: 7.5pt, fill: muted)[predict])
  content((xR + 0.18, (yLos + 0.66 + yLos) / 2 + 0.25), anchor: "west", text(size: 7.5pt, fill: muted)[target #h(2pt) $bold(z)'$])

  // ════════════════════════ SGD update (online, blue) ════════════════════
  // gradient of the loss updates ONLY the online params θ (encoder+projector+predictor).
  // route from loss.west up the far-left gutter into the online encoder's west.
  let xGutL = xL - 2.05
  line(
    (xC - lw - 0.02, yLos),
    (xGutL, yLos),
    (xGutL, yEnc),
    W(xL, yEnc, hw: bw),
    ..sgd,
  )
  content((xGutL - 0.12, (yLos + yEnc) / 2), anchor: "east", text(size: 8pt, fill: blue)[$theta arrow.l theta - eta nabla_theta cal(L)$])
  content((xGutL - 0.12, (yLos + yEnc) / 2 - 0.50), anchor: "east", text(size: 7pt, fill: muted)[SGD on online only])

  // ════════════════════════ EMA / momentum update (θ → ξ, garnet dashed) ══
  // the target params are a slow EMA of the online params. Draw it as a dashed garnet
  // arrow straight across the CLEAR central gutter from the online encoder to the target
  // encoder — the spine of the whole method (online weights flow into the target, slowly).
  line(
    E(xL, yEnc, hw: bw),
    W(xR, yEnc, hw: bw),
    ..ema,
  )
  content((xC, yEnc + 0.30), text(size: 8.5pt, fill: garnet)[$bold(xi) arrow.l tau bold(xi) + (1 - tau) bold(theta)$])
  content((xC, yEnc - 0.28), text(size: 7pt, fill: muted)[momentum #h(2pt) $tau in [0,1)$])

  // ════════════════════════ LANE LABELS (top brackets) ═══════════════════
  let topY = yImg + 1.05
  let drop = 0.18
  // online bracket (left)
  let lx0 = xGutL - 0.45
  let lx1 = -0.55
  line((lx0, topY - drop), (lx0, topY), (lx1, topY), (lx1, topY - drop), stroke: 1.0pt + blue)
  content(((lx0 + lx1) / 2, topY + 0.28), text(size: 9.5pt, weight: "bold", fill: blue)[ONLINE network #h(3pt) $theta$])
  // target bracket (right) — span the target lane + its stop-grad annotation
  let rx0 = 0.55
  let rx1 = xR + 1.55
  line((rx0, topY - drop), (rx0, topY), (rx1, topY), (rx1, topY - drop), stroke: 1.0pt + garnet)
  content(((rx0 + rx1) / 2, topY + 0.28), text(size: 9.5pt, weight: "bold", fill: garnet)[TARGET network #h(3pt) $xi$ (momentum)])

  // ── title + objective caption ──────────────────────────────────────────
  content(
    (xC, topY + 1.05),
    text(size: 12pt, weight: "bold", fill: ink)[BYOL — momentum (EMA) self-supervised learning],
  )
  content(
    (xC, yLos - 1.35),
    text(size: 8.5pt, fill: muted)[
      One image, two augmentations. Online predicts the target's projection; the predictor #h(3pt) $q_theta$ + stop-grad + EMA target break symmetry — collapse-free with #emph[no] negative pairs.
    ],
  )
})
