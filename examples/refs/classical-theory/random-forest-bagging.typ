// Random forest / bagging ensemble — a standard ML concept taught from ESL & ISLR/ISLP.
// One training set D is RESAMPLED WITH REPLACEMENT into B bootstrap samples D*_b. Each
// bootstrap sample (and, in a random forest, a random subset of features at each split)
// grows one decorrelated decision tree. The B tree predictions are then aggregated:
//   classification -> MAJORITY VOTE        regression -> AVERAGE
// Built from scratch in mlatlas's print-first house style (light fills, dark text, sharp
// orthogonal corners, stealth arrowheads, garnet as a sparse accent on the final ensemble).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let panel  = rgb("#ECECEC")
#let beige  = rgb("#FFF2E3")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ───────────────────────── layout constants ─────────────────────────
  let n-trees = 4
  let tree-gap = 3.2                 // horizontal spacing between tree centres
  let span = (n-trees - 1) * tree-gap
  let xs = range(n-trees).map(i => i * tree-gap - span / 2)   // tree centre x's
  let y-data = 7.4                   // training-set block
  let y-boot = 5.2                   // bootstrap-sample row
  let y-tree = 2.7                   // tree apex row
  let y-vote = -2.4                  // aggregation node
  let y-out  = -4.2                  // final prediction

  // ───────────────────────── 1. training set D ────────────────────────
  // a little data-table glyph so "dataset" reads instantly
  let dw = 2.6
  let dh = 1.25
  rect((-dw / 2, y-data - dh / 2), (dw / 2, y-data + dh / 2),
       fill: beige, stroke: 0.9pt + ink, radius: 0pt)
  // grid rows/cols
  for r in range(1, 4) {
    let yy = y-data - dh / 2 + r * dh / 4
    line((-dw / 2, yy), (dw / 2, yy), stroke: 0.4pt + faint)
  }
  for c in range(1, 4) {
    let xx = -dw / 2 + c * dw / 4
    line((xx, y-data - dh / 2), (xx, y-data + dh / 2), stroke: 0.4pt + faint)
  }
  content((0, y-data + dh / 2 + 0.42), text(size: 9.5pt, fill: ink)[*training set* $D$])
  content((dw / 2 + 0.15, y-data), anchor: "west",
          text(size: 7.5pt, fill: muted)[$n$ rows])

  // ───────────────────────── 2. bootstrap fan-out ─────────────────────
  // label on the fan-out
  content((span / 2 + 0.7, (y-data + y-boot) / 2 + 0.05), anchor: "west",
          box(fill: white, inset: 1.5pt,
              text(size: 7.5pt, fill: garnet)[resample\ with replacement]))

  // small bootstrap-sample glyph: a stack of three offset cards (a "sampled" dataset)
  let draw-boot(cx, cy) = {
    let bw = 1.0
    let bh = 0.78
    for k in (2, 1, 0) {
      let o = k * 0.12
      let fc = if k == 0 { panel } else { white }
      rect((cx - bw / 2 + o, cy - bh / 2 - o), (cx + bw / 2 + o, cy + bh / 2 - o),
           fill: fc, stroke: 0.7pt + ink, radius: 0pt)
    }
    // a few "row" ticks on the front card to suggest resampled rows
    for r in range(1, 3) {
      let yy = cy - bh / 2 + r * bh / 3
      line((cx - bw / 2 + 0.12, yy), (cx + bw / 2 - 0.12, yy), stroke: 0.35pt + faint)
    }
  }

  for (i, x) in xs.enumerate() {
    // fan-out arrow from D down to each bootstrap sample
    line((x * 0.18, y-data - dh / 2 - 0.04), (x, y-boot + 0.5),
         stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.85))
    draw-boot(x, y-boot)
    content((x, y-boot - 0.78), text(size: 8pt, fill: ink)[$D^*_#(i + 1)$])
  }

  // ───────────────────────── 3. the decision trees ────────────────────
  // a compact binary-tree glyph: root -> 2 internal -> 4 leaves.
  // leaves coloured by predicted class so the "vote" is concrete.
  let leaf-colors = (
    (garnet,  panel,  garnet, panel),    // tree 1 votes garnet (3:1 -> garnet)
    (garnet,  garnet, panel,  garnet),   // tree 2 votes garnet
    (panel,   garnet, garnet, garnet),   // tree 3 votes garnet
    (panel,   garnet, panel,  panel),    // tree 4 votes panel (minority)
  )

  let draw-tree(cx, cy, leaves) = {
    let halfw = 0.95         // root-to-child horizontal half-span
    let dy = 0.78            // vertical step per level
    let r-root = 0.16
    // node coordinates
    let root = (cx, cy)
    let l1 = (cx - halfw, cy - dy)
    let l2 = (cx + halfw, cy - dy)
    let ls = (
      (cx - halfw - 0.5, cy - 2 * dy),
      (cx - halfw + 0.5, cy - 2 * dy),
      (cx + halfw - 0.5, cy - 2 * dy),
      (cx + halfw + 0.5, cy - 2 * dy),
    )
    // edges (split branches)
    line(root, l1, stroke: 0.8pt + ink)
    line(root, l2, stroke: 0.8pt + ink)
    line(l1, ls.at(0), stroke: 0.8pt + ink)
    line(l1, ls.at(1), stroke: 0.8pt + ink)
    line(l2, ls.at(2), stroke: 0.8pt + ink)
    line(l2, ls.at(3), stroke: 0.8pt + ink)
    // internal split nodes (small squares = decision tests)
    for p in (root, l1, l2) {
      rect((p.at(0) - 0.13, p.at(1) - 0.13), (p.at(0) + 0.13, p.at(1) + 0.13),
           fill: white, stroke: 0.8pt + ink, radius: 0pt)
    }
    // leaf nodes (circles, filled by predicted class)
    for (j, p) in ls.enumerate() {
      circle(p, radius: 0.18, fill: leaves.at(j), stroke: 0.8pt + ink)
    }
  }

  // a faint card behind each tree to read as "tree T_b"
  for (i, x) in xs.enumerate() {
    let cw = 3.0
    rect((x - cw / 2, y-tree - 2.05), (x + cw / 2, y-tree + 0.55),
         fill: white, stroke: 0.6pt + faint, radius: 0pt)
    draw-tree(x, y-tree, leaf-colors.at(i))
    content((x, y-tree - 2.32), text(size: 8.5pt, fill: ink)[tree $T_#(i + 1)$])
    // arrow bootstrap-sample -> tree
    line((x, y-boot - 1.05), (x, y-tree + 0.62),
         stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.85))
  }
  // brace-ish label for the forest as a whole
  content((span / 2 + 1.65, y-tree - 1.05), anchor: "west",
          box(fill: white, inset: 1.5pt,
              text(size: 7.5pt, fill: muted)[$B$ decorrelated\ trees]))

  // ───────────────────── 4. aggregation -> vote/average ───────────────
  // each tree's prediction flows down into the aggregation node
  for x in xs {
    line((x, y-tree - 2.5), (x * 0.10, y-vote + 0.55),
         stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.85))
  }

  // the ensemble aggregation node — garnet focal element
  let vr = 0.82
  circle((0, y-vote), radius: vr, fill: garnet, stroke: 1.1pt + garnet)
  content((0, y-vote + 0.18), text(size: 9pt, fill: white)[*vote*])
  content((0, y-vote - 0.26), text(size: 6.5pt, fill: white)[\/ avg])

  // aggregation rule, set beside the node
  content((vr + 0.5, y-vote + 0.2), anchor: "west",
          text(size: 8pt, fill: ink)[
            classification: majority vote])
  content((vr + 0.5, y-vote - 0.45), anchor: "west",
          text(size: 8pt, fill: ink)[
            regression: $hat(y) = 1/B sum_(b=1)^B T_b (x)$])

  // ───────────────────────── 5. final prediction ─────────────────────
  line((0, y-vote - vr - 0.04), (0, y-out + 0.42),
       stroke: 1.1pt + garnet, mark: (end: "stealth", scale: 0.9))
  let ow = 2.7
  let oh = 0.78
  rect((-ow / 2, y-out - oh / 2), (ow / 2, y-out + oh / 2),
       fill: beige, stroke: 1.0pt + garnet, radius: 0pt)
  content((0, y-out), text(size: 9pt, fill: ink)[*ensemble prediction* $hat(y)$])
})
