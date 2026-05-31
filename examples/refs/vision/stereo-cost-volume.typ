// mlatlas · Stereo cost volume → disparity / depth.
// A rectified stereo pair (left/right) is run through a shared feature extractor.
// For every candidate disparity d ∈ {0..D−1} the right features are shifted by d
// and matched against the left, giving a per-disparity matching cost C(d, x, y).
// Stacked over all disparities this is a D×H×W cost volume. Collapsing it along
// the disparity axis (argmin / soft-argmin) yields a per-pixel disparity map,
// which inverts to metric depth z = f·B / d.  (Szeliski; Foundations of CV.)
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// ── palette ───────────────────────────────────────────────────────────────────
#let p = (
  ink:    rgb("#1A1A1A"),
  text:   rgb("#222222"),
  muted:  rgb("#5C5C5C"),
  edge:   rgb("#243038"),
  grid:   rgb("#A2A2A2"),
  faint:  rgb("#C7C7C7"),
  beige:  rgb("#FFF2E3"),
  blue:   rgb("#466A9F"),
  green:  rgb("#65780B"),
  garnet: rgb("#73000A"),
)

// sequential ramp: beige (t=0) → garnet (t=1), interpolated in oklab.
#let ramp(t) = {
  let t = calc.max(0.0, calc.min(1.0, t))
  p.beige.mix((p.garnet, t * 100%), space: oklab)
}
#let on-fill(t) = if t > 0.58 { white } else { p.ink }

// ── synthetic scene: a near foreground box on a slanted ground plane ───────────
// disparity(x,y) field — large where near (foreground block), small far away.
#let nW = 16            // image columns (W)
#let nH = 11            // image rows    (H)
#let disp-at(x, y) = {
  let u = x / (nW - 1)
  let v = y / (nH - 1)
  // ground plane: disparity grows toward the bottom (closer ground)
  let ground = 0.18 + 0.42 * (1 - v)
  // a near rectangular object in the middle-left → high disparity plateau
  let obj = if (u > 0.20 and u < 0.58 and v > 0.28 and v < 0.78) { 0.92 } else { 0.0 }
  calc.max(ground, obj)
}

// ── geometry constants ────────────────────────────────────────────────────────
#let cw = 0.150        // small image cell width
#let ch = 0.150        // small image cell height
#let imgW = nW * cw
#let imgH = nH * ch

