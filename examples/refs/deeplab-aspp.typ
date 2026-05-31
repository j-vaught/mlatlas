// mlatlas · Atrous Spatial Pyramid Pooling (DeepLab ASPP segmentation head).
// One backbone feature map is probed in parallel by several atrous (dilated)
// convolutions at increasing rates r = 6 / 12 / 18, plus a global image-level
// pooling branch and a 1×1 conv. Atrous convolution inserts r−1 holes between
// kernel taps, enlarging the receptive field WITHOUT downsampling or extra
// parameters, so each branch sees a different spatial context. The five branch
// outputs are concatenated and fused by a 1×1 conv, which a low-stride decoder
// turns into a dense per-pixel class map. A dilated-kernel inset (top-left)
// shows the r = 2 sampling pattern: 3×3 taps spread over a 5×5 footprint.
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
    slab:   rgb("#ECECEC"),     // backbone feature-map slab
    beige:  rgb("#FFF2E3"),
    garnet: rgb("#73000A"),     // focal accent (concat / fused head)
    blue:   rgb("#466A9F"),
    green:  rgb("#65780B"),
    lime:   rgb("#CED318"),
    brown:  rgb("#A49137"),
  )

  // ── helpers ───────────────────────────────────────────────────────────────
  let arr(a, b, w: 1.1pt, color: p.edge, s: 0.5, dash: none) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: s),
  )
  // labelled op block by centre + (w, h)
  let opbox(cx, cy, w, h, fill, scol, title, sub) = {
    draw.rect(
      (cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
      fill: fill, stroke: 1.3pt + scol, radius: 0pt,
    )
    draw.content((cx, cy + 0.16), text(size: 8.5pt, weight: "bold", fill: p.text)[#title])
    draw.content((cx, cy - 0.20), text(size: 7pt, fill: p.muted)[#sub])
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Backbone feature-map slab (left) — the shared input to every branch
  // ══════════════════════════════════════════════════════════════════════════
  let sx = 0.0                  // slab left edge
  let syc = 0.0                 // slab vertical centre
  let sgn = 5                   // 5 × 5 cells
  let sgc = 0.40                // cell side (cm)
  let SW = sgn * sgc
  let sy0 = syc - SW / 2
  for i in range(sgn) {
    for j in range(sgn) {
      draw.rect(
        (sx + i * sgc, sy0 + j * sgc), (sx + (i + 1) * sgc, sy0 + (j + 1) * sgc),
        fill: p.slab, stroke: 0.5pt + p.grid, radius: 0pt,
      )
    }
  }
  draw.rect((sx, sy0), (sx + SW, sy0 + SW), fill: none, stroke: 1.2pt + p.edge, radius: 0pt)
  draw.content((sx + SW / 2, sy0 + SW + 0.32), text(size: 9pt, weight: "bold", fill: p.text)[backbone features])
  draw.content((sx + SW / 2, sy0 - 0.30), text(size: 7.5pt, fill: p.muted, style: "italic")[$H slash 16 times W slash 16 times C$])

  // ══════════════════════════════════════════════════════════════════════════
  //  Dilated-kernel inset (top-left): 3×3 taps spread over a 5×5 grid (r = 2)
  // ══════════════════════════════════════════════════════════════════════════
  let kx = sx - 0.10            // inset left edge
  let kyc = syc + SW / 2 + 2.55 // above the slab
  let kgn = 5
  let kgc = 0.34
  let KW = kgn * kgc
  let ky0 = kyc - KW / 2
  for i in range(kgn) {
    for j in range(kgn) {
      // active taps every 2nd cell (r = 2): i,j ∈ {0,2,4}
      let active = calc.rem(i, 2) == 0 and calc.rem(j, 2) == 0
      draw.rect(
        (kx + i * kgc, ky0 + j * kgc), (kx + (i + 1) * kgc, ky0 + (j + 1) * kgc),
        fill: if active { p.garnet } else { white }, stroke: 0.5pt + p.grid, radius: 0pt,
      )
    }
  }
  draw.rect((kx, ky0), (kx + KW, ky0 + KW), fill: none, stroke: 1.0pt + p.edge, radius: 0pt)
  draw.content((kx + KW / 2, ky0 + KW + 0.30), text(size: 8pt, weight: "bold", fill: p.text)[atrous kernel])
  draw.content((kx + KW / 2, ky0 - 0.28), text(size: 7pt, fill: p.muted, style: "italic")[$3 times 3$ taps, rate $r = 2$])
  // small legend dot
  draw.rect((kx + KW + 0.18, ky0 + KW - 0.34), (kx + KW + 0.44, ky0 + KW - 0.08), fill: p.garnet, stroke: 0.5pt + p.edge, radius: 0pt)
  draw.content((kx + KW + 0.52, ky0 + KW - 0.21), anchor: "west", text(size: 6.5pt, fill: p.muted)[sampled])
  draw.rect((kx + KW + 0.18, ky0 + KW - 0.78), (kx + KW + 0.44, ky0 + KW - 0.52), fill: white, stroke: 0.5pt + p.edge, radius: 0pt)
  draw.content((kx + KW + 0.52, ky0 + KW - 0.65), anchor: "west", text(size: 6.5pt, fill: p.muted)[hole])

  // ══════════════════════════════════════════════════════════════════════════
  //  Parallel branches (middle column): five op-nodes stacked vertically
  // ══════════════════════════════════════════════════════════════════════════
  let bx = sx + SW + 2.35       // branch column centre x
  let bw = 2.20                 // branch box width
  let bh = 0.78                 // branch box height
  let bvs = 1.06                // vertical pitch between branches
  // top → bottom: 1×1 conv, atrous r=6, r=12, r=18, image pool
  let branches = (
    (p.beige, p.edge,   [$1 times 1$ conv],   [rate $r = 1$]),
    (rgb("#EAF0F6"), p.blue,  [atrous conv], [$3 times 3$, $r = 6$]),
    (rgb("#EAF0F6"), p.blue,  [atrous conv], [$3 times 3$, $r = 12$]),
    (rgb("#EAF0F6"), p.blue,  [atrous conv], [$3 times 3$, $r = 18$]),
    (rgb("#EEF1D8"), p.green, [image pool], [global avg]),
  )
  let nB = branches.len()
  // vertically centre the stack on syc
  let by0 = syc + (nB - 1) * bvs / 2
  let bcy = ()
  for k in range(nB) { bcy.push(by0 - k * bvs) }

  for (k, b) in branches.enumerate() {
    opbox(bx, bcy.at(k), bw, bh, b.at(0), b.at(1), b.at(2), b.at(3))
  }

  // fan-out: slab east edge → each branch west edge
  let slab-e = (sx + SW, syc)
  for k in range(nB) {
    let col = if k == 0 { p.edge } else if k == nB - 1 { p.green } else { p.blue }
    arr(slab-e, (bx - bw / 2, bcy.at(k)), color: col, w: 1.0pt, s: 0.45)
  }
  draw.content((sx + SW + 1.02, by0 + 0.92), anchor: "south", text(size: 7pt, fill: p.muted, style: "italic")[same input,\ five contexts])

  // ══════════════════════════════════════════════════════════════════════════
  //  Concat node → 1×1 fuse conv (right column)
  // ══════════════════════════════════════════════════════════════════════════
  let cx = bx + bw / 2 + 2.05   // concat node centre x
  let ccy = syc                 // concat vertical centre
  let cr = 0.42                 // concat node radius
  draw.circle((cx, ccy), radius: cr, fill: p.beige, stroke: 1.6pt + p.garnet)
  draw.content((cx, ccy), text(size: 11pt, weight: "bold", fill: p.garnet)[$⊕$])
  draw.content((cx, ccy - cr - 0.26), text(size: 7.5pt, fill: p.garnet, weight: "bold")[concat])
  draw.content((cx, ccy + cr + 0.24), text(size: 6.5pt, fill: p.muted, style: "italic")[$5 C'$ ch])

  // each branch east edge → concat node
  for k in range(nB) {
    let col = if k == 0 { p.edge } else if k == nB - 1 { p.green } else { p.blue }
    arr((bx + bw / 2, bcy.at(k)), (cx - cr - 0.02, ccy), color: col, w: 1.0pt, s: 0.45)
  }

  // concat → 1×1 fuse conv
  let fx = cx + 1.95            // fuse conv centre x
  let fw = 1.70
  let fh = 0.88
  arr((cx + cr, ccy), (fx - fw / 2, ccy), color: p.garnet, w: 1.4pt, s: 0.55)
  draw.rect(
    (fx - fw / 2, ccy - fh / 2), (fx + fw / 2, ccy + fh / 2),
    fill: p.beige, stroke: 1.6pt + p.garnet, radius: 0pt,
  )
  draw.content((fx, ccy + 0.17), text(size: 8.5pt, weight: "bold", fill: p.garnet)[$1 times 1$ conv])
  draw.content((fx, ccy - 0.20), text(size: 7pt, fill: p.muted)[fuse $#sym.arrow.r C'$])

  // ══════════════════════════════════════════════════════════════════════════
  //  Output segmentation heatmap (far right) — dense per-pixel class map
  // ══════════════════════════════════════════════════════════════════════════
  let hx = fx + fw / 2 + 1.45   // heatmap left edge
  let hgn = 7
  let hgc = 0.33
  let HW = hgn * hgc
  let hy0 = syc - HW / 2
  // class-id field (3 classes) → distinct hues, painting a simple "object" blob
  // 0 = background, 1 = object A (garnet), 2 = object B (blue)
  let seg = (
    (0, 0, 0, 0, 0, 0, 0),
    (0, 0, 1, 1, 0, 0, 0),
    (0, 1, 1, 1, 1, 0, 0),
    (0, 1, 1, 1, 1, 2, 0),
    (0, 0, 1, 1, 2, 2, 2),
    (0, 0, 0, 2, 2, 2, 0),
    (0, 0, 0, 0, 2, 0, 0),
  )
  let segcol = (rgb("#ECECEC"), p.garnet, p.blue)
  for r in range(hgn) {
    for c in range(hgn) {
      let id = seg.at(r).at(c)
      let xx = hx + c * hgc
      // row 0 at top → flip
      let yy = hy0 + (hgn - 1 - r) * hgc
      draw.rect((xx, yy), (xx + hgc, yy + hgc), fill: segcol.at(id), stroke: 0.4pt + white, radius: 0pt)
    }
  }
  draw.rect((hx, hy0), (hx + HW, hy0 + HW), fill: none, stroke: 1.2pt + p.edge, radius: 0pt)
  draw.content((hx + HW / 2, hy0 + HW + 0.30), text(size: 9pt, weight: "bold", fill: p.text)[per-pixel labels])
  draw.content((hx + HW / 2, hy0 - 0.30), text(size: 7.5pt, fill: p.muted, style: "italic")[$H times W times K$])

  // fuse conv → upsample → heatmap
  arr((fx + fw / 2, ccy), (hx - 0.02, ccy), color: p.edge, w: 1.2pt, s: 0.55)
  draw.content(((fx + fw / 2 + hx) / 2, ccy + 0.24), text(size: 6.5pt, fill: p.muted, style: "italic")[upsample])

  // ── title ─────────────────────────────────────────────────────────────────
  let topY = kyc + KW / 2 + 0.70
  draw.content(
    (sx - 0.20, topY), anchor: "west",
    text(size: 11pt, weight: "bold", fill: p.garnet)[Atrous Spatial Pyramid Pooling (ASPP) — DeepLab segmentation head],
  )
})
