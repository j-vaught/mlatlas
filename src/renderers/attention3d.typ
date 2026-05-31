// mlatlas · renderers/attention3d.typ
// Scaled dot-product attention in 3-D: Q/K/V slabs -> a QKᵀ score CUBE (seq×seq×heads, depth =
// heads via seams, never chopped) -> softmax -> weighted sum with V -> output. The multi-head
// cube is the highlight. Print-first, sharp, stealth arrows.
#import "@preview/cetz:0.5.2"
#import "../prim/tensor3d.typ": tensor3d
#import "../adapters/3d.typ": block3d-anchors, cam-cabinet

#let attn3d-palette = (
  q: rgb("#CBE0F4"), k: rgb("#F2E4C4"), v: rgb("#D8E8C8"),
  score: rgb("#F2A6C9"), soft: rgb("#E2C4F0"), out: rgb("#ECECEC"),
  edge: rgb("#243038"), text: rgb("#222222"), muted: rgb("#5C5C5C"), accent: rgb("#73000A"),
)

#let attention-3d(seq: 6, d-k: 64, heads: 4, palette: attn3d-palette, cam: cam-cabinet) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let p = palette
  let sh = 2.0 // seq -> height
  let dw = 0.95 // d_k -> slab width
  let cs = 2.0 // score cube side (seq×seq)
  let hd = calc.max(0.8, calc.min(2.2, 0.45 + heads * 0.3)) // heads -> depth
  let seams-h = if heads > 1 { range(1, heads).map(k => k / heads) } else { () }

  // positions (centers)
  let qo = (0, 1.6)
  let ko = (0, -1.6)
  let vo = (3.9, -3.7)
  let so = (3.9, 0.2)
  let xo = (7.5, 0.2)
  let oo = (11.0, 0.0)

  let A(o, w, h, dep) = block3d-anchors(origin: o, w: w, h: h, dep: dep, cam: cam)
  let arr(a, b, color: p.edge, w: 1.4pt) = draw.line(a, b, stroke: w + color, mark: (end: "stealth", scale: 0.75))

  // Q, K, V slabs
  tensor3d(draw, origin: qo, w: dw, h: sh, dep: 0.42, base: p.q, edge: p.edge, cam: cam, title: [Q], y-label: [seq], x-label: [#d-k])
  tensor3d(draw, origin: ko, w: dw, h: sh, dep: 0.42, base: p.k, edge: p.edge, cam: cam, title: [K], y-label: [seq], x-label: [#d-k])
  tensor3d(draw, origin: vo, w: dw, h: sh, dep: 0.42, base: p.v, edge: p.edge, cam: cam, title: [V], x-label: [#d-k])

  // QKᵀ score cube (seq×seq×heads), then softmax cube
  tensor3d(draw, origin: so, w: cs, h: cs, dep: hd, base: p.score, edge: p.edge, cam: cam, seams: seams-h, title: [QKᵀ / √d], y-label: [seq], x-label: [seq], z-label: [#heads heads])
  tensor3d(draw, origin: xo, w: cs, h: cs, dep: hd, base: p.soft, edge: p.edge, cam: cam, seams: seams-h, title: [softmax])
  // output
  tensor3d(draw, origin: oo, w: dw, h: sh, dep: 0.42, base: p.out, edge: p.edge, cam: cam, title: [output], x-label: [#d-k])

  // wiring
  let qa = A(qo, dw, sh, 0.42)
  let ka = A(ko, dw, sh, 0.42)
  let sa = A(so, cs, cs, hd)
  let xa = A(xo, cs, cs, hd)
  let va = A(vo, dw, sh, 0.42)
  let oa = A(oo, dw, sh, 0.42)
  arr((qa.anchor)("east"), ((sa.anchor)("west").at(0), 0.7))
  arr((ka.anchor)("east"), ((sa.anchor)("west").at(0), -0.3))
  arr((sa.anchor)("east"), (xa.anchor)("west"))
  arr((xa.anchor)("east"), (oa.anchor)("west"))
  // V feeds the output (the · V matmul)
  arr((va.anchor)("east"), ((oa.anchor)("bottom-screen").at(0), (oa.anchor)("bottom-screen").at(1)), color: p.accent)
  draw.content(((xa.anchor)("east").at(0) + 1.0, -1.6), text(size: 7pt, fill: p.accent)[· V])
})

#let attention-3d-figure(..args) = attention-3d(..args)
