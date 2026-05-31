// Structure from Motion / Bundle Adjustment — the joint optimization graph.
// Several camera poses (R,t)_i view ONE shared sparse 3-D point cloud {X_j}. Each camera projects
// a point through its frustum onto an image plane; reprojection rays (3-D point -> camera center)
// are the residuals BA minimizes. Built on the hand-rolled 3-D engine (project / projector).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- palette ------------------------------------------------------------
  let ink = rgb("#363636")
  let garnet = rgb("#73000A")
  let blue = rgb("#466A9F")
  let dblue = rgb("#1F414D")
  let mid = rgb("#5C5C5C")
  let faint = rgb("#A2A2A2")
  let beige = rgb("#FFF2E3")

  // ---- camera + projection ------------------------------------------------
  let cam = (24deg, -32deg, 0deg) // axonometric viewpoint
  let pr = projector(cam: cam, origin: (0, 0))
  let zof = p => project-z(p, cam: cam) // painter-sort key (larger = nearer viewer)

  // ============================ 3-D POINT CLOUD ============================
  // A sparse cluster of scene points {X_j} (a small "building corner" structure).
  let cloud = (
    (-0.8, 1.7, 0.2), (0.3, 2.1, -0.5), (1.0, 1.4, 0.6), (-0.2, 1.0, 1.0),
    (0.7, 0.6, -0.3), (-1.1, 0.4, -0.6), (1.3, 0.1, 0.4), (-0.5, -0.2, 0.7),
    (0.2, -0.5, -0.4), (1.0, -0.8, 0.1), (-1.0, -0.9, 0.3), (0.0, 1.5, 0.0),
    (0.6, 1.9, 0.9), (-0.9, 1.2, -0.2), (1.4, 0.8, -0.5), (-0.3, -1.1, -0.2),
  )

  // ============================ CAMERA POSES ==============================
  // Each pose: center C (world), a "look" target, an up hint, image-plane half-size & focal-ish
  // depth f. We build a small right-handed frame (rgt, up, fwd) pointing at the target so the
  // frustum visibly faces the cloud. The garnet camera (index 0) is the focal accent.
  let target = (0.1, 0.5, 0.0)
  let cams = (
    (C: (-4.6, -1.4, 2.9), accent: true),  // 0 — garnet focal camera (front-left)
    (C: (4.8, 0.2, 2.0), accent: false),   // 1 — right
    (C: (0.4, -4.0, 3.0), accent: false),  // 2 — low front
    (C: (-1.2, 4.0, -2.4), accent: false), // 3 — high back-left
  )
  let half = 0.62 // image-plane half width/height
  let fdep = 1.05 // distance camera center -> image plane

  let unit = v => {
    let m = calc.sqrt(v.at(0) * v.at(0) + v.at(1) * v.at(1) + v.at(2) * v.at(2))
    if m == 0 { v } else { (v.at(0) / m, v.at(1) / m, v.at(2) / m) }
  }
  let sub = (a, b) => (a.at(0) - b.at(0), a.at(1) - b.at(1), a.at(2) - b.at(2))
  let add = (a, b) => (a.at(0) + b.at(0), a.at(1) + b.at(1), a.at(2) + b.at(2))
  let scl = (a, s) => (a.at(0) * s, a.at(1) * s, a.at(2) * s)
  let crs = (a, b) => (
    a.at(1) * b.at(2) - a.at(2) * b.at(1),
    a.at(2) * b.at(0) - a.at(0) * b.at(2),
    a.at(0) * b.at(1) - a.at(1) * b.at(0),
  )

  // Build per-camera frame + the four image-plane corners (world coords).
  let frames = cams.map(cm => {
    let fwd = unit(sub(target, cm.C))
    let uph = (0, 0, 1) // world up-ish hint
    let rgt = unit(crs(fwd, uph))
    let up = unit(crs(rgt, fwd))
    let pc = add(cm.C, scl(fwd, fdep)) // image-plane center
    let corners = (
      add(add(pc, scl(rgt, -half)), scl(up, -half)),
      add(add(pc, scl(rgt, half)), scl(up, -half)),
      add(add(pc, scl(rgt, half)), scl(up, half)),
      add(add(pc, scl(rgt, -half)), scl(up, half)),
    )
    (C: cm.C, accent: cm.accent, pc: pc, rgt: rgt, up: up, fwd: fwd, corners: corners)
  })

  // ---- draw order via crude painter sort over all primitives --------------
  // We split into FAR cameras (drawn first) and points; reprojection rays go on top.
  let cam-z = frames.map(f => (f: f, z: zof(f.C)))
  let cam-ord = cam-z.sorted(key: e => e.z)

  // ============================ DRAW: ground grid ============================
  // A faint reference floor (z=0 plane) anchors the 3-D scene.
  let g = 5.0
  for i in range(-2, 3) {
    let t = i * (g / 2) / 2
    draw.line(pr((-g, t, -2.4)), pr((g, t, -2.4)), stroke: 0.4pt + rgb("#ECECEC"))
    draw.line(pr((t * 2, -g, -2.4)), pr((t * 2, g, -2.4)), stroke: 0.4pt + rgb("#ECECEC"))
  }

  // ============================ DRAW: cameras (far first) ====================
  let draw-cam(f) = {
    let col = if f.accent { garnet } else { dblue }
    let pC = pr(f.C)
    let pcorn = f.corners.map(pr)
    // frustum side edges (apex -> 4 image corners)
    for k in range(4) {
      draw.line(pC, pcorn.at(k), stroke: 0.7pt + col.lighten(if f.accent { 0% } else { 18% }))
    }
    // image plane (translucent quad)
    draw.line(
      ..pcorn, close: true,
      fill: if f.accent { garnet.lighten(82%) } else { blue.lighten(80%) },
      stroke: 0.9pt + col,
    )
    // small "up" tick on top edge so orientation reads
    let topmid = scl(add(f.corners.at(2), f.corners.at(3)), 0.5)
    draw.line(pr(topmid), pr(add(topmid, scl(f.up, 0.26))), stroke: 0.8pt + col)
    // camera-center marker
    draw.circle(pC, radius: 0.085, fill: col, stroke: 0.6pt + white)
  }
  for e in cam-ord { draw-cam(e.f) }

  // ============================ DRAW: reprojection rays =====================
  // A subset of (point, camera) pairs gets an explicit ray X_j -> C_i. These are the BA
  // residuals: the camera observes a 2-D measurement; the ray is the back-projection.
  // Garnet rays belong to the focal camera; others are thin neutral.
  let rays = (
    (2, 0), (5, 0), (9, 0), (12, 0), // focal (garnet) camera 0
    (0, 1), (6, 1), (10, 1),
    (3, 2), (8, 2), (14, 2),
    (1, 3), (7, 3),
  )
  for (pj, ci) in rays {
    let X = cloud.at(pj)
    let f = frames.at(ci)
    // where the ray pierces the image plane: intersect segment C->X with the plane.
    // param along fwd: project (X - C) onto fwd, scale to image-plane depth.
    let d = sub(X, f.C)
    let along = d.at(0) * f.fwd.at(0) + d.at(1) * f.fwd.at(1) + d.at(2) * f.fwd.at(2)
    let hit = if along > 0.001 { add(f.C, scl(d, fdep / along)) } else { f.pc }
    if f.accent {
      // residual ray to the focal camera — garnet, with the measurement dot on the image plane
      draw.line(pr(X), pr(hit), stroke: (paint: garnet, thickness: 0.9pt, dash: none))
      draw.line(pr(hit), pr(f.C), stroke: (paint: garnet.lighten(45%), thickness: 0.5pt, dash: "dotted"))
      draw.circle(pr(hit), radius: 0.05, fill: garnet, stroke: none) // projected measurement x_ij
    } else {
      draw.line(pr(X), pr(f.C), stroke: (paint: faint, thickness: 0.45pt, dash: "dotted"))
      draw.circle(pr(hit), radius: 0.035, fill: mid, stroke: none)
    }
  }

  // ============================ DRAW: the point cloud =======================
  // Painter-sorted so nearer points sit on top; size cues depth slightly.
  let pt-z = range(cloud.len()).map(j => (j: j, z: zof(cloud.at(j))))
  for e in pt-z.sorted(key: r => r.z) {
    let X = cloud.at(e.j)
    let p = pr(X)
    let r = 0.072 + 0.018 * (e.z + 2) / 4
    draw.circle(p, radius: r, fill: beige, stroke: 0.9pt + ink)
  }

  // ============================ LABELS ======================================
  let f0 = frames.at(0)
  // focal-camera ray endpoints we reference in callouts.
  let Xr = cloud.at(5)
  let dr = sub(Xr, f0.C)
  let alr = dr.at(0) * f0.fwd.at(0) + dr.at(1) * f0.fwd.at(1) + dr.at(2) * f0.fwd.at(2)
  let hitr = add(f0.C, scl(dr, fdep / alr))

  // (a) scene-point callout — leader line from an upper-right empty area to point X_12.
  let Xlab = cloud.at(2)
  let lp = (pr(Xlab).at(0) + 1.7, pr(Xlab).at(1) + 1.0)
  draw.line(pr(Xlab), lp, stroke: 0.4pt + mid)
  draw.content(
    (rel: (0.05, 0.0), to: lp),
    text(fill: ink)[scene point $X_j in RR^3$ #h(2pt) #text(size: 7.5pt, fill: mid)[(sparse cloud)]],
    anchor: "west",
  )

  // (b) focal camera pose label, with a short leader to the camera center.
  let cpl = (pr(f0.C).at(0) - 0.2, pr(f0.C).at(1) - 1.0)
  draw.line(pr(f0.C), cpl, stroke: 0.4pt + garnet.lighten(20%))
  draw.content(
    (rel: (-0.04, 0.0), to: cpl),
    text(fill: garnet)[camera $i$: pose $(R_i, t_i)$],
    anchor: "north-east",
  )
  // (c) image-plane label, above-left of the focal frustum's top corner.
  draw.content(
    (rel: (-0.06, 0.46), to: pr(f0.corners.at(3))),
    text(size: 8pt, fill: garnet)[image plane],
    anchor: "south-east",
  )
  // (d) measurement callout on the garnet ray hit (one labelled dot), placed up-left
  //     with a short leader so the text clears the frustum silhouette.
  let mlp = (pr(hitr).at(0) - 0.55, pr(hitr).at(1) + 0.30)
  draw.line(pr(hitr), mlp, stroke: 0.4pt + garnet.lighten(20%))
  draw.content(
    (rel: (-0.04, 0.0), to: mlp),
    text(size: 8pt, fill: garnet)[measurement $x_(i j)$],
    anchor: "east",
  )

  // (e) other camera pose labels.
  draw.content((rel: (0.30, -0.05), to: pr(frames.at(1).C)), text(size: 8.5pt, fill: dblue)[$(R_k, t_k)$], anchor: "west")
  draw.content((rel: (0.0, -0.34), to: pr(frames.at(2).C)), text(size: 8.5pt, fill: dblue)[$(R_k, t_k)$], anchor: "north")
  draw.content((rel: (0.0, 0.32), to: pr(frames.at(3).C)), text(size: 8.5pt, fill: dblue)[$(R_k, t_k)$], anchor: "south")

  // (f) reprojection-residual callout — placed in the open region right of the focal rays,
  //     with a leader to the midpoint of the highlighted ray.
  let Xb = cloud.at(2)
  let db = sub(Xb, f0.C)
  let alb = db.at(0) * f0.fwd.at(0) + db.at(1) * f0.fwd.at(1) + db.at(2) * f0.fwd.at(2)
  let hitb = add(f0.C, scl(db, fdep / alb))
  let mid-ray = (0.5 * pr(Xb).at(0) + 0.5 * pr(hitb).at(0), 0.5 * pr(Xb).at(1) + 0.5 * pr(hitb).at(1))
  let fbox = (mid-ray.at(0) + 2.0, mid-ray.at(1) - 1.7)
  draw.line(mid-ray, fbox, stroke: 0.4pt + garnet.lighten(30%))
  draw.content(
    (rel: (0.0, -0.06), to: fbox),
    box(
      inset: 3pt, fill: white, stroke: 0.5pt + garnet.lighten(20%),
      text(size: 8.5pt, fill: garnet)[reprojection residual $#h(1pt) e_(i j) = norm(pi(R_i X_j + t_i) - x_(i j))$],
    ),
    anchor: "north",
  )
})

// ---- caption / objective -------------------------------------------------
#v(2pt)
#align(center, box(width: 16.5cm)[
  #set text(size: 8.5pt, fill: rgb("#363636"))
  *Structure from Motion / Bundle Adjustment.* Jointly recover camera poses
  $(R_i, t_i)$ and 3-D points $X_j$ by minimizing total reprojection error
  $ min_(\{R_i, t_i\}, \{X_j\}) sum_(i) sum_(j) rho(norm(pi(R_i X_j + t_i) - x_(i j))^2). $
])
