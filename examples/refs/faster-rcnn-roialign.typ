// mlatlas · Faster R-CNN — two-stage detector with RPN + RoIAlign.
// A shared CNN backbone turns the image into a feature map. Stage 1 — the Region
// Proposal Network (RPN) — slides a small conv over that map; at every cell it scores
// A anchors for objectness (2A logits) and regresses 4A box offsets, yielding a sparse
// set of region proposals (RoIs). Stage 2 — RoIAlign crops each RoI from the feature map
// and resamples it to a fixed grid using BILINEAR interpolation (no quantisation, unlike
// RoIPool). The fixed-size RoI features feed two (or three) parallel heads: a softmax
// classifier (K+1 classes), a box-regression head (4K deltas), and an optional FCN mask
// head. Left -> right: image, backbone, RPN, RoIAlign, heads.
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
    cell:   rgb("#ECECEC"),
    hot:    rgb("#FFF2E3"),     // beige highlight
    garnet: rgb("#73000A"),     // focal accent (RoIAlign / matched proposal)
    blue:   rgb("#466A9F"),     // objectness / cls branch
    green:  rgb("#65780B"),     // box-regression branch
    pink:   rgb("#CC2E40"),     // proposals / mask accent
    teal:   rgb("#1F414D"),
  )

  // ── helpers ─────────────────────────────────────────────────────────────────
  let arr(a, b, w: 1.2pt, color: p.edge, s: 0.6, dash: none) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: s),
  )
  let box-c(cx, cy, w, h, color: p.edge, thick: 1pt, fill: none, dash: none) = draw.rect(
    (cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
    stroke: (paint: color, thickness: thick, dash: dash), fill: fill, radius: 0pt,
  )
  // labelled block centred at (cx,cy)
  let lblk(cx, cy, w, h, fill, scol, title, sub, tsize: 8.5pt, ssize: 7pt) = {
    draw.rect(
      (cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
      fill: fill, stroke: 1.2pt + scol, radius: 0pt,
    )
    if sub == none {
      draw.content((cx, cy), text(size: tsize, weight: "bold", fill: p.text)[#title])
    } else {
      draw.content((cx, cy + h / 2 - 0.30), text(size: tsize, weight: "bold", fill: p.text)[#title])
      draw.content((cx, cy + h / 2 - 0.30 - 0.34), text(size: ssize, fill: p.muted)[#sub])
    }
  }

  let yc = 0.0   // pipeline centre line

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 0 — input image (with two ground-truth boxes)
  // ══════════════════════════════════════════════════════════════════════════
  let imx = 0.0
  let imw = 1.85
  let imh = 2.20
  draw.rect((imx, yc - imh / 2), (imx + imw, yc + imh / 2), fill: p.cell, stroke: 1.1pt + p.edge, radius: 0pt)
  // two GT objects
  box-c(imx + 0.62, yc + 0.18, 0.78, 1.05, color: p.garnet, thick: 1.3pt)
  box-c(imx + 1.32, yc - 0.42, 0.70, 0.60, color: p.garnet, thick: 1.3pt)
  draw.content((imx + imw / 2, yc + imh / 2 + 0.30), text(size: 8.5pt, weight: "bold", fill: p.text)[image])
  draw.content((imx + imw / 2, yc - imh / 2 - 0.30), text(size: 7pt, fill: p.muted, style: "italic")[$H times W times 3$])

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 1 — CNN backbone (3-D feature volume) -> feature map
  // ══════════════════════════════════════════════════════════════════════════
  let bbx = imx + imw + 1.05
  // three stacked feature volumes, decreasing spatial / growing channels
  feature-map(draw, (bbx + 0.00, yc), spatial: 120, channels: 64,  base: rgb("#DCE6F2"), edge: p.edge, cam: cam-cabinet, relu: true)
  feature-map(draw, (bbx + 0.55, yc), spatial: 70,  channels: 128, base: rgb("#CBDAEF"), edge: p.edge, cam: cam-cabinet, relu: true)
  feature-map(draw, (bbx + 1.10, yc), spatial: 36,  channels: 256, base: rgb("#B9CEEA"), edge: p.edge, cam: cam-cabinet, relu: true)
  let bbA = block3d-anchors(origin: (bbx + 1.10, yc), w: 0.34, h: 1.4, dep: 1.6, cam: cam-cabinet)
  let bbE = (bbA.anchor)("east").at(0)
  draw.content((bbx + 0.55, yc + 1.55), text(size: 8.5pt, weight: "bold", fill: p.text)[CNN backbone])
  draw.content((bbx + 0.55, yc - 1.62), text(size: 7pt, fill: p.muted, style: "italic")[shared feature map  $C times H' times W'$])

  arr((imx + imw + 0.06, yc), (bbx - 0.18, yc), color: p.edge, w: 1.3pt)

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 2 — Region Proposal Network (RPN): anchors -> objectness + box
  // ══════════════════════════════════════════════════════════════════════════
  let rpx = bbE + 0.95          // left edge of RPN grid
  let rgn = 4                    // 4x4 feature cells
  let rgc = 0.42
  let RGW = rgn * rgc
  let rpy0 = yc + RGW / 2        // grid top
  // grid (drawn from a top-left local frame so it stays compact)
  for i in range(rgn) {
    for j in range(rgn) {
      draw.rect(
        (rpx + i * rgc, yc - RGW / 2 + j * rgc), (rpx + (i + 1) * rgc, yc - RGW / 2 + (j + 1) * rgc),
        fill: p.cell, stroke: 0.6pt + p.grid, radius: 0pt,
      )
    }
  }
  // focal cell + anchor fan (3 anchors: square, wide, tall)
  let fcx = rpx + 1.5 * rgc
  let fcy = yc - RGW / 2 + 2.5 * rgc
  draw.rect(
    (rpx + 1 * rgc, yc - RGW / 2 + 2 * rgc), (rpx + 2 * rgc, yc - RGW / 2 + 3 * rgc),
    fill: p.hot, stroke: 1.2pt + p.garnet, radius: 0pt,
  )
  draw.circle((fcx, fcy), radius: 0.045, fill: p.garnet, stroke: none)
  box-c(fcx, fcy, 0.62, 0.62, color: p.muted, thick: 1.0pt, dash: "dashed")
  box-c(fcx, fcy, 1.10, 0.55, color: p.blue,  thick: 1.0pt, dash: "dashed")
  box-c(fcx, fcy, 0.55, 1.10, color: p.green, thick: 1.0pt, dash: "dashed")
  draw.content((rpx + RGW / 2, yc + RGW / 2 + 0.34), text(size: 8.5pt, weight: "bold", fill: p.text)[RPN])
  draw.content((rpx + RGW / 2, yc + RGW / 2 + 0.04), anchor: "south", text(size: 6.8pt, fill: p.garnet, style: "italic")[$A$ anchors / cell])
  draw.content((rpx + RGW / 2, yc - RGW / 2 - 0.30), text(size: 7pt, fill: p.muted, style: "italic")[3#sym.times 3 conv])

  arr((bbE + 0.08, yc), (rpx - 0.14, yc), color: p.edge, w: 1.3pt)

  // RPN twin heads (objectness, box) stacked to the right of the grid
  let rhx = rpx + RGW + 1.20
  let obj = (rhx, yc + 0.62, 1.95, 0.78)
  let rbx = (rhx, yc - 0.62, 1.95, 0.78)
  lblk(obj.at(0), obj.at(1), obj.at(2), obj.at(3), rgb("#DCE6F2"), p.blue,  [objectness], [$2A$ logits])
  lblk(rbx.at(0), rbx.at(1), rbx.at(2), rbx.at(3), rgb("#E7ECCF"), p.green, [anchor reg.], [$4A$ deltas])
  // grid -> heads
  arr((rpx + RGW + 0.06, yc + 0.15), (obj.at(0) - obj.at(2) / 2 - 0.04, obj.at(1)), color: p.blue,  w: 1.1pt, s: 0.5)
  arr((rpx + RGW + 0.06, yc - 0.15), (rbx.at(0) - rbx.at(2) / 2 - 0.04, rbx.at(1)), color: p.green, w: 1.1pt, s: 0.5)
  // heads -> proposals (NMS) node
  let prop = (rhx + 2.55, yc, 1.55, 1.05)
  lblk(prop.at(0), prop.at(1), prop.at(2), prop.at(3), p.hot, p.pink, [proposals], [top-$N$ RoIs], tsize: 8pt)
  draw.content((prop.at(0), prop.at(1) - prop.at(3) / 2 - 0.28), text(size: 6.8pt, fill: p.muted, style: "italic")[NMS on objectness])
  arr((obj.at(0) + obj.at(2) / 2 + 0.04, obj.at(1)), (prop.at(0) - prop.at(2) / 2 - 0.04, prop.at(1) + 0.22), color: p.blue,  w: 1.0pt, s: 0.5)
  arr((rbx.at(0) + rbx.at(2) / 2 + 0.04, rbx.at(1)), (prop.at(0) - prop.at(2) / 2 - 0.04, prop.at(1) - 0.22), color: p.green, w: 1.0pt, s: 0.5)

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 3 — RoIAlign: crop a proposal from the feature map, bilinearly resample
  // ══════════════════════════════════════════════════════════════════════════
  let rax = prop.at(0) + prop.at(2) / 2 + 1.55   // RoIAlign panel centre-x
  let ray = yc
  // op-node (garnet focal)
  let opR = 0.74
  draw.circle((rax, ray + 1.55), radius: opR, fill: p.garnet, stroke: 1.3pt + p.garnet.darken(15%))
  draw.content((rax, ray + 1.55), text(size: 8.5pt, weight: "bold", fill: white)[RoI\ Align])
  arr((prop.at(0) + prop.at(2) / 2 + 0.04, prop.at(1)), (rax - opR - 0.04, ray + 1.55), color: p.pink, w: 1.2pt, s: 0.55)
  // backbone feature map also feeds RoIAlign (curved feed from backbone east)
  draw.bezier(
    (bbE + 0.10, yc + 1.05), (rax - 0.30, ray + 1.55 + opR + 0.02), (bbx + 2.2, yc + 2.55), (rax - 0.55, ray + 2.55),
    stroke: (paint: p.faint, thickness: 1.0pt), mark: (end: "stealth", scale: 0.5),
  )
  draw.content((bbx + 1.9, yc + 2.30), anchor: "south", text(size: 6.8pt, fill: p.muted, style: "italic")[feeds RoIAlign])

  // ---- bilinear-sampling inset (the heart of RoIAlign) ----
  let bx0 = rax - 1.05          // inset grid left
  let by0 = ray - 1.95          // inset grid bottom
  let bn = 3                    // 3x3 feature-cell neighbourhood
  let bc = 0.62
  let BW = bn * bc
  for i in range(bn) {
    for j in range(bn) {
      draw.rect(
        (bx0 + i * bc, by0 + j * bc), (bx0 + (i + 1) * bc, by0 + (j + 1) * bc),
        fill: p.cell, stroke: 0.7pt + p.grid, radius: 0pt,
      )
    }
  }
  // the misaligned RoI bin (a 2x2 region that does NOT snap to cell borders)
  let rb_l = bx0 + 0.55
  let rb_b = by0 + 0.50
  let rb_w = 1.10
  let rb_h = 1.05
  draw.rect((rb_l, rb_b), (rb_l + rb_w, rb_b + rb_h), fill: none, stroke: 1.3pt + p.garnet, radius: 0pt)
  // 4 bilinear sample points inside the bin, each pulling from its 4 nearest cell centres
  let samples = (
    (rb_l + rb_w * 0.30, rb_b + rb_h * 0.30),
    (rb_l + rb_w * 0.70, rb_b + rb_h * 0.30),
    (rb_l + rb_w * 0.30, rb_b + rb_h * 0.70),
    (rb_l + rb_w * 0.70, rb_b + rb_h * 0.70),
  )
  for s in samples {
    draw.circle(s, radius: 0.05, fill: p.pink, stroke: none)
    // thin spokes to the four surrounding cell centres
    let gi = calc.clamp(calc.floor((s.at(0) - bx0) / bc - 0.5), 0, bn - 2)
    let gj = calc.clamp(calc.floor((s.at(1) - by0) / bc - 0.5), 0, bn - 2)
    for di in (0, 1) {
      for dj in (0, 1) {
        let cxx = bx0 + (gi + di + 0.5) * bc
        let cyy = by0 + (gj + dj + 0.5) * bc
        draw.line(s, (cxx, cyy), stroke: (paint: p.pink.transparentize(45%), thickness: 0.5pt))
        draw.circle((cxx, cyy), radius: 0.028, fill: p.muted, stroke: none)
      }
    }
  }
  draw.content((bx0 + BW / 2, by0 - 0.30), text(size: 6.8pt, fill: p.muted, style: "italic")[bilinear samples · no quantisation])
  draw.content((rax, ray + 1.55 - opR - 0.30), text(size: 6.8pt, fill: p.garnet, style: "italic")[crop + resample])
  arr((rax, ray + 1.55 - opR - 0.55), (rax, by0 + BW + 0.06), color: p.garnet, w: 1.0pt, s: 0.5)

  // RoIAlign output: fixed-size RoI feature
  let rox = rax + 1.95
  feature-map(draw, (rox, ray + 1.55), spatial: 14, channels: 256, base: rgb("#F2D9DD"), edge: p.edge, cam: cam-cabinet)
  let roA = block3d-anchors(origin: (rox, ray + 1.55), w: 0.34, h: 0.92, dep: 1.2, cam: cam-cabinet)
  draw.content((rox + 0.1, ray + 1.55 - 0.95), text(size: 6.8pt, fill: p.muted, style: "italic")[7#sym.times 7 RoI feat.])
  arr((rax + opR + 0.04, ray + 1.55), ((roA.anchor)("west").at(0) - 0.06, ray + 1.55), color: p.garnet, w: 1.1pt, s: 0.5)

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 4 — parallel detection heads: cls / box / mask
  // ══════════════════════════════════════════════════════════════════════════
  let hbx = roA.anchor
  let hx = (roA.anchor)("east").at(0) + 1.35   // heads column centre-x
  let hy = ray + 1.55
  // FC trunk (shared) before cls/box
  let fc = (hx, hy, 1.30, 0.66)
  lblk(fc.at(0), fc.at(1), fc.at(2), fc.at(3), p.cell, p.edge, [2#sym.times FC], none, tsize: 8pt)
  arr(((roA.anchor)("east").at(0) + 0.04, hy), (fc.at(0) - fc.at(2) / 2 - 0.04, hy), color: p.edge, w: 1.1pt, s: 0.5)

  let h_cls  = (hx + 2.05, hy + 1.05, 2.05, 0.80)
  let h_box  = (hx + 2.05, hy + 0.00, 2.05, 0.80)
  let h_mask = (hx + 2.05, hy - 1.18, 2.05, 0.92)
  lblk(h_cls.at(0),  h_cls.at(1),  h_cls.at(2),  h_cls.at(3),  rgb("#DCE6F2"), p.blue,  [classifier], [softmax · $K + 1$])
  lblk(h_box.at(0),  h_box.at(1),  h_box.at(2),  h_box.at(3),  rgb("#E7ECCF"), p.green, [box reg.],   [$4K$ deltas])
  lblk(h_mask.at(0), h_mask.at(1), h_mask.at(2), h_mask.at(3), rgb("#F2D9DD"), p.pink,  [mask head], [FCN · $K$#sym.times 28#sym.times 28], tsize: 8pt, ssize: 6.6pt)

  // FC trunk -> cls, box
  arr((fc.at(0) + fc.at(2) / 2 + 0.04, hy + 0.10), (h_cls.at(0) - h_cls.at(2) / 2 - 0.04, h_cls.at(1)), color: p.blue,  w: 1.1pt, s: 0.5)
  arr((fc.at(0) + fc.at(2) / 2 + 0.04, hy - 0.10), (h_box.at(0) - h_box.at(2) / 2 - 0.04, h_box.at(1)), color: p.green, w: 1.1pt, s: 0.5)
  // RoI feature -> mask head (skips FC; conv path)
  arr(((roA.anchor)("east").at(0) + 0.04, hy - 0.22), (h_mask.at(0) - h_mask.at(2) / 2 - 0.04, h_mask.at(1)), color: p.pink, w: 1.0pt, s: 0.5, dash: "dashed")
  draw.content((h_mask.at(0) - h_mask.at(2) / 2 - 0.10, hy - 0.62), anchor: "east", text(size: 6.5pt, fill: p.muted, style: "italic")[(Mask R-CNN)])

  // heads bracket label
  draw.content((h_cls.at(0), h_cls.at(1) + h_cls.at(3) / 2 + 0.32), text(size: 8.5pt, weight: "bold", fill: p.text)[detection heads])

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE bracket labels along the top
  // ══════════════════════════════════════════════════════════════════════════
  let tag(x1, x2, ty, body, col) = {
    draw.line((x1, ty - 0.16), (x1, ty), (x2, ty), (x2, ty - 0.16), stroke: 0.9pt + col)
    draw.content(((x1 + x2) / 2, ty + 0.26), text(size: 8pt, weight: "bold", fill: col)[#body])
  }
  tag(rpx - 0.10, prop.at(0) + prop.at(2) / 2, yc + RGW / 2 + 1.50, [Stage 1 · region proposals], p.teal)
  tag(rax - opR - 0.10, h_cls.at(0) + h_cls.at(2) / 2, hy + 1.05 + 0.40 + 0.72, [Stage 2 · RoIAlign + heads], p.garnet)

  // ── title ───────────────────────────────────────────────────────────────────
  draw.content(
    (imx, yc - imh / 2 - 1.45),
    anchor: "west",
    text(size: 11pt, weight: "bold", fill: p.garnet)[Faster R-CNN — RPN proposals + RoIAlign two-stage detector],
  )
})
