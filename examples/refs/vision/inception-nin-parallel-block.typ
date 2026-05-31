// Inception / NiN parallel-branch conv block — rebuilt in mlatlas style (from
// architectural knowledge, Szegedy et al. 2015 "GoogLeNet"; Lin et al. 2014 NiN).
// Hallmark: instead of choosing ONE kernel size, run several differently-sized
// convolutions (1x1, 3x3, 5x5) AND a pooling path IN PARALLEL on the same input,
// then CONCATENATE their output feature maps along the channel axis. The 1x1
// "network-in-network" convs (garnet) act as cheap channel-reducing bottlenecks
// before the expensive 3x3 / 5x5 convs, and after the pool path.
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
#let c-conv = rgb("#FFF2E3") // beige — spatial conv feature maps (3x3 / 5x5)
#let c-conv-edge = rgb("#243038")
#let c-1x1 = rgb("#F2DADC") // pale garnet tint — the 1x1 NiN bottlenecks
#let c-pool = rgb("#E3ECF2") // pale blue — the pooling path
#let c-out = rgb("#ECECEC")

#let CAM = cam-cabinet // upright front face, depth shears up-right — best for slab rows

// feature-map size mapping (matches the engine so slabs == anchors exactly) -----
#let fm-h(sp) = calc.max(0.8, calc.min(3.0, 0.7 + sp * 0.012))
#let fm-dep(ch) = calc.max(0.4, calc.min(2.6, 0.3 + calc.log(calc.max(ch, 1), base: 2) * 0.20))
#let fm-anchors(x, y, sp, ch) = block3d-anchors(
  origin: (x, y), w: 0.34, h: fm-h(sp), dep: fm-dep(ch), cam: CAM,
)
#let fm(x, y, sp, ch, base, edge, relu: false) = feature-map(
  cetz.draw, (x, y), spatial: sp, channels: ch,
  base: base, edge: edge, cam: CAM, relu: relu,
  h-fn: fm-h, dep-fn: fm-dep,
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- geometry -------------------------------------------------------------
  let spatial = 28 // spatial size is preserved across the block (same-padding)
  let c-in = 256 // input channels

  // column x-positions
  let x-in = 0.0
  let x-b1 = 3.0 // 1x1 bottleneck column (arms 1,2,3) / pool column (arm 4)
  let x-b2 = 6.0 // spatial conv column (3x3 / 5x5) / 1x1 column (pool path)
  let x-cat = 9.4 // channel-concat node
  let x-out = 12.0 // concatenated output slab

  // arm y-centers (top -> bottom)
  let ys = (5.1, 2.4, -0.3, -3.0)
  let y-mid = (ys.at(0) + ys.at(3)) / 2 // vertical centre of the block

  // per-arm channel budgets (illustrative GoogLeNet "inception (3a)"-style numbers)
  // arm 0: 1x1 conv                        -> 64 ch
  // arm 1: 1x1 reduce (96) -> 3x3 conv     -> 128 ch
  // arm 2: 1x1 reduce (16) -> 5x5 conv     -> 32 ch
  // arm 3: 3x3 maxpool -> 1x1 proj         -> 32 ch
  let out-ch = (64, 128, 32, 32)
  let cat-ch = out-ch.fold(0, (s, c) => s + c) // = 256

  // ---- (1) EDGES (draw FIRST, behind the slabs) -----------------------------
  let edge(pa, pb, col: ink, th: 1.0pt) = draw.line(
    pa, pb,
    stroke: (paint: col, thickness: th),
    mark: (end: "stealth", fill: col, scale: 0.62),
  )

  // anchors for the input slab + concat node + output
  let A-in = fm-anchors(x-in, y-mid, spatial, c-in)
  let A-out = fm-anchors(x-out, y-mid, spatial, cat-ch)

  // arm node anchors: first stage at x-b1, second stage at x-b2
  let A-s1 = ()
  let A-s2 = ()
  // arm 0: single 1x1 at x-b1, no second stage
  A-s1.push(fm-anchors(x-b1, ys.at(0), spatial, out-ch.at(0)))
  A-s2.push(none)
  // arm 1: 1x1 reduce (96) -> 3x3 (128)
  A-s1.push(fm-anchors(x-b1, ys.at(1), spatial, 96))
  A-s2.push(fm-anchors(x-b2, ys.at(1), spatial, out-ch.at(1)))
  // arm 2: 1x1 reduce (16) -> 5x5 (32)
  A-s1.push(fm-anchors(x-b1, ys.at(2), spatial, 16))
  A-s2.push(fm-anchors(x-b2, ys.at(2), spatial, out-ch.at(2)))
  // arm 3: 3x3 pool -> 1x1 proj (32)
  A-s1.push(fm-anchors(x-b1, ys.at(3), spatial, c-in))
  A-s2.push(fm-anchors(x-b2, ys.at(3), spatial, out-ch.at(3)))

  // fan-out: input -> each arm's first stage
  let from-in = (A-in.anchor)("east")
  for a in A-s1 {
    edge((from-in.at(0) + 0.02, from-in.at(1)), (a.anchor)("west"), col: muted, th: 0.9pt)
  }
  // within-arm: stage1 -> stage2
  for i in range(4) {
    if A-s2.at(i) != none {
      edge(((A-s1.at(i)).anchor)("east"), ((A-s2.at(i)).anchor)("west"))
    }
  }
  // fan-in: each arm's LAST stage -> concat node
  for i in range(4) {
    let last = if A-s2.at(i) == none { A-s1.at(i) } else { A-s2.at(i) }
    edge((last.anchor)("east"), (x-cat - 0.58, y-mid), col: muted, th: 0.9pt)
  }
  // concat -> output
  edge((x-cat + 0.58, y-mid), (A-out.anchor)("west"), th: 1.1pt)

  // ---- (2) THE SLABS --------------------------------------------------------
  // input
  fm(x-in, y-mid, spatial, c-in, c-input, c-input-edge)
  // arm 0: 1x1 conv
  fm(x-b1, ys.at(0), spatial, out-ch.at(0), c-1x1, c-garnet, relu: true)
  // arm 1: 1x1 reduce -> 3x3
  fm(x-b1, ys.at(1), spatial, 96, c-1x1, c-garnet, relu: true)
  fm(x-b2, ys.at(1), spatial, out-ch.at(1), c-conv, c-conv-edge, relu: true)
  // arm 2: 1x1 reduce -> 5x5
  fm(x-b1, ys.at(2), spatial, 16, c-1x1, c-garnet, relu: true)
  fm(x-b2, ys.at(2), spatial, out-ch.at(2), c-conv, c-conv-edge, relu: true)
  // arm 3: 3x3 maxpool -> 1x1 proj
  fm(x-b1, ys.at(3), spatial, c-in, c-pool, c-blue)
  fm(x-b2, ys.at(3), spatial, out-ch.at(3), c-1x1, c-garnet, relu: true)
  // output (concatenated)
  fm(x-out, y-mid, spatial, cat-ch, c-out, c-input-edge)

  // ---- (3) CONCAT NODE (sharp square, channel-axis concatenation) -----------
  let cnx = 0.58
  let cny = 0.40
  draw.rect(
    (x-cat - cnx, y-mid - cny), (x-cat + cnx, y-mid + cny),
    stroke: (paint: c-garnet, thickness: 1.1pt), fill: white, radius: 0pt,
  )
  draw.content((x-cat, y-mid), text(size: 8.5pt, weight: "bold", fill: c-garnet)[concat])
  draw.content(
    (x-cat, y-mid - cny - 0.26),
    text(size: 6.5pt, fill: muted)[along channel axis],
  )

  // ---- (4) LABELS -----------------------------------------------------------
  let label-above(a, top, bot) = {
    let p = (a.anchor)("top-screen")
    draw.content((p.at(0), p.at(1) + 0.62), text(size: 7.5pt, weight: "bold", fill: ink)[#top])
    if bot != none {
      draw.content((p.at(0), p.at(1) + 0.30), text(size: 6.5pt, fill: muted)[#bot])
    }
  }
  let label-below(a, top, bot) = {
    let p = (a.anchor)("bottom-screen")
    draw.content((p.at(0), p.at(1) - 0.30), text(size: 7.5pt, weight: "bold", fill: ink)[#top])
    if bot != none {
      draw.content((p.at(0), p.at(1) - 0.62), text(size: 6.5pt, fill: muted)[#bot])
    }
  }

  // input / output labels (below their slabs)
  label-below(A-in, [Input], [#c-in ch])
  label-below(A-out, [Output], [concat = #cat-ch ch])

  // arm operation labels — place above the slab for each stage
  // arm 0 (top)
  label-above(A-s1.at(0), [1#sym.times#h(0.04em)1 conv], [#out-ch.at(0) ch])
  // arm 1
  label-above(A-s1.at(1), [1#sym.times#h(0.04em)1 reduce], [96 ch])
  label-above(A-s2.at(1), [3#sym.times#h(0.04em)3 conv], [#out-ch.at(1) ch])
  // arm 2
  label-above(A-s1.at(2), [1#sym.times#h(0.04em)1 reduce], [16 ch])
  label-above(A-s2.at(2), [5#sym.times#h(0.04em)5 conv], [#out-ch.at(2) ch])
  // arm 3 (bottom) — pool path labelled below to avoid the arm above
  label-above(A-s1.at(3), [3#sym.times#h(0.04em)3 maxpool], none)
  label-above(A-s2.at(3), [1#sym.times#h(0.04em)1 proj], [#out-ch.at(3) ch])

  // ---- (5) ARM BRACKETS / NAMES ---------------------------------------------
  // a faint label at the far-left of each arm naming the branch
  let arm-name = (
    [Branch 1],
    [Branch 2],
    [Branch 3],
    [Branch 4],
  )
  for i in range(4) {
    draw.content(
      (x-in - 2.05, ys.at(i)),
      anchor: "west",
      text(size: 7.5pt, fill: muted)[#arm-name.at(i)],
    )
  }

  // ---- (6) TITLE ------------------------------------------------------------
  let topy = (A-s1.at(0).anchor)("top-screen").at(1) + 1.35
  let title-x = 5.0
  draw.content(
    (title-x, topy + 0.55),
    text(size: 13pt, weight: "bold", fill: ink)[Inception block — parallel multi-scale convolutions],
  )
  draw.content(
    (title-x, topy + 0.12),
    text(size: 8.5pt, fill: muted)[four arms (1#sym.times#h(0.04em)1, 3#sym.times#h(0.04em)3, 5#sym.times#h(0.04em)5, pool) run in parallel, then concatenate along channels],
  )

  // ---- (7) LEGEND -----------------------------------------------------------
  let lx = x-out - 0.4
  let ly = ys.at(3) - 1.7
  let sw = 0.46
  let swatch(yy, col, ed, lab) = {
    draw.rect((lx, yy - 0.16), (lx + sw, yy + 0.16), fill: col, stroke: (paint: ed, thickness: 0.8pt), radius: 0pt)
    draw.content((lx + sw + 0.16, yy), anchor: "west", text(size: 7pt, fill: ink)[#lab])
  }
  swatch(ly + 0.9, c-1x1, c-garnet, [1#sym.times#h(0.04em)1 conv (NiN bottleneck)])
  swatch(ly + 0.45, c-conv, c-conv-edge, [spatial conv (3#sym.times#h(0.04em)3 / 5#sym.times#h(0.04em)5)])
  swatch(ly, c-pool, c-blue, [3#sym.times#h(0.04em)3 max-pool path])
})
