// Normalizing flow — invertible coupling chain.
//   A normalizing flow models a complex data density p_X by pushing a simple base
//   density p_Z (here a standard Gaussian) through a stack of invertible bijectors
//   f_1 ∘ … ∘ f_K. Two directions share the SAME parameters:
//     forward / sampling     x = f_K(…f_1(z)…)          z ~ p_Z  →  x ~ p_X
//     inverse / density-eval z = f_1⁻¹(…f_K⁻¹(x)…)      x       →  z, log p_X(x)
//   Density transforms by change-of-variables, with a tractable log-det-Jacobian
//   contributed per layer:
//     log p_X(x) = log p_Z(z) + Σ_k log|det ∂f_k⁻¹/∂x|.
//   Each f_k is an AFFINE COUPLING layer: split the vector u = (u_a, u_b); pass u_a
//   through unchanged; condition a scale s and shift t on u_a (any net, no inverse
//   needed); affine-transform u_b. The split makes the Jacobian triangular, so its
//   log-det is just Σ log s — cheap in both directions, and the layer is exactly
//   invertible. Original schematic from UDL / Bishop / Murphy knowledge; no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ───────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // sparse accent: the active per-layer log-det term
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let blue   = rgb("#466A9F")   // inverse / density-eval direction
#let grid-c = rgb("#ECECEC")
#let fillc  = rgb("#C7C7C7")
#let beige  = rgb("#FFF2E3")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── geometry of the coupling chain ────────────────────────────────────────
  let nK = 3              // number of coupling layers drawn explicitly
  let bw = 1.55           // block half-width
  let bh = 0.78           // block half-height
  let x0 = 0.0            // centre x of the base-density panel
  let dpanel = 2.05       // half-width of the density panels
  let gap = 1.55          // gap between consecutive block centres
  let y0 = 0.0            // chain centre line

  // centre x of each coupling block and the two density panels
  let bx = range(nK).map(k => x0 + dpanel + gap + k * (2 * bw + gap) + bw)
  let xZ = x0                                     // base density centre
  let xX = bx.at(nK - 1) + bw + gap + dpanel      // data density centre

  // ── small Gaussian-blob density renderer (filled concentric rings) ────────
  // draws an axis-aligned set of iso-contours; `comps` = list of (cx,cy,sx,sy)
  let blob(cx, cy, comps, accent) = {
    let rings = (
      (r: 1.05, a: 90%),
      (r: 0.80, a: 84%),
      (r: 0.55, a: 74%),
      (r: 0.32, a: 60%),
    )
    for R in rings {
      for c in comps {
        let pts = range(49).map(i => {
          let t = i / 48 * 2 * calc.pi
          (cx + c.at(0) + R.r * c.at(2) * calc.cos(t),
           cy + c.at(1) + R.r * c.at(3) * calc.sin(t))
        })
        line(..pts, close: true,
          stroke: none, fill: accent.transparentize(R.a))
      }
    }
    // 1σ outline ring(s)
    for c in comps {
      let pts = range(65).map(i => {
        let t = i / 64 * 2 * calc.pi
        (cx + c.at(0) + 0.80 * c.at(2) * calc.cos(t),
         cy + c.at(1) + 0.80 * c.at(3) * calc.sin(t))
      })
      line(..pts, close: true, stroke: 0.7pt + accent.transparentize(35%))
    }
  }

  // ── density panels (sharp-cornered frames) ────────────────────────────────
  let panel(cx, top-lbl, sub-lbl, comps, accent) = {
    rect((cx - dpanel, y0 - dpanel), (cx + dpanel, y0 + dpanel),
      fill: white, stroke: 0.9pt + ink, radius: 0pt)
    // faint interior grid
    for gx in range(-2, 3) {
      line((cx + gx * 0.9, y0 - dpanel + 0.05), (cx + gx * 0.9, y0 + dpanel - 0.05),
        stroke: 0.4pt + grid-c)
      line((cx - dpanel + 0.05, y0 + gx * 0.9), (cx + dpanel - 0.05, y0 + gx * 0.9),
        stroke: 0.4pt + grid-c)
    }
    blob(cx, y0, comps, accent)
    content((cx, y0 + dpanel + 0.58), text(size: 9.5pt, weight: "bold", fill: ink)[#top-lbl])
    content((cx, y0 + dpanel + 0.22), text(size: 7pt, fill: muted)[#sub-lbl])
  }

  // base density: single isotropic Gaussian  (centred component)
  panel(xZ, [base  $p_Z(bold(z)) = cal(N)(bold(0), bold(I))$], [simple · unimodal],
    ((0, 0, 1.0, 1.0),), muted)
  // data density: complex multimodal target  (three displaced components)
  panel(xX, [data  $p_X(bold(x))$], [complex · multimodal],
    (( 0.55,  0.45, 0.55, 0.90),
     (-0.65,  0.20, 0.85, 0.50),
     ( 0.05, -0.70, 0.95, 0.45)), garnet)

  // ── coupling blocks  f_k  ─────────────────────────────────────────────────
  let block-at(cx, k) = {
    rect((cx - bw, y0 - bh), (cx + bw, y0 + bh),
      fill: beige, stroke: 1pt + ink, radius: 0pt)
    content((cx, y0 + 0.30), text(size: 10pt, weight: "bold", fill: ink)[$f_#k$])
    content((cx, y0 - 0.10), text(size: 6.5pt, fill: muted)[affine])
    content((cx, y0 - 0.40), text(size: 6.5pt, fill: muted)[coupling])
  }
  for k in range(nK) { block-at(bx.at(k), k + 1) }

  // ── flow arrows: forward (top, garnet) and inverse (bottom, blue) ─────────
  // forward arrow segment between centres ca → cb at vertical offset dy
  let fseg(ca, cb, dy, accent, dash: none, lab: none) = {
    line((ca + 0.04, y0 + dy), (cb - 0.04, y0 + dy),
      stroke: (paint: accent, thickness: 1.5pt, dash: dash),
      mark: (end: "stealth", fill: accent, scale: 0.85))
    if lab != none {
      content(((ca + cb) / 2, y0 + dy + (if dy > 0 { 0.30 } else { -0.30 })),
        text(size: 7pt, fill: accent)[#lab])
    }
  }
  // inverse arrow segment cb → ca (right to left) at vertical offset dy
  let rseg(cb, ca, dy, accent, dash: none) = {
    line((cb - 0.04, y0 + dy), (ca + 0.04, y0 + dy),
      stroke: (paint: accent, thickness: 1.5pt, dash: dash),
      mark: (end: "stealth", fill: accent, scale: 0.85))
  }

  // left edge of each block / panel for routing
  let leftedge(cx, half) = cx - half
  let rightedge(cx, half) = cx + half

  // the centre sequence of right-edges and left-edges along the chain
  // nodes in order: Z-panel, f1, f2, f3, X-panel
  let rights = (rightedge(xZ, dpanel),) + range(nK).map(k => rightedge(bx.at(k), bw))
  let lefts  = range(nK).map(k => leftedge(bx.at(k), bw)) + (leftedge(xX, dpanel),)
  let dyF = 0.42          // forward arrow height
  let dyR = -0.42         // inverse arrow height

  for i in range(nK + 1) {
    fseg(rights.at(i), lefts.at(i), dyF, garnet)
    rseg(lefts.at(i), rights.at(i), dyR, blue)
  }

  // intermediate latent labels  u_0=z, u_1, u_2, u_K=x  at each junction
  let junc = range(nK + 1).map(i => (rights.at(i) + lefts.at(i)) / 2)
  let jlab = ([$bold(z)$], [$bold(u)_1$], [$bold(u)_2$], [$bold(x)$])
  for i in range(nK + 1) {
    content((junc.at(i), y0 + 1.12),
      box(fill: white, inset: 1pt, text(size: 7.5pt, fill: ink)[#jlab.at(i)]))
  }

  // ── direction labels (centred over the chain, clear of the panels) ────────
  let chain-mid = (rights.at(0) + lefts.at(nK)) / 2
  content((chain-mid, y0 + dpanel + 1.15),
    text(size: 8.5pt, weight: "bold", fill: garnet)[forward  ·  sampling
      #h(0.7em) $bold(x) = f_K compose dots.c compose f_1(bold(z))$])

  // big direction arrows under the chain ends, with their defining maps
  let chain-l = rights.at(0)
  let chain-r = lefts.at(nK)
  line((chain-l, y0 - dpanel - 0.62), (chain-r, y0 - dpanel - 0.62),
    stroke: 1.3pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.9))
  content(((chain-l + chain-r) / 2, y0 - dpanel - 0.37),
    box(fill: white, inset: 1pt,
      text(size: 6.5pt, fill: garnet)[forward · sampling:  $bold(x) = f_K compose dots.c compose f_1(bold(z))$]))
  line((chain-r, y0 - dpanel - 1.18), (chain-l, y0 - dpanel - 1.18),
    stroke: 1.3pt + blue, mark: (end: "stealth", fill: blue, scale: 0.9))
  content(((chain-l + chain-r) / 2, y0 - dpanel - 0.93),
    box(fill: white, inset: 1pt,
      text(size: 6.5pt, fill: blue)[inverse · density-eval:  $bold(z) = f_1^(-1) compose dots.c compose f_K^(-1)(bold(x))$]))

  // ── per-layer log-det-Jacobian annotations (garnet, sparse accent) ────────
  for k in range(nK) {
    content((bx.at(k), y0 - bh - 0.34),
      text(size: 6.5pt, fill: garnet)[$+ log|det J_#(k + 1)|$])
  }

  // ── change-of-variables identity (caption under everything) ──────────────
  let cap-y = y0 - dpanel - 1.95
  content((( xZ + xX) / 2, cap-y),
    text(size: 9pt, fill: ink)[
      $log p_X (bold(x)) = log p_Z (bold(z)) + sum_(k=1)^K log abs(det (diff f_k^(-1)) / (diff bold(u)))$
    ])
  content(((xZ + xX) / 2, cap-y - 0.55),
    text(size: 7pt, fill: muted, style: "italic")[change of variables · tractable log-det per layer])

  // ────────────────────────────────────────────────────────────────────────
  // INSET: affine-coupling split glyph — what one f_k does internally.
  // placed below the chain, centred.
  // ────────────────────────────────────────────────────────────────────────
  let gx = (xZ + xX) / 2
  let gy = cap-y - 2.95
  // glyph frame
  let gW = 5.6
  let gH = 2.2
  rect((gx - gW / 2, gy - gH / 2), (gx + gW / 2, gy + gH / 2),
    fill: rgb("#FBFBFB"), stroke: 0.8pt + rgb("#C7C7C7"), radius: 0pt)
  content((gx, gy + gH / 2 + 0.34),
    text(size: 8.5pt, weight: "bold", fill: ink)[affine coupling layer  $f_k$  (one block, unpacked)])

  // split point on the left: u = (u_a, u_b)
  let inx = gx - gW / 2 + 0.55
  let yA = gy + 0.62      // identity branch  (u_a)
  let yB = gy - 0.62      // transformed branch (u_b)
  let outx = gx + gW / 2 - 0.55

  // input node
  content((inx - 0.30, gy), anchor: "east", text(size: 8pt, fill: ink)[$bold(u)$])
  line((inx - 0.22, gy), (inx, gy), stroke: 1.2pt + ink)
  // split fork
  line((inx, gy), (inx, yA), (inx + 0.55, yA), stroke: 1.2pt + ink,
    mark: (end: "stealth", scale: 0.7, fill: ink))
  line((inx, gy), (inx, yB), (inx + 0.55, yB), stroke: 1.2pt + ink,
    mark: (end: "stealth", scale: 0.7, fill: ink))
  content((inx + 0.10, gy + 0.30), anchor: "west", text(size: 6pt, fill: muted)[split])

  // identity branch label
  content((inx + 0.75, yA), anchor: "west", text(size: 7.5pt, fill: ink)[$bold(u)_a$])

  // conditioner net box (s, t) = NN(u_a)
  let cnx = gx - 0.15
  rect((cnx - 0.85, gy - 0.05 - 0.34), (cnx + 0.85, gy - 0.05 + 0.34),
    fill: beige, stroke: 0.8pt + ink, radius: 0pt)
  content((cnx, gy - 0.05), text(size: 7pt, fill: ink)[$(bold(s), bold(t)) = "NN"(bold(u)_a)$])
  // tap from u_a down into the conditioner
  line((inx + 1.35, yA), (inx + 1.35, gy + 0.29), stroke: (paint: muted, thickness: 0.8pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.55, fill: muted))

  // affine op on u_b
  let opx = cnx + 1.55
  circle((opx, yB), radius: 0.26, fill: white, stroke: 1pt + garnet)
  content((opx, yB), text(size: 8pt, fill: garnet)[$dot.circle$])
  // u_b input into op
  content((inx + 0.75, yB), anchor: "west", text(size: 7.5pt, fill: ink)[$bold(u)_b$])
  line((inx + 1.45, yB), (opx - 0.27, yB), stroke: 1.2pt + ink,
    mark: (end: "stealth", scale: 0.7, fill: ink))
  // (s,t) feeding the op
  line((cnx + 0.85, gy - 0.05), (opx, gy - 0.05), (opx, yB + 0.27),
    stroke: (paint: garnet, thickness: 1pt),
    mark: (end: "stealth", scale: 0.6, fill: garnet))

  // outputs: v_a = u_a (identity), v_b = s ⊙ u_b + t
  line((opx + 0.27, yB), (outx, yB), stroke: 1.2pt + garnet,
    mark: (end: "stealth", scale: 0.7, fill: garnet))
  line((inx + 0.55, yA), (outx, yA), stroke: 1.2pt + ink,
    mark: (end: "stealth", scale: 0.7, fill: ink))
  content((outx + 0.12, yA), anchor: "west", text(size: 7pt, fill: ink)[$bold(v)_a = bold(u)_a$])
  content((outx + 0.12, yB), anchor: "west", text(size: 7pt, fill: garnet)[$bold(v)_b = bold(s) dot.circle bold(u)_b + bold(t)$])

  // log-det note for the glyph
  content((gx, gy - gH / 2 - 0.34),
    text(size: 6.5pt, fill: garnet)[triangular Jacobian  $#sym.arrow.r.double$  $log|det J_k| = sum_i log s_i$])
})
