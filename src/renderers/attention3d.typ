// mlatlas · renderers/attention3d.typ
// Scaled dot-product attention in 3-D: Q/K/V slabs -> a QKᵀ score CUBE (seq×seq×heads, depth =
// heads via seams, never chopped) -> softmax -> weighted sum with V -> output. The multi-head
// cube is the highlight. Print-first, sharp, stealth arrows.
#import "@preview/cetz:0.5.2"
#import "../prim/tensor3d.typ": tensor3d
#import "../adapters/3d.typ": block3d, block3d-anchors, project, cam-cabinet, cam-iso

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

// a single embedding/token tensor (seq × d) as a thin labeled slab
#let embedding-tensor3d(draw, origin: (0, 0), seq: 8, d: 512, base: rgb("#CBE0F4"), cam: cam-cabinet, palette: attn3d-palette, title: [token\ embeddings]) = {
  tensor3d(draw, origin: origin, w: 1.1, h: 2.6, dep: 0.5, base: base, edge: palette.edge, cam: cam, title: title, y-label: [seq=#seq], x-label: [d=#d])
}

// depth-plate: a block standing in for an N×-repeated layer, with a bold "N×" multiplier and
// a faint ghost outline behind it to read as a stack. Returns nothing (draws).
#let depth-plate(draw, origin: (0, 0), w: 2.2, h: 2.8, dep: 1.9, n: 6, base: rgb("#E9EDF0"), palette: attn3d-palette, cam: cam-cabinet, label: none, sublabels: ()) = {
  // ghost copies behind (offset up-right) to suggest repetition
  for k in (2, 1) {
    let o = (origin.at(0) + 0.16 * k, origin.at(1) + 0.16 * k)
    block3d(draw, origin: o, w: w, h: h, dep: dep, base: base.lighten(6%), edge: palette.edge.lighten(35%), cam: cam)
  }
  block3d(draw, origin: origin, w: w, h: h, dep: dep, base: base, edge: palette.edge, cam: cam, seams: (0.5,))
  let A = block3d-anchors(origin: origin, w: w, h: h, dep: dep, cam: cam)
  draw.content(((A.anchor)("west").at(0) - 0.3, origin.at(1)), anchor: "east", text(size: 12pt, weight: "bold", fill: palette.accent)[#n#sym.times])
  if label != none { draw.content((origin.at(0), (A.anchor)("top-screen").at(1) + 0.34), text(size: 9pt, weight: "bold", fill: palette.text)[#label]) }
  // sublabels stacked on the front face
  let m = sublabels.len()
  for (i, s) in sublabels.enumerate() {
    let yy = origin.at(1) + (m - 1) / 2 * 0.62 - i * 0.62
    draw.content((origin.at(0), yy), text(size: 7.5pt, fill: palette.text)[#s])
  }
}

// a compact transformer stack: embeddings -> [block ×N] -> logits
#let transformer-3d(layers: 6, d-model: 512, seq: 8, vocab: "50k", palette: attn3d-palette, cam: cam-cabinet) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let p = palette
  let arr(a, b) = draw.line(a, b, stroke: 1.4pt + p.edge, mark: (end: "stealth", scale: 0.75))
  embedding-tensor3d(draw, origin: (0, 0), seq: seq, d: d-model, base: p.q, cam: cam, palette: p)
  let ea = block3d-anchors(origin: (0, 0), w: 1.1, h: 2.6, dep: 0.5, cam: cam)
  depth-plate(draw, origin: (4.4, 0), n: layers, base: rgb("#F3E6CF"), palette: p, cam: cam, label: [transformer block], sublabels: ([Masked MHA], [LayerNorm], [Feed-forward]))
  let ba = block3d-anchors(origin: (4.4, 0), w: 2.2, h: 2.8, dep: 1.9, cam: cam)
  tensor3d(draw, origin: (8.8, 0), w: 1.1, h: 2.6, dep: 0.5, base: p.out, edge: p.edge, cam: cam, title: [logits], x-label: [vocab=#vocab])
  let oa = block3d-anchors(origin: (8.8, 0), w: 1.1, h: 2.6, dep: 0.5, cam: cam)
  arr((ea.anchor)("east"), (ba.anchor)("west"))
  arr((ba.anchor)("east"), (oa.anchor)("west"))
})
