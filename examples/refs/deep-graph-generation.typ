// Deep graph generation — graph VAE (latent → adjacency probabilities → sampled graph)
// and the autoregressive (edge-by-edge) alternative.  Hamilton, Graph Representation
// Learning; Prince, Understanding Deep Learning.
//
// TOP — graph variational autoencoder.  An encoder (a GNN over the input graph) maps a
// graph G to an approximate posterior q_phi(z|G) = N(mu, diag(sigma^2)); a latent code z
// is sampled and pushed through an MLP decoder p_theta(A|z) that emits an n×n matrix of
// independent edge probabilities A-hat_ij = sigmoid(z_i^T z_j) (inner-product decoder).
// Sampling each entry as Bernoulli(A-hat_ij) yields a discrete graph.  Training maximizes
// the ELBO: reconstruction (cross-entropy on edges) minus the KL to a N(0, I) prior.
//
// BOTTOM — autoregressive generation.  Instead of one shot, build the graph one edge (or
// node) at a time: at step t the model factorizes p(G) = prod_t p(e_t | e_<t), reading the
// partial graph and emitting the probability of the next edge (GraphRNN / GRAN style).
//
// Built from architectural knowledge in mlatlas's print-first house style.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let blue   = rgb("#466A9F")
#let green  = rgb("#65780B")
#let pinkr  = rgb("#CC2E40")
#let gridc  = rgb("#A2A2A2")
#let faint  = rgb("#C7C7C7")
#let beige  = rgb("#FFF2E3")
#let panel  = rgb("#ECECEC")

// sequential ramp beige(0) → garnet(1) for the probability heatmap
#let ramp(t) = {
  let t = calc.max(0.0, calc.min(1.0, t))
  beige.mix((garnet, t * 100%), space: oklab)
}
#let on-fill(t) = if t > 0.58 { white } else { ink }
// format a probability in 0..1 to a 2-decimal string like ".91" / ".00"
#let fmt2(v) = {
  let hund = calc.round(v * 100)
  let s = str(hund)
  if hund < 10 { s = "0" + s }
  "." + s
}

// ─────────────────────────────────────────────────────────────────────────────
// helper: draw a small node-link graph inside a box, given node positions (in a
// local 0..1 unit square) and an adjacency edge list.
#let small-graph(draw, ox, oy, side, nodes, edges, accent: ink, nlabels: none, rad: 0.13) = {
  import draw: *
  let P(i) = (ox + nodes.at(i).at(0) * side, oy + nodes.at(i).at(1) * side)
  for e in edges {
    line(P(e.at(0)), P(e.at(1)), stroke: 1.4pt + accent)
  }
  for i in range(nodes.len()) {
    let p = P(i)
    circle(p, radius: rad, fill: white, stroke: 1.2pt + ink)
    if nlabels != none {
      content(p, text(size: 6pt, fill: ink)[#nlabels.at(i)])
    }
  }
}

// node layout shared by input graph and reconstructed graph (5 nodes, pentagon)
#let pent = {
  let r = 0.40
  range(5).map(k => {
    let a = 90deg - k * 72deg
    (0.5 + r * calc.cos(a), 0.5 + r * calc.sin(a))
  })
}

