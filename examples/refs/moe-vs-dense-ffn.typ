// Dense FFN vs Mixture-of-Experts (MoE).
// LEFT  — dense: every token flows through ONE shared feed-forward (SwiGLU) block.
// RIGHT — MoE: a router scores the N experts and routes each token to the top-k; only the
//         selected expert FFNs run, their outputs combined by router weights.
// Rebuilt from architectural knowledge in mlatlas's style (DeepSeek-V3-style MoE layer).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 8pt)

#let pal = (
  edge: rgb("#243038"),
  text: rgb("#222222"),
  muted: rgb("#5C5C5C"),
  faint: rgb("#A2A2A2"),
  accent: rgb("#73000A"), // garnet — the active / selected path
  tok: rgb("#ECECEC"), // token slab (neutral 10% black)
  dense: rgb("#FFF2E3"), // dense FFN block (beige)
  expert: rgb("#FFF2E3"), // idle expert (beige)
  active: rgb("#E7B7BB"), // selected expert (garnet-tinted)
  router: rgb("#C7C7C7"), // router (30% black)
)

#let cam = cam-cabinet

#cetz.canvas(length: 1cm, {
  import cetz.draw
  let p = pal

  let A(o, w, h, dep) = block3d-anchors(origin: o, w: w, h: h, dep: dep, cam: cam)
  // solid (active) and faint (idle) stealth arrows
  let arr(a, b, color: p.edge, w: 1.3pt, dash: none) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: 0.7),
  )

  // ============================================================ LEFT : DENSE FFN
  let lx = 0
  // panel title
  draw.content((lx + 2.0, 4.5), text(size: 11pt, weight: "bold", fill: p.text)[Dense feed-forward])
  draw.content((lx + 2.0, 3.95), text(size: 8pt, fill: p.muted)[one shared FFN — every token])

  // input token slab
  let din = (lx, 0)
  tensor3d(draw, origin: din, w: 0.85, h: 2.6, dep: 0.5, base: p.tok, edge: p.edge, cam: cam,
    title: [tokens], y-label: [seq], x-label: [d])
  let dina = A(din, 0.85, 2.6, 0.5)

  // single FFN (SwiGLU) block, with seam to read as gate/up + down
  let dffn = (lx + 2.0, 0)
  tensor3d(draw, origin: dffn, w: 1.9, h: 2.6, dep: 1.5, base: p.dense, edge: p.edge, cam: cam, seams: (0.5,),
    title: [FFN (SwiGLU)])
  let dffna = A(dffn, 1.9, 2.6, 1.5)
  draw.content((dffn.at(0), dffn.at(1) + 0.45), text(size: 7pt, fill: p.muted)[gate · up])
  draw.content((dffn.at(0), dffn.at(1) - 0.45), text(size: 7pt, fill: p.muted)[down proj])

  // output slab
  let dout = (lx + 4.3, 0)
  tensor3d(draw, origin: dout, w: 0.85, h: 2.6, dep: 0.5, base: p.tok, edge: p.edge, cam: cam,
    title: [output], x-label: [d])
  let douta = A(dout, 0.85, 2.6, 0.5)

  arr((dina.anchor)("east"), (dffna.anchor)("west"))
  arr((dffna.anchor)("east"), (douta.anchor)("west"))

  // ============================================================ divider
  let mid = 7.0
  draw.line((mid, -5.6), (mid, 4.9), stroke: (paint: p.faint, thickness: 0.6pt, dash: "dashed"))

  // ============================================================ RIGHT : MoE
  let rx = 8.4
  draw.content((rx + 3.4, 4.5), text(size: 11pt, weight: "bold", fill: p.accent)[Mixture-of-Experts])
  draw.content((rx + 3.4, 3.95), text(size: 8pt, fill: p.muted)[router picks top-$k$ of $N$ experts])

  // input token slab
  let min = (rx, 0)
  tensor3d(draw, origin: min, w: 0.85, h: 2.6, dep: 0.5, base: p.tok, edge: p.edge, cam: cam,
    title: [tokens], y-label: [seq], x-label: [d])
  let mina = A(min, 0.85, 2.6, 0.5)

  // router (thin gate block)
  let rt = (rx + 1.85, 0)
  tensor3d(draw, origin: rt, w: 0.55, h: 2.6, dep: 0.5, base: p.router, edge: p.edge, cam: cam, title: [router])
  let rta = A(rt, 0.55, 2.6, 0.5)
  draw.content((rt.at(0), rt.at(1) - 0.0), text(size: 7pt, fill: p.text)[softmax\ top-$k$])
  arr((mina.anchor)("east"), (rta.anchor)("west"))

  // N expert FFNs stacked vertically; experts 2 & 4 selected (top-k = 2)
  let N = 5
  let selected = (1, 3) // 0-indexed -> experts 2 and 4 are routed
  let ex = (rx + 4.3, 0)
  let ew = 1.7
  let eh = 0.78
  let edep = 0.95
  let gap = 1.42
  let y0 = (N - 1) / 2 * gap
  let router-east = (rta.anchor)("east")
  for i in range(N) {
    let yy = y0 - i * gap
    let o = (ex.at(0), yy)
    let on = selected.contains(i)
    let fill = if on { p.active } else { p.expert }
    let ec = if on { p.accent } else { p.edge.lighten(20%) }
    block3d(draw, origin: o, w: ew, h: eh, dep: edep, base: fill, edge: ec, cam: cam,
      sil-weight: if on { 1.1pt } else { 0.8pt })
    let a = A(o, ew, eh, edep)
    draw.content((o.at(0), yy), text(size: 7pt, fill: if on { p.accent } else { p.muted },
      weight: if on { "bold" } else { "regular" })[expert #(i + 1)])
    // routing arrow: bold garnet to selected, faint dashed to idle
    if on {
      arr(router-east, (a.anchor)("west"), color: p.accent, w: 1.4pt)
    } else {
      arr(router-east, (a.anchor)("west"), color: p.faint, w: 0.7pt, dash: "dotted")
    }
  }
  // label for the expert bank, placed below the lowest expert
  draw.content((ex.at(0), y0 - (N - 1) * gap - 0.95), text(size: 7.5pt, fill: p.muted)[$N$ = #N expert FFNs])

  // weighted combine node (only selected outputs, scaled by router weights)
  let cmb = (rx + 6.7, 0)
  draw.circle(cmb, radius: 0.32, fill: white, stroke: 1.2pt + p.accent)
  draw.content(cmb, text(size: 10pt, fill: p.accent)[$+$])
  draw.content((cmb.at(0), cmb.at(1) - 0.62), text(size: 6.5pt, fill: p.muted)[weighted\ sum])
  // arrows from selected experts to the combine node
  for i in selected {
    let yy = y0 - i * gap
    let a = A((ex.at(0), yy), ew, eh, edep)
    arr((a.anchor)("east"), (cmb.at(0) - 0.34, cmb.at(1) + (yy - cmb.at(1)) * 0.18), color: p.accent, w: 1.2pt)
  }

  // output slab
  let mout = (rx + 8.1, 0)
  tensor3d(draw, origin: mout, w: 0.85, h: 2.6, dep: 0.5, base: p.tok, edge: p.edge, cam: cam,
    title: [output], x-label: [d])
  let mouta = A(mout, 0.85, 2.6, 0.5)
  arr((cmb.at(0) + 0.34, cmb.at(1)), (mouta.anchor)("west"), color: p.accent)

  // ============================================================ footnote
  draw.content((rx + 4.0, -4.9), anchor: "north",
    text(size: 7.5pt, fill: p.muted)[#box(width: 9cm)[All $N$ experts share the parameter budget, but only $k$ run per token —
      so MoE adds capacity at near-constant compute. The router (a learned softmax gate) chooses which.]])
})
