// mlatlas · Anchor boxes, IoU overlap, and the per-anchor detection head.
// Single-stage object detectors tile every feature-map cell with a fixed set of
// anchor (prior) boxes spanning several scales and aspect ratios. Each anchor is
// matched to the ground-truth box it overlaps most, where overlap is measured by
// Intersection-over-Union (IoU = area∩ / area∪). For every anchor the head emits a
// class-score vector (K+1 logits, incl. background) and 4 box-offset deltas
// (Δx, Δy, Δw, Δh) that warp the anchor toward the matched ground-truth box.
//
// Three coupled panels, left → right:
//   A  feature-map grid, one cell tiled with 5 anchors (varied scale / aspect)
//   B  IoU inset: predicted box vs ground-truth box, intersection shaded
//   C  per-anchor head outputs: cls logits (K+1) + box deltas (4) block stack
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
    faint:  rgb("#A2A2A2"),
    grid:   rgb("#C7C7C7"),
    cell:   rgb("#ECECEC"),     // feature-map cell fill
    hot:    rgb("#FFF2E3"),     // highlighted cell (beige)
    garnet: rgb("#73000A"),     // focal accent (matched anchor / GT)
    blue:   rgb("#466A9F"),     // prediction
    green:  rgb("#65780B"),     // box-delta branch
    pink:   rgb("#CC2E40"),     // intersection / mismatch accent
    panel:  rgb("#FFFFFF"),
  )

  // ── small helpers ───────────────────────────────────────────────────────────
  let arr(a, b, w: 1.1pt, color: p.edge, s: 0.55, dash: none) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: s),
  )
  // an axis-aligned rectangle by centre + (w,h)
  let box-c(cx, cy, w, h, color: p.edge, thick: 1pt, fill: none, dash: none) = draw.rect(
    (cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
    stroke: (paint: color, thickness: thick, dash: dash),
    fill: fill, radius: 0pt,
  )

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL A — feature-map grid with anchors tiled at one cell
  // ══════════════════════════════════════════════════════════════════════════
  let gx = 0.0                  // grid left edge
  let gy = 0.0                  // grid bottom edge
  let gn = 6                    // 6 × 6 cells
  let gc = 0.74                 // cell side (cm)
  let GW = gn * gc

  // grid cells
  for i in range(gn) {
    for j in range(gn) {
      draw.rect(
        (gx + i * gc, gy + j * gc), (gx + (i + 1) * gc, gy + (j + 1) * gc),
        fill: p.cell, stroke: 0.6pt + p.grid, radius: 0pt,
      )
    }
  }

  // the focal cell (col 3, row 3 from bottom-left): centre of the anchor fan
  let ci = 3
  let cj = 3
  let ccx = gx + (ci + 0.5) * gc
  let ccy = gy + (cj + 0.5) * gc
  draw.rect(
    (gx + ci * gc, gy + cj * gc), (gx + (ci + 1) * gc, gy + (cj + 1) * gc),
    fill: p.hot, stroke: 1.3pt + p.garnet, radius: 0pt,
  )
  // mark the cell centre (anchor origin)
  draw.circle((ccx, ccy), radius: 0.055, fill: p.garnet, stroke: none)

  // anchor set centred on the cell: (w, h) in cm, varied scale × aspect ratio
  //   small square · medium square · large square · wide (2:1) · tall (1:2)
  let anchors = (
    (0.62, 0.62, p.muted, "1:1 s"),     // small square
    (1.05, 1.05, p.muted, "1:1 m"),     // medium square
    (1.70, 1.70, p.faint, "1:1 ℓ"),     // large square
    (2.05, 1.02, p.blue,  "2:1"),       // wide
    (1.00, 2.05, p.green, "1:2"),       // tall
  )
  // draw large → small so smaller boxes stay readable on top
  for a in anchors.rev() {
    box-c(ccx, ccy, a.at(0), a.at(1), color: a.at(2), thick: 1.1pt, dash: "dashed")
  }

  // labels for panel A
  draw.content(
    (gx + GW / 2, gy + GW + 0.46),
    text(size: 9.5pt, weight: "bold", fill: p.text)[Feature map · anchors per cell],
  )
  draw.content(
    (gx + GW / 2, gy - 0.42),
    text(size: 8pt, fill: p.muted, style: "italic")[$H' times W'$ cells, $A$ anchors each],
  )
  // call out the focal cell
  draw.content(
    (ccx, gy + GW + 0.06),
    anchor: "south",
    text(size: 7.5pt, fill: p.garnet, style: "italic")[one cell, $A = 5$ priors],
  )
  // mini anchor legend (scale × aspect)
  let lx = gx + GW + 0.30
  let ly0 = gy + GW - 0.55
  draw.content((lx, ly0 + 0.40), anchor: "west", text(size: 7.5pt, weight: "bold", fill: p.text)[anchors])
  let leg = (
    (p.muted, "dashed", [square · 3 scales]),
    (p.blue,  "dashed", [wide  2:1]),
    (p.green, "dashed", [tall  1:2]),
  )
  for (k, e) in leg.enumerate() {
    let yy = ly0 - k * 0.40
    draw.line((lx, yy), (lx + 0.42, yy), stroke: (paint: e.at(0), thickness: 1.2pt, dash: e.at(1)))
    draw.content((lx + 0.54, yy), anchor: "west", text(size: 7.5pt, fill: p.muted)[#e.at(2)])
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL B — IoU inset: predicted box vs ground-truth box
  // ══════════════════════════════════════════════════════════════════════════
  let bx = lx + 2.55            // panel-B local origin (left)
  let byc = gy + GW / 2 + 0.15  // vertical centre

  // panel frame title
  draw.content(
    (bx + 1.55, byc + 2.30),
    text(size: 9.5pt, weight: "bold", fill: p.text)[Intersection over Union],
  )

  // ground-truth box (garnet, solid) and predicted box (blue, dashed), overlapping
  // GT:   centre (bx+1.25, byc), 2.4 × 1.7
  // pred: centre (bx+1.95, byc+0.55), 2.2 × 1.7
  let gt = (bx + 1.20, byc - 0.05, 2.40, 1.70)
  let pr = (bx + 1.92, byc + 0.55, 2.20, 1.70)
  let gt_l = gt.at(0) - gt.at(2) / 2
  let gt_r = gt.at(0) + gt.at(2) / 2
  let gt_b = gt.at(1) - gt.at(3) / 2
  let gt_t = gt.at(1) + gt.at(3) / 2
  let pr_l = pr.at(0) - pr.at(2) / 2
  let pr_r = pr.at(0) + pr.at(2) / 2
  let pr_b = pr.at(1) - pr.at(3) / 2
  let pr_t = pr.at(1) + pr.at(3) / 2
  // intersection rectangle
  let ix_l = calc.max(gt_l, pr_l)
  let ix_r = calc.min(gt_r, pr_r)
  let ix_b = calc.max(gt_b, pr_b)
  let ix_t = calc.min(gt_t, pr_t)

  // shaded intersection (drawn first, under the outlines)
  draw.rect(
    (ix_l, ix_b), (ix_r, ix_t),
    fill: p.pink.transparentize(55%), stroke: none, radius: 0pt,
  )
  // outlines
  box-c(gt.at(0), gt.at(1), gt.at(2), gt.at(3), color: p.garnet, thick: 1.6pt)
  box-c(pr.at(0), pr.at(1), pr.at(2), pr.at(3), color: p.blue, thick: 1.4pt, dash: "dashed")
  // re-stroke intersection border for clarity
  draw.rect((ix_l, ix_b), (ix_r, ix_t), fill: none, stroke: 1.0pt + p.pink, radius: 0pt)

  // box labels
  draw.content(
    (gt_l - 0.02, gt_b + 0.20), anchor: "west",
    text(size: 8pt, fill: p.garnet, weight: "bold")[ground truth],
  )
  draw.content(
    (pr_r - 0.04, pr_t + 0.20), anchor: "east",
    text(size: 8pt, fill: p.blue, weight: "bold")[prediction],
  )
  draw.content(
    ((ix_l + ix_r) / 2, (ix_b + ix_t) / 2),
    text(size: 7.5pt, fill: p.pink, weight: "bold")[∩],
  )

  // IoU formula, below the inset
  draw.content(
    (bx + 1.55, byc - 1.95),
    text(size: 10pt, fill: p.text)[
      $ "IoU" = (|B_p inter B_(g t)|) / (|B_p union B_(g t)|) $
    ],
  )

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL C — per-anchor head outputs (block stack)
  // ══════════════════════════════════════════════════════════════════════════
  let cx0 = bx + 4.30           // panel-C left edge
  let cyc = gy + GW / 2 + 0.15

  draw.content(
    (cx0 + 1.10, cyc + 2.30),
    text(size: 9.5pt, weight: "bold", fill: p.text)[Per-anchor head],
  )

  // a labelled block: (cx, cy) centre, w, h
  let head-block(cx, cy, w, h, fill, scol, title, sub) = {
    draw.rect(
      (cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
      fill: fill, stroke: 1.2pt + scol, radius: 0pt,
    )
    draw.content((cx, cy + 0.18), text(size: 8.5pt, weight: "bold", fill: p.text)[#title])
    draw.content((cx, cy - 0.22), text(size: 7.5pt, fill: p.muted)[#sub])
  }

  // shared backbone-features source block
  let fbx = cx0 + 1.10
  head-block(fbx, cyc + 1.45, 2.30, 0.82, p.cell, p.edge, [anchor feature], [$d$-vector])

  // two parallel output heads
  let cls = (cx0 + 0.05, cyc - 0.55, 1.90, 0.95)   // classification
  let reg = (cx0 + 2.15, cyc - 0.55, 1.90, 0.95)   // box regression
  head-block(cls.at(0), cls.at(1), cls.at(2), cls.at(3), p.hot, p.garnet, [cls logits], [$K + 1$])
  head-block(reg.at(0), reg.at(1), reg.at(2), reg.at(3), rgb("#E7ECCF"), p.green, [box deltas], [$Delta x, Delta y, Delta w, Delta h$])

  // arrows from feature → each head
  arr((fbx - 0.55, cyc + 1.45 - 0.41), (cls.at(0), cls.at(1) + cls.at(3) / 2), color: p.garnet, w: 1.2pt)
  arr((fbx + 0.55, cyc + 1.45 - 0.41), (reg.at(0), reg.at(1) + reg.at(3) / 2), color: p.green, w: 1.2pt)

  // softmax / smooth-L1 annotations under the heads
  draw.content(
    (cls.at(0), cls.at(1) - cls.at(3) / 2 - 0.30),
    text(size: 7pt, fill: p.muted, style: "italic")[softmax],
  )
  draw.content(
    (reg.at(0), reg.at(1) - reg.at(3) / 2 - 0.30),
    text(size: 7pt, fill: p.muted, style: "italic")[smooth-$L_1$],
  )

  // ── connecting arrows across the three panels ───────────────────────────────
  // A focal cell → B (anchor matched to GT by IoU)
  arr((gx + GW + 0.10, ccy), (bx + 0.05, byc + 0.10), color: p.edge, w: 1.0pt, s: 0.5)
  draw.content(
    ((gx + GW + bx) / 2 + 0.05, byc - 0.55),
    text(size: 7pt, fill: p.muted, style: "italic")[match by IoU],
  )
  // B → C (matched anchor feeds the head)
  arr((bx + 3.15, byc + 0.10), (cx0 - 0.10, cyc + 1.45), color: p.edge, w: 1.0pt, s: 0.5)
  draw.content(
    ((bx + 3.15 + cx0) / 2, cyc + 1.05),
    text(size: 7pt, fill: p.muted, style: "italic")[predict],
  )
})
