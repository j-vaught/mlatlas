// GraphSAGE — inductive GNN with fixed-size NEIGHBOURHOOD SAMPLING + aggregation.
//
// Instead of using the full (variable-size, possibly huge) neighbourhood, GraphSAGE
// SAMPLES a fixed number S of neighbours per hop, so the receptive field — and the
// per-batch compute — is bounded regardless of node degree. For target node v:
//   (1) sample  N_S(v) ⊂ N(v),  |N_S(v)| = S          (e.g. S1 at hop-1, S2 at hop-2)
//   (2) aggregate sampled neighbour features:
//         h_N(v) = AGG_k({ h_u^{k-1} : u ∈ N_S(v) })   (mean | pool | LSTM)
//   (3) concat with self, then linear-project + nonlinearity:
//         h_v^k = sigma( W_k · [ h_v^{k-1}  ||  h_N(v) ] )
//   (4) (optional) L2-normalise.
// Stacking K layers reaches K hops out; sampling is applied at every hop.
//
// Built from the standard GraphSAGE convention (Hamilton, Ying, Leskovec 2017;
// Hamilton GRL ch.5) in mlatlas's print-first house style. Original layout — not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet   = rgb("#73000A")
#let ink      = rgb("#1A1A1A")
#let muted    = rgb("#5C5C5C")
#let faint    = rgb("#A2A2A2")
#let edgecol  = rgb("#5C5C5C")
#let sampfill = rgb("#FFF2E3")   // beige — SAMPLED neighbour
#let dropfill = rgb("#ECECEC")   // 10% black — un-sampled (dropped) neighbour
#let ctrfill  = rgb("#FFF2E3")   // beige — target node
#let blue     = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // =====================================================================
  // PANEL A — fixed-size sampling of a 2-hop neighbourhood
  // =====================================================================
  let r1 = 0.46          // target node radius
  let rh = 0.36          // hop-1 radius
  let r2 = 0.27          // hop-2 radius
  let V  = (0, 0)        // target node v

  draw.content((0, 4.05), text(size: 10.5pt, weight: "bold", fill: ink)[(a) fixed-size 2-hop neighbourhood sampling])

  // hop-1 neighbours of v.  (label, pos, sampled?)  — sample S1 = 3 of 5.
  let hop1 = (
    ([$u_1$], ( 2.6,  1.9), true),
    ([$u_2$], ( 3.1,  0.0), true),
    ([$u_3$], ( 2.6, -1.9), false),
    ([$u_4$], (-2.6, -1.4), true),
    ([$u_5$], (-3.0,  0.9), false),
  )

  // hop-2 neighbours, attached to a hop-1 node (parent index, label, pos, sampled?)
  // only neighbours of SAMPLED hop-1 nodes get sampled further (S2 = 2 each shown).
  let hop2 = (
    (0, ([$w$], ( 4.7,  3.0), true)),
    (0, ([$w$], ( 5.0,  1.9), false)),
    (1, ([$w$], ( 5.2,  0.5), true)),
    (1, ([$w$], ( 5.0, -0.7), true)),
    (3, ([$w$], (-4.6, -2.1), true)),
    (3, ([$w$], (-4.9, -0.8), false)),
  )

  // ---- hop-2 edges (drawn first, behind nodes) ----
  for (pi, info) in hop2 {
    let (lbl, p, samp) = info
    let par = hop1.at(pi).at(1)
    let col = if samp { ink } else { faint }
    let th  = if samp { 0.9pt } else { 0.6pt }
    let dash = if samp { none } else { "dashed" }
    draw.line(par, p, stroke: (paint: col, thickness: th, dash: dash))
  }
  // ---- hop-1 edges ----
  for (lbl, p, samp) in hop1 {
    let col = if samp { ink } else { faint }
    let th  = if samp { 1.1pt } else { 0.6pt }
    let dash = if samp { none } else { "dashed" }
    draw.line(V, p, stroke: (paint: col, thickness: th, dash: dash))
  }

  // ---- hop-2 nodes ----
  for (pi, info) in hop2 {
    let (lbl, p, samp) = info
    let fill = if samp { sampfill } else { dropfill }
    let stk  = if samp { ink } else { faint }
    draw.circle(p, radius: r2, fill: fill, stroke: (paint: stk, thickness: if samp { 1.0pt } else { 0.7pt }))
  }
  // ---- hop-1 nodes ----
  for (lbl, p, samp) in hop1 {
    let fill = if samp { sampfill } else { dropfill }
    let stk  = if samp { garnet } else { faint }
    draw.circle(p, radius: rh, fill: fill, stroke: (paint: stk, thickness: if samp { 1.5pt } else { 0.8pt }))
    draw.content(p, text(size: 8.5pt, fill: if samp { ink } else { muted })[#lbl])
  }
  // ---- target node v (focal) ----
  draw.circle(V, radius: r1 + 0.04, fill: ctrfill, stroke: (paint: garnet, thickness: 1.9pt))
  draw.content(V, text(size: 10pt, fill: ink)[$v$])

  // legend (bottom of panel A)
  let ly = -3.55
  draw.circle((-3.7, ly), radius: 0.22, fill: sampfill, stroke: (paint: garnet, thickness: 1.4pt))
  draw.content((-3.35, ly), anchor: "west", text(size: 8pt, fill: ink)[sampled  $u in cal(N)_S (v)$])
  draw.circle((0.55, ly), radius: 0.22, fill: dropfill, stroke: (paint: faint, thickness: 0.8pt))
  draw.content((0.9, ly), anchor: "west", text(size: 8pt, fill: muted)[not sampled (dashed = dropped edge)])
  draw.content((0, -4.25), anchor: "center",
    text(size: 8pt, fill: muted)[hop-1: keep $S_1$ of $deg(v)$ neighbours  ·  hop-2: keep $S_2$ per node  ·  bounded fan-out $S_1 S_2$])

  // =====================================================================
  // PANEL B — the per-layer update: AGG · CONCAT · LINEAR
  // =====================================================================
  let bx = 8.6
  draw.content((bx + 2.5, 4.05), text(size: 10.5pt, weight: "bold", fill: ink)[(b) layer-$k$ update for node $v$])

  // sampled-neighbour feature stack (left), fanning into the AGG op
  let sx = bx + 0.1
  let sy0 = 2.7
  let dvs = 0.62
  let nsamp = 3
  let agg = (bx + 3.0, 2.7 - dvs)   // AGG op centre, vertically centred on the stack
  for i in range(nsamp) {
    let yi = sy0 - i * dvs
    draw.rect((sx - 0.85, yi - 0.22), (sx + 0.85, yi + 0.22),
      fill: sampfill, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
    draw.content((sx, yi), text(size: 7.5pt, fill: ink)[$h_(u_#(i+1))^(k-1)$])
    draw.line((sx + 0.85, yi), (agg.at(0) - 0.52, agg.at(1)),
      stroke: (paint: edgecol, thickness: 0.9pt), mark: (end: "stealth", scale: 0.7))
  }
  draw.content((sx, sy0 + 0.55), anchor: "center",
    text(size: 7.5pt, fill: muted)[sampled neighbour features])

  // AGG op-node (circle)
  draw.circle(agg, radius: 0.52, fill: rgb("#ECECEC"), stroke: (paint: ink, thickness: 1.2pt))
  draw.content(agg, text(size: 8pt, weight: "bold", fill: ink)[AGG])
  draw.content((agg.at(0), agg.at(1) - 0.78), anchor: "center",
    text(size: 7pt, fill: muted)[mean · pool · LSTM])

  // h_N(v) result of aggregation
  let hn = (agg.at(0) + 1.85, agg.at(1))
  draw.line((agg.at(0) + 0.52, agg.at(1)), (hn.at(0) - 0.62, hn.at(1)),
    stroke: (paint: ink, thickness: 1.0pt), mark: (end: "stealth", scale: 0.75))
  draw.rect((hn.at(0) - 0.62, hn.at(1) - 0.27), (hn.at(0) + 0.62, hn.at(1) + 0.27),
    fill: rgb("#ECECEC"), stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content(hn, text(size: 8pt, fill: ink)[$h_(cal(N)(v))$])

  // self feature h_v^{k-1} (below), feeding the concat
  let hv = (hn.at(0), hn.at(1) - 1.85)
  draw.rect((hv.at(0) - 0.62, hv.at(1) - 0.27), (hv.at(0) + 0.62, hv.at(1) + 0.27),
    fill: ctrfill, stroke: (paint: garnet, thickness: 1.4pt), radius: 0pt)
  draw.content(hv, text(size: 8pt, fill: ink)[$h_v^(k-1)$])
  draw.content((hv.at(0), hv.at(1) - 0.52), anchor: "center",
    text(size: 7pt, fill: muted)[self (previous layer)])

  // CONCAT op (square-ish): both h_N(v) and h_v feed in
  let cc = (hn.at(0) + 1.85, (hn.at(1) + hv.at(1)) / 2)
  draw.line((hn.at(0) + 0.62, hn.at(1)), (cc.at(0) - 0.5, cc.at(1) + 0.28),
    stroke: (paint: ink, thickness: 1.0pt), mark: (end: "stealth", scale: 0.7))
  draw.line((hv.at(0) + 0.62, hv.at(1)), (cc.at(0) - 0.5, cc.at(1) - 0.28),
    stroke: (paint: garnet, thickness: 1.2pt), mark: (end: "stealth", fill: garnet, scale: 0.7))
  draw.circle(cc, radius: 0.5, fill: rgb("#ECECEC"), stroke: (paint: ink, thickness: 1.1pt))
  draw.content(cc, text(size: 9pt, fill: ink)[$bar.v.double$])
  draw.content((cc.at(0), cc.at(1) + 0.72), anchor: "center",
    text(size: 7.5pt, fill: ink, weight: "bold")[concat])

  // LINEAR (W_k) block + nonlinearity -> new embedding
  let lin = (cc.at(0) + 1.95, cc.at(1))
  draw.line((cc.at(0) + 0.5, cc.at(1)), (lin.at(0) - 0.7, lin.at(1)),
    stroke: (paint: ink, thickness: 1.0pt), mark: (end: "stealth", scale: 0.75))
  draw.rect((lin.at(0) - 0.7, lin.at(1) - 0.42), (lin.at(0) + 0.7, lin.at(1) + 0.42),
    fill: blue.lighten(72%), stroke: (paint: blue, thickness: 1.4pt), radius: 0pt)
  draw.content((lin.at(0), lin.at(1) + 0.11), text(size: 8.5pt, fill: ink)[$W_k dot.c$])
  draw.content((lin.at(0), lin.at(1) - 0.16), text(size: 7pt, fill: muted)[then $sigma$])

  // updated embedding h_v^k (focal output)
  let out = (lin.at(0) + 1.65, lin.at(1))
  draw.line((lin.at(0) + 0.7, lin.at(1)), (out.at(0) - 0.5, out.at(1)),
    stroke: (paint: garnet, thickness: 1.4pt), mark: (end: "stealth", fill: garnet, scale: 0.85))
  draw.circle(out, radius: 0.5, fill: ctrfill, stroke: (paint: garnet, thickness: 1.7pt))
  draw.content(out, text(size: 9pt, fill: ink)[$h_v^k$])

  // the update equation under panel B
  draw.content((bx + 3.3, -1.05), anchor: "center",
    text(size: 9.5pt, fill: ink)[$h_v^k = sigma( W_k dot.c [ h_v^(k-1) thin bar.v.double thin "AGG"_k ({ h_u^(k-1) : u in cal(N)_S (v) }) ] )$])
  draw.content((bx + 3.3, -1.85), anchor: "center",
    text(size: 8pt, fill: muted)[repeat for $k = 1 .. K$ layers ($K$ hops); optional $ell_2$-normalise $h_v^k$])
})
