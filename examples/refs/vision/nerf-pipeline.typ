// NeRF — Neural Radiance Fields: the volumetric rendering pipeline.
//   A scene is represented by a single MLP  F_Θ : (x, d) ↦ (c, σ)  that maps a 5-D input
//   — a 3-D position  x = (x,y,z)  and a 2-D viewing direction  d = (θ,φ) — to an emitted
//   RGB colour  c  and a volume density  σ. To render one pixel: cast the camera ray
//   r(t) = o + t·d through that pixel, draw N sample points x_i = r(t_i) along it, lift
//   each through a positional encoding γ(·), and query F_Θ at every sample. The resulting
//   (c_i, σ_i) are alpha-composited along the ray by the discrete volume-rendering integral
//        C(r) = Σ_i T_i (1 − e^{−σ_i δ_i}) c_i ,   T_i = e^{−Σ_{j<i} σ_j δ_j} ,
//   which accumulates colour weighted by transmittance T_i and opacity, giving the pixel.
//   Left: the 3-D ray-field scene (camera, image plane, ray, samples) over mlatlas's
//   orthographic projector. Right: the per-sample network + the rendering integral.
//   Standard NeRF teaching figure, built from scratch in mlatlas's print-first style.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ─────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent — the camera ray and the MLP
#let blue   = rgb("#466A9F")   // view direction / encoded inputs
#let green  = rgb("#65780B")   // density σ / transmittance
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let grid-c = rgb("#ECECEC")
#let beige  = rgb("#FFF2E3")

// ── scene camera (axonometric: pitch, yaw, roll) — looking down onto the rig ────
#let cam = (16deg, -30deg, 0deg)
#let pj(p) = project(p, cam: cam)

// ── world geometry (scene units) ────────────────────────────────────────────────
//   Camera centre o; ray goes from o through the image plane into a density volume.
#let o   = (-4.6, 0.4, 0.0)        // camera centre / ray origin  o
#let dir = (1.0, 0.0, 0.0)         // ray direction  d  (toward +x)

// image plane: a small upright retina one focal length ahead of o
#let f  = 1.5
#let pw = 1.05                     // half width
#let ph = 1.05                     // half height
#let ppc = (o.at(0) + f, o.at(1), o.at(2))   // principal point (plane centre)
// the pixel we are rendering sits slightly off-centre on the retina
#let pix = (ppc.at(0), o.at(1), o.at(2))
// image-plane corners (in the y–z plane, facing +x): TL TR BR BL
#let plane-corner(u, v) = (ppc.at(0), ppc.at(1) + v, ppc.at(2) + u)
#let pc-TL = plane-corner(-pw,  ph)
#let pc-TR = plane-corner( pw,  ph)
#let pc-BR = plane-corner( pw, -ph)
#let pc-BL = plane-corner(-pw, -ph)

// ── the density volume the ray passes through (a box of "stuff") ────────────────
#let vmin = (0.4, -1.2, -1.2)
#let vmax = (3.6,  1.2,  1.2)
#let vcorner(i, j, k) = (
  if i == 0 { vmin.at(0) } else { vmax.at(0) },
  if j == 0 { vmin.at(1) } else { vmax.at(1) },
  if k == 0 { vmin.at(2) } else { vmax.at(2) },
)

