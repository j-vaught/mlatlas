// Proto v3 — GENERAL camera. Take three angles (like cetz ortho), build a rotation
// matrix, project the 8 corners ourselves, then:
//   * cull faces by rotated-normal sign (works at ANY angle, no hardcoded face list)
//   * silhouette = convex hull of the projected corners (correct order at ANY angle)
//   * fold edges = edges shared by two VISIBLE faces
// Fills stroke:none; edges drawn once -> clean corners. This is the production design.
#import "@preview/cetz:0.5.2"
#set page(width: 26cm, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// --- tiny linear algebra ---
#let mm(A, B) = range(3).map(i => range(3).map(j => range(3).fold(0.0, (s, k) => s + A.at(i).at(k) * B.at(k).at(j))))
#let mv(A, v) = range(3).map(i => range(3).fold(0.0, (s, k) => s + A.at(i).at(k) * v.at(k)))
#let rot(ax, ay, az) = {
  let (cx, sx) = (calc.cos(ax), calc.sin(ax))
  let (cy, sy) = (calc.cos(ay), calc.sin(ay))
  let (cz, sz) = (calc.cos(az), calc.sin(az))
  let Rx = ((1, 0, 0), (0, cx, -sx), (0, sx, cx))
  let Ry = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
  let Rz = ((cz, -sz, 0), (sz, cz, 0), (0, 0, 1))
  mm(Rz, mm(Ry, Rx))
}

// --- convex hull (monotone chain) of 2-D points -> the silhouette outline ---
#let cross(o, a, b) = (a.at(0) - o.at(0)) * (b.at(1) - o.at(1)) - (a.at(1) - o.at(1)) * (b.at(0) - o.at(0))
#let hull(pts) = {
  let P = pts.sorted(key: p => (p.at(0), p.at(1)))
  let lo = ()
  for p in P {
    while lo.len() >= 2 and cross(lo.at(lo.len() - 2), lo.at(lo.len() - 1), p) <= 0 { let _ = lo.pop() }
    lo.push(p)
  }
  let up = ()
  for p in P.rev() {
    while up.len() >= 2 and cross(up.at(up.len() - 2), up.at(up.len() - 1), p) <= 0 { let _ = up.pop() }
    up.push(p)
  }
  lo.slice(0, -1) + up.slice(0, -1)
}

#let CORNERS(w, h, d) = (
  (-w / 2, -h / 2, -d / 2), (w / 2, -h / 2, -d / 2), (w / 2, h / 2, -d / 2), (-w / 2, h / 2, -d / 2),
  (-w / 2, -h / 2, d / 2), (w / 2, -h / 2, d / 2), (w / 2, h / 2, d / 2), (-w / 2, h / 2, d / 2),
)
#let FACES = (
  (idx: (0, 1, 2, 3), n: (0, 0, -1)), (idx: (4, 5, 6, 7), n: (0, 0, 1)),
  (idx: (0, 1, 5, 4), n: (0, -1, 0)), (idx: (3, 2, 6, 7), n: (0, 1, 0)),
  (idx: (0, 3, 7, 4), n: (-1, 0, 0)), (idx: (1, 2, 6, 5), n: (1, 0, 0)),
)

#let block3d(
  draw, origin: (0, 0), w: 2, h: 2, dep: 2,
  base: rgb("#F4C58D"), edge: rgb("#243038"),
  cam: (25deg, -30deg, 0deg), shade: false,
) = {
  let R = rot(cam.at(0), cam.at(1), cam.at(2))
  let C3 = CORNERS(w, h, dep)
  let proj = C3.map(p => { let r = mv(R, p); (origin.at(0) + r.at(0), origin.at(1) + r.at(1)) })
  let Lr = { let l = (0.4, 0.7, 0.65); let m = calc.sqrt(0.4 * 0.4 + 0.7 * 0.7 + 0.65 * 0.65); l.map(v => v / m) }
  // visible faces (rotated normal points toward the +z camera)
  let vis = FACES.filter(f => mv(R, f.n).at(2) > 0.0)
  for f in vis {
    let fill = base
    if shade {
      let nr = mv(R, f.n)
      let d = calc.max(0.0, nr.at(0) * Lr.at(0) + nr.at(1) * Lr.at(1) + nr.at(2) * Lr.at(2))
      let pct = 0.55 + 0.5 * d - 0.8 // delta off the mid baseline
      fill = if pct >= 0 { base.lighten(calc.round(pct * 100) * 1%) } else { base.darken(calc.round(-pct * 100) * 1%) }
    }
    draw.line(..f.idx.map(i => proj.at(i)), close: true, fill: fill, stroke: none)
  }
  // fold edges: visible-visible shared edges (2 common corners)
  for i in range(vis.len()) {
    for j in range(i + 1, vis.len()) {
      let common = vis.at(i).idx.filter(k => vis.at(j).idx.contains(k))
      if common.len() == 2 {
        draw.line(proj.at(common.at(0)), proj.at(common.at(1)), stroke: 0.45pt + edge.lighten(40%))
      }
    }
  }
  // silhouette = convex hull, one closed polyline
  draw.line(..hull(proj), close: true, stroke: 0.95pt + edge)
}

#let demo(title, cam, base: rgb("#FFF2E3"), shade: false) = [
  *#title* — `cam: #cam`
  #cetz.canvas(length: 1cm, {
    import cetz.draw
    block3d(draw, w: 2.0, h: 2.6, dep: 1.5, base: base, cam: cam, shade: shade)
  })
]

#grid(
  columns: (1fr, 1fr, 1fr), gutter: 10pt,
  demo("face-front-ish", (22deg, -30deg, 0deg)),
  demo("isometric", (35.264deg, 45deg, 0deg)),
  demo("steep + roll", (18deg, -58deg, 7deg)),
  demo("face, shaded", (22deg, -30deg, 0deg), base: rgb("#F4C58D"), shade: true),
  demo("iso, shaded", (35.264deg, 45deg, 0deg), base: rgb("#9AA7E6"), shade: true),
  demo("top-down-ish", (62deg, -28deg, 0deg), base: rgb("#E2999B"), shade: true),
)
