// mlatlas · Decision tree (CART) and its induced feature-space partition.
// A small binary tree of axis-aligned splits (left = condition TRUE) maps one-
// to-one onto a recursive rectangular partition of the (x_1, x_2) plane: every
// leaf of the tree is exactly one region of the partition, carrying its label.
//
// Splits (chosen so tree and partition agree exactly):
//   root:  x_1 <= 4   ─ yes → left subtree         ─ no → right subtree
//   left:  x_2 <= 6   ─ yes → R1                    ─ no → R2
//   right: x_2 <= 3   ─ yes → R3                    ─ no → (x_1 <= 7 ? R4 : R5)
#import "../../lib.typ": *
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
    split:  rgb("#FFFFFF"),     // internal (split) node fill
    garnet: rgb("#73000A"),     // root accent
    grid:   rgb("#C7C7C7"),
  )
  // five region tints (light fills, dark text) — one per leaf
  let reg = (
    R1: rgb("#FFF2E3"),         // beige
    R2: rgb("#D9E2EE"),         // light blue
    R3: rgb("#E7ECCF"),         // light green
    R4: rgb("#F4D6DB"),         // light pink-red
    R5: rgb("#ECECEC"),         // 10% black
  )
  // leaf-label text colors (the saturated cousins of the tints)
  let regtx = (
    R1: rgb("#A4621A"), R2: rgb("#466A9F"), R3: rgb("#65780B"),
    R4: rgb("#CC2E40"), R5: rgb("#5C5C5C"),
  )

  let arr(a, b, w: 1pt, color: p.edge, s: 0.55) = draw.line(
    a, b, stroke: w + color, mark: (end: "stealth", scale: s),
  )

  // ══════════════════════════════════════════════════════════════════════════
  //  PART A — the decision tree (top-down, hand-ranked)
  // ══════════════════════════════════════════════════════════════════════════
  // node geometry
  let nw = 1.55                 // split-node width
  let nh = 0.72                 // split-node height
  let lr = 0.46                 // leaf radius (square half-width)

  // a rectangular SPLIT node centered at pos with a condition label
  let split-node(pos, body, accent: false) = {
    let f = if accent { p.garnet } else { p.split }
    let tcol = if accent { rgb("#FFFFFF") } else { p.text }
    let scol = if accent { p.garnet } else { p.edge }
    draw.rect(
      (pos.at(0) - nw / 2, pos.at(1) - nh / 2),
      (pos.at(0) + nw / 2, pos.at(1) + nh / 2),
      fill: f, stroke: 1.1pt + scol, radius: 0pt,
    )
    draw.content(pos, text(size: 9pt, fill: tcol)[#body])
  }
  // a square LEAF node centered at pos with region tint + label
  let leaf-node(pos, key) = {
    draw.rect(
      (pos.at(0) - lr, pos.at(1) - lr),
      (pos.at(0) + lr, pos.at(1) + lr),
      fill: reg.at(key), stroke: 1.1pt + p.edge, radius: 0pt,
    )
    draw.content(pos, text(size: 10pt, weight: "bold", fill: regtx.at(key))[#key])
  }

  // an edge between two nodes carrying a yes/no chip near the parent
  let tree-edge(a, b, lbl, side: "left") = {
    arr(a, b)
    // place the chip a third of the way down, offset to the branch side
    let mx = a.at(0) + (b.at(0) - a.at(0)) * 0.42
    let my = a.at(1) + (b.at(1) - a.at(1)) * 0.42
    let dx = if side == "left" { -0.30 } else { 0.30 }
    draw.content(
      (mx + dx, my),
      text(size: 7.5pt, fill: p.muted, style: "italic")[#lbl],
    )
  }

  // coordinates (origin of the tree block; x grows right, y grows up)
  // levels from top: root y=6.0, L1 y=4.2, L2 y=2.4, L3 y=0.6
  let yA = 6.0
  let yB = 4.2
  let yC = 2.4
  let yD = 0.6

  let n-root = (3.0, yA)
  let n-L    = (1.0, yB)        // x_2 <= 6   (left subtree)
  let n-R    = (5.4, yB)        // x_2 <= 3   (right subtree)
  let l-R1   = (0.2, yC)
  let l-R2   = (1.8, yC)
  let l-R3   = (4.2, yC)
  let n-RR   = (6.6, yC)        // x_1 <= 7
  let l-R4   = (5.9, yD)
  let l-R5   = (7.5, yD)

  // edges (draw first so nodes sit on top)
  tree-edge(n-root, n-L, [yes], side: "left")
  tree-edge(n-root, n-R, [no], side: "right")
  tree-edge(n-L, l-R1, [yes], side: "left")
  tree-edge(n-L, l-R2, [no], side: "right")
  tree-edge(n-R, l-R3, [yes], side: "left")
  tree-edge(n-R, n-RR, [no], side: "right")
  tree-edge(n-RR, l-R4, [yes], side: "left")
  tree-edge(n-RR, l-R5, [no], side: "right")

  // nodes
  split-node(n-root, [$x_1 <= 4$], accent: true)
  split-node(n-L, [$x_2 <= 6$])
  split-node(n-R, [$x_2 <= 3$])
  split-node(n-RR, [$x_1 <= 7$])
  leaf-node(l-R1, "R1")
  leaf-node(l-R2, "R2")
  leaf-node(l-R3, "R3")
  leaf-node(l-R4, "R4")
  leaf-node(l-R5, "R5")

  // a small legend for the branch convention
  draw.content(
    (3.0, yA + 0.95),
    text(size: 8.5pt, fill: p.text, weight: "bold")[Decision tree (CART)],
  )
  draw.content(
    (-0.2, yD - 0.55),
    anchor: "west",
    text(size: 7.5pt, fill: p.muted, style: "italic")[left branch = condition true],
  )

  // ══════════════════════════════════════════════════════════════════════════
  //  PART B — the induced axis-aligned partition of the (x_1, x_2) plane
  // ══════════════════════════════════════════════════════════════════════════
  // plot box: data range 0..10 on both axes, mapped to a 6cm square, offset right
  let ox = 10.6                 // left edge of plot (canvas units)
  let oy = 0.4                  // bottom edge of plot
  let S  = 0.6                  // 1 data unit = 0.6 cm  → 10 units = 6cm
  let X(v) = ox + v * S
  let Y(v) = oy + v * S

  // a filled region rectangle in DATA coords with a centered label
  let region(x0, x1, y0, y1, key) = {
    draw.rect(
      (X(x0), Y(y0)), (X(x1), Y(y1)),
      fill: reg.at(key), stroke: 0.6pt + p.grid, radius: 0pt,
    )
    draw.content(
      ((X(x0) + X(x1)) / 2, (Y(y0) + Y(y1)) / 2),
      text(size: 11pt, weight: "bold", fill: regtx.at(key))[#key],
    )
  }

  // partition that EXACTLY matches the tree:
  //   x_1 <= 4 : split on x_2 <= 6 → R1 (low), R2 (high)
  //   x_1 >  4 : x_2 <= 3 → R3 ; else x_1 <= 7 → R4 else R5
  region(0, 4, 0, 6, "R1")
  region(0, 4, 6, 10, "R2")
  region(4, 10, 0, 3, "R3")
  region(4, 7, 3, 10, "R4")
  region(7, 10, 3, 10, "R5")

  // emphasize the split boundaries; root split (x_1 = 4) in garnet
  let bd(a, b, w: 1.4pt, color: p.edge) = draw.line(a, b, stroke: w + color)
  bd((X(4), Y(0)), (X(4), Y(10)), w: 2pt, color: p.garnet)        // root: x_1 = 4
  bd((X(0), Y(6)), (X(4), Y(6)))                                  // left:  x_2 = 6
  bd((X(4), Y(3)), (X(10), Y(3)))                                 // right: x_2 = 3
  bd((X(7), Y(3)), (X(7), Y(10)))                                 // right-right: x_1 = 7

  // sample points scattered into their regions (label = leaf color)
  let pts = (
    ("R1", (1.2, 1.4)), ("R1", (2.6, 3.1)), ("R1", (1.8, 5.0)), ("R1", (3.3, 2.0)),
    ("R2", (1.0, 8.4)), ("R2", (2.9, 7.2)), ("R2", (2.0, 9.1)), ("R2", (3.4, 6.8)),
    ("R3", (5.6, 1.2)), ("R3", (7.8, 2.1)), ("R3", (9.0, 0.9)), ("R3", (6.7, 2.5)),
    ("R4", (4.8, 5.4)), ("R4", (6.3, 7.8)), ("R4", (5.5, 9.0)), ("R4", (6.6, 4.2)),
    ("R5", (8.1, 4.5)), ("R5", (9.3, 7.0)), ("R5", (7.6, 8.6)), ("R5", (8.8, 5.7)),
  )
  for (key, q) in pts {
    draw.circle(
      (X(q.at(0)), Y(q.at(1))), radius: 0.10,
      fill: regtx.at(key), stroke: 0.5pt + rgb("#FFFFFF"),
    )
  }

  // axes (drawn over the fills, with ticks + labels)
  draw.rect((X(0), Y(0)), (X(10), Y(10)), fill: none, stroke: 1.1pt + p.edge, radius: 0pt)
  for v in (0, 2, 4, 6, 8, 10) {
    // x ticks
    draw.line((X(v), Y(0)), (X(v), Y(0) - 0.14), stroke: 0.9pt + p.edge)
    draw.content((X(v), Y(0) - 0.34), text(size: 7.5pt, fill: p.muted)[#v])
    // y ticks
    draw.line((X(0), Y(v)), (X(0) - 0.14, Y(v)), stroke: 0.9pt + p.edge)
    draw.content((X(0) - 0.34, Y(v)), anchor: "east", text(size: 7.5pt, fill: p.muted)[#v])
  }
  draw.content((X(5), Y(0) - 0.78), text(size: 9.5pt, fill: p.text)[$x_1$])
  draw.content((X(0) - 0.86, Y(5)), text(size: 9.5pt, fill: p.text)[$x_2$])
  draw.content(
    (X(5), Y(10) + 0.55),
    text(size: 8.5pt, fill: p.text, weight: "bold")[Induced feature-space partition],
  )
  // annotate the root split on the plot
  draw.content(
    (X(4), Y(10) + 0.18),
    anchor: "south",
    text(size: 7pt, fill: p.garnet, style: "italic")[$x_1 = 4$],
  )
})
