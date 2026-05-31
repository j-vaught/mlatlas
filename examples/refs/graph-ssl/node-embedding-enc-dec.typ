// Node-embedding encoder–decoder framework (shallow embeddings) — Hamilton, GRL ch.3.
// The unifying view of shallow node embeddings as an ENCODER–DECODER pair:
//
//   ENC:  v  ↦  z_v  ∈ ℝ^d            a (lookup-table) encoder maps each node to a vector
//   DEC:  (z_u, z_v) ↦  ŝ(u,v)        a pairwise decoder reconstructs graph proximity
//   loss: Σ_(u,v)  ℓ( DEC(z_u,z_v),  S[u,v] )   match a similarity target S (adjacency,
//                                                random-walk co-occurrence, …)
//
// With the inner-product decoder  ŝ(u,v) = z_u^⊤ z_v, the whole reconstructed-similarity
// matrix is  Ŝ = Z Z^⊤.  Training pulls Ŝ toward the target S so that nearby nodes in the
// graph get nearby embeddings.  Pipeline shown left→right: GRAPH → ENC → embeddings Z →
// DEC (inner product) → reconstructed Ŝ (heatmap) → loss vs. target S.
// Built from standard GRL conventions in mlatlas's print-first house style — not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let text-c = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let edgec  = rgb("#363636")
#let grid   = rgb("#A2A2A2")
#let blue   = rgb("#466A9F")
#let green  = rgb("#65780B")
#let beige  = rgb("#FFF2E3")
#let n10    = rgb("#ECECEC")
#let n30    = rgb("#C7C7C7")

// 5-node toy graph; node 0 is the focal node (garnet). Embeddings z_v ∈ ℝ^2.
#let names = ($a$, $b$, $c$, $d$, $e$)
// 2-D embedding vectors (chosen so that graph-adjacent nodes are close).
#let Z = (
  ( 0.95,  0.30),   // a
  ( 0.80,  0.62),   // b
  ( 0.20,  0.97),   // c
  (-0.88,  0.40),   // d
  (-0.55, -0.82),   // e
)
// adjacency-style target similarity S (1 = edge / proximal, 0 = far)
#let edges = ((0,1),(1,2),(0,2),(2,3),(3,4))

// inner-product reconstructed similarity  Ŝ = Z Z^⊤
#let dot(u, v) = u.at(0)*v.at(0) + u.at(1)*v.at(1)
#let Shat = Z.map(u => Z.map(v => dot(u, v)))
// normalise Ŝ to 0..1 for the heatmap ramp
#let svals = Shat.flatten()
#let smin = calc.min(..svals)
#let smax = calc.max(..svals)
#let norm(x) = (x - smin) / (smax - smin)