#cetz.canvas(length: 1cm, {
  import cetz.draw
  let arr = (end: (symbol: "stealth", fill: p.edge, scale: 0.55))
  let arr-g = (end: (symbol: "stealth", fill: p.garnet, scale: 0.6))

  // helper: render a small grayscale "image" grid at a screen origin, optionally
  // with an epipolar scanline highlighted and a feature patch marked.
  let mini-image(ox, oy, shade-fn, title, sub, line-row: none, patch: none) = {
    for j in range(nH) {
      for i in range(nW) {
        let g = (shade-fn)(i, j)                // 0 (dark) .. 1 (light) luma
        let xx = ox + i * cw
        let yy = oy + (nH - 1 - j) * ch
        draw.rect((xx, yy), (xx + cw, yy + ch),
          fill: luma(int(40 + 200 * g)), stroke: none)
      }
    }
    draw.rect((ox, oy), (ox + imgW, oy + imgH), fill: none, stroke: 0.9pt + p.edge, radius: 0pt)
    // epipolar scanline (same row in both images — rectification guarantee)
    if line-row != none {
      let yy = oy + (nH - 1 - line-row) * ch + ch / 2
      draw.line((ox - 0.10, yy), (ox + imgW + 0.10, yy), stroke: 1.1pt + p.garnet)
    }
    // matching feature patch on that scanline
    if patch != none {
      let (pi, pj) = patch
      let xx = ox + pi * cw
      let yy = oy + (nH - 1 - pj) * ch
      draw.rect((xx, yy), (xx + cw, yy + ch), fill: none, stroke: 1.4pt + p.blue, radius: 0pt)
    }
    draw.content((ox + imgW / 2, oy + imgH + 0.22), anchor: "south",
      text(size: 9.5pt, fill: p.ink, weight: "bold")[#title])
    if sub != none {
      draw.content((ox + imgW / 2, oy - 0.18), anchor: "north",
        text(size: 7.5pt, fill: p.muted, style: "italic")[#sub])
    }
  }

  // luma fields for the pair: left & right differ only by a horizontal shift that
  // scales with disparity (closer = larger shift). Brightness ~ a textured scene.
  let scene-luma(i, j) = {
    let d = disp-at(i, j)
    // soft texture so the images read as photos, brighter on the near object
    let tex = 0.5 + 0.32 * calc.sin(i * 0.9 + j * 0.6) * calc.cos(i * 0.4)
    0.30 + 0.55 * (0.4 * d + 0.6 * tex)
  }
  let left-luma(i, j) = scene-luma(i, j)
  let right-luma(i, j) = {
    // right image: each point appears shifted LEFT by its disparity (px≈cells)
    let dpx = calc.round(disp-at(i, j) * 4)
    scene-luma(calc.min(nW - 1, i + dpx), j)
  }

  // ════════════════════════════════════════════════════════════════════════
  // (A) rectified stereo pair, stacked vertically on the far left
  // ════════════════════════════════════════════════════════════════════════
  let row-hl = 6            // highlighted epipolar row
  mini-image(0, 4.7, left-luma,  [Left image $I_L$],  [reference],
    line-row: row-hl, patch: (7, row-hl))
  mini-image(0, 1.6, right-luma, [Right image $I_R$], [search along same row],
    line-row: row-hl, patch: (4, row-hl))
  // brace tying the pair together as a rectified pair
  draw.content((imgW / 2, 1.05), anchor: "north",
    text(size: 8pt, fill: p.green, style: "italic")[rectified · epipolar lines horizontal])
  // disparity = horizontal offset of the matched patch
  draw.line((0.7, 4.7 - 0.30), (0.4, 4.7 - 0.30), stroke: 1.0pt + p.blue, mark: (start: (symbol: "stealth", fill: p.blue, scale: 0.5)))
  draw.content((0.55, 4.7 - 0.52), anchor: "north",
    text(size: 7.5pt, fill: p.blue)[$d$ = shift])

  // ════════════════════════════════════════════════════════════════════════
  // (B) shared feature extractor → two feature-map slabs
  // ════════════════════════════════════════════════════════════════════════
  let fx = imgW + 0.95     // x of feature slabs
  // arrows from the two images into the encoder
  draw.line((imgW + 0.10, 4.7 + imgH / 2), (fx - 0.55, 4.7 + imgH / 2 - 0.05), stroke: 1.0pt + p.edge, mark: arr)
  draw.line((imgW + 0.10, 1.6 + imgH / 2), (fx - 0.55, 1.6 + imgH / 2 + 0.05), stroke: 1.0pt + p.edge, mark: arr)
  // shared-weights encoder tag
  draw.content((fx - 0.30, 4.05), anchor: "center", angle: 90deg,
    text(size: 7.5pt, fill: p.muted)[shared CNN $f_θ$])

  feature-map(draw, (fx + 0.05, 4.7 + imgH / 2), spatial: 96, channels: 64, base: rgb("#D9E1EE"), edge: p.edge, cam: cam-cabinet)
  feature-map(draw, (fx + 0.05, 1.6 + imgH / 2), spatial: 96, channels: 64, base: rgb("#D9E1EE"), edge: p.edge, cam: cam-cabinet)
  draw.content((fx + 0.05, 4.7 + imgH + 0.12), anchor: "south", text(size: 8pt, fill: p.text)[$F_L$])
  draw.content((fx + 0.05, 1.6 - 0.16), anchor: "north", text(size: 8pt, fill: p.text)[$F_R$])

  // ════════════════════════════════════════════════════════════════════════
  // (C) build the D×H×W cost volume (concat / correlate F_L with shifted F_R)
  // ════════════════════════════════════════════════════════════════════════
  let cvo = (fx + 2.75, 4.05)        // cost-volume origin (screen)
  // funnel arrows from both slabs into the cost volume
  draw.line((fx + 0.55, 4.7 + imgH / 2), (cvo.at(0) - 1.20, cvo.at(1) + 0.55), stroke: 1.0pt + p.edge, mark: arr)
  draw.line((fx + 0.55, 1.6 + imgH / 2), (cvo.at(0) - 1.20, cvo.at(1) - 0.55), stroke: 1.0pt + p.edge, mark: arr)
  draw.content((fx + 0.85, 3.62), anchor: "center",
    text(size: 7pt, fill: p.muted, style: "italic")[for each $d$:\ shift $F_R$ by $d$,\ match $F_L$])

  // the labeled D×H×W tensor — disparity is the DEPTH axis, sliced by seams
  let cv-w = 2.0     // → W
  let cv-h = 2.3     // → H
  let cv-d = 1.7     // → D (disparity)
  tensor3d(draw,
    origin: cvo, w: cv-w, h: cv-h, dep: cv-d,
    base: rgb("#FBE7D2"), edge: p.edge, cam: cam-iso,
    seams: (0.2, 0.4, 0.6, 0.8),
    x-label: [W], y-label: [H], z-label: [D disparities],
    title: [cost volume $C(d, x, y)$],
    muted: p.muted, text-fill: p.text,
  )
  // a garnet matching-cost "fiber": the column of costs C(·, x, y) along D for one pixel
  let pc = projector(cam: cam-iso, origin: cvo)
  let fx0 = -cv-w / 2 + 0.62 * cv-w
  let fy0 = -cv-h / 2 + 0.40 * cv-h
  draw.line(pc((fx0, fy0, -cv-d / 2)), pc((fx0, fy0, cv-d / 2)), stroke: 1.8pt + p.garnet)
  draw.circle(pc((fx0, fy0, -cv-d / 2)), radius: 0.045, fill: p.garnet, stroke: none)
  draw.circle(pc((fx0, fy0, cv-d / 2)), radius: 0.045, fill: p.garnet, stroke: none)
  // label the fiber via a leader line out to the right, clear of other text
  let fib-end = pc((fx0, fy0, cv-d / 2))
  let fib-lbl = (cvo.at(0) + 2.05, cvo.at(1) - 1.05)
  draw.line(fib-end, fib-lbl, stroke: 0.7pt + p.garnet)
  draw.content((fib-lbl.at(0) + 0.05, fib-lbl.at(1)), anchor: "west",
    text(size: 7.5pt, fill: p.garnet, style: "italic")[cost fiber $C(·,x,y)$])

  // ════════════════════════════════════════════════════════════════════════
  // (D) tiny cost-vs-disparity curve: the fiber's profile, argmin = match
  // ════════════════════════════════════════════════════════════════════════
  let px0 = cvo.at(0) - 0.2
  let py0 = 1.05
  let pw = 2.2
  let ph = 1.20
  // axes
  draw.line((px0, py0), (px0 + pw, py0), stroke: 0.8pt + p.edge, mark: arr)
  draw.line((px0, py0), (px0, py0 + ph), stroke: 0.8pt + p.edge, mark: arr)
  draw.content((px0 + pw + 0.05, py0), anchor: "west", text(size: 7.5pt, fill: p.muted)[$d$])
  draw.content((px0 - 0.10, py0 + ph), anchor: "south-east", angle: 90deg, text(size: 7.5pt, fill: p.muted)[cost])
  // a U-shaped cost profile with a clear minimum (the true disparity d*)
  let nD = 24
  let dmin = 0.40           // location of minimum (fraction of axis)
  // cost rises away from the minimum
  let cost-of(t) = {
    let base = calc.pow((t - dmin) / 0.5, 2)
    0.12 + 0.80 * calc.min(1.0, base)
  }
  let curve = range(nD + 1).map(k => {
    let t = k / nD
    (px0 + t * pw, py0 + cost-of(t) * ph)
  })
  draw.line(..curve, stroke: 1.3pt + p.blue)
  // mark the argmin
  let mx = px0 + dmin * pw
  let my = py0 + cost-of(dmin) * ph
  draw.line((mx, py0), (mx, my), stroke: (paint: p.garnet, thickness: 0.8pt, dash: "dashed"))
  draw.circle((mx, my), radius: 0.05, fill: p.garnet, stroke: none)
  draw.content((mx, py0 - 0.12), anchor: "north", text(size: 7pt, fill: p.garnet)[$d^*$])
  draw.content((px0 + pw / 2 - 0.35, py0 + ph + 0.20), anchor: "south",
    text(size: 7.5pt, fill: p.text, style: "italic")[$d^*(x,y) = arg min_d C(d,x,y)$])

  // ════════════════════════════════════════════════════════════════════════
  // (E) collapse along D → disparity / depth map (colormesh heatmap)
  // ════════════════════════════════════════════════════════════════════════
  let dispo = (cvo.at(0) + 3.7, 3.05)      // disparity-map origin
  // big arrow from the cost volume into the disparity map
  draw.line((cvo.at(0) + 1.7, cvo.at(1) - 0.1), (dispo.at(0) - 0.55, dispo.at(1) + imgH / 2), stroke: 1.6pt + p.garnet, mark: arr-g)
  draw.content(((cvo.at(0) + 1.7 + dispo.at(0) - 0.55) / 2, dispo.at(1) + imgH / 2 + 0.62), anchor: "center",
    text(size: 7.5pt, fill: p.garnet, weight: "bold")[soft-argmin\ over $D$])

  // disparity heatmap (beige→garnet ramp: dark = near/large disparity)
  for j in range(nH) {
    for i in range(nW) {
      let t = disp-at(i, j)
      let xx = dispo.at(0) + i * cw
      let yy = dispo.at(1) + (nH - 1 - j) * ch
      draw.rect((xx, yy), (xx + cw, yy + ch), fill: ramp(t), stroke: none)
    }
  }
  draw.rect((dispo.at(0), dispo.at(1)), (dispo.at(0) + imgW, dispo.at(1) + imgH), fill: none, stroke: 0.9pt + p.edge, radius: 0pt)
  draw.content((dispo.at(0) + imgW / 2, dispo.at(1) + imgH + 0.22), anchor: "south",
    text(size: 9.5pt, fill: p.ink, weight: "bold")[Disparity map $d(x,y)$])
  draw.content((dispo.at(0) + imgW / 2, dispo.at(1) - 0.18), anchor: "north",
    text(size: 7.5pt, fill: p.muted, style: "italic")[depth $z = f B \/ d$])

  // colorbar for the disparity map
  let bx = dispo.at(0) + imgW + 0.28
  let bw = 0.30
  let nseg = 32
  for s in range(nseg) {
    let t0 = s / nseg
    let t1 = (s + 1) / nseg
    draw.rect((bx, dispo.at(1) + t0 * imgH), (bx + bw, dispo.at(1) + t1 * imgH),
      fill: ramp((t0 + t1) / 2), stroke: none)
  }
  draw.rect((bx, dispo.at(1)), (bx + bw, dispo.at(1) + imgH), fill: none, stroke: 0.7pt + p.edge, radius: 0pt)
  draw.content((bx + bw + 0.10, dispo.at(1) + imgH), anchor: "west", text(size: 7pt, fill: p.muted)[near (large $d$)])
  draw.content((bx + bw + 0.10, dispo.at(1)), anchor: "west", text(size: 7pt, fill: p.muted)[far (small $d$)])
})
