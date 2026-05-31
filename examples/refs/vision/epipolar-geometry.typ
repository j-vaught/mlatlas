// Epipolar geometry (two-view) — the core constraint of stereo / structure-from-motion.
//   A 3-D world point  X  is imaged by two pinhole cameras with centres  C  and  C'.
//   It projects to  x  in the left image and  x'  in the right image. The two centres,
//   the point, and its rays all lie in one EPIPOLAR PLANE  π = (C, C', X). The line
//   joining the centres is the BASELINE; it pierces each image plane at the EPIPOLES
//   e, e'. The epipolar plane cuts each image plane in an EPIPOLAR LINE  (l, l'): the
//   image of one camera's ray as seen by the other. Hence  x'  must lie on  l' = F x,
//   the fundamental-matrix constraint   x'ᵀ F x = 0   (calibrated:  E = [t]× R ).
//   Bespoke cetz scene over mlatlas's hand-rolled orthographic projector — every point
//   (X, x, x', e, e') is computed in 3-D and projected, not traced from any image.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent: the world point X and its rays
#let blue   = rgb("#466A9F")   // epipolar lines / right-view structure
#let green  = rgb("#65780B")   // baseline + epipoles
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let plane-fill = rgb("#ECECEC")

// ── camera for the whole scene (axonometric: pitch, yaw, roll) ──────────────────
//   a gentle tilt reads as "looking down onto the stereo rig" with depth visible.
#let cam = (20deg, -10deg, 0deg)
#let pj(p) = project(p, cam: cam)

// ── world geometry (all in metres-ish scene units) ──────────────────────────────
//   The two cameras VERGE (toe-in) toward the scene so the baseline pierces each
//   image plane WITHIN the retina — i.e. the epipoles e, e' fall on the visible
//   images, the well-conditioned textbook case (Hartley–Zisserman Fig 9.1).
#let f = 1.9                       // focal length (centre → image plane)
#let CL = (-2.8, -0.6, -1.4)       // left  camera centre  C
#let CR = ( 2.8, -0.6, -1.4)       // right camera centre  C'
#let lookL = ( 3.0, 1.2, 3.0)      // left  optical-axis target (toed in to the right)
#let lookR = (-3.0, 1.2, 3.0)      // right optical-axis target (mirror image)
#let X  = ( 0.0,  3.0, 4.8)        // the 3-D world point  X (above the baseline)

// image-plane half-extents (a small rectangle / "retina" in front of each camera)
#let pw = 1.7                      // half width
#let ph = 1.35                     // half height

#let _norm(v) = { let n = calc.sqrt(v.at(0)*v.at(0)+v.at(1)*v.at(1)+v.at(2)*v.at(2)); (v.at(0)/n, v.at(1)/n, v.at(2)/n) }
#let _cross(a, b) = (a.at(1)*b.at(2)-a.at(2)*b.at(1), a.at(2)*b.at(0)-a.at(0)*b.at(2), a.at(0)*b.at(1)-a.at(1)*b.at(0))

// each camera's forward axis points from its centre to its toe-in target
#let aL = _norm((lookL.at(0)-CL.at(0), lookL.at(1)-CL.at(1), lookL.at(2)-CL.at(2)))
#let aR = _norm((lookR.at(0)-CR.at(0), lookR.at(1)-CR.at(1), lookR.at(2)-CR.at(2)))

// build an orthonormal frame (right, up, forward) for a camera given its forward axis
#let _frame(fwd) = {
  let up0 = (0.0, 1.0, 0.0)
  let r = _norm(_cross(up0, fwd))
  let u = _norm(_cross(fwd, r))
  (r, u, fwd)
}
#let frL = _frame(aL)
#let frR = _frame(aR)

// principal point: image-plane centre = C + f·forward
#let _pp(C, fr) = (C.at(0)+f*fr.at(2).at(0), C.at(1)+f*fr.at(2).at(1), C.at(2)+f*fr.at(2).at(2))
#let ppL = _pp(CL, frL)
#let ppR = _pp(CR, frR)

// a point on an image plane from local (u,v) coords:  pp + u·right + v·up
#let _ip(C, fr, u, v) = {
  let pp = _pp(C, fr)
  (pp.at(0)+u*fr.at(0).at(0)+v*fr.at(1).at(0),
   pp.at(1)+u*fr.at(0).at(1)+v*fr.at(1).at(1),
   pp.at(2)+u*fr.at(0).at(2)+v*fr.at(1).at(2))
}

// four corners of an image plane (TL, TR, BR, BL)
#let _plane-corners(C, fr) = (
  _ip(C, fr, -pw,  ph), _ip(C, fr,  pw,  ph),
  _ip(C, fr,  pw, -ph), _ip(C, fr, -pw, -ph),
)

