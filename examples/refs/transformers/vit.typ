// Vision Transformer (ViT) — rebuilt in mlatlas style from architectural knowledge.
// Image -> non-overlapping patches -> flatten + linear patch embedding -> prepend a [class]
// token, add learned position embeddings -> Transformer encoder (N×) -> MLP head -> class.
// Reference used only to confirm structure (D2L ViT). Not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let c-blue = rgb("#466A9F")
#let ink = rgb("#1A1A1A")
#let edge = rgb("#243038")
#let muted = rgb("#5C5C5C")
#let c-patch = rgb("#ECECEC") // image patch cells (neutral)
#let c-embed = rgb("#DCE6F2") // patch-embedding slabs (pale blue)
#let c-cls = rgb("#F4DBDB") // class token (pale garnet)
#let c-pos = rgb("#FFF2E3") // position embeddings (beige)
#let c-enc = rgb("#F3E6CF") // transformer encoder block (amber)
#let c-head = rgb("#D8E8C8") // MLP head (pale green)

#let CAM = cam-cabinet // upright front face, depth shears up-right — best for a row of slabs

// embedding slab geometry
#let SW = 0.5
#let SH = 2.0
#let SD = 0.4

#let slab-anchors(x, y) = block3d-anchors(origin: (x, y), w: SW, h: SH, dep: SD, cam: CAM)
#let arr(draw, a, b, color: edge, w: 1.2pt) = draw.line(
  a, b, stroke: w + color, mark: (end: "stealth", scale: 0.7),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ============================================================ (1) image patches
  // a 3×3 grid of image patches, drawn as thin flat tiles in the same oblique camera
  let grid-x0 = 0.0
  let grid-y0 = 5.6
  let cell = 0.62
  let CW = 0.58
  for r in range(3) {
    for c in range(3) {
      let cx = grid-x0 + c * cell
      let cy = grid-y0 - r * cell
      // alternate tint so the patch grid reads as distinct tiles
      let f = if calc.rem(r + c, 2) == 0 { c-patch } else { c-patch.darken(8%) }
      block3d(draw, origin: (cx, cy), w: CW, h: CW, dep: 0.16, base: f, edge: edge, cam: CAM)
    }
  }
  let grid-cx = grid-x0 + cell
  draw.content(
    (grid-cx, grid-y0 + 0.95),
    text(size: 9.5pt, weight: "bold", fill: ink)[Image patches],
  )
  draw.content(
    (grid-cx, grid-y0 - 2 * cell - 0.6),
    text(size: 7.5pt, fill: muted)[$16 times 16$ each],
  )

  // ============================================================ (2) linear patch embedding
  // each patch is flattened and linearly projected to a D-dim embedding vector (a thin slab)
  let proj-x = grid-cx + 1.7
  let proj-y = grid-y0 - cell
  block3d(draw, origin: (proj-x, proj-y), w: 1.0, h: 1.5, dep: 0.6, base: c-blue.lighten(60%), edge: c-blue, cam: CAM)
  let projA = block3d-anchors(origin: (proj-x, proj-y), w: 1.0, h: 1.5, dep: 0.6, cam: CAM)
  draw.content((proj-x, proj-y), text(size: 7.5pt, fill: c-blue, weight: "bold")[Linear\ proj.])
  draw.content(
    (proj-x, (projA.anchor)("top-screen").at(1) + 0.32),
    text(size: 8.5pt, weight: "bold", fill: ink)[Patch embedding],
  )
  // patch grid -> linear projection
  let gridA = block3d-anchors(origin: (grid-cx + cell, grid-y0 - cell), w: CW, h: CW, dep: 0.16, cam: CAM)
  arr(draw, ((gridA.anchor)("east").at(0) + 0.05, proj-y), (projA.anchor)("west"))

  // ============================================================ (3) embedding sequence (row of slabs)
  // [class] token prepended, then one embedding per patch; learned position embeddings added.
  let row-x0 = proj-x + 1.95
  let row-dx = 0.84
  let row-y = 1.7
  let n-patch = 6 // shown; "·· ·" implies the rest up to N=196
  let cols = range(n-patch + 1).map(i => row-x0 + i * row-dx)

  // position-embedding strip beneath the row (a long flat beige slab) + "+" markers
  let pos-w = (cols.last() - cols.first()) + SW + 0.4
  let pos-cx = (cols.first() + cols.last()) / 2
  let pos-y = row-y - 1.6
  block3d(draw, origin: (pos-cx, pos-y), w: pos-w, h: 0.42, dep: 0.32, base: c-pos, edge: edge, cam: CAM)
  let posA = block3d-anchors(origin: (pos-cx, pos-y), w: pos-w, h: 0.42, dep: 0.32, cam: CAM)
  draw.content(
    ((posA.anchor)("west").at(0) - 0.2, pos-y),
    anchor: "east",
    text(size: 8pt, fill: muted)[Position\ embeddings],
  )

  // the slabs: index 0 is the class token (garnet), the rest are patch embeddings (blue)
  for (i, x) in cols.enumerate() {
    let is-cls = i == 0
    let fill = if is-cls { c-cls } else { c-embed }
    let ed = if is-cls { c-garnet } else { c-blue }
    block3d(draw, origin: (x, row-y), w: SW, h: SH, dep: SD, base: fill, edge: ed, cam: CAM)
    let A = slab-anchors(x, row-y)
    // glyph on the front face
    let fc = (A.anchor)("front")
    let glyph = if is-cls { text(size: 9pt, weight: "bold", fill: c-garnet)[\*] } else {
      text(size: 7.5pt, fill: c-blue)[$bold(e)_#i$]
    }
    draw.content((fc.at(0), fc.at(1) + 0.55), glyph)
    // "+ position" dotted stem from the position strip up to each slab
    draw.line(
      ((A.anchor)("bottom").at(0), (posA.anchor)("top").at(1)),
      (A.anchor)("bottom"),
      stroke: (paint: muted, thickness: 0.6pt, dash: "dotted"),
    )
  }
  // class-token label
  let clsA = slab-anchors(cols.at(0), row-y)
  draw.content(
    (cols.at(0), (clsA.anchor)("top-screen").at(1) + 0.3),
    text(size: 7.5pt, weight: "bold", fill: c-garnet)[\[class\]],
  )
  // patch -> embedding row arrow (from projection block to the first patch slab)
  arr(draw, (projA.anchor)("east"), ((slab-anchors(cols.at(1), row-y).anchor)("west").at(0) - 0.05, row-y))
  // "··· (N patches)" hint after the visible slabs
  let lastA = slab-anchors(cols.last(), row-y)
  draw.content(
    ((lastA.anchor)("east").at(0) + 0.3, row-y + 0.2),
    anchor: "west",
    text(size: 9pt, fill: muted)[$dots.c$],
  )
  draw.content(
    (pos-cx, row-y + SH / 2 + 0.55),
    text(size: 8.5pt, weight: "bold", fill: ink)[Embedded patches $+$ \[class\] token],
  )

  // ============================================================ (4) transformer encoder (N×)
  // a depth-plate block standing in for the L× repeated encoder layer
  let enc-x = cols.last() + 2.5
  let enc-y = row-y
  let ew = 2.2
  let eh = 2.9
  let ed-dep = 1.7
  // ghost copies behind to suggest the L× stack
  for k in (2, 1) {
    let o = (enc-x + 0.16 * k, enc-y + 0.16 * k)
    block3d(draw, origin: o, w: ew, h: eh, dep: ed-dep, base: c-enc.lighten(6%), edge: edge.lighten(35%), cam: CAM)
  }
  block3d(draw, origin: (enc-x, enc-y), w: ew, h: eh, dep: ed-dep, base: c-enc, edge: edge, cam: CAM, seams: (0.5,))
  let encA = block3d-anchors(origin: (enc-x, enc-y), w: ew, h: eh, dep: ed-dep, cam: CAM)
  draw.content(
    (enc-x, (encA.anchor)("top-screen").at(1) + 0.34),
    text(size: 9pt, weight: "bold", fill: ink)[Transformer encoder],
  )
  draw.content(
    ((encA.anchor)("west").at(0) - 0.28, enc-y),
    anchor: "east",
    text(size: 13pt, weight: "bold", fill: c-garnet)[$L times$],
  )
  // sublabels on the front face — the encoder-layer internals
  let subs = ([LayerNorm], [Multi-head\ attention], [LayerNorm], [MLP],)
  for (i, s) in subs.enumerate() {
    let yy = enc-y + (subs.len() - 1) / 2 * 0.66 - i * 0.66
    draw.content((enc-x, yy), text(size: 7pt, fill: ink)[#s])
  }
  // embedding row -> encoder
  arr(draw, ((lastA.anchor)("east").at(0) + 0.55, enc-y), (encA.anchor)("west"))

  // ============================================================ (5) MLP head -> class
  let head-x = enc-x + 3.0
  let head-y = enc-y
  block3d(draw, origin: (head-x, head-y), w: 1.0, h: 1.9, dep: 0.6, base: c-head, edge: rgb("#65780B"), cam: CAM)
  let headA = block3d-anchors(origin: (head-x, head-y), w: 1.0, h: 1.9, dep: 0.6, cam: CAM)
  draw.content((head-x, head-y), text(size: 7.5pt, weight: "bold", fill: rgb("#3f4a07"))[MLP\ head])
  draw.content(
    (head-x, (headA.anchor)("top-screen").at(1) + 0.32),
    text(size: 8.5pt, weight: "bold", fill: ink)[Classification head],
  )
  // only the [class] token's output feeds the head — accent that path in garnet
  arr(draw, (encA.anchor)("east"), (headA.anchor)("west"), color: c-garnet)
  let mid-x = ((encA.anchor)("east").at(0) + (headA.anchor)("west").at(0)) / 2
  draw.content(
    (mid-x, head-y + 0.42),
    text(size: 6.5pt, fill: c-garnet)[\[class\] token],
  )
  // class probabilities out
  let outx = head-x + 1.6
  arr(draw, (headA.anchor)("east"), (outx, head-y))
  draw.content(
    (outx + 0.1, head-y),
    anchor: "west",
    text(size: 8.5pt, fill: ink)[Class$\ $\ probabilities],
  )
})
