// 3-D Gaussian Splatting — a scene as a cloud of anisotropic 3-D Gaussians,
// differentiably rasterized ("splatted") and alpha-blended into a novel view.
//
//   Each primitive g is an anisotropic 3-D Gaussian with a mean (position) mu_g,
//   a 3x3 covariance  Sigma_g = R S Sᵀ Rᵀ  (an ellipsoid: scale S + rotation R),
//   an opacity alpha_g, and a view-dependent color c_g (spherical harmonics).
//   RENDER = (1) view-project each Gaussian to a 2-D screen-space Gaussian
//   Sigma' = J W Sigma Wᵀ Jᵀ (a "splat"), (2) sort the splats front-to-back by
//   depth, (3) alpha-blend (over-compositing) their colors per pixel:
//      C = Σ_i c_i α_i Π_{j<i}(1 − α_j).
//   The whole pipeline is differentiable, so a photometric loss against ground
//   truth flows gradients back into every (mu, Sigma, alpha, c).
//
//   Built on the hand-rolled 3-D engine (project / projector / project-z): the
//   left panel is the true axonometric scene of ellipsoids, the right panel is
//   the orthographically projected & composited image. Each ellipsoid silhouette
//   is the projection of a unit sphere scaled by its covariance eigen-axes — the
//   covariance is realized as a real oriented ellipse, not faked. No image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- palette ------------------------------------------------------------
  let ink    = rgb("#222222")
  let garnet = rgb("#73000A")
  let blue   = rgb("#466A9F")
  let dgreen = rgb("#65780B")
  let pinkr  = rgb("#CC2E40")
  let mid    = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let b10    = rgb("#ECECEC")
  let b30    = rgb("#C7C7C7")
  let beige  = rgb("#FFF2E3")

  // ---- vector helpers -----------------------------------------------------
  let sub = (a, b) => (a.at(0) - b.at(0), a.at(1) - b.at(1), a.at(2) - b.at(2))
  let add = (a, b) => (a.at(0) + b.at(0), a.at(1) + b.at(1), a.at(2) + b.at(2))
  let scl = (a, s) => (a.at(0) * s, a.at(1) * s, a.at(2) * s)

  // ---- camera + projection for the LEFT (world) scene ---------------------
  let cam = (22deg, -34deg, 0deg)              // axonometric viewpoint
  let O   = (0, 0)                              // scene origin on canvas
  let pr  = projector(cam: cam, origin: O)     // 3-D world -> 2-D canvas
  let zof = p => project-z(p, cam: cam)         // painter-sort key (larger = nearer)

  // =====================================================================
  //  ANISOTROPIC 3-D GAUSSIAN PRIMITIVE
  //  A Gaussian's iso-density surface is an ellipsoid whose principal axes are
  //  the eigen-directions of Sigma with half-lengths sqrt(lambda_i). We draw the
  //  PROJECTED SILHOUETTE of that ellipsoid: project the three semi-axis
  //  endpoints, then trace the screen-space ellipse spanned by the two largest
  //  projected axes (a faithful 2-D silhouette of a scaled+rotated unit sphere).
  // =====================================================================
  // ax = (sx, sy, sz) scales (eigen sqrt(lambda)); rot = (rx, ry, rz) Euler angles.
  let rotpt = (p, r) => {
    let (cx, sx) = (calc.cos(r.at(0)), calc.sin(r.at(0)))
    let (cy, sy) = (calc.cos(r.at(1)), calc.sin(r.at(1)))
    let (cz, sz) = (calc.cos(r.at(2)), calc.sin(r.at(2)))
    // Rz Ry Rx applied to p
    let x1 = p.at(0)
    let y1 = cx * p.at(1) - sx * p.at(2)
    let z1 = sx * p.at(1) + cx * p.at(2)
    let x2 = cy * x1 + sy * z1
    let y2 = y1
    let z2 = -sy * x1 + cy * z1
    let x3 = cz * x2 - sz * y2
    let y3 = sz * x2 + cz * y2
    (x3, y3, z2)
  }
  // projected ellipse outline (n samples) of the ellipsoid at center mu.
  // We build the 2x2 screen covariance from the projected semi-axes a1,a2,a3
  // (sum of outer products) and trace its 1-sigma contour. This is the exact
  // 2-D footprint of the projected anisotropic Gaussian — the "splat".
  let splat-outline = (mu, ax, rot, ctr, n: 48) => {
    // projected semi-axis vectors in canvas space (relative to projected center)
    let c0 = ctr
    let axisvec = (i) => {
      let e = (0, 0, 0)
      let e2 = if i == 0 { (ax.at(0), 0, 0) } else if i == 1 { (0, ax.at(1), 0) } else { (0, 0, ax.at(2)) }
      let w = add(mu, rotpt(e2, rot))
      let p = pr(w)
      (p.at(0) - c0.at(0), p.at(1) - c0.at(1))
    }
    let a1 = axisvec(0)
    let a2 = axisvec(1)
    let a3 = axisvec(2)
    // 2x2 screen covariance M = Σ a_i a_iᵀ
    let m11 = a1.at(0) * a1.at(0) + a2.at(0) * a2.at(0) + a3.at(0) * a3.at(0)
    let m12 = a1.at(0) * a1.at(1) + a2.at(0) * a2.at(1) + a3.at(0) * a3.at(1)
    let m22 = a1.at(1) * a1.at(1) + a2.at(1) * a2.at(1) + a3.at(1) * a3.at(1)
    // eigendecomp of [[m11,m12],[m12,m22]]
    let trc = m11 + m22
    let det = m11 * m22 - m12 * m12
    let dsc = calc.sqrt(calc.max(trc * trc - 4 * det, 0))
    let l1 = (trc + dsc) / 2
    let l2 = (trc - dsc) / 2
    let r1x = m12
    let r1y = l1 - m11
    let nn = calc.sqrt(r1x * r1x + r1y * r1y)
    let (u1x, u1y) = if nn < 1e-6 { (1, 0) } else { (r1x / nn, r1y / nn) }
    let (u2x, u2y) = (-u1y, u1x)
    let s1 = calc.sqrt(calc.max(l1, 0))
    let s2 = calc.sqrt(calc.max(l2, 0))
    range(n + 1).map(k => {
      let t = k / n * 2 * calc.pi
      let a = s1 * calc.cos(t)
      let b = s2 * calc.sin(t)
      (c0.at(0) + a * u1x + b * u2x, c0.at(1) + a * u1y + b * u2y)
    })
  }

  // =====================================================================
  //  THE SCENE — a small cloud of anisotropic Gaussians forming an object.
  //  Each: mu (position), ax (eigen semi-axes), rot (orientation), col, op.
  // =====================================================================
  let deg = d => d * calc.pi / 180
  let splats = (
    (mu: (-0.1, 0.9, 0.0),  ax: (0.95, 0.40, 0.55), rot: (deg(10), deg(20), deg(35)),  col: garnet, op: 0.92),
    (mu: (0.9, 0.3, -0.5),  ax: (0.70, 0.32, 0.50), rot: (deg(-20), deg(40), deg(-15)), col: blue,   op: 0.80),
    (mu: (-0.95, 0.2, 0.6), ax: (0.60, 0.50, 0.30), rot: (deg(15), deg(-30), deg(20)),  col: dgreen, op: 0.78),
    (mu: (0.2, -0.6, 0.7),  ax: (0.80, 0.30, 0.45), rot: (deg(30), deg(10), deg(-40)),  col: pinkr,  op: 0.70),
    (mu: (-0.4, -0.5, -0.7),ax: (0.55, 0.45, 0.40), rot: (deg(-10), deg(25), deg(60)),  col: blue,   op: 0.62),
    (mu: (1.0, 1.0, 0.4),   ax: (0.50, 0.28, 0.42), rot: (deg(40), deg(-20), deg(10)),  col: dgreen, op: 0.55),
    (mu: (0.5, 1.3, -0.3),  ax: (0.45, 0.40, 0.30), rot: (deg(5), deg(35), deg(-25)),   col: garnet, op: 0.68),
    (mu: (-0.7, 1.1, -0.4), ax: (0.52, 0.30, 0.38), rot: (deg(-25), deg(15), deg(45)),  col: pinkr,  op: 0.58),
  )

  // ---- ground reference plane (light, behind everything) ------------------
  let gpoly = (
    pr((-2.0, -1.3, -2.0)), pr((2.0, -1.3, -2.0)),
    pr((2.0, -1.3, 2.0)),   pr((-2.0, -1.3, 2.0)),
  )
  draw.line(..gpoly, close: true, stroke: 0.6pt + b30, fill: b10.transparentize(45%))
  // a couple of ground grid lines
  for t in (-1.0, 0.0, 1.0) {
    draw.line(pr((t, -1.3, -2.0)), pr((t, -1.3, 2.0)), stroke: 0.4pt + b30)
    draw.line(pr((-2.0, -1.3, t)), pr((2.0, -1.3, t)), stroke: 0.4pt + b30)
  }

  // ---- draw splats back-to-front (painter's algorithm) --------------------
  let sorted = splats.sorted(key: s => zof(s.mu))
  for s in sorted {
    let ctr = pr(s.mu)
    let ring = splat-outline(s.mu, s.ax, s.rot, ctr)
    // soft filled core (low-alpha tint) + crisp 1-sigma outline
    draw.line(..ring, close: true,
      fill: s.col.transparentize(100% - int(s.op * 55) * 1%),
      stroke: (paint: s.col, thickness: 1.1pt))
    // mark the mean
    draw.circle(ctr, radius: 0.045, fill: ink, stroke: none)
  }

  // ---- camera frustum looking at the cloud (the source viewpoint) ---------
  let camC = (-3.4, 0.3, 3.1)
  let target = (0.0, 0.4, 0.0)
  let cpos = pr(camC)
  // a tiny pyramid frustum toward the scene
  let fwd = sub(target, camC)
  let flen = calc.sqrt(fwd.at(0) * fwd.at(0) + fwd.at(1) * fwd.at(1) + fwd.at(2) * fwd.at(2))
  let fn = scl(fwd, 1 / flen)
  // right & up via cross with world-up
  let up0 = (0, 1, 0)
  let crs = (a, b) => (
    a.at(1) * b.at(2) - a.at(2) * b.at(1),
    a.at(2) * b.at(0) - a.at(0) * b.at(2),
    a.at(0) * b.at(1) - a.at(1) * b.at(0),
  )
  let nrm = v => { let m = calc.sqrt(v.at(0) * v.at(0) + v.at(1) * v.at(1) + v.at(2) * v.at(2)); scl(v, 1 / m) }
  let rgt = nrm(crs(fn, up0))
  let upv = crs(rgt, fn)
  let pc = add(camC, scl(fn, 1.1))           // image-plane center
  let hw = 0.55
  let hh = 0.42
  let corner = (sx, sy) => pr(add(pc, add(scl(rgt, sx * hw), scl(upv, sy * hh))))
  let c1 = corner(-1, -1)
  let c2 = corner(1, -1)
  let c3 = corner(1, 1)
  let c4 = corner(-1, 1)
  // frustum edges
  for cc in (c1, c2, c3, c4) { draw.line(cpos, cc, stroke: 0.7pt + mid) }
  draw.line(c1, c2, c3, c4, close: true, stroke: 0.9pt + ink, fill: beige.transparentize(40%))
  draw.circle(cpos, radius: 0.07, fill: ink, stroke: none)
  draw.content((cpos.at(0) - 0.1, cpos.at(1) - 0.42),
    text(size: 7.5pt, fill: mid)[camera $(bold(R), bold(t))$])

  // ---- left-panel title ---------------------------------------------------
  let lcx = O.at(0)
  draw.content((lcx, 3.05),
    text(size: 9.5pt, weight: "bold", fill: ink)[Anisotropic 3-D Gaussians])
  draw.content((lcx, 2.62),
    text(size: 7.5pt, fill: mid)[scene = $\{ (bold(mu)_g, bold(Sigma)_g, alpha_g, bold(c)_g) \}_(g=1)^N$])

  // ---- callout: one Gaussian's parameters (point to the garnet splat) -----
  let hero = splats.at(0)
  let hpos = pr(hero.mu)
  let boxx = 2.55
  let boxy = -1.7
  draw.line(hpos, (boxx + 0.4, boxy + 0.05), stroke: (paint: garnet, thickness: 0.7pt, dash: "dashed"))
  draw.rect((boxx, boxy - 1.5), (boxx + 2.55, boxy + 0.05),
    stroke: 0.8pt + garnet, fill: white)
  draw.content((boxx + 0.12, boxy - 0.13), anchor: "north-west",
    text(size: 7pt, fill: garnet, weight: "bold")[one splat $g$])
  draw.content((boxx + 0.12, boxy - 0.45), anchor: "north-west",
    text(size: 7pt, fill: ink)[$bold(Sigma)_g = bold(R) bold(S) bold(S)^top bold(R)^top$])
  draw.content((boxx + 0.12, boxy - 0.81), anchor: "north-west",
    text(size: 7pt, fill: ink)[opacity $alpha_g$, color $bold(c)_g$ (SH)])
  draw.content((boxx + 0.12, boxy - 1.17), anchor: "north-west",
    text(size: 6.5pt, fill: mid)[ellipsoid = $sqrt(lambda_i)$ semi-axes])

  // =====================================================================
  //  PIPELINE ARROW + DIFFERENTIABLE RASTERIZER OP
  // =====================================================================
  let opx = 7.7        // op-node center x
  let opy = 0.4
  // big forward arrow from scene into the op
  draw.line((4.05, 0.4), (opx - 0.95, 0.4),
    stroke: 1.6pt + ink, mark: (end: "stealth", fill: ink, scale: 0.9))
  draw.content((5.35, 0.95), anchor: "south",
    text(size: 7.5pt, fill: ink)[project to screen])
  draw.content((5.35, 0.5), anchor: "south",
    text(size: 7.5pt, fill: ink)[$bold(Sigma)' = bold(J) bold(W) bold(Sigma) bold(W)^top bold(J)^top$])
  // the op box (differentiable splat rasterizer) — sharp corners, light fill
  draw.rect((opx - 0.95, opy - 1.1), (opx + 0.95, opy + 1.1),
    stroke: 1.4pt + ink, fill: b10)
  draw.content((opx, opy + 0.62), text(size: 8pt, weight: "bold", fill: ink)[differentiable])
  draw.content((opx, opy + 0.26), text(size: 8pt, weight: "bold", fill: ink)[tile rasterizer])
  draw.content((opx, opy - 0.18), text(size: 7pt, fill: mid)[sort by depth])
  draw.content((opx, opy - 0.5), text(size: 7pt, fill: mid)[$alpha$-blend (over)])
  draw.content((opx, opy - 0.86),
    text(size: 6.8pt, fill: garnet)[$C = sum_i bold(c)_i alpha_i product_(j<i)(1 - alpha_j)$])

  // arrow from op to rendered view
  draw.line((opx + 0.95, 0.4), (opx + 2.0, 0.4),
    stroke: 1.6pt + ink, mark: (end: "stealth", fill: ink, scale: 0.9))

  // =====================================================================
  //  RIGHT PANEL — the rendered novel view (composited 2-D splats)
  // =====================================================================
  let vx = opx + 2.05        // left edge of rendered image
  let vy = -1.55             // bottom edge
  let vw = 3.7
  let vh = 3.7
  // image frame
  draw.rect((vx, vy), (vx + vw, vy + vh), stroke: 1.2pt + ink, fill: white)
  // map a world splat to the image plane via the same camera, then re-fit
  // into the image box (a clean orthographic re-projection of the splats).
  let cxr = vx + vw / 2
  let cyr = vy + vh / 2 + 0.15
  let sc  = 1.18
  let img-of = (p) => {
    let q = pr(p)
    (cxr + (q.at(0) - O.at(0)) * sc, cyr + (q.at(1) - O.at(1)) * sc)
  }
  // draw composited splats back-to-front, more opaque fill (the final image)
  for s in sorted {
    let ctr = img-of(s.mu)
    // reuse outline geometry but recentered & rescaled into the image box
    let ring0 = splat-outline(s.mu, s.ax, s.rot, pr(s.mu))
    let ring = ring0.map(p => (
      cxr + (p.at(0) - O.at(0)) * sc,
      cyr + (p.at(1) - O.at(1)) * sc,
    ))
    draw.line(..ring, close: true,
      fill: s.col.transparentize(100% - int(s.op * 78) * 1%),
      stroke: (paint: s.col.darken(8%), thickness: 0.5pt))
  }
  // right-panel labels
  draw.content((cxr, vy + vh + 0.62),
    text(size: 9.5pt, weight: "bold", fill: ink)[Rendered view])
  draw.content((cxr, vy + vh + 0.25),
    text(size: 7.5pt, fill: mid)[$alpha$-blended image $C(bold(u))$])
  draw.content((cxr, vy - 0.34),
    text(size: 7pt, fill: mid)[per-pixel over-composite of overlapping splats])

  // =====================================================================
  //  BACKWARD PASS — photometric loss + gradient flow (dashed garnet)
  // =====================================================================
  let loss-y = vy - 1.25
  draw.rect((cxr - 1.25, loss-y - 0.34), (cxr + 1.25, loss-y + 0.34),
    stroke: 1pt + garnet, fill: white)
  draw.content((cxr, loss-y),
    text(size: 7.5pt, fill: garnet)[$cal(L) = norm(C - C^"gt")_1 + dots$])
  // image -> loss
  draw.line((cxr, vy - 0.5), (cxr, loss-y + 0.34),
    stroke: 1pt + ink, mark: (end: "stealth", fill: ink, scale: 0.7))
  // loss -> op (gradient, dashed garnet, curving back under)
  draw.line((cxr - 1.25, loss-y), (opx, loss-y), (opx, opy - 1.1),
    stroke: (paint: garnet, thickness: 1pt, dash: "dashed"),
    mark: (end: "stealth", fill: garnet, scale: 0.7))
  draw.content(((cxr - 1.25 + opx) / 2, loss-y - 0.3), anchor: "north",
    text(size: 6.8pt, fill: garnet)[$nabla_(bold(mu), bold(Sigma), alpha, bold(c)) cal(L)$ (back to every splat)])

  // =====================================================================
  //  TITLE
  // =====================================================================
  draw.content((opx, 4.05),
    text(size: 12.5pt, weight: "bold", fill: ink)[3-D Gaussian Splatting])
  draw.content((opx, 3.62),
    text(size: 8.5pt, fill: mid)[explicit radiance field: rasterize \& $alpha$-blend a cloud of 3-D Gaussians])
})
