// mlatlas · Optical flow field — a dense 2-D motion field between two frames.
//   Optical flow assigns to every pixel x = (x,y) a displacement vector
//   v(x) = (u(x), v(x)) describing where its brightness moves from frame I_t to I_{t+1},
//   under the brightness-constancy constraint  I_t(x) = I_{t+1}(x + v(x)),  whose
//   linearization is the optical-flow equation  I_x u + I_y v + I_t = 0.
//   The MAIN panel is a quiver: an arrow per grid cell whose direction/length is v(x).
//   Here the synthetic field is a translating + expanding object — a uniform pan
//   plus a radial divergence (looming) centred on the object — so arrows fan outward
//   on a drifting background, the canonical "looming" flow.  A small two-frame
//   (t, t+1) inset feeds the field; a coarse-to-fine pyramid shows the warp ladder
//   that lets large displacements be recovered.  Built from first principles; no trace.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ────────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid-c = rgb("#ECECEC")
  let frame-c = rgb("#C7C7C7")
  let garnet = rgb("#73000A")     // focal accent — fast / object arrows
  let blue   = rgb("#466A9F")     // background / slow arrows
  let beige  = rgb("#FFF2E3")

  // ── main quiver panel geometry ───────────────────────────────────────────────
  let PW = 9.6          // panel width  (cm)
  let PH = 9.6          // panel height (cm)
  let nx = 11           // arrows across
  let ny = 11           // arrows down

  // synthetic flow field  v(x) at world position (px,py) in [0,1]^2.
  // = uniform pan  + radial divergence (looming) from an object centre.
  let panx = 0.30       // background pan, +x
  let pany = 0.10       // background pan, +y (down on screen → handled by sy)
  let cx = 0.62         // object centre (looming source)
  let cy = 0.44
  let div-gain = 1.05   // strength of the radial expansion
  let sigma = 0.34      // spatial extent of the object

  // returns (u, v) flow in normalized units at normalized position (px,py)
  let flow(px, py) = {
    let dx = px - cx
    let dy = py - cy
    let r2 = dx * dx + dy * dy
    let w = calc.exp(-r2 / (2 * sigma * sigma))   // object support (Gaussian falloff)
    let u = panx + div-gain * w * dx
    let vv = pany + div-gain * w * dy
    (u, vv)
  }

  // normalized → panel-canvas mapping (y up in canvas; screen-y grows downward,
  // so flip py for placement to read like an image with origin top-left).
  let sx(px) = px * PW
  let sy(py) = (1 - py) * PH

  // ── panel frame + faint image grid ───────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: beige.lighten(40%), stroke: 1pt + ink, radius: 0pt)
  let gn = 12
  for i in range(1, gn) {
    let gx = i / gn * PW
    line((gx, 0), (gx, PH), stroke: 0.5pt + grid-c)
    let gy = i / gn * PH
    line((0, gy), (PW, gy), stroke: 0.5pt + grid-c)
  }

  // ── faint object footprint (the looming thing), drawn under the arrows ───────
  // concentric supports kept inside the panel; the innermost is tinted.
  for k in (1.05, 0.72, 0.40) {
    let rr = sigma * k
    let ring = range(65).map(i => {
      let t = i / 64 * 2 * calc.pi
      (sx(cx + rr * calc.cos(t)), sy(cy + rr * calc.sin(t)))
    })
    line(..ring, close: true,
      stroke: (paint: frame-c, thickness: 0.7pt, dash: "dashed"),
      fill: garnet.transparentize(if k == 0.45 { 90% } else { 96% }))
  }

  // ── the quiver: one stealth arrow per grid cell ──────────────────────────────
  // scale flow magnitude to a readable arrow length (cells are PW/(nx-1) apart).
  let cell = PW / (nx + 1)
  let arr-scale = cell * 2.05    // longest arrows ≈ ~2 cells
  // find max magnitude for colour thresholding
  let maxmag = 0.0
  for ix in range(nx) {
    for iy in range(ny) {
      let px = (ix + 1) / (nx + 1)
      let py = (iy + 1) / (ny + 1)
      let f = flow(px, py)
      let m = calc.sqrt(f.at(0) * f.at(0) + f.at(1) * f.at(1))
      if m > maxmag { maxmag = m }
    }
  }

  for ix in range(nx) {
    for iy in range(ny) {
      let px = (ix + 1) / (nx + 1)
      let py = (iy + 1) / (ny + 1)
      let f = flow(px, py)
      let u = f.at(0)
      let vv = f.at(1)
      let m = calc.sqrt(u * u + vv * vv)
      // tail at the grid point; head displaced by the (scaled) flow.
      let tx = sx(px)
      let ty = sy(py)
      // screen-down for +v means subtract in canvas-y (sy flips), so add to canvas-y
      // because positive vv = downward motion in image → lower canvas-y.
      let hx = tx + u * arr-scale
      let hy = ty - vv * arr-scale
      // colour: garnet for the fast object arrows, blue for slow background.
      let frac = m / maxmag
      let col = if frac > 0.55 { garnet } else { blue }
      let sw = if frac > 0.55 { 1.5pt } else { 1.0pt }
      // small white halo dot at each sample (grid-point footprint)
      circle((tx, ty), radius: 0.026, fill: muted, stroke: none)
      line((tx, ty), (hx, hy),
        stroke: sw + col, mark: (end: "stealth", scale: 0.42, fill: col))
    }
  }

  // mark the looming centre (focus of expansion)
  let fe = (sx(cx), sy(cy))
  circle(fe, radius: 0.11, fill: white, stroke: 1.2pt + garnet)
  circle(fe, radius: 0.035, fill: garnet, stroke: none)
  content((fe.at(0) + 0.18, fe.at(1) + 0.16), anchor: "south-west",
    box(fill: white.transparentize(12%), inset: 1.4pt,
      text(size: 7.5pt, weight: "bold", fill: garnet)[FOE]))

  // ── panel title + flow equation ──────────────────────────────────────────────
  content((PW / 2, PH + 1.18),
    text(size: 12pt, weight: "bold", fill: ink)[Optical flow field])
  content((PW / 2, PH + 0.62),
    text(size: 8.5pt, fill: ink)[dense motion $bold(v)(bold(x)) = (u, v)$ from $I_t arrow.r I_(t+1)$, one arrow per pixel grid cell])
  content((PW / 2, -0.55),
    text(size: 8pt, fill: muted)[brightness constancy $I_t(bold(x)) = I_(t+1)(bold(x) + bold(v))$ #h(0.6em) $arrow.r$ #h(0.6em) $I_x u + I_y v + I_t = 0$])

  // ════════════════════════════════════════════════════════════════════════════
  //  RIGHT SIDEBAR : two-frame pair  →  flow,  then the coarse-to-fine pyramid
  // ════════════════════════════════════════════════════════════════════════════
  let lx = PW + 0.95            // left edge of sidebar
  let sw-box = 2.7              // small frame size

  // ── (1) two-frame (t, t+1) pair that feeds the field ─────────────────────────
  content((lx + sw-box, PH + 0.62), anchor: "center",
    text(size: 9.5pt, weight: "bold", fill: ink)[input frames])

  // a little "object" patch (square) that translates + grows between frames.
  let frame-box(ox, oy, label, opx, opy, osz, oc) = {
    rect((ox, oy), (ox + sw-box, oy + sw-box),
      fill: beige.lighten(35%), stroke: 0.9pt + ink, radius: 0pt)
    // faint inner grid
    for j in range(1, 4) {
      line((ox + j / 4 * sw-box, oy), (ox + j / 4 * sw-box, oy + sw-box),
        stroke: 0.4pt + grid-c)
      line((ox, oy + j / 4 * sw-box), (ox + sw-box, oy + j / 4 * sw-box),
        stroke: 0.4pt + grid-c)
    }
    // the object patch
    rect((ox + opx, oy + opy), (ox + opx + osz, oy + opy + osz),
      fill: oc.transparentize(45%), stroke: 1pt + oc, radius: 0pt)
    content((ox + sw-box / 2, oy - 0.34), anchor: "north",
      text(size: 8pt, fill: muted)[#label])
  }
  let row1y = PH - sw-box       // top of the frame row
  frame-box(lx, row1y, $I_t$, 0.55, 0.85, 0.95, blue)
  frame-box(lx + sw-box + 0.85, row1y, $I_(t+1)$, 1.10, 0.50, 1.30, garnet)

  // arrow between the two frames
  let ax0 = lx + sw-box + 0.10
  let axc = (row1y + sw-box / 2)
  line((ax0, axc), (ax0 + 0.65, axc),
    stroke: 1.2pt + ink, mark: (end: "stealth", scale: 0.5))

  // "= flow" arrow pointing back to the main panel + caption
  content((lx + sw-box + 0.42, row1y - 0.92), anchor: "north",
    text(size: 7.5pt, fill: muted, style: "italic")[displacement of the patch $arrow.r$ flow $bold(v)$])

  // ── (2) coarse-to-fine pyramid (warp ladder) ─────────────────────────────────
  let pyy = row1y - 2.05        // top reference for pyramid block
  content((lx + sw-box, pyy + 0.30), anchor: "center",
    text(size: 9.5pt, weight: "bold", fill: ink)[coarse-to-fine warping])

  // three pyramid levels: coarse (small) at top → fine (large) at bottom.
  // each is a downsampled grid; resolution doubles going down.
  let levels = (
    (res: 3, scale: 1.2, lbl: [coarse $ell = 2$]),
    (res: 5, scale: 1.9, lbl: [$ell = 1$]),
    (res: 8, scale: 2.7, lbl: [fine $ell = 0$]),
  )
  let pcx = lx + sw-box         // centre x of pyramid column
  let py-cursor = pyy - 0.55
  let prev = none
  for (li, L) in levels.enumerate() {
    let s = L.scale
    let bx0 = pcx - s / 2
    let by0 = py-cursor - s
    // grid box
    rect((bx0, by0), (bx0 + s, by0 + s),
      fill: beige.lighten(35%), stroke: 0.9pt + ink, radius: 0pt)
    let r = L.res
    for j in range(1, r) {
      line((bx0 + j / r * s, by0), (bx0 + j / r * s, by0 + s), stroke: 0.4pt + grid-c)
      line((bx0, by0 + j / r * s), (bx0 + s, by0 + j / r * s), stroke: 0.4pt + grid-c)
    }
    // a few representative flow arrows at this level (refined each step)
    let na = if r <= 3 { 2 } else if r <= 5 { 3 } else { 4 }
    for ii in range(na) {
      for jj in range(na) {
        let qx = bx0 + (ii + 0.5) / na * s
        let qy = by0 + (jj + 0.5) / na * s
        let al = s * 0.10 * (1 + li * 0.15)
        line((qx, qy), (qx + al * 1.0, qy + al * 0.45),
          stroke: 0.7pt + garnet, mark: (end: "stealth", scale: 0.3, fill: garnet))
      }
    }
    content((bx0 + s + 0.20, by0 + s / 2), anchor: "west",
      text(size: 7.5pt, fill: muted)[#L.lbl])
    // up-sample / warp connector from previous (coarser) level
    if prev != none {
      line((pcx, prev.at(1)), (pcx, by0 + s),
        stroke: (paint: muted, thickness: 1pt), mark: (end: "stealth", scale: 0.4))
    }
    prev = (pcx, by0)
    py-cursor = by0 - 0.55
  }
  // pyramid arrow caption
  content((pcx, py-cursor + 0.30), anchor: "north",
    text(size: 7pt, fill: muted, style: "italic")[upsample $times 2$ + warp $arrow.r$ refine])

  // ── colour key for the main quiver (small, lower-left of sidebar) ────────────
  let ky = py-cursor - 0.25
  line((lx, ky), (lx + 0.7, ky), stroke: 1.5pt + garnet,
    mark: (end: "stealth", scale: 0.42, fill: garnet))
  content((lx + 0.86, ky), anchor: "west",
    text(size: 8pt, fill: ink)[fast — object (looming)])
  line((lx, ky - 0.5), (lx + 0.7, ky - 0.5), stroke: 1.0pt + blue,
    mark: (end: "stealth", scale: 0.42, fill: blue))
  content((lx + 0.86, ky - 0.5), anchor: "west",
    text(size: 8pt, fill: ink)[slow — background pan])
  circle((lx + 0.30, ky - 1.02), radius: 0.08, fill: white, stroke: 1.1pt + garnet)
  circle((lx + 0.30, ky - 1.02), radius: 0.028, fill: garnet, stroke: none)
  content((lx + 0.86, ky - 1.02), anchor: "west",
    text(size: 8pt, fill: ink)[focus of expansion (FOE)])
})