// world point on a camera plane → local (u,v) coords w.r.t. principal point
#let _to-uv(C, fr, P) = {
  let pp = _pp(C, fr)
  let d = (P.at(0)-pp.at(0), P.at(1)-pp.at(1), P.at(2)-pp.at(2))
  let r = fr.at(0); let u = fr.at(1)
  (d.at(0)*r.at(0)+d.at(1)*r.at(1)+d.at(2)*r.at(2),
   d.at(0)*u.at(0)+d.at(1)*u.at(1)+d.at(2)*u.at(2))
}
// clip the line through local points a,b to the rectangle [-pw,pw]×[-ph,ph]
// (Liang–Barsky); returns the two clipped local endpoints, or none if outside.
#let _clip-uv(a, b) = {
  let (x0, y0) = a; let (x1, y1) = b
  let dx = x1 - x0; let dy = y1 - y0
  let t0 = -1e9; let t1 = 1e9
  let edges = (
    (-dx, x0 - (-pw)), (dx, pw - x0),
    (-dy, y0 - (-ph)), (dy, ph - y0),
  )
  let ok = true
  for (p, q) in edges {
    if p == 0 {
      if q < 0 { ok = false }
    } else {
      let t = q / p
      if p < 0 { if t > t0 { t0 = t } } else { if t < t1 { t1 = t } }
    }
  }
  if (not ok) or t0 > t1 { return none }
  let lo = calc.max(t0, -1e9); let hi = calc.min(t1, 1e9)
  ((x0 + lo*dx, y0 + lo*dy), (x0 + hi*dx, y0 + hi*dy))
}

// ── intersect the ray  C + t·(P−C)  with a camera's image plane (z'=f) ──────────
//   solve for t so the point lands on the plane through pp with normal = forward.
#let _ray-plane(C, fr, P) = {
  let n = fr.at(2)
  let pp = _pp(C, fr)
  let d = (P.at(0)-C.at(0), P.at(1)-C.at(1), P.at(2)-C.at(2))
  let num = n.at(0)*(pp.at(0)-C.at(0))+n.at(1)*(pp.at(1)-C.at(1))+n.at(2)*(pp.at(2)-C.at(2))
  let den = n.at(0)*d.at(0)+n.at(1)*d.at(1)+n.at(2)*d.at(2)
  let t = num/den
  (C.at(0)+t*d.at(0), C.at(1)+t*d.at(1), C.at(2)+t*d.at(2))
}

