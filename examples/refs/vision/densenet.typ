// DenseNet dense block — rebuilt in mlatlas style (from architectural knowledge).
// Hallmark of DenseNet (Huang et al., 2017): inside a dense block every conv layer
// receives the CONCATENATION of all preceding feature maps. So layer ℓ takes the
// outputs of layers 0..ℓ-1 as input -> a dense web of skip connections, one from
// each earlier layer to every later layer. Each layer adds k ("growth rate") new
// channels, so the running concatenation grows linearly across the block.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let c-blue = rgb("#466A9F")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let c-input = rgb("#ECECEC") // 10% black — the block input
#let c-input-edge = rgb("#5C5C5C")
#let c-conv = rgb("#FFF2E3") // beige — conv feature maps
#let c-conv-edge = rgb("#243038")

#let CAM = cam-cabinet // upright front face, depth shears up-right — best for slab rows

// each layer adds k channels via concatenation; running depth grows.  spatial is
// constant inside a dense block (the transition layer downsamples — shown after).
#let k = 32 // growth rate
#let c0 = 64 // input channels into the block
#let spatial = 28 // constant feature-map size in the block

// layer i (0 = input) carries c0 + i*k channels (the concatenated stack)
#let chan(i) = c0 + i * k

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let y = 0.0
  let dx = 2.35 // column spacing
  let n-conv = 4 // conv layers inside the block

  // x-centers: column 0 is the block input, then n-conv conv layers, then transition
  let cols = range(n-conv + 2).map(i => i * dx)

  // ---- anchors for each feature-map slab (pure computation) ------------------
  // feature-map height/depth come from the engine's spatial/channels mapping so the
  // slabs match feature-map() exactly; we recompute via block3d-anchors.
  let fm-h(sp) = calc.max(0.8, calc.min(3.4, 0.7 + sp * 0.009))
  let fm-dep(ch) = calc.max(0.4, calc.min(2.4, 0.3 + calc.log(calc.max(ch, 1), base: 2) * 0.19))
  let fm-anchors(x, sp, ch) = block3d-anchors(
    origin: (x, y), w: 0.34, h: fm-h(sp), dep: fm-dep(ch), cam: CAM,
  )

  // input slab + conv slabs all live at spatial=28; depth grows with concat channels
  let A = ()
  // column 0: block input
  A.push(fm-anchors(cols.at(0), spatial, c0))
  // columns 1..n-conv: conv layers, each carrying the concatenated stack so far
  for i in range(1, n-conv + 1) {
    A.push(fm-anchors(cols.at(i), spatial, chan(i)))
  }
  // last column: transition (1x1 conv + pool) — halves spatial & channels
  A.push(fm-anchors(cols.at(n-conv + 1), spatial / 2, calc.floor(chan(n-conv) / 2)))

  // ---- (1) DENSE SKIP ARROWS (draw FIRST, behind the slabs) ------------------
  // from every layer's OUTPUT (front-top of its slab) into every LATER layer's
  // input, arcing over the top of the row.  Direct neighbour i->i+1 is the plain
  // forward path (drawn dark); longer skips (i->j, j>i+1) are the garnet dense
  // connections that define DenseNet.
  // skips LEAVE from the top of the source slab and ENTER at the front-top of the
  // target slab (so the arrowhead clearly points INTO the receiving layer).
  let out-of(a) = (a.anchor)("top-screen")
  let into(a) = (a.anchor)("front-top")
  for i in range(0, n-conv) {
    for j in range(i + 1, n-conv + 1) {
      let pa = out-of(A.at(i))
      let pb = into(A.at(j))
      let span = j - i
      // arc height grows with how far the skip reaches, so long skips clear short ones
      let lift = 0.6 + 0.5 * span
      let mx = (pa.at(0) + pb.at(0)) / 2
      let ctrl = (mx, calc.max(pa.at(1), pb.at(1)) + lift)
      if span == 1 {
        // plain forward concat edge — dark, modest arc
        draw.line(
          (pa.at(0), pa.at(1) + 0.06),
          ctrl,
          (pb.at(0) - 0.04, pb.at(1) + 0.08),
          stroke: (paint: ink, thickness: 0.9pt),
          mark: (end: "stealth", fill: ink, scale: 0.7),
        )
      } else {
        // dense skip — garnet accent, taller arc
        draw.line(
          (pa.at(0), pa.at(1) + 0.06),
          ctrl,
          (pb.at(0) - 0.04, pb.at(1) + 0.08),
          stroke: (paint: c-garnet, thickness: 0.85pt),
          mark: (end: "stealth", fill: c-garnet, scale: 0.66),
        )
      }
    }
  }

  // forward edge from last conv layer into the transition block
  {
    let pa = (A.at(n-conv).anchor)("east")
    let pb = (A.at(n-conv + 1).anchor)("west")
    draw.line(
      pa, pb,
      stroke: (paint: ink, thickness: 0.9pt),
      mark: (end: "stealth", fill: ink, scale: 0.7),
    )
  }

  // ---- (2) THE SLABS ---------------------------------------------------------
  // block input
  feature-map(
    draw, (cols.at(0), y), spatial: spatial, channels: c0,
    base: c-input, edge: c-input-edge, cam: CAM,
  )
  // conv layers — beige, ReLU band; depth grows with the concatenated channel count
  for i in range(1, n-conv + 1) {
    feature-map(
      draw, (cols.at(i), y), spatial: spatial, channels: chan(i),
      base: c-conv, edge: c-conv-edge, cam: CAM, relu: true,
    )
  }
  // transition layer (1x1 conv + 2x2 avg-pool) — slightly tinted, narrower
  feature-map(
    draw, (cols.at(n-conv + 1), y), spatial: spatial / 2, channels: calc.floor(chan(n-conv) / 2),
    base: rgb("#E3ECF2"), edge: c-blue, cam: CAM,
  )

  // ---- (3) LABELS ------------------------------------------------------------
  let bottom-of(a) = (a.anchor)("bottom-screen")
  let label(a, top, bot) = {
    let p = bottom-of(a)
    draw.content((p.at(0), p.at(1) - 0.30), text(size: 8.5pt, weight: "bold", fill: ink)[#top])
    if bot != none {
      draw.content((p.at(0), p.at(1) - 0.66), text(size: 7.5pt, fill: muted)[#bot])
    }
  }
  label(A.at(0), [Input], [#c0 ch])
  for i in range(1, n-conv + 1) {
    label(A.at(i), [Conv #i], [#chan(i) ch])
  }
  label(A.at(n-conv + 1), [Transition], [1#sym.times#h(0.05em)1 conv + pool])

  // channel-count axis under the conv layers (concatenation grows)
  let lx = bottom-of(A.at(0))
  let rx = bottom-of(A.at(n-conv))
  let basey = calc.min(lx.at(1), rx.at(1)) - 1.15
  draw.content(
    ((lx.at(0) + rx.at(0)) / 2, basey),
    text(size: 8pt, fill: c-garnet)[concatenated channels grow #sym.plus#h(0.05em)k each layer
      (k #sym.eq #k)],
  )

  // ---- (4) TITLE -------------------------------------------------------------
  let cx = (cols.at(0) + cols.at(n-conv)) / 2
  // sit the title above the tallest arc (longest skip, span = n-conv)
  let max-lift = 0.6 + 0.5 * n-conv
  let topy = out-of(A.at(0)).at(1) + max-lift + 0.4
  draw.content(
    (cx, topy + 0.5),
    text(size: 12pt, weight: "bold", fill: ink)[DenseNet — dense block],
  )
  draw.content(
    (cx, topy + 0.08),
    text(size: 8.5pt, fill: muted)[each layer receives the concatenation of all earlier feature maps],
  )

  // legend for the two edge kinds
  let leg-x = cols.at(n-conv + 1) + 0.6
  let leg-y = out-of(A.at(0)).at(1) + 0.3
  draw.line(
    (leg-x, leg-y), (leg-x + 0.6, leg-y),
    stroke: (paint: ink, thickness: 0.9pt), mark: (end: "stealth", fill: ink, scale: 0.6),
  )
  draw.content((leg-x + 0.72, leg-y), anchor: "west", text(size: 7.5pt, fill: ink)[forward])
  draw.line(
    (leg-x, leg-y - 0.42), (leg-x + 0.6, leg-y - 0.42),
    stroke: (paint: c-garnet, thickness: 0.85pt), mark: (end: "stealth", fill: c-garnet, scale: 0.6),
  )
  draw.content((leg-x + 0.72, leg-y - 0.42), anchor: "west", text(size: 7.5pt, fill: c-garnet)[dense skip])
})
