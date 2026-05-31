// mlatlas · Hierarchical clustering dendrogram (agglomerative).
// Leaf samples sit on a baseline; each merge joins two clusters with a U-shaped
// bracket whose vertical extent reaches y = inter-cluster linkage distance
// (merge height). Heights increase monotonically up the tree. A dashed
// horizontal cut at height h slices the tree into a fixed number of clusters:
// every branch the line crosses is one returned cluster.
//
// Merge order (bottom-up), with linkage heights:
//   m1: {C,D}            h = 0.9
//   m2: {A,B}           h = 1.4
//   m3: {C,D,E}        h = 2.1
//   m4: {F,G}           h = 2.6
//   m5: {A,B} ∪ {C,D,E}  h = 3.5   ← left super-cluster
//   m6: {F,G,H}        h = 4.3   ← right super-cluster
//   m7: root            h = 5.6
// Cut at h = 3.0 crosses 4 branches → 4 clusters: {A,B}, {C,D,E}, {F,G}, {H}.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── palette ───────────────────────────────────────────────────────────────
  let p = (
    edge:   rgb("#363636"),
    text:   rgb("#1A1A1A"),
    muted:  rgb("#5C5C5C"),
    grid:   rgb("#C7C7C7"),
    garnet: rgb("#73000A"),     // sparse accent: the cut line + cut count
    leaf:   rgb("#ECECEC"),     // leaf chip fill
  )
  // four cluster tints (one per cluster created by the cut at h = 3.0)
  let ctint = (
    K1: rgb("#D9E2EE"),         // light blue   {A,B}
    K2: rgb("#E7ECCF"),         // light green  {C,D,E}
    K3: rgb("#F4D6DB"),         // light pink   {F,G}
    K4: rgb("#FFF2E3"),         // beige        {H}
  )
  let ctx = (
    K1: rgb("#466A9F"), K2: rgb("#65780B"),
    K3: rgb("#CC2E40"), K4: rgb("#A4621A"),
  )

  // ── geometry ──────────────────────────────────────────────────────────────
  // 8 leaves evenly spaced along x; y = linkage height (data units → cm via S).
  let leaves = ("A", "B", "C", "D", "E", "F", "G", "H")
  let dx = 1.45                 // spacing between adjacent leaves (cm)
  let lx = (key) => dx * leaves.position(k => k == key)   // leaf x-position
  let S  = 1.5                  // 1 height-unit = 1.5 cm
  let Y  = (h) => h * S         // map linkage height → canvas y
  let ymax = 5.6                // root height

  // which leaf belongs to which cut-cluster (for tinting leaf chips + stems)
  let leafclust = (
    A: "K1", B: "K1", C: "K2", D: "K2", E: "K2",
    F: "K3", G: "K3", H: "K4",
  )

  // a U-shaped merge bracket joining child anchors (cx, cy) and (dx2, dy)
  // at height h: two vertical risers up to y=Y(h) and one horizontal cross-bar.
  // returns the parent anchor (midpoint, Y(h)) implicitly via the caller.
  let bracket(ax, ay, bx, by, h, col: p.edge, w: 1.3pt) = {
    let yt = Y(h)
    draw.line((ax, ay), (ax, yt), stroke: w + col)         // left riser
    draw.line((bx, by), (bx, yt), stroke: w + col)         // right riser
    draw.line((ax, yt), (bx, yt), stroke: w + col)         // cross-bar
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  axes / height scale (drawn first, behind the tree)
  // ══════════════════════════════════════════════════════════════════════════
  let x0 = -0.55                          // left edge of axis
  let xR = dx * 7 + 0.7                    // right edge of plot region
  draw.line((x0, 0), (x0, Y(ymax) + 0.55), stroke: 1.0pt + p.edge,
    mark: (end: "stealth", scale: 0.5))
  draw.content((x0 - 0.62, Y(ymax) + 0.34), anchor: "west",
    text(size: 8.5pt, fill: p.text)[height])
  draw.content((x0 + 0.30, Y(ymax) + 0.34), anchor: "west",
    text(size: 7.5pt, fill: p.muted, style: "italic")[(linkage distance $d$)])
  // y ticks + gridlines
  for hv in (1, 2, 3, 4, 5) {
    draw.line((x0, Y(hv)), (xR, Y(hv)), stroke: 0.5pt + p.grid)
    draw.line((x0, Y(hv)), (x0 - 0.12, Y(hv)), stroke: 0.9pt + p.edge)
    draw.content((x0 - 0.26, Y(hv)), anchor: "east",
      text(size: 7.5pt, fill: p.muted)[#hv])
  }
  // baseline
  draw.line((x0, 0), (xR, 0), stroke: 0.9pt + p.edge)

  // ══════════════════════════════════════════════════════════════════════════
  //  leaf chips on the baseline (tinted by cut-cluster)
  // ══════════════════════════════════════════════════════════════════════════
  let lr = 0.30                            // leaf chip half-width
  for k in leaves {
    let cx = lx(k)
    let cl = leafclust.at(k)
    // short stem from baseline up to chip top is implicit; draw chip at baseline
    draw.rect((cx - lr, -0.46), (cx + lr, -0.46 + 2 * lr),
      fill: ctint.at(cl), stroke: 1.0pt + p.edge, radius: 0pt)
    draw.content((cx, -0.46 + lr),
      text(size: 9pt, weight: "bold", fill: ctx.at(cl))[#k])
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  merges — draw in increasing-height order. Each merge tracks the (x,y)
  //  anchor of the new internal node so parents can attach to it.
  // ══════════════════════════════════════════════════════════════════════════
  // helper: midpoint x of two x-positions
  let mid = (a, b) => (a + b) / 2

  // leaf anchors start at baseline y = 0 (chip top)
  // m1 : {C,D} at h=0.9
  let h1 = 0.9
  bracket(lx("C"), 0, lx("D"), 0, h1, col: ctx.K2)
  let n1 = (mid(lx("C"), lx("D")), Y(h1))

  // m2 : {A,B} at h=1.4
  let h2 = 1.4
  bracket(lx("A"), 0, lx("B"), 0, h2, col: ctx.K1)
  let n2 = (mid(lx("A"), lx("B")), Y(h2))

  // m3 : {C,D} ∪ {E} at h=2.1
  let h3 = 2.1
  bracket(n1.at(0), n1.at(1), lx("E"), 0, h3, col: ctx.K2)
  let n3 = (mid(n1.at(0), lx("E")), Y(h3))

  // m4 : {F,G} at h=2.6
  let h4 = 2.6
  bracket(lx("F"), 0, lx("G"), 0, h4, col: ctx.K3)
  let n4 = (mid(lx("F"), lx("G")), Y(h4))

  // m5 : {A,B} ∪ {C,D,E} at h=3.5  (left super-cluster)
  let h5 = 3.5
  bracket(n2.at(0), n2.at(1), n3.at(0), n3.at(1), h5)
  let n5 = (mid(n2.at(0), n3.at(0)), Y(h5))

  // m6 : {F,G} ∪ {H} at h=4.3  (right super-cluster)
  let h6 = 4.3
  bracket(n4.at(0), n4.at(1), lx("H"), 0, h6)
  let n6 = (mid(n4.at(0), lx("H")), Y(h6))

  // m7 : root at h=5.6
  let h7 = 5.6
  bracket(n5.at(0), n5.at(1), n6.at(0), n6.at(1), h7)
  let nroot = (mid(n5.at(0), n6.at(0)), Y(h7))

  // small height labels at each internal node (to the right of the cross-bar)
  let hlbl(n, h) = draw.content((n.at(0) + 0.14, n.at(1) + 0.20),
    anchor: "west", text(size: 6.5pt, fill: p.muted)[$d = #h$])
  hlbl(n1, h1); hlbl(n2, h2); hlbl(n3, h3); hlbl(n4, h4)
  hlbl(n5, h5); hlbl(n6, h6)
  draw.content((nroot.at(0), nroot.at(1) + 0.24),
    text(size: 6.5pt, fill: p.muted)[$d = #h7$])

  // ══════════════════════════════════════════════════════════════════════════
  //  the CUT line — dashed garnet horizontal at h = 3.0
  // ══════════════════════════════════════════════════════════════════════════
  let hcut = 3.0
  draw.line((x0, Y(hcut)), (xR, Y(hcut)),
    stroke: (paint: p.garnet, thickness: 1.6pt, dash: "dashed"))
  draw.content((xR + 0.10, Y(hcut)), anchor: "west",
    text(size: 8pt, fill: p.garnet, weight: "bold")[cut $h = #hcut$])

  // mark where the cut crosses live branches (the 4 surviving clusters).
  // crossings: the 4 vertical risers active at y=Y(hcut):
  //   left super-cluster's two children risers (n2→up, n3→up)  → {A,B},{C,D,E}
  //   merge m4 riser into m6 (F,G subtree)                      → {F,G}
  //   leaf H riser into m6                                       → {H}
  let crossings = (
    (n2.at(0), "K1"),     // {A,B}
    (n3.at(0), "K2"),     // {C,D,E}
    (n4.at(0), "K3"),     // {F,G}
    (lx("H"), "K4"),      // {H}
  )
  for (cxp, cl) in crossings {
    draw.circle((cxp, Y(hcut)), radius: 0.11,
      fill: ctx.at(cl), stroke: 0.8pt + rgb("#FFFFFF"))
  }

  // bracket-and-label each resulting cluster under the baseline
  let cluster-brace(xa, xb, lbl, cl) = {
    let yb = -1.05
    draw.line((xa - lr, yb + 0.18), (xa - lr, yb), stroke: 0.8pt + ctx.at(cl))
    draw.line((xb + lr, yb + 0.18), (xb + lr, yb), stroke: 0.8pt + ctx.at(cl))
    draw.line((xa - lr, yb), (xb + lr, yb), stroke: 0.8pt + ctx.at(cl))
    draw.content((mid(xa, xb), yb - 0.26),
      text(size: 7.5pt, fill: ctx.at(cl), weight: "bold")[#lbl])
  }
  cluster-brace(lx("A"), lx("B"), [$C_1$], "K1")
  cluster-brace(lx("C"), lx("E"), [$C_2$], "K2")
  cluster-brace(lx("F"), lx("G"), [$C_3$], "K3")
  cluster-brace(lx("H"), lx("H"), [$C_4$], "K4")

  // ══════════════════════════════════════════════════════════════════════════
  //  title + footnote
  // ══════════════════════════════════════════════════════════════════════════
  draw.content((mid(x0, xR), Y(ymax) + 1.05),
    text(size: 10pt, fill: p.text, weight: "bold")[
      Agglomerative hierarchical clustering — dendrogram])
  draw.content((mid(x0, xR), -1.75),
    text(size: 7.5pt, fill: p.muted, style: "italic")[
      cut at height #hcut crosses 4 branches #sym.arrow.r 4 clusters])
})
