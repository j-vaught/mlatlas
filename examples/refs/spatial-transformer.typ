// mlatlas · Spatial Transformer Network (STN) — a learnable, differentiable module
// that lets a network actively spatially transform its own feature maps. Three parts:
// (1) a LOCALIZATION NET (a small MLP / conv stack) reads the input feature map U and
// regresses the parameters theta of a transformation T_theta (here a 2x3 affine).
// (2) a GRID GENERATOR turns theta into a sampling grid: for every output pixel
// (x_t, y_t) it computes the source coordinate (x_s, y_s) = T_theta(x_t, y_t). (3) a
// BILINEAR SAMPLER reads U at those (generally non-integer) source points, each value an
// interpolation of the 4 nearest input pixels, producing the warped output V. Every step
// is differentiable, so theta is learned end-to-end by backprop. Left -> right pipeline,
// with an inset that shows the regular output grid mapped back onto the warped input grid.
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
    garnet: rgb("#73000A"),     // focal accent (grid generator / sampling)
    blue:   rgb("#466A9F"),     // localization / theta branch
    green:  rgb("#65780B"),     // output / sampled values
    pink:   rgb("#CC2E40"),     // sample point accent
  )

  // ── helpers ───────────────────────────────────────────────────────────────
  let arr(a, b, w: 1.2pt, color: p.edge, s: 0.6, dash: none) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: s),
  )
  let lblk(cx, cy, w, h, fill, scol, title, sub, tsize: 8.5pt, ssize: 6.8pt) = {
    draw.rect(
      (cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
      fill: fill, stroke: 1.2pt + scol, radius: 0pt,
    )
    if sub == none {
      draw.content((cx, cy), text(size: tsize, weight: "bold", fill: p.text)[#title])
    } else {
      draw.content((cx, cy + h / 4), text(size: tsize, weight: "bold", fill: p.text)[#title])
      draw.content((cx, cy - h / 4), text(size: ssize, fill: p.muted)[#sub])
    }
  }

  let yc = 0.0   // pipeline centre line

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 0 — input feature map  U  (C × H × W)
  // ══════════════════════════════════════════════════════════════════════════
  let ux = 0.0
  feature-map(draw, (ux, yc), spatial: 64, channels: 32, base: rgb("#DCE6F2"), edge: p.edge, cam: cam-cabinet, relu: true)
  let uA = block3d-anchors(origin: (ux, yc), w: 0.34, h: 1.55, dep: 1.75, cam: cam-cabinet)
  let uE = (uA.anchor)("east").at(0)
  draw.content((ux + 0.10, yc + 1.55), text(size: 9pt, weight: "bold", fill: p.text)[input  $U$])
  draw.content((ux + 0.10, yc - 1.62), text(size: 6.8pt, fill: p.muted, style: "italic")[$C times H times W$])

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 1 — localization net (small MLP/conv) -> theta  (2×3 affine)
  // ══════════════════════════════════════════════════════════════════════════
  let lx = uE + 1.55           // localization-net box centre-x
  let loc = (lx, yc, 1.95, 1.05)
  lblk(loc.at(0), loc.at(1), loc.at(2), loc.at(3), rgb("#DCE6F2"), p.blue, [localization], [net  $f_(text("loc"))$])
  arr((uE + 0.06, yc), (loc.at(0) - loc.at(2) / 2 - 0.04, yc), color: p.edge, w: 1.3pt)
  draw.content((loc.at(0), loc.at(1) - loc.at(3) / 2 - 0.30), text(size: 6.6pt, fill: p.muted, style: "italic")[conv / FC regressor])

  // theta — the regressed 2×3 affine matrix (focal-ish, blue branch terminus)
  let thx = loc.at(0) + loc.at(2) / 2 + 1.55
  draw.rect((thx - 1.05, yc - 0.62), (thx + 1.05, yc + 0.62), fill: p.hot, stroke: 1.2pt + p.blue, radius: 0pt)
  draw.content((thx, yc + 0.86), text(size: 8.5pt, weight: "bold", fill: p.text)[$theta$  (affine)])
  draw.content((thx, yc), text(size: 8.5pt, fill: p.text)[
    $mat(delim: "[", theta_11, theta_12, theta_13; theta_21, theta_22, theta_23)$
  ])
  arr((loc.at(0) + loc.at(2) / 2 + 0.04, yc), (thx - 1.05 - 0.04, yc), color: p.blue, w: 1.2pt, s: 0.55)
  draw.content(((loc.at(0) + loc.at(2) / 2 + thx - 1.05) / 2, yc + 0.26), text(size: 6.6pt, fill: p.blue, style: "italic")[regress])

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 2 — grid generator (op-node): (x_t,y_t) -> (x_s,y_s) = T_theta(x_t,y_t)
  // ══════════════════════════════════════════════════════════════════════════
  let gx = thx + 1.05 + 1.55     // grid-generator op centre-x
  let opR = 0.74
  draw.circle((gx, yc), radius: opR, fill: p.garnet, stroke: 1.3pt + p.garnet.darken(15%))
  draw.content((gx, yc), text(size: 8pt, weight: "bold", fill: white)[grid\ gen.])
  arr((thx + 1.05 + 0.04, yc), (gx - opR - 0.04, yc), color: p.blue, w: 1.2pt, s: 0.55)
  draw.content((gx, yc - opR - 0.30), text(size: 6.6pt, fill: p.garnet, style: "italic")[$T_theta$])
  draw.content((gx, yc + opR + 0.34), text(size: 6.8pt, fill: p.muted, style: "italic")[$mat(delim: "(", x_s; y_s) = theta dot.c mat(delim: "(", x_t; y_t; 1)$])

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 3 — bilinear sampler (op-node): reads U at (x_s,y_s) -> output V
  // ══════════════════════════════════════════════════════════════════════════
  let sx = gx + opR + 1.55       // sampler op centre-x
  draw.circle((sx, yc), radius: opR, fill: p.garnet, stroke: 1.3pt + p.garnet.darken(15%))
  draw.content((sx, yc), text(size: 8pt, weight: "bold", fill: white)[bilinear\ sampler])
  arr((gx + opR + 0.04, yc), (sx - opR - 0.04, yc), color: p.garnet, w: 1.2pt, s: 0.55)
  draw.content((gx + opR + 0.74, yc + 0.26), text(size: 6.6pt, fill: p.muted, style: "italic")[sampling grid])
  // U also feeds the sampler (the source signal being read) — curved skip feed from U
  draw.bezier(
    (uE + 0.10, yc - 1.10), (sx, yc - opR - 0.04), (ux + 1.2, yc - 2.55), (sx - 0.30, yc - 2.10),
    stroke: (paint: p.faint, thickness: 1.0pt), mark: (end: "stealth", scale: 0.5),
  )
  draw.content((ux + 2.5, yc - 2.32), anchor: "south", text(size: 6.6pt, fill: p.muted, style: "italic")[feature map  $U$  (sampled)])

  // ══════════════════════════════════════════════════════════════════════════
  //  STAGE 4 — output feature map  V  (warped)
  // ══════════════════════════════════════════════════════════════════════════
  let vx = sx + opR + 1.45
  feature-map(draw, (vx, yc), spatial: 64, channels: 32, base: rgb("#E7ECCF"), edge: p.edge, cam: cam-cabinet, relu: true)
  let vA = block3d-anchors(origin: (vx, yc), w: 0.34, h: 1.55, dep: 1.75, cam: cam-cabinet)
  draw.content((vx + 0.10, yc + 1.55), text(size: 9pt, weight: "bold", fill: p.text)[output  $V$])
  draw.content((vx + 0.10, yc - 1.62), text(size: 6.8pt, fill: p.muted, style: "italic")[warped  $C times H' times W'$])
  arr((sx + opR + 0.04, yc), ((vA.anchor)("west").at(0) - 0.06, yc), color: p.green, w: 1.2pt, s: 0.55)

  // ══════════════════════════════════════════════════════════════════════════
  //  INSET — output grid (regular) mapped back onto the warped sampling grid in U
  // ══════════════════════════════════════════════════════════════════════════
  let inx = gx - 0.95          // inset block left
  let iny = yc - 6.30          // inset baseline (well below pipeline + title)
  let n = 4                    // 4×4 grid of bins
  let c = 0.50                 // cell size

  // --- left panel: regular OUTPUT grid V (target lattice) ---
  let ox0 = inx
  let oy0 = iny
  for i in range(n + 1) {
    draw.line((ox0 + i * c, oy0), (ox0 + i * c, oy0 + n * c), stroke: 0.7pt + p.grid)
    draw.line((ox0, oy0 + i * c), (ox0 + n * c, oy0 + i * c), stroke: 0.7pt + p.grid)
  }
  // one focal target pixel (x_t, y_t)
  let tpx = ox0 + 2.5 * c
  let tpy = oy0 + 1.5 * c
  draw.circle((tpx, tpy), radius: 0.07, fill: p.green, stroke: none)
  draw.content((ox0 + n * c / 2, oy0 + n * c + 0.30), text(size: 7.5pt, weight: "bold", fill: p.text)[output grid  $V$])
  draw.content((ox0 + n * c / 2, oy0 - 0.28), text(size: 6.6pt, fill: p.muted, style: "italic")[regular target lattice  $(x_t, y_t)$])

  // arrow between panels labelled T_theta
  let mid0 = ox0 + n * c + 0.45
  let mid1 = mid0 + 1.05
  arr((mid0, oy0 + n * c / 2), (mid1, oy0 + n * c / 2), color: p.garnet, w: 1.2pt, s: 0.55)
  draw.content(((mid0 + mid1) / 2, oy0 + n * c / 2 + 0.28), text(size: 7pt, fill: p.garnet, style: "italic")[$T_theta$])
  draw.content(((mid0 + mid1) / 2, oy0 + n * c / 2 - 0.26), text(size: 6.2pt, fill: p.muted, style: "italic")[warp])

  // --- right panel: warped sampling grid over input U (affine-deformed) ---
  // apply a fixed affine (rotation + shear + scale) to each lattice node for illustration
  let wx0 = mid1 + 0.55
  let wy0 = iny
  // affine params (display only): rotate ~ -16°, slight shear + scale
  let a11 = 0.88; let a12 = 0.26
  let a21 = -0.24; let a22 = 0.84
  let cx = wx0 + n * c / 2
  let cy = wy0 + n * c / 2
  let warp(i, j) = {
    let lx0 = (i - n / 2) * c
    let ly0 = (j - n / 2) * c
    (cx + a11 * lx0 + a12 * ly0, cy + a21 * lx0 + a22 * ly0)
  }
  // light backing input cells (regular, faint) so the deformation reads against U
  for i in range(n) {
    for j in range(n) {
      draw.rect(
        (wx0 + i * c, wy0 + j * c), (wx0 + (i + 1) * c, wy0 + (j + 1) * c),
        fill: p.cell, stroke: 0.5pt + p.grid.lighten(20%), radius: 0pt,
      )
    }
  }
  // deformed sampling grid (garnet lines)
  for i in range(n + 1) {
    // verticals
    let pts = range(n + 1).map(j => warp(i, j))
    for k in range(n) {
      draw.line(pts.at(k), pts.at(k + 1), stroke: 0.9pt + p.garnet)
    }
    // horizontals
    let pth = range(n + 1).map(jj => warp(jj, i))
    for k in range(n) {
      draw.line(pth.at(k), pth.at(k + 1), stroke: 0.9pt + p.garnet)
    }
  }
  // the source point (x_s, y_s) = T_theta(x_t, y_t) — image of the focal target pixel
  let sp = warp(2.5, 1.5)
  draw.circle(sp, radius: 0.07, fill: p.pink, stroke: none)
  // its 4 nearest INPUT-pixel centres + bilinear spokes
  let gi = calc.floor((sp.at(0) - wx0) / c - 0.5)
  let gj = calc.floor((sp.at(1) - wy0) / c - 0.5)
  for di in (0, 1) {
    for dj in (0, 1) {
      let ccx = wx0 + (gi + di + 0.5) * c
      let ccy = wy0 + (gj + dj + 0.5) * c
      draw.line(sp, (ccx, ccy), stroke: (paint: p.pink.transparentize(40%), thickness: 0.6pt))
      draw.circle((ccx, ccy), radius: 0.035, fill: p.muted, stroke: none)
    }
  }
  draw.content((cx, wy0 + n * c + 0.30), text(size: 7.5pt, weight: "bold", fill: p.text)[sampling grid on  $U$])
  draw.content((cx, wy0 - 0.28), text(size: 6.6pt, fill: p.garnet, style: "italic")[source coords  $(x_s, y_s)$])
  draw.content((cx, wy0 - 0.58), text(size: 6.2pt, fill: p.muted, style: "italic")[$V(x_t,y_t)$ = bilinear of 4 nearest  $U$  pixels])

  // legend connecting focal points: target pixel -> source pixel
  draw.content((tpx, tpy + 0.20), anchor: "south", text(size: 6pt, fill: p.green)[$(x_t,y_t)$])

  // ── title ───────────────────────────────────────────────────────────────────
  draw.content(
    (ux - 0.55, yc - 3.05),
    anchor: "west",
    text(size: 11pt, weight: "bold", fill: p.garnet)[Spatial Transformer — localization net  $arrow.r$  grid generator  $arrow.r$  bilinear sampler],
  )
  draw.content(
    (ux - 0.55, yc - 3.55),
    anchor: "west",
    text(size: 8pt, fill: p.muted, style: "italic")[a differentiable module for spatial attention: $theta$ is learned end-to-end by backprop],
  )
})