// projections of X into each image plane  → image points x, x'
#let xL = _ray-plane(CL, frL, X)
#let xR = _ray-plane(CR, frR, X)
// epipoles: image of the OTHER centre (baseline pierces this plane here)
#let eL = _ray-plane(CL, frL, CR)   // e  in left  image
#let eR = _ray-plane(CR, frR, CL)   // e' in right image

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // small helpers -------------------------------------------------------------
  let dot3(p, r, col) = { circle(pj(p), radius: r, fill: col, stroke: none) }
  let halo-dot(p, r, col) = {
    circle(pj(p), radius: r + 0.045, fill: white, stroke: none)
    circle(pj(p), radius: r, fill: col, stroke: none)
  }
  let lbl(p, body, col, dx: 0, dy: 0, anc: "center") = {
    let q = pj(p)
    content((q.at(0)+dx, q.at(1)+dy), anchor: anc,
      box(fill: white.transparentize(12%), inset: 1.4pt,
        text(size: 8.5pt, fill: col, weight: "bold", body)))
  }

  // ── epipolar PLANE π = (C, C', X) — filled translucent triangle, drawn first ──
  let pX = pj(X); let pCL = pj(CL); let pCR = pj(CR)
  line(pCL, pCR, pX, close: true, stroke: none, fill: garnet.transparentize(90%))

  // ── image planes (light filled rectangles with a sharp dark frame) ───────────
  let draw-plane(C, fr) = {
    let cs = _plane-corners(C, fr).map(pj)
    line(..cs, close: true, fill: plane-fill.transparentize(8%), stroke: 0.9pt + muted)
  }
  draw-plane(CL, frL)
  draw-plane(CR, frR)

  // ── camera frusta: 4 edges centre → image-plane corners (thin, faint) ────────
  let frustum(C, fr) = {
    let pc = pj(C)
    for cor in _plane-corners(C, fr) { line(pc, pj(cor), stroke: 0.6pt + faint) }
  }
  frustum(CL, frL)
  frustum(CR, frR)

  // ── BASELINE  C—C'  (the line through the two camera centres). It pierces each
  //   image plane exactly at that view's epipole (eL, eR lie ON this segment). ───
  line(pCL, pCR, stroke: (paint: green, thickness: 1.6pt, dash: "dashed"))

  // ── EPIPOLAR LINES on each image plane: the line through (epipole, image pt) ──
  //   computed in local plane coords and CLIPPED to the retina rectangle, so each
  //   reads as a full chord of the image, not an unbounded ray.
  let epiline(C, fr, e, xpt, col) = {
    let ea = _to-uv(C, fr, e)
    let xa = _to-uv(C, fr, xpt)
    let seg = _clip-uv(ea, xa)
    if seg != none {
      let (a, b) = seg
      line(pj(_ip(C, fr, a.at(0), a.at(1))), pj(_ip(C, fr, b.at(0), b.at(1))),
        stroke: 1.6pt + col)
    }
  }
  epiline(CL, frL, eL, xL, blue)
  epiline(CR, frR, eR, xR, blue)

  // ── RAYS  C→X  and  C'→X  (garnet, the focal structure) ──────────────────────
  line(pCL, pX, stroke: 1.7pt + garnet)
  line(pCR, pX, stroke: 1.7pt + garnet)

  // ── markers ──────────────────────────────────────────────────────────────────
  // camera centres
  halo-dot(CL, 0.10, ink)
  halo-dot(CR, 0.10, ink)
  // world point X (focal, garnet, larger)
  halo-dot(X, 0.13, garnet)
  // image points x, x'  (where rays meet planes)
  halo-dot(xL, 0.085, garnet)
  halo-dot(xR, 0.085, garnet)
  // epipoles e, e'
  halo-dot(eL, 0.085, green)
  halo-dot(eR, 0.085, green)

  // ── labels ────────────────────────────────────────────────────────────────────
  lbl(CL, $C$, ink, dx: -0.32, dy: -0.04, anc: "east")
  lbl(CR, $C'$, ink, dx: 0.32, dy: -0.04, anc: "west")
  lbl(X,  $X$, garnet, dx: 0.30, dy: 0.18, anc: "south-west")
  lbl(xL, $x$, garnet, dx: -0.20, dy: 0.16, anc: "south-east")
  lbl(xR, $x'$, garnet, dx: 0.20, dy: 0.16, anc: "south-west")
  lbl(eL, $e$, green, dx: -0.16, dy: 0.20, anc: "south-east")
  lbl(eR, $e'$, green, dx: 0.16, dy: 0.22, anc: "south-west")

  // epipolar-line tags (place near the upper end of each line)
  lbl(_ip(CL, frL, -pw*0.62, ph*0.82), $ell$, blue, dx: -0.10, dy: 0.10, anc: "south-east")
  lbl(_ip(CR, frR, pw*0.52, ph*0.84), $ell'$, blue, dx: 0.10, dy: 0.12, anc: "south-west")

  // baseline tag — slid right of the epipoles into the open gap below the baseline
  let mB = ((pCL.at(0)+pCR.at(0))/2, (pCL.at(1)+pCR.at(1))/2)
  content((mB.at(0) + 1.7, mB.at(1)-0.34), anchor: "north",
    box(fill: white.transparentize(12%), inset: 1.4pt,
      text(size: 8pt, fill: green, style: "italic")[baseline]))

  // epipolar-plane tag (interior of the triangle, upper region)
  let cTri = ((pCL.at(0)+pCR.at(0)+pX.at(0))/3, (pCL.at(1)+pCR.at(1)+pX.at(1))/3)
  content((cTri.at(0)+0.55, cTri.at(1)+0.92), anchor: "center",
    box(fill: white.transparentize(28%), inset: 1pt,
      text(size: 8pt, fill: garnet, style: "italic")[epipolar plane $pi$]))

  // image-plane tags
  lbl(_ip(CL, frL, -pw*0.78, -ph*1.18), [left image], muted, anc: "north")
  lbl(_ip(CR, frR, pw*0.30, -ph*1.18), [right image], muted, anc: "north")

  // ── title + the defining constraint, top-centre over the scene ───────────────
  let bx = (pCL.at(0)+pCR.at(0))/2
  let topy = calc.max(pj(X).at(1), pj(_ip(CL,frL,0,ph)).at(1)) + 0.9
  content((bx, topy + 0.45), anchor: "south",
    text(size: 12pt, weight: "bold", fill: ink)[Epipolar geometry (two-view)])
  content((bx, topy), anchor: "south",
    text(size: 10pt, fill: garnet)[$bold(x)'^top bold(F) bold(x) = 0 quad (bold(E) = [bold(t)]_times bold(R))$])
})