// ── N sample points along the ray  x_i = o + t_i · d ────────────────────────────
//   sampled near-to-far; t spans the segment crossing the volume.
#let tnear = 4.8
#let tfar  = 8.6
#let N = 7
#let samp(i) = {
  let t = tnear + (tfar - tnear) * i / (N - 1)
  (o.at(0) + t * dir.at(0), o.at(1) + t * dir.at(1), o.at(2) + t * dir.at(2))
}
// a per-sample density profile (high in the middle = an object surface)
#let dens(i) = {
  let u = (i - (N - 1) / 2) / ((N - 1) / 2)   // -1..1
  calc.exp(-3.2 * u * u)                       // bump centred mid-ray
}

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // helpers --------------------------------------------------------------------
  let dot3(p, r, col) = { circle(pj(p), radius: r, fill: col, stroke: none) }
  let halo-dot(p, r, col) = {
    circle(pj(p), radius: r + 0.05, fill: white, stroke: none)
    circle(pj(p), radius: r, fill: col, stroke: none)
  }
  let lbl(p, body, col, dx: 0, dy: 0, anc: "center", sz: 8.5pt, w: "regular", st: "normal") = {
    let q = pj(p)
    content((q.at(0) + dx, q.at(1) + dy), anchor: anc,
      box(fill: white.transparentize(15%), inset: 1.2pt,
        text(size: sz, fill: col, weight: w, style: st, body)))
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  LEFT PANEL — the 3-D ray-casting scene
  // ════════════════════════════════════════════════════════════════════════════

  // ── density volume: light box, back faces first then front edges ─────────────
  let v = (i, j, k) => pj(vcorner(i, j, k))
  // back face (k=0 .. far in z), drawn faint
  line(v(0,0,1), v(1,0,1), v(1,1,1), v(0,1,1), close: true,
       fill: grid-c.transparentize(35%), stroke: 0.5pt + faint)
  // connect back to front (the 4 depth edges)
  for (a, b) in (((0,0,0),(0,0,1)), ((1,0,0),(1,0,1)), ((1,1,0),(1,1,1)), ((0,1,0),(0,1,1))) {
    line(pj(vcorner(..a)), pj(vcorner(..b)), stroke: 0.5pt + faint)
  }
  // front face (k=1 toward viewer)
  line(v(0,0,0), v(1,0,0), v(1,1,0), v(0,1,0), close: true,
       fill: grid-c.transparentize(55%), stroke: 0.7pt + muted)
  lbl(vcorner(1, 1, 0), [density volume $sigma(bold(x))$], muted,
      dx: 0.25, dy: 0.28, anc: "south-west", sz: 8pt, st: "italic")

  // ── image plane (retina): light filled rectangle, sharp dark frame ───────────
  line(pj(pc-TL), pj(pc-TR), pj(pc-BR), pj(pc-BL), close: true,
       fill: beige.transparentize(8%), stroke: 0.9pt + muted)
  // a faint pixel grid on the retina
  for s in range(1, 4) {
    let u = -pw + 2 * pw * s / 4
    line(pj(plane-corner(u, -ph)), pj(plane-corner(u, ph)), stroke: 0.4pt + faint)
    let vv = -ph + 2 * ph * s / 4
    line(pj(plane-corner(-pw, vv)), pj(plane-corner(pw, vv)), stroke: 0.4pt + faint)
  }
  lbl(pc-TL, [image plane], muted, dx: -0.15, dy: 0.22, anc: "south", sz: 8pt, st: "italic")

  // ── camera frustum: centre → 4 retina corners (thin, faint) ──────────────────
  for cor in (pc-TL, pc-TR, pc-BR, pc-BL) {
    line(pj(o), pj(cor), stroke: 0.6pt + faint)
  }

  // ── the CAMERA RAY  r(t) = o + t·d  (focal garnet), extended through volume ──
  let rfar = (o.at(0) + tfar * dir.at(0) + 0.5, o.at(1), o.at(2))
  line(pj(o), pj(rfar), stroke: 1.9pt + garnet)
  // arrowhead at far end
  line(pj((rfar.at(0) - 0.45, o.at(1), o.at(2))), pj(rfar),
       stroke: 1.9pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.8))

  // ── sample points x_i along the ray; size/fill encode density σ_i ────────────
  for i in range(N) {
    let p = samp(i)
    let s = dens(i)
    let r = 0.07 + 0.085 * s
    // density "glow": faint green disk under high-σ samples
    if s > 0.15 { circle(pj(p), radius: r + 0.18 * s, fill: green.transparentize(78%), stroke: none) }
    halo-dot(p, r, green.darken(20% * s))
  }
  // label first/last samples + the generic x_i
  lbl(samp(0), [$bold(x)_1$], ink, dx: -0.05, dy: 0.34, anc: "south", sz: 8pt)
  lbl(samp(N - 1), [$bold(x)_N$], ink, dx: 0.0, dy: 0.34, anc: "south", sz: 8pt)
  let mid = samp(3)
  lbl(mid, [$bold(x)_i = bold(o) + t_i bold(d)$], garnet, dx: 0.05, dy: -0.40, anc: "north", sz: 8.5pt)

  // ── camera centre o + view direction arrow d ─────────────────────────────────
  halo-dot(o, 0.12, ink)
  lbl(o, [$bold(o)$], ink, dx: -0.30, dy: 0.10, anc: "east", sz: 9.5pt, w: "bold")
  // short view-direction arrow d, in blue, just past the camera
  let dtip = (o.at(0) + 1.0, o.at(1), o.at(2) + 0.0)
  let dtail = (o.at(0) + 0.15, o.at(1) - 0.9, o.at(2))
  line(pj(dtail), pj((dtail.at(0) + 0.95, dtail.at(1), dtail.at(2))),
       stroke: 1.4pt + blue, mark: (end: "stealth", fill: blue, scale: 0.7))
  lbl((dtail.at(0) + 0.95, dtail.at(1), dtail.at(2)), [$bold(d)$], blue,
      dx: 0.10, dy: -0.18, anc: "north-west", sz: 9pt, w: "bold")

  // pixel marker on the retina (where this ray pierces the image plane)
  halo-dot(pix, 0.075, garnet)

  // panel title
  content((pj(o).at(0) + 0.4, pj(pc-TL).at(1) + 1.15), anchor: "south",
    text(size: 10.5pt, weight: "bold", fill: ink)[1 · Cast a ray, sample N points])

  // ════════════════════════════════════════════════════════════════════════════
  //  RIGHT PANEL — per-sample network  +  volume-rendering integral
  // ════════════════════════════════════════════════════════════════════════════
  //  Lay out in plain 2-D (cetz canvas units). Anchor everything off x0.
  let X0 = 7.4
  let yc = 0.4          // vertical centre of the pipeline row

  // a sharp-cornered labelled box (print-first: light fill, dark text, no rounding)
  let bx(cx, cy, w, h, body, fill: white, stroke-c: muted, txt: ink, sz: 8.5pt, w8: "regular") = {
    rect((cx - w/2, cy - h/2), (cx + w/2, cy + h/2),
         fill: fill, stroke: 0.9pt + stroke-c, radius: 0pt)
    content((cx, cy), text(size: sz, fill: txt, weight: w8, body))
  }
  let arr(x1, y1, x2, y2, col: ink, th: 1.0pt) = {
    line((x1, y1), (x2, y2), stroke: th + col, mark: (end: "stealth", fill: col, scale: 0.75))
  }

  // node x-centres along the pipeline
  let xin  = X0 + 0.0     // (x, d) input
  let xpe  = X0 + 2.05    // positional encoding γ
  let xmlp = X0 + 4.2     // MLP F_Θ
  let xout = X0 + 6.5     // (c_i, σ_i)

  // 1) 5-D input  (x, d)
  bx(xin, yc, 1.5, 1.0,
     [#text(size: 8.5pt)[5-D input] \ $(bold(x), bold(d))$], fill: grid-c.transparentize(45%))
  content((xin, yc - 0.72), text(size: 7.5pt, fill: muted, style: "italic")[pos. + view dir.])

  // 2) positional encoding  γ
  arr(xin + 0.78, yc, xpe - 0.92, yc, col: blue, th: 1.1pt)
  bx(xpe, yc, 1.7, 1.0,
     [pos. encoding \ $gamma(dot)$], fill: blue.lighten(82%), stroke-c: blue, txt: blue.darken(10%))
  content((xpe, yc - 0.72), text(size: 7pt, fill: blue.darken(5%), style: "italic")[sin/cos bands])

  // 3) the MLP  F_Θ  (the focal garnet box) — show a tiny net inside
  arr(xpe + 0.88, yc, xmlp - 1.05, yc, col: blue, th: 1.1pt)
  bx(xmlp, yc, 1.95, 1.55, [], fill: garnet.lighten(90%), stroke-c: garnet)
  // mini-MLP glyph inside the box
  let layers = ((xmlp - 0.6, 3), (xmlp - 0.2, 4), (xmlp + 0.25, 4), (xmlp + 0.62, 2))
  let nodepos(lx, n, k) = (lx, yc + 0.34 - 0.62 * (if n == 1 { 0 } else { k / (n - 1) }) + 0.0)
  // edges
  for li in range(layers.len() - 1) {
    let (lx, n) = layers.at(li)
    let (lx2, n2) = layers.at(li + 1)
    for a in range(n) {
      for b in range(n2) {
        line(nodepos(lx, n, a), nodepos(lx2, n2, b), stroke: 0.3pt + garnet.transparentize(55%))
      }
    }
  }
  for (lx, n) in layers {
    for k in range(n) { circle(nodepos(lx, n, k), radius: 0.055, fill: garnet, stroke: none) }
  }
  content((xmlp, yc + 0.62), text(size: 9pt, fill: garnet, weight: "bold")[$F_Theta$])
  content((xmlp, yc - 0.95), text(size: 7.5pt, fill: garnet, style: "italic")[shared MLP])

  // 4) output  (c_i, σ_i)
  arr(xmlp + 1.05, yc, xout - 0.95, yc, col: garnet, th: 1.1pt)
  bx(xout, yc, 1.55, 1.0,
     [$(bold(c)_i, sigma_i)$ \ #text(size: 7.5pt)[colour, density]],
     fill: green.lighten(85%), stroke-c: green, txt: green.darken(12%))

  // bracket: "evaluated at every sample x_i"
  let bx_l = xin - 0.78
  let bx_r = xout + 0.78
  let by = yc - 1.35
  line((bx_l, by + 0.12), (bx_l, by), (bx_r, by), (bx_r, by + 0.12), stroke: 0.7pt + muted)
  content(((bx_l + bx_r)/2, by - 0.22), anchor: "north",
    text(size: 8pt, fill: muted, style: "italic")[run for each of the $N$ samples $bold(x)_i$])

  // panel title (right)
  content((xmlp, yc + 1.6), anchor: "south",
    text(size: 10.5pt, weight: "bold", fill: ink)[2 · Query the radiance-field MLP])

  // ── 3) VOLUME-RENDERING INTEGRAL : composite (c_i,σ_i) → pixel colour ────────
  let yV = yc - 3.55
  content((X0 + 3.4, yV + 1.30), anchor: "south",
    text(size: 10.5pt, weight: "bold", fill: ink)[3 · Volume render (alpha-composite) the ray])

  // op-node: the compositing integral Σ
  let xSig = X0 + 1.05
  circle((xSig, yV), radius: 0.42, fill: white, stroke: 1.1pt + ink)
  content((xSig, yV), text(size: 13pt, fill: ink)[$sum$])
  // feeds from all samples (drawn as a fan coming in from the left)
  for dy in (-0.30, 0.0, 0.30) {
    arr(xSig - 1.65, yV + dy, xSig - 0.46, yV + dy*0.55, col: green, th: 0.8pt)
  }
  content((xSig - 1.80, yV), anchor: "east",
    text(size: 8.5pt, fill: green.darken(8%))[${(bold(c)_i, sigma_i)}_(i=1)^N$])

  // the discrete rendering equation, to the right of Σ
  arr(xSig + 0.46, yV, xSig + 1.05, yV, col: ink, th: 1.0pt)
  content((xSig + 1.20, yV + 0.02), anchor: "west",
    box(inset: 2pt, text(size: 10pt, fill: ink)[
      $hat(C)(bold(r)) = sum_(i=1)^N T_i thin (1 - e^(-sigma_i delta_i)) thin bold(c)_i$
    ]))
  content((xSig + 1.20, yV - 0.70), anchor: "west",
    text(size: 8.5pt, fill: green.darken(8%))[$T_i = exp(-sum_(j<i) sigma_j delta_j)$ #h(0.5em) #text(fill: muted, style: "italic")[(transmittance)]])

  // arrow to the final pixel colour swatch (well clear of the equation)
  let xPix = X0 + 8.25
  arr(xSig + 6.0, yV, xPix - 0.55, yV, col: garnet, th: 1.2pt)
  rect((xPix - 0.42, yV - 0.42), (xPix + 0.42, yV + 0.42),
       fill: garnet.transparentize(15%), stroke: 0.9pt + ink, radius: 0pt)
  content((xPix, yV - 0.70), anchor: "north",
    text(size: 8.5pt, fill: ink, weight: "bold")[pixel colour])

  // ── connective tissue: scene ray-samples → input box of the query pipeline ───
  //   a soft dashed cue from the scene's last sample up into the (x,d) input box.
  line(pj(samp(N - 1)), (xin - 0.78, yc - 0.15),
       stroke: (paint: faint, thickness: 0.7pt, dash: "dashed"))
})
