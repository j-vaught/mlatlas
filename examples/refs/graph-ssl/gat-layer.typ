// Graph Attention Network (GAT) layer — a GNN layer where a center node aggregates
// neighbour messages weighted by LEARNED attention coefficients.
//
// For center node i with neighbourhood N(i):
//   (1) project every node:        z_k = W h_k
//   (2) score each edge (i,j):     e_ij = LeakyReLU( a^T [ W h_i || W h_j ] )
//   (3) normalise over neighbours: alpha_ij = softmax_j(e_ij)
//                                            = exp(e_ij) / sum_{k in N(i)} exp(e_ik)
//   (4) aggregate:                 h'_i = sigma( sum_{j in N(i)} alpha_ij W h_j )
// Multi-head: K independent attention heads run in parallel; their outputs are
// concatenated (hidden layers) or averaged (final layer).
//
// Built from the standard GAT convention (Velickovic et al. 2018; Hamilton GRL ch.5;
// Prince UDL ch.13) in mlatlas's print-first house style. Original layout — not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let edgecol = rgb("#5C5C5C")
#let nbrfill = rgb("#ECECEC")  // 10% black — neighbour node fill
#let ctrfill = rgb("#FFF2E3")  // beige — center node fill
#let blue    = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // =====================================================================
  // PANEL A — neighbourhood aggregation with per-edge attention weights
  // =====================================================================
  let r  = 0.50          // node radius
  let Ci = (0, 0)        // center node i

  // five neighbours fanned around the center, each with an attention weight.
  // (label, position, alpha, focal?) — strokes scale with alpha; focal edge garnet.
  let nbrs = (
    ([$j_1$], ( 2.7,  2.0), 0.30, false),
    ([$j_2$], ( 3.3,  0.4), 0.42, true),   // focal: highest weight -> garnet
    ([$j_3$], ( 2.7, -1.7), 0.11, false),
    ([$j_4$], (-1.5, -2.4), 0.08, false),
    ([$j_5$], (-2.9,  0.2), 0.09, false),
  )

  // ---- attention edges (drawn first, behind nodes) -------------------------
  // each edge points INTO the center; stroke thickness ∝ alpha_ij (message weight).
  for (lbl, p, a, focal) in nbrs {
    let dx = Ci.at(0) - p.at(0)
    let dy = Ci.at(1) - p.at(1)
    let len = calc.sqrt(dx * dx + dy * dy)
    let ux = dx / len
    let uy = dy / len
    let s = (p.at(0) + ux * r, p.at(1) + uy * r)
    let e = (Ci.at(0) - ux * r, Ci.at(1) - uy * r)
    let th = 0.6pt + a * 9pt          // thickness encodes alpha
    let col = if focal { garnet } else { edgecol }
    draw.line(s, e, stroke: (paint: col, thickness: th), mark: (end: "stealth", fill: col, scale: 0.85))
    // alpha label near the midpoint, nudged perpendicular to the edge
    let mx = (s.at(0) + e.at(0)) / 2
    let my = (s.at(1) + e.at(1)) / 2
    let off = 0.30
    draw.content(
      (mx - uy * off, my + ux * off),
      text(size: 7.5pt, fill: if focal { garnet } else { muted }, weight: if focal { "bold" } else { "regular" })[
        $alpha_(i #lbl)$
      ],
    )
  }

  // ---- neighbour nodes -----------------------------------------------------
  for (lbl, p, a, focal) in nbrs {
    draw.circle(p, radius: r, fill: nbrfill, stroke: (paint: ink, thickness: 1.0pt))
    draw.content(p, text(size: 9pt, fill: ink)[$h_(#lbl)$])
  }

  // ---- center node i (focal, beige + garnet ring) --------------------------
  draw.circle(Ci, radius: r + 0.04, fill: ctrfill, stroke: (paint: garnet, thickness: 1.7pt))
  draw.content(Ci, text(size: 10pt, fill: ink)[$h_i$])

  // ---- panel-A caption -----------------------------------------------------
  draw.content((0.25, 3.0), text(size: 10pt, weight: "bold", fill: ink)[(a) attention-weighted aggregation])
  draw.content((0.25, -3.05), anchor: "center",
    text(size: 8pt, fill: muted)[edge width $prop alpha_(i j)$  ·  garnet = highest-weight neighbour])

  // =====================================================================
  // PANEL B — how a single attention coefficient is computed
  // =====================================================================
  let bx = 8.2           // panel B origin x
  // box frame (sharp corners)
  draw.rect((bx - 0.7, -2.7), (bx + 5.3, 2.55), stroke: (paint: rgb("#A2A2A2"), thickness: 0.8pt))
  draw.content((bx + 2.3, 3.0), text(size: 10pt, weight: "bold", fill: ink)[(b) computing $alpha_(i j)$])

  // small node-pair (i, j) at the top of the box
  let pi = (bx + 0.4, 1.7)
  let pj = (bx + 2.1, 1.7)
  draw.circle(pi, radius: 0.34, fill: ctrfill, stroke: (paint: garnet, thickness: 1.4pt))
  draw.content(pi, text(size: 8pt, fill: ink)[$h_i$])
  draw.circle(pj, radius: 0.34, fill: nbrfill, stroke: (paint: ink, thickness: 1.0pt))
  draw.content(pj, text(size: 8pt, fill: ink)[$h_j$])
  draw.line((pi.at(0) + 0.34, pi.at(1)), (pj.at(0) - 0.34, pj.at(1)),
    stroke: (paint: edgecol, thickness: 1.0pt))

  // step list inside the box (left-aligned at bx-0.4)
  let lx = bx - 0.4
  let step(y, body) = draw.content((lx, y), anchor: "west", text(size: 8.5pt, fill: ink)[#body])
  step( 0.85, [linear map: $#h(0.1em) z_k = W h_k$])
  step( 0.10, [edge score: $#h(0.1em) e_(i j) = "LeakyReLU"(a^top [z_i bar.v.double z_j])$])
  // softmax normalisation, highlighted as the GAT essence (garnet)
  draw.content((lx, -0.78), anchor: "west",
    text(size: 8.5pt, fill: garnet, weight: "bold")[normalise (softmax over $j in cal(N)(i)$):])
  draw.content((lx + 0.25, -1.62), anchor: "west",
    text(size: 9.5pt, fill: ink)[$alpha_(i j) = exp(e_(i j)) / (sum_(k in cal(N)(i)) exp(e_(i k)))$])

  // =====================================================================
  // PANEL C — multi-head attention fan + aggregation update
  // =====================================================================
  let cy = -5.8
  draw.content((0.3, cy + 1.75), anchor: "center",
    text(size: 10pt, weight: "bold", fill: ink)[(c) multi-head attention ($K$ heads), then aggregate])

  // K parallel heads as small boxes STACKED VERTICALLY, fanning into one
  // aggregate node — emphasises that the heads are independent / parallel.
  let nheads = 3
  let hx = -3.5            // head column x
  let boxw = 1.3
  let boxh = 0.52
  let vsp = 0.78          // vertical spacing between heads
  let agg = (-0.7, cy)    // aggregate / concat node center
  for k in range(nheads) {
    let yk = cy + vsp - k * vsp        // top head highest, head1 at top
    let topcol = if k == 0 { garnet } else { ink }
    draw.rect((hx - boxw / 2, yk - boxh / 2), (hx + boxw / 2, yk + boxh / 2),
      fill: rgb("#ECECEC"), stroke: (paint: topcol, thickness: if k == 0 { 1.4pt } else { 1.0pt }), radius: 0pt)
    draw.content((hx, yk), text(size: 7.5pt, fill: ink)[head #(k + 1)])
    // arrow from each head fanning into the aggregate node
    draw.line((hx + boxw / 2, yk), (agg.at(0) - 0.62, agg.at(1)),
      stroke: (paint: edgecol, thickness: 0.9pt), mark: (end: "stealth", scale: 0.7))
  }
  // note beside the head column
  draw.content((hx + 1.55, cy + vsp + boxh / 2 + 0.16), anchor: "west",
    text(size: 7.5pt, fill: muted)[$K$ independent heads, params $W^((k)), a^((k))$])

  // aggregate / concat node
  draw.rect((agg.at(0) - 0.62, cy - 0.42), (agg.at(0) + 0.62, cy + 0.42),
    fill: rgb("#FFF2E3"), stroke: (paint: garnet, thickness: 1.4pt), radius: 0pt)
  draw.content((agg.at(0), cy + 0.13), text(size: 8pt, fill: ink)[concat])
  draw.content((agg.at(0), cy - 0.16), text(size: 7pt, fill: muted)[or avg])

  // arrow to the updated embedding h'_i
  draw.line((agg.at(0) + 0.62, cy), (agg.at(0) + 1.55, cy),
    stroke: (paint: garnet, thickness: 1.3pt), mark: (end: "stealth", fill: garnet, scale: 0.85))
  draw.circle((agg.at(0) + 2.1, cy), radius: 0.46, fill: ctrfill, stroke: (paint: garnet, thickness: 1.6pt))
  draw.content((agg.at(0) + 2.1, cy), text(size: 9pt, fill: ink)[$h'_i$])

  // the per-head aggregation equation to the right of the fan
  draw.content((3.7, cy + 0.45), anchor: "west",
    text(size: 9pt, fill: ink)[$h'_i = sigma( sum_(j in cal(N)(i)) alpha_(i j) thin W h_j )$])
  draw.content((3.7, cy - 0.45), anchor: "west",
    text(size: 8pt, fill: muted)[per head $k$, then concat $bar.v.double_(k=1)^K$ (hidden) or average (output)])
})
