// Reparameterization trick — the probabilistic-graph view of a VAE.
//
//   z = mu + sigma (.) epsilon,   epsilon ~ N(0, I).
//
// The encoder q_phi(z | x) outputs (mu, sigma). Sampling z directly from
// N(mu, sigma^2) is a STOCHASTIC node — gradients cannot pass through a random
// draw. The trick pushes the randomness OUT into an auxiliary noise variable
// epsilon ~ N(0, I) and makes z a DETERMINISTIC, differentiable function of
// (mu, sigma, epsilon). Now the deterministic path mu/sigma -> z -> decoder is
// fully differentiable, so reverse-mode gradients of the ELBO flow back through
// mu and sigma into phi, while the noise leaf epsilon is simply bypassed.
//
// Solid black = forward data flow; dashed garnet = backward gradient flow.
// Hand-built in cetz so every wire (and its overlaid reverse-mode gradient) is
// placed exactly — print-first house style. Standard formulation (Kingma &
// Welling 2014; Bishop DL; Murphy PML book 2); original layout, not traced.

#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")
#let b30    = rgb("#C7C7C7")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: ink)[Reparameterization trick]

  #v(2pt)
  #text(size: 10pt, fill: muted)[
    $bold(z) = mu_phi (bold(x)) + sigma_phi (bold(x)) dot.c bold(epsilon), wide bold(epsilon) tilde cal(N)(bold(0), bold(I))$
  ]

  #v(16pt)

  #cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // ── styling helpers ──────────────────────────────────────────────────────
    let fwd  = (stroke: 1pt + ink, mark: (end: "stealth", scale: 0.75))
    let grad = (stroke: (paint: garnet, thickness: 1pt, dash: "dashed"), mark: (end: "stealth", scale: 0.75))

    // a labelled rectangle (sharp corners). returns nothing; geometry from `pos`.
    let boxw = 1.6
    let boxh = 0.92
    let rectnode(x, y, body, fill: white, stroke: 1.2pt + ink, w: boxw, h: boxh) = {
      rect((x - w / 2, y - h / 2), (x + w / 2, y + h / 2), fill: fill, stroke: stroke)
      content((x, y), text(size: 9pt, fill: ink)[#body])
    }
    // a circular op / variable node.
    let circnode(x, y, body, r: 0.42, fill: white, stroke: 1.1pt + ink, sz: 11pt) = {
      circle((x, y), radius: r, fill: fill, stroke: stroke)
      content((x, y), text(size: sz, fill: ink)[#body])
    }

    // ── node coordinates ─────────────────────────────────────────────────────
    let y0   = 0           // forward spine
    let ymu  = 1.35        // mu row (upper)
    let ysig = -1.35       // sigma row (lower)
    let yeps = -3.05       // epsilon leaf (below)
    let ygt  = 3.4         // gradient tape (above the boxes)

    let xx   = 0           // input x
    let xenc = 2.6         // encoder
    let xms  = 5.4         // mu / sigma column
    let xmul = 7.6         // multiply node (sigma . eps)
    let xadd = 9.6         // add node (mu + .)
    let xz   = 11.5        // z (focal)
    let xdec = 13.9        // decoder
    let xxh  = 16.5        // reconstruction

    // ── FORWARD data edges (solid) ───────────────────────────────────────────
    // x -> encoder
    line((xx + boxw / 2, y0), (xenc - boxw / 2, y0), ..fwd)
    // encoder -> mu  (split up) and encoder -> sigma (split down)
    line((xenc + boxw / 2, y0), (xenc + boxw / 2 + 0.45, y0), (xenc + boxw / 2 + 0.45, ymu),
         (xms - boxw / 2, ymu), ..fwd)
    line((xenc + boxw / 2, y0), (xenc + boxw / 2 + 0.45, y0), (xenc + boxw / 2 + 0.45, ysig),
         (xms - boxw / 2, ysig), ..fwd)
    // mu -> add  (right, then down into the TOP of the + node)
    line((xms + boxw / 2, ymu), (xadd, ymu), (xadd, y0 + 0.42), ..fwd)
    // sigma -> multiply  (right into the LEFT rim of the . node)
    line((xms + boxw / 2, ysig), (xmul - 0.42, ysig), ..fwd)
    // epsilon -> multiply  (up into the BOTTOM rim of the . node)
    line((xmul, yeps + 0.52), (xmul, ysig - 0.42), ..fwd)
    // multiply -> add  (right out of the . node, then up into the BOTTOM of +)
    line((xmul + 0.42, ysig), (xadd, ysig), (xadd, y0 - 0.42), ..fwd)
    // add -> z -> decoder -> x_hat
    line((xadd + 0.42, y0), (xz - 0.52, y0), ..fwd)
    line((xz + 0.52, y0), (xdec - boxw / 2, y0), ..fwd)
    line((xdec + boxw / 2, y0), (xxh - boxw / 2, y0), ..fwd)

    // ── BACKWARD gradient edges (dashed garnet), routed ABOVE so they never
    //    touch the epsilon leaf — the gradient simply bypasses the noise. ──────
    // z -> mu  (climb to the tape, run left, drop into mu)
    line((xz, 0.52), (xz, ygt), (xms + 0.55, ygt), (xms + 0.55, ymu + boxh / 2), ..grad)
    // z -> sigma  (a slightly lower tape lane, dropping into sigma's upper-left
    //              corner so it is clearly distinct from the forward edge that
    //              enters sigma at centre-left)
    let ygt2 = 2.55
    line((xz, 0.52), (xz, ygt2), (xms - boxw / 2 - 0.5, ygt2),
         (xms - boxw / 2 - 0.5, ysig + 0.22), (xms - boxw / 2, ysig + 0.22), ..grad)
    // mu -> encoder  and  sigma -> encoder  (gradient into phi)
    line((xms - boxw / 2, ymu - 0.18), (xenc + boxw / 2 + 0.78, ymu - 0.18),
         (xenc + boxw / 2 + 0.78, 0.20), (xenc + boxw / 2, 0.20), ..grad)
    line((xms - boxw / 2, ysig + 0.18), (xenc + boxw / 2 + 0.78, ysig + 0.18),
         (xenc + boxw / 2 + 0.78, -0.20), (xenc + boxw / 2, -0.20), ..grad)

    // ── NODES (drawn last, on top of the wires) ──────────────────────────────
    rectnode(xx,   y0,  [Input \ $bold(x)$], fill: beige)
    rectnode(xenc, y0,  [Encoder \ $q_phi (z | bold(x))$], stroke: 1.6pt + garnet)
    rectnode(xms,  ymu, [$mu_phi (bold(x))$], fill: b10, stroke: 1.6pt + garnet)
    rectnode(xms,  ysig,[$sigma_phi (bold(x))$], fill: b10, stroke: 1.6pt + garnet)
    circnode(xmul, ysig,[$dot.c$], sz: 13pt)
    circnode(xadd, y0,  [$+$], sz: 13pt)
    circnode(xz,   y0,  [$bold(z)$], r: 0.52, stroke: 2.5pt + garnet, sz: 12pt)
    rectnode(xdec, y0,  [Decoder \ $p_theta (bold(x) | z)$], stroke: 1.6pt + garnet)
    rectnode(xxh,  y0,  [Recon. \ $hat(bold(x))$], fill: b10, stroke: 1.6pt + ink)
    // epsilon: the auxiliary stochastic LEAF (beige = a data source)
    circnode(xmul, yeps, [$bold(epsilon)$], r: 0.52, fill: beige, sz: 12pt)
    content((xmul, yeps - 0.85), text(size: 7.5pt, fill: muted)[$bold(epsilon) tilde cal(N)(bold(0), bold(I))$])
    content((xmul, yeps - 1.28), text(size: 7pt, fill: muted)[noise (stochastic leaf)])

    // small role tags under mu/sigma
    content((xms, ymu + boxh / 2 + 0.26), text(size: 7pt, fill: garnet)[mean])
    content((xms, ysig - boxh / 2 - 0.26), text(size: 7pt, fill: garnet)[std-dev])
  })

  #v(12pt)

  // ── legend ────────────────────────────────────────────────────────────────
  #cetz.canvas(length: 1cm, {
    import cetz.draw: *
    line((0, 0), (1.1, 0), stroke: 1pt + ink, mark: (end: "stealth", scale: 0.7))
    content((1.3, 0), anchor: "west", text(size: 8.5pt, fill: ink)[forward (data flow, deterministic)])
    line((8.2, 0), (9.3, 0), stroke: (paint: garnet, thickness: 1pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
    content((9.5, 0), anchor: "west", text(size: 8.5pt, fill: garnet)[backward (gradient of the ELBO)])
  })

  #v(6pt)

  #box(width: 16.8cm, [
    #set par(justify: false)
    #set align(center)
    #text(size: 8.5pt, fill: muted)[
      Sampling $bold(z) tilde cal(N)(mu, sigma^2)$ directly is a *stochastic* node:
      no gradient can pass through a random draw. The trick moves the randomness into
      an auxiliary leaf #text(fill: ink)[$bold(epsilon) tilde cal(N)(bold(0), bold(I))$]
      and writes #text(fill: garnet)[$bold(z)$] as a *deterministic*, differentiable
      function of $(mu, sigma, bold(epsilon))$. The backward pass
      (#text(fill: garnet)[dashed]) then flows through $mu$ and $sigma$ into the encoder
      parameters $phi$ — and simply *bypasses* the noise leaf $bold(epsilon)$.
    ]
  ])
]
