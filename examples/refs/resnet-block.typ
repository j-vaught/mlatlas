// ResNet residual block — rebuilt in mlatlas style (from architectural knowledge).
// Hallmark of ResNet (He et al., 2016): instead of learning H(x) directly, a block
// learns the RESIDUAL F(x) = H(x) - x through two stacked 3x3 conv layers, then adds
// back the untouched input via an IDENTITY skip: y = ReLU( F(x) + x ).  The skip
// carries x around both convs straight into the elementwise sum ⊕.  Each conv is
// followed by BatchNorm; ReLU sits after the first conv and again after the ⊕.
// Reference (d2l residual block) used only to confirm the layer order / 3x3 kernels.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let c-input = rgb("#ECECEC") // 10% black — the block input x
#let c-input-edge = rgb("#5C5C5C")
#let c-conv = rgb("#FFF2E3") // beige — conv feature maps F(x)
#let c-conv-edge = rgb("#243038")

#let CAM = cam-cabinet // upright front face, depth shears up-right — best for slab rows

// inside a residual block spatial size & channel count stay constant (stride 1)
#let spatial = 28
#let channels = 64

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let y = 0.0
  let dx = 2.6 // column spacing
  // columns: 0 input x, 1 conv1 (3x3+BN+ReLU), 2 conv2 (3x3+BN), 3 the ⊕ sum, 4 output
  let x-in = 0.0
  let x-c1 = dx
  let x-c2 = 2 * dx
  let x-add = 3 * dx
  let x-out = 3 * dx + 1.9

  // ---- feature-map geometry (match feature-map() engine mapping) -------------
  let fm-h(sp) = calc.max(0.8, calc.min(3.4, 0.7 + sp * 0.009))
  let fm-dep(ch) = calc.max(0.4, calc.min(2.4, 0.3 + calc.log(calc.max(ch, 1), base: 2) * 0.19))
  let fm-anchors(x, sp, ch) = block3d-anchors(
    origin: (x, y), w: 0.34, h: fm-h(sp), dep: fm-dep(ch), cam: CAM,
  )

  let A-in = fm-anchors(x-in, spatial, channels)
  let A-c1 = fm-anchors(x-c1, spatial, channels)
  let A-c2 = fm-anchors(x-c2, spatial, channels)

  let east(a) = (a.anchor)("east")
  let west(a) = (a.anchor)("west")
  let top-of(a) = (a.anchor)("top-screen")
  let bottom-of(a) = (a.anchor)("bottom-screen")

  // the ⊕ node centre, vertically aligned with the slab row centre
  let add-c = (x-add, y)
  let add-r = 0.34

  // ---- (1) IDENTITY SKIP (draw FIRST, behind everything) ---------------------
  // x routed from the block input, arcing over the top of both convs, down into ⊕.
  // This is the defining ResNet edge — garnet accent.
  {
    let pa = top-of(A-in)
    let pb = (add-c.at(0), add-c.at(1) + add-r) // top of the ⊕ circle
    let lift = top-of(A-c1).at(1) + 1.05 // clear the tallest slab + ReLU labels
    draw.line(
      (pa.at(0), pa.at(1) + 0.05),
      (pa.at(0), lift),
      (pb.at(0), lift),
      (pb.at(0), pb.at(1) + 0.02),
      stroke: (paint: c-garnet, thickness: 1.05pt),
      mark: (end: "stealth", fill: c-garnet, scale: 0.72),
    )
    // label on the skip
    draw.content(
      ((pa.at(0) + pb.at(0)) / 2, lift + 0.30),
      text(size: 8.5pt, fill: c-garnet, weight: "bold")[identity skip $bold(x)$],
    )
  }

  // ---- (2) FORWARD MAIN-PATH ARROWS (the residual function F(x)) -------------
  let fwd(pa, pb) = draw.line(
    pa, pb,
    stroke: (paint: ink, thickness: 0.95pt),
    mark: (end: "stealth", fill: ink, scale: 0.7),
  )
  fwd(east(A-in), west(A-c1))
  fwd(east(A-c1), west(A-c2))
  // conv2 -> ⊕ (stop at the left rim of the circle)
  fwd(east(A-c2), (add-c.at(0) - add-r, add-c.at(1)))
  // ⊕ -> output (start at the right rim)
  fwd((add-c.at(0) + add-r, add-c.at(1)), (x-out - 0.05, add-c.at(1)))

  // ---- (3) THE SLABS ---------------------------------------------------------
  // block input x (untouched)
  feature-map(
    draw, (x-in, y), spatial: spatial, channels: channels,
    base: c-input, edge: c-input-edge, cam: CAM,
  )
  // conv1: 3x3 conv + BN + ReLU  (ReLU shown as the trailing band)
  feature-map(
    draw, (x-c1, y), spatial: spatial, channels: channels,
    base: c-conv, edge: c-conv-edge, cam: CAM, relu: true,
  )
  // conv2: 3x3 conv + BN  (NO ReLU here — ReLU comes AFTER the ⊕)
  feature-map(
    draw, (x-c2, y), spatial: spatial, channels: channels,
    base: c-conv, edge: c-conv-edge, cam: CAM,
  )

  // ---- (4) THE ⊕ SUM NODE ----------------------------------------------------
  draw.circle(add-c, radius: add-r, fill: white, stroke: (paint: c-garnet, thickness: 1.15pt))
  draw.line(
    (add-c.at(0) - add-r * 0.62, add-c.at(1)), (add-c.at(0) + add-r * 0.62, add-c.at(1)),
    stroke: (paint: c-garnet, thickness: 1.15pt),
  )
  draw.line(
    (add-c.at(0), add-c.at(1) - add-r * 0.62), (add-c.at(0), add-c.at(1) + add-r * 0.62),
    stroke: (paint: c-garnet, thickness: 1.15pt),
  )

  // ---- (5) LABELS ------------------------------------------------------------
  let label(a, top, bot) = {
    let p = bottom-of(a)
    draw.content((p.at(0), p.at(1) - 0.32), text(size: 8.5pt, weight: "bold", fill: ink)[#top])
    if bot != none {
      draw.content((p.at(0), p.at(1) - 0.70), text(size: 7.5pt, fill: muted)[#bot])
    }
  }
  label(A-in, [Input $bold(x)$], [#channels ch])
  label(A-c1, [3#sym.times#h(0.03em)3 conv], [BatchNorm + ReLU])
  label(A-c2, [3#sym.times#h(0.03em)3 conv], [BatchNorm])

  // ⊕ label + the residual equation underneath
  draw.content(
    (add-c.at(0), bottom-of(A-c2).at(1) - 0.32),
    text(size: 8.5pt, weight: "bold", fill: c-garnet)[$+$ add],
  )
  draw.content(
    (add-c.at(0), bottom-of(A-c2).at(1) - 0.70),
    text(size: 7.5pt, fill: muted)[then ReLU],
  )

  // output label
  draw.content(
    (x-out + 0.08, add-c.at(1)), anchor: "west",
    text(size: 8.5pt, weight: "bold", fill: ink)[$bold(y) = "ReLU"(cal(F)(bold(x)) + bold(x))$],
  )

  // ---- (6) TITLE (centred over the full input -> output span) ----------------
  let cx = (x-in + x-out) / 2
  let topy = top-of(A-in).at(1) + 1.05 + 0.75
  draw.content(
    (cx, topy + 0.5),
    text(size: 12pt, weight: "bold", fill: ink)[ResNet — residual block],
  )
  draw.content(
    (cx, topy + 0.08),
    text(size: 8.5pt, fill: muted)[two 3#sym.times#h(0.03em)3 convs learn $cal(F)(bold(x))$; an identity skip adds $bold(x)$ back],
  )
})
