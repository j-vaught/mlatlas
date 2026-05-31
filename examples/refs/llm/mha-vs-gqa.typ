// Multi-head attention vs grouped-query attention — rebuilt in mlatlas style.
// MHA: every query head owns a private K,V pair.  GQA: query heads in a group SHARE one K,V.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let c-blue = rgb("#466A9F")
#let c-q-fill = rgb("#DCE6F2") // pale blue  -> queries
#let c-q-edge = rgb("#466A9F")
#let c-k-fill = rgb("#F4DBDB") // pale garnet -> keys
#let c-k-edge = rgb("#73000A")
#let c-v-fill = rgb("#FBE8D4") // pale amber  -> values
#let c-v-edge = rgb("#A4762A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")

#let CAM = cam-cabinet // upright front face, depth shears up-right — best for slab rows
#let SW = 0.92 // slab width
#let SH = 1.34 // slab height
#let SD = 0.66 // slab depth

// pure anchor handle (no drawing) for a slab at (x,y)
#let slab-anchors(x, y) = block3d-anchors(origin: (x, y), w: SW, h: SH, dep: SD, cam: CAM)

// draw one labeled slab (drawing only — anchors come from slab-anchors)
#let slab-at(draw, x, y, fill, edge, glyph) = {
  block3d(draw, origin: (x, y), w: SW, h: SH, dep: SD, base: fill, edge: edge, cam: CAM)
  let fc = (slab-anchors(x, y).anchor)("front")
  draw.content((fc.at(0), fc.at(1)), text(size: 13pt, weight: "bold", fill: edge)[#glyph])
}

#let stem = (draw, a, b) => draw.line(a, b, stroke: 1.0pt + ink)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // row y-centers
  let yV = 5.4
  let yK = 2.9
  let yQ = 0.4

  // === MHA (left panel) =======================================================
  let mha-x0 = 0.0
  let mha-dx = 1.55
  let mha-cols = range(4).map(i => mha-x0 + i * mha-dx)

  // anchors (pure computation)
  let Vs = mha-cols.map(x => slab-anchors(x, yV))
  let Ks = mha-cols.map(x => slab-anchors(x, yK))
  let Qs = mha-cols.map(x => slab-anchors(x, yQ))
  // vertical stems V->K and K->Q (one private K,V per query head) — drawn under the slabs
  for i in range(4) {
    stem(draw, (Ks.at(i).anchor)("top"), (Vs.at(i).anchor)("bottom"))
    stem(draw, (Qs.at(i).anchor)("top"), (Ks.at(i).anchor)("bottom"))
  }
  // slabs
  for x in mha-cols {
    slab-at(draw, x, yV, c-v-fill, c-v-edge, [v])
    slab-at(draw, x, yK, c-k-fill, c-k-edge, [k])
    slab-at(draw, x, yQ, c-q-fill, c-q-edge, [q])
  }
  // head labels under queries
  for i in range(4) {
    let qb = (Qs.at(i).anchor)("bottom-screen")
    draw.content((qb.at(0), qb.at(1) - 0.34), text(size: 8pt, weight: "bold", fill: muted)[Head #(i + 1)])
  }

  // row labels (left of MHA panel)
  let lblx = mha-x0 - 1.55
  draw.content((lblx, yV), anchor: "west", text(size: 10pt, fill: ink)[Values])
  draw.content((lblx, yK), anchor: "west", text(size: 10pt, fill: ink)[Keys])
  draw.content((lblx, yQ), anchor: "west", text(size: 10pt, fill: ink)[Queries])

  // panel title
  let mha-cx = (mha-cols.first() + mha-cols.last()) / 2
  draw.content((mha-cx, yV + 1.5), text(size: 11pt, weight: "bold", fill: ink)[Multi-head attention])
  draw.content((mha-cx, yV + 1.05), text(size: 8.5pt, fill: muted)[1 K,V per query head])

  // === GQA (right panel) ======================================================
  let gqa-x0 = mha-cols.last() + 2.95
  let gqa-dx = 1.55
  let q-cols = range(4).map(i => gqa-x0 + i * gqa-dx)
  // two K,V groups, each centered over its pair of query heads
  let g-cols = (
    (q-cols.at(0) + q-cols.at(1)) / 2,
    (q-cols.at(2) + q-cols.at(3)) / 2,
  )

  let gVs = g-cols.map(x => slab-anchors(x, yV))
  let gKs = g-cols.map(x => slab-anchors(x, yK))
  let gQs = q-cols.map(x => slab-anchors(x, yQ))

  // V->K within each group, and each K branches to its two query heads — drawn under slabs
  for g in range(2) {
    stem(draw, (gKs.at(g).anchor)("top"), (gVs.at(g).anchor)("bottom"))
    let kb = (gKs.at(g).anchor)("bottom")
    for h in (2 * g, 2 * g + 1) {
      draw.line(kb, (gQs.at(h).anchor)("top"), stroke: 1.0pt + ink)
    }
  }
  // slabs
  for x in g-cols {
    slab-at(draw, x, yV, c-v-fill, c-v-edge, [v])
    slab-at(draw, x, yK, c-k-fill, c-k-edge, [k])
  }
  for x in q-cols { slab-at(draw, x, yQ, c-q-fill, c-q-edge, [q]) }
  // head labels
  for i in range(4) {
    let qb = (gQs.at(i).anchor)("bottom-screen")
    draw.content((qb.at(0), qb.at(1) - 0.34), text(size: 8pt, weight: "bold", fill: muted)[Head #(i + 1)])
  }

  // panel title
  let gqa-cx = (q-cols.first() + q-cols.last()) / 2
  draw.content((gqa-cx, yV + 1.5), text(size: 11pt, weight: "bold", fill: ink)[Grouped-query attention])
  draw.content((gqa-cx, yV + 1.05), text(size: 8.5pt, fill: muted)[1 K,V shared by 2 query heads])

  // callout: shared K,V annotation pointing at the right group's key slab
  let ann-target = (gKs.at(1).anchor)("east")
  let ann-x = q-cols.last() + 1.0
  let ann-y = yK + 0.55
  draw.content(
    (ann-x, ann-y),
    anchor: "west",
    box(width: 3.2cm)[#text(size: 8pt, fill: c-garnet)[Same key & value heads
      reused across a group of query heads]],
  )
  draw.line(
    (ann-x - 0.1, ann-y - 0.25),
    (ann-target.at(0) + 0.12, ann-target.at(1)),
    stroke: 0.9pt + c-garnet,
    mark: (end: "stealth", fill: c-garnet, scale: 0.8),
  )

  // thin vertical divider between the two panels
  let div-x = (mha-cols.last() + gqa-x0) / 2 - 0.2
  draw.line(
    (div-x, yQ - 0.9),
    (div-x, yV + 1.6),
    stroke: (paint: rgb("#C7C7C7"), thickness: 0.8pt, dash: "dotted"),
  )
})