// ════════════════════════════════════════════════════════════════════════════
//  TOP PANEL — GRAPH VAE PIPELINE
// ════════════════════════════════════════════════════════════════════════════
#cetz.canvas(length: 1cm, {
  import cetz.draw
  import cetz.draw: *

  // ── 1. INPUT GRAPH G ────────────────────────────────────────────────────────
  let gx = 0.0
  let gy = 0.0
  let gside = 1.7
  let g-edges = ((0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 2), (1, 4))
  rect((gx, gy), (gx + gside, gy + gside), fill: white, stroke: 1.0pt + ink, radius: 0pt)
  small-graph(draw, gx, gy, gside, pent, g-edges, accent: muted, rad: 0.15)
  content((gx + gside / 2, gy - 0.36), text(size: 9pt, fill: ink)[input graph $G$])
  content((gx + gside / 2, gy + gside + 0.30), text(size: 7pt, fill: muted)[$(bold(X), bold(A))$])

  // ── 2. ENCODER (GNN) — a contracting trapezoid ──────────────────────────────
  let ex0 = gx + gside + 0.55
  let ew = 1.25
  let eh0 = gside
  let eh1 = 0.95
  let ecx = ex0 + ew / 2
  let ecy = gy + gside / 2
  line(
    (ex0, ecy + eh0 / 2), (ex0 + ew, ecy + eh1 / 2),
    (ex0 + ew, ecy - eh1 / 2), (ex0, ecy - eh0 / 2),
    close: true, fill: panel, stroke: 1.0pt + ink,
  )
  content((ecx, ecy + 0.16), text(size: 8.5pt, weight: "bold", fill: ink)[Encoder])
  content((ecx, ecy - 0.18), text(size: 6.5pt, fill: muted)[$q_phi (bold(z) | G)$])
  // arrow G → encoder
  line((gx + gside + 0.06, ecy), (ex0 - 0.04, ecy), stroke: 1.5pt + ink, mark: (end: "stealth", scale: 0.8))

  // ── 3. POSTERIOR PARAMS  mu, sigma  →  z ~ N ────────────────────────────────
  let px = ex0 + ew + 0.55
  let pcy = ecy
  // two small param chips
  let chipw = 0.92
  let chiph = 0.52
  let muy = pcy + 0.50
  let sgy = pcy - 0.50
  rect((px, muy - chiph / 2), (px + chipw, muy + chiph / 2), fill: rgb("#E6ECF4"), stroke: 0.9pt + blue, radius: 0pt)
  content((px + chipw / 2, muy), text(size: 8.5pt, fill: blue)[$bold(mu)$])
  rect((px, sgy - chiph / 2), (px + chipw, sgy + chiph / 2), fill: rgb("#E6ECF4"), stroke: 0.9pt + blue, radius: 0pt)
  content((px + chipw / 2, sgy), text(size: 8.5pt, fill: blue)[$bold(sigma)$])
  // encoder → params
  line((ex0 + ew + 0.04, ecy), (px - 0.04, muy), stroke: 1.2pt + muted, mark: (end: "stealth", scale: 0.7))
  line((ex0 + ew + 0.04, ecy), (px - 0.04, sgy), stroke: 1.2pt + muted, mark: (end: "stealth", scale: 0.7))

  // latent z node (focal — garnet)
  let zx = px + chipw + 0.78
  let zcy = pcy
  let zr = 0.40
  circle((zx, zcy), radius: zr, fill: garnet, stroke: 1.2pt + garnet)
  content((zx, zcy), text(size: 9pt, weight: "bold", fill: white)[$bold(z)$])
  content((zx + 0.34, zcy - zr - 0.50), text(size: 6.5pt, fill: garnet)[$bold(z) ~ cal(N)(bold(mu), "diag"(bold(sigma)^2))$])
  // reparam arrows from mu, sigma into z
  line((px + chipw + 0.04, muy), (zx - zr - 0.02, zcy + 0.10), stroke: 1.1pt + muted, mark: (end: "stealth", scale: 0.65))
  line((px + chipw + 0.04, sgy), (zx - zr - 0.02, zcy - 0.10), stroke: 1.1pt + muted, mark: (end: "stealth", scale: 0.65))
  content((px + chipw / 2 + 0.10, pcy + 1.05), text(size: 6pt, fill: muted, style: "italic")[reparam.  $bold(z) = bold(mu) + bold(sigma) dot.o bold(epsilon)$])

  // ── 4. MLP DECODER (expanding trapezoid) ────────────────────────────────────
  let dx0 = zx + zr + 0.60
  let dw = 1.30
  let dh0 = 0.95
  let dh1 = 1.7
  let dcx = dx0 + dw / 2
  let dcy = pcy
  line(
    (dx0, dcy + dh0 / 2), (dx0 + dw, dcy + dh1 / 2),
    (dx0 + dw, dcy - dh1 / 2), (dx0, dcy - dh0 / 2),
    close: true, fill: panel, stroke: 1.0pt + ink,
  )
  content((dcx, dcy + 0.16), text(size: 8.5pt, weight: "bold", fill: ink)[Decoder])
  content((dcx, dcy - 0.16), text(size: 7pt, fill: muted)[MLP $p_theta (bold(A) | bold(z))$])
  line((zx + zr + 0.04, zcy), (dx0 - 0.04, dcy), stroke: 1.5pt + ink, mark: (end: "stealth", scale: 0.8))

  // ── 5. ADJACENCY-PROBABILITY HEATMAP  A-hat = sigmoid(z z^T) ─────────────────
  // 5×5 symmetric matrix of edge probabilities (zero diagonal — no self loops).
  let Phat = (
    (0.00, 0.91, 0.62, 0.18, 0.83),
    (0.91, 0.00, 0.78, 0.21, 0.74),
    (0.62, 0.78, 0.00, 0.86, 0.27),
    (0.18, 0.21, 0.86, 0.00, 0.71),
    (0.83, 0.74, 0.27, 0.71, 0.00),
  )
  let n = 5
  let cs = 0.46                    // heatmap cell side
  let hx = dx0 + dw + 0.70
  let Hs = n * cs
  let hy = pcy - Hs / 2
  for i in range(n) {
    for j in range(n) {
      let v = Phat.at(i).at(j)
      let xx = hx + j * cs
      let yy = hy + (n - 1 - i) * cs
      rect((xx, yy), (xx + cs, yy + cs), fill: ramp(v), stroke: 0.5pt + gridc, radius: 0pt)
      content((xx + cs / 2, yy + cs / 2), text(size: 5.4pt, fill: on-fill(v))[#fmt2(v)])
    }
  }
  rect((hx, hy), (hx + Hs, hy + Hs), fill: none, stroke: 1.1pt + ink, radius: 0pt)
  content((hx + Hs / 2, hy + Hs + 0.30), text(size: 7pt, fill: ink)[$hat(bold(A))_(i j) = sigma(bold(z)_i^top bold(z)_j)$])
  content((hx + Hs / 2, hy - 0.34), text(size: 7.5pt, fill: ink)[edge-prob. matrix])
  line((dx0 + dw + 0.04, dcy), (hx - 0.04, pcy), stroke: 1.5pt + ink, mark: (end: "stealth", scale: 0.8))

  // ── 6. SAMPLED GRAPH  A_ij ~ Bernoulli(A-hat_ij) ────────────────────────────
  let sgx = hx + Hs + 0.70
  let sgside = 1.7
  let sgy = pcy - sgside / 2
  let s-edges = ((0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (0, 4), (1, 4))
  rect((sgx, sgy), (sgx + sgside, sgy + sgside), fill: white, stroke: 1.0pt + ink, radius: 0pt)
  small-graph(draw, sgx, sgy, sgside, pent, s-edges, accent: garnet, rad: 0.15)
  content((sgx + sgside / 2, sgy - 0.36), text(size: 9pt, fill: ink)[sampled graph $tilde(G)$])
  content((sgx + sgside / 2, sgy + sgside + 0.30), text(size: 6.5pt, fill: muted)[$A_(i j) ~ "Bern"(hat(A)_(i j))$])
  line((hx + Hs + 0.04, pcy), (sgx - 0.04, pcy), stroke: 1.5pt + ink, mark: (end: "stealth", scale: 0.8))

  // ── reconstruction tie: input adjacency A  vs  predicted A-hat ──────────────
  let ty = pcy - 1.55                  // height of the horizontal recon bracket
  let tcx0 = gx + gside / 2
  let tcx1 = hx + Hs / 2
  line((tcx0, gy - 0.50), (tcx0, ty), stroke: (paint: ink, thickness: 0.7pt, dash: "densely-dotted"))
  line((tcx1, hy - 0.50), (tcx1, ty), stroke: (paint: ink, thickness: 0.7pt, dash: "densely-dotted"))
  line((tcx0, ty), (tcx1, ty), stroke: (paint: ink, thickness: 0.7pt, dash: "densely-dotted"))
  content(
    ((tcx0 + tcx1) / 2 - 0.30, ty - 0.22),
    text(size: 6.4pt, fill: ink)[reconstruct $bold(A)$ from $hat(bold(A))$],
  )

  // ── ELBO loss ribbon along the bottom ───────────────────────────────────────
  let ly = pcy - 2.45
  let lx0 = gx
  let lx1 = sgx + sgside

  // headline ELBO box
  rect((lx0, ly - 0.42), (lx1, ly + 0.42), fill: beige, stroke: 0.9pt + ink, radius: 0pt)
  content(
    ((lx0 + lx1) / 2, ly),
    text(size: 9pt, fill: ink)[
      objective (ELBO):#h(4pt)
      $cal(L) = underbrace(EE_(q_phi) [log p_theta (bold(A) | bold(z))], "edge reconstruction") - underbrace("KL"(q_phi (bold(z) | G) || p(bold(z))), "latent regularizer")$
    ],
  )

  // GENERATE arrow: sample z from prior at test time → decoder (dashed, green)
  line(
    (zx, zcy + zr + 0.95), (zx, zcy + zr + 0.10),
    stroke: (paint: green, thickness: 1.0pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7),
  )
  content((zx, zcy + zr + 1.18), text(size: 6.2pt, fill: green)[sample $bold(z) ~ p(bold(z))$ to #emph[generate]])
})

#v(2pt)
#line(length: 100%, stroke: 0.6pt + faint)
#v(2pt)

// ════════════════════════════════════════════════════════════════════════════
//  BOTTOM PANEL — AUTOREGRESSIVE (EDGE-BY-EDGE) GENERATION
// ════════════════════════════════════════════════════════════════════════════
#cetz.canvas(length: 1cm, {
  import cetz.draw
  import cetz.draw: *

  content((0.0, 2.05), anchor: "west", text(size: 9pt, weight: "bold", fill: ink)[Autoregressive alternative — build the graph edge by edge])
  content((0.0, 1.62), anchor: "west", text(size: 7.5pt, fill: muted)[$p(G) = product_t p(e_t | e_(<t))$#h(6pt) (GraphRNN / GRAN): a recurrent state reads the partial graph and emits the next-edge probability])

  // 4 snapshots of a growing graph, 4 nodes placed on a unit square corners-ish
  let lay = ((0.18, 0.78), (0.80, 0.82), (0.86, 0.22), (0.24, 0.20))
  let steps = (
    (edges: ((0, 1),),                         add: (0, 1)),
    (edges: ((0, 1), (1, 2)),                  add: (1, 2)),
    (edges: ((0, 1), (1, 2), (2, 3)),          add: (2, 3)),
    (edges: ((0, 1), (1, 2), (2, 3), (3, 0)),  add: (3, 0)),
  )
  let side = 1.45
  let gap = 0.95
  let by = -0.6
  for (k, st) in steps.enumerate() {
    let bx = k * (side + gap)
    rect((bx, by), (bx + side, by + side), fill: white, stroke: 0.9pt + ink, radius: 0pt)
    // existing edges (the ones before the new add) in muted, the new edge in garnet
    let newe = st.add
    for e in st.edges {
      let is-new = (e.at(0) == newe.at(0) and e.at(1) == newe.at(1))
      let col = if is-new { garnet } else { muted }
      let th = if is-new { 1.8pt } else { 1.3pt }
      line(
        (bx + lay.at(e.at(0)).at(0) * side, by + lay.at(e.at(0)).at(1) * side),
        (bx + lay.at(e.at(1)).at(0) * side, by + lay.at(e.at(1)).at(1) * side),
        stroke: th + col,
      )
    }
    for i in range(4) {
      let p = (bx + lay.at(i).at(0) * side, by + lay.at(i).at(1) * side)
      circle(p, radius: 0.13, fill: white, stroke: 1.1pt + ink)
    }
    content((bx + side / 2, by - 0.32), text(size: 7.5pt, fill: ink)[step $t = #(k + 1)$])
    content((bx + side / 2, by + side + 0.26), text(size: 6.2pt, fill: garnet)[add $e_#(k + 1)$])
    // arrow to next snapshot
    if k < steps.len() - 1 {
      line((bx + side + 0.06, by + side / 2), (bx + side + gap - 0.06, by + side / 2),
        stroke: 1.4pt + ink, mark: (end: "stealth", scale: 0.8))
      content((bx + side + gap / 2, by + side / 2 + 0.24), text(size: 6pt, fill: muted)[$p(e_#(k + 2) | e_(<#(k + 2)))$])
    }
  }
})