// sequential ramp beige(0) → garnet(1) in oklab
#let ramp(t) = beige.mix((garnet, calc.max(0,calc.min(1,t)) * 100%), space: oklab)
#let on-fill(t) = if t > 0.55 { white } else { ink }

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ════════════════════════════════════════════════════════════════════════════
  // STAGE 1 — the input GRAPH  G = (V, E)
  // ════════════════════════════════════════════════════════════════════════════
  let gx = 0.0            // graph panel centre x
  let gy = 0.0
  let nr = 0.34           // node radius
  // pentagon-ish layout for the 5 nodes
  let gpos = (
    ( 0.00,  1.20),   // a (top, focal)
    ( 1.15,  0.40),   // b
    ( 0.72, -0.95),   // c
    (-0.72, -0.95),   // d
    (-1.15,  0.40),   // e
  )
  // edges first (behind nodes)
  for (i, j) in edges {
    draw.line(
      (gx + gpos.at(i).at(0), gy + gpos.at(i).at(1)),
      (gx + gpos.at(j).at(0), gy + gpos.at(j).at(1)),
      stroke: (paint: edgec, thickness: 1.0pt),
    )
  }
  // nodes
  for (k, p) in gpos.enumerate() {
    let focal = k == 0
    draw.circle(
      (gx + p.at(0), gy + p.at(1)), radius: nr,
      fill: if focal { beige } else { n10 },
      stroke: (paint: if focal { garnet } else { ink }, thickness: if focal { 1.7pt } else { 1.0pt }),
    )
    draw.content((gx + p.at(0), gy + p.at(1)), text(size: 9pt, fill: ink)[#names.at(k)])
  }
  draw.content((gx, gy + 2.05), text(size: 9.5pt, weight: "bold", fill: ink)[graph $G=(V,E)$])
  draw.content((gx, gy - 1.85), text(size: 7.5pt, fill: muted)[nodes $v in V$])

  // ════════════════════════════════════════════════════════════════════════════
  // STAGE 2 — ENC block  (lookup-table encoder  v ↦ z_v)
  // ════════════════════════════════════════════════════════════════════════════
  let ex = 3.55
  // arrow graph → ENC
  draw.line((gx + 1.55, gy), (ex - 0.95, gy),
    stroke: (paint: edgec, thickness: 1.1pt), mark: (end: "stealth", fill: edgec, scale: 0.85))
  draw.content(((gx + 1.55 + ex - 0.95)/2, gy + 0.32), text(size: 7.5pt, fill: muted)[lookup $v$])

  // ENC box (op / parameter block)
  let ebw = 0.92
  let ebh = 1.55
  draw.rect((ex - ebw, gy - ebh), (ex + ebw, gy + ebh),
    fill: n10, stroke: (paint: ink, thickness: 1.2pt), radius: 0pt)
  draw.content((ex, gy + 0.40), text(size: 11pt, weight: "bold", fill: ink)[ENC])
  draw.content((ex, gy - 0.18), text(size: 8.5pt, fill: ink)[$z_v = "EMB"[v]$])
  draw.content((ex, gy - 0.62), text(size: 7pt, fill: muted)[trainable])
  draw.content((ex, gy - 0.92), text(size: 7pt, fill: muted)[table $Z in RR^(|V| times d)$])
  draw.content((ex, gy + ebh + 0.28), text(size: 9.5pt, weight: "bold", fill: ink)[encoder])

  // ════════════════════════════════════════════════════════════════════════════
  // STAGE 3 — embedding vectors  Z  (a |V| × d tensor of rows z_v)
  // ════════════════════════════════════════════════════════════════════════════
  let zx = 6.45          // left edge of the Z tensor
  // arrow ENC → Z
  draw.line((ex + ebw, gy), (zx - 0.30, gy),
    stroke: (paint: edgec, thickness: 1.1pt), mark: (end: "stealth", fill: edgec, scale: 0.85))

  let cellh = 0.46       // row height
  let cellw = 0.70       // per-component cell width (d = 2)
  let dcols = 2
  let nrow = Z.len()
  let ztop = gy + (nrow * cellh) / 2     // top y of the tensor
  // each row v is the vector z_v; cells show the 2 components
  for r in range(nrow) {
    let yy = ztop - r * cellh
    let focal = r == 0
    for c in range(dcols) {
      let xx = zx + c * cellw
      draw.rect((xx, yy - cellh), (xx + cellw, yy),
        fill: if focal { beige } else { white },
        stroke: (paint: grid, thickness: 0.6pt), radius: 0pt)
      let val = Z.at(r).at(c)
      draw.content((xx + cellw/2, yy - cellh/2),
        text(size: 7pt, fill: ink)[#calc.round(val, digits: 2)])
    }
    // row label z_v at the left
    draw.content((zx - 0.14, yy - cellh/2), anchor: "east",
      text(size: 8pt, fill: if focal { garnet } else { muted },
        weight: if focal { "bold" } else { "regular" })[$z_(#names.at(r))$])
    // garnet ring around the focal row
    if focal {
      draw.rect((zx, yy - cellh), (zx + dcols*cellw, yy),
        fill: none, stroke: (paint: garnet, thickness: 1.5pt), radius: 0pt)
    }
  }
  // outer frame of Z
  draw.rect((zx, ztop - nrow*cellh), (zx + dcols*cellw, ztop),
    fill: none, stroke: (paint: edgec, thickness: 1.1pt), radius: 0pt)
  // d = 2 component bracket on top
  draw.content((zx + dcols*cellw/2, ztop + 0.52), text(size: 9.5pt, weight: "bold", fill: ink)[$Z$])
  draw.content((zx + dcols*cellw/2, ztop + 0.12), anchor: "south",
    text(size: 7pt, fill: muted)[$|V| times d$])
  draw.content((zx + dcols*cellw/2, ztop - nrow*cellh - 0.22), anchor: "north",
    text(size: 7.5pt, fill: muted)[embeddings $z_v in RR^d$])

  // ════════════════════════════════════════════════════════════════════════════
  // STAGE 4 — DEC block  (pairwise inner-product decoder)
  // ════════════════════════════════════════════════════════════════════════════
  let zr = zx + dcols*cellw
  let dx = zr + 1.85
  // arrow Z → DEC
  draw.line((zr + 0.18, gy), (dx - 0.95, gy),
    stroke: (paint: edgec, thickness: 1.1pt), mark: (end: "stealth", fill: edgec, scale: 0.85))
  draw.content(((zr + 0.18 + dx - 0.95)/2, gy + 0.30), text(size: 7.5pt, fill: muted)[$z_u, z_v$])

  let dbw = 1.05
  let dbh = 1.55
  draw.rect((dx - dbw, gy - dbh), (dx + dbw, gy + dbh),
    fill: n10, stroke: (paint: ink, thickness: 1.2pt), radius: 0pt)
  draw.content((dx, gy + 0.42), text(size: 11pt, weight: "bold", fill: ink)[DEC])
  draw.content((dx, gy - 0.10), text(size: 8.5pt, fill: ink)[$hat(s)(u,v)$])
  draw.content((dx, gy - 0.55), text(size: 9pt, fill: garnet, weight: "bold")[$= z_u^top z_v$])
  draw.content((dx, gy - 1.02), text(size: 7pt, fill: muted)[inner product])
  draw.content((dx, gy + dbh + 0.28), text(size: 9.5pt, weight: "bold", fill: ink)[decoder])

  // ════════════════════════════════════════════════════════════════════════════
  // STAGE 5 — reconstructed similarity  Ŝ = Z Z^⊤  (heatmap)
  // ════════════════════════════════════════════════════════════════════════════
  let hx = dx + dbw + 1.25     // left edge of heatmap
  // arrow DEC → Ŝ
  draw.line((dx + dbw, gy), (hx - 0.30, gy),
    stroke: (paint: edgec, thickness: 1.1pt), mark: (end: "stealth", fill: edgec, scale: 0.85))
  draw.content(((dx + dbw + hx - 0.30)/2, gy + 0.30), text(size: 7.5pt, fill: muted)[all pairs])

  let hc = 0.50          // heatmap cell side
  let n = Z.len()
  let htop = gy + (n * hc) / 2
  for i in range(n) {
    for j in range(n) {
      let t = norm(Shat.at(i).at(j))
      let xx = hx + j * hc
      let yy = htop - (i + 1) * hc
      draw.rect((xx, yy), (xx + hc, yy + hc),
        fill: ramp(t), stroke: (paint: grid, thickness: 0.5pt), radius: 0pt)
    }
    // row / col node labels
    draw.content((hx - 0.12, htop - (i + 0.5)*hc), anchor: "east",
      text(size: 6.5pt, fill: muted)[#names.at(i)])
    draw.content((hx + (i + 0.5)*hc, htop + 0.10), anchor: "south",
      text(size: 6.5pt, fill: muted)[#names.at(i)])
  }
  draw.rect((hx, htop - n*hc), (hx + n*hc, htop),
    fill: none, stroke: (paint: edgec, thickness: 1.1pt), radius: 0pt)
  draw.content((hx + n*hc/2, htop + 0.50), text(size: 9.5pt, weight: "bold", fill: ink)[$hat(S) = Z Z^top$])
  draw.content((hx + n*hc/2, htop - n*hc - 0.22), anchor: "north",
    text(size: 7.5pt, fill: muted)[reconstructed sim.])

  // ════════════════════════════════════════════════════════════════════════════
  // STAGE 6 — LOSS node  (match Ŝ to the target S)
  // ════════════════════════════════════════════════════════════════════════════
  let hr = hx + n*hc
  let lx = hr + 1.55
  // arrow Ŝ → loss
  draw.line((hr + 0.10, gy), (lx - 0.90, gy),
    stroke: (paint: edgec, thickness: 1.1pt), mark: (end: "stealth", fill: edgec, scale: 0.85))
  // loss node (garnet output)
  let lw = 0.92
  let lh = 0.70
  draw.rect((lx - lw, gy - lh), (lx + lw, gy + lh),
    fill: beige, stroke: (paint: garnet, thickness: 1.7pt), radius: 0pt)
  draw.content((lx, gy + 0.30), text(size: 10pt, weight: "bold", fill: garnet)[$cal(L)$])
  draw.content((lx, gy - 0.18), text(size: 7pt, fill: ink)[$sum_(u,v) ell(hat(s),S)$])
  draw.content((lx, gy + lh + 0.28), text(size: 9.5pt, weight: "bold", fill: ink)[loss])

  // target S feeding the loss from below
  let ty = gy - 2.55
  draw.rect((lx - lw, ty - lh*0.62), (lx + lw, ty + lh*0.62),
    fill: n10, stroke: (paint: blue, thickness: 1.2pt), radius: 0pt)
  draw.content((lx, ty + 0.16), text(size: 8.5pt, fill: blue, weight: "bold")[$S$])
  draw.content((lx, ty - 0.20), text(size: 6.5pt, fill: muted)[target sim.])
  draw.line((lx, ty + lh*0.62), (lx, gy - lh),
    stroke: (paint: blue, thickness: 1.0pt), mark: (end: "stealth", fill: blue, scale: 0.8))
  draw.content((lx + 0.16, (ty + lh*0.62 + gy - lh)/2), anchor: "west",
    text(size: 6.5pt, fill: muted)[adjacency /])
  draw.content((lx + 0.16, (ty + lh*0.62 + gy - lh)/2 - 0.26), anchor: "west",
    text(size: 6.5pt, fill: muted)[rand-walk])

  // ════════════════════════════════════════════════════════════════════════════
  // training feedback: gradient flows back to update the embedding table Z
  // ════════════════════════════════════════════════════════════════════════════
  let fbY = gy - 3.45
  let fbX = lx + lw + 0.45        // route feedback down the RIGHT side, clear of S box
  draw.line((lx + lw, gy - lh*0.4), (fbX, gy - lh*0.4),
    stroke: (paint: garnet, thickness: 1.0pt, dash: "dashed"))
  draw.line((fbX, gy - lh*0.4), (fbX, fbY),
    stroke: (paint: garnet, thickness: 1.0pt, dash: "dashed"))
  draw.line((fbX, fbY), (zx + dcols*cellw/2, fbY),
    stroke: (paint: garnet, thickness: 1.0pt, dash: "dashed"))
  draw.line((zx + dcols*cellw/2, fbY), (zx + dcols*cellw/2, ztop - nrow*cellh - 0.42),
    stroke: (paint: garnet, thickness: 1.0pt, dash: "dashed"),
    mark: (end: "stealth", fill: garnet, scale: 0.8))
  draw.content(((fbX + zx + dcols*cellw/2)/2, fbY - 0.22), anchor: "north",
    text(size: 7.5pt, fill: garnet, style: "italic")[$nabla_Z cal(L)$ — update embeddings (SGD)])

  // colorbar legend for the heatmap (bottom-left, compact)
  let bx0 = gx - 1.55
  let by0 = gy - 3.35
  let bw = 2.2
  let bh = 0.30
  let nseg = 32
  for s in range(nseg) {
    let t = s / (nseg - 1)
    draw.rect((bx0 + s*bw/nseg, by0), (bx0 + (s+1)*bw/nseg, by0 + bh),
      fill: ramp(t), stroke: none)
  }
  draw.rect((bx0, by0), (bx0 + bw, by0 + bh), fill: none, stroke: (paint: edgec, thickness: 0.7pt), radius: 0pt)
  draw.content((bx0, by0 - 0.10), anchor: "north-west", text(size: 6.5pt, fill: muted)[far])
  draw.content((bx0 + bw, by0 - 0.10), anchor: "north-east", text(size: 6.5pt, fill: muted)[close])
  draw.content((bx0 + bw/2, by0 + bh + 0.08), anchor: "south",
    text(size: 7pt, fill: muted)[reconstructed proximity $hat(s)(u,v)$])
})
