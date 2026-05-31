// mlatlas · prim/connect3d.typ
// Connectors that live in 3-D and project through the active camera so arrows attach to block
// faces without drifting at non-cabinet cameras. Sharp/orthogonal-friendly, stealth heads.
#import "../adapters/3d.typ": project, projector, cam-iso

// dock: world-space center of a named face of a box centered at `origin3` with sizes (w,h,dep).
// face in: right left top bottom front back. Returns the 3-D point (feed to arrow3d).
#let dock(origin3, w, h, dep, face) = {
  let (ox, oy, oz) = origin3
  let o = (
    right: (w / 2, 0, 0), left: (-w / 2, 0, 0), top: (0, h / 2, 0), bottom: (0, -h / 2, 0),
    front: (0, 0, -dep / 2), back: (0, 0, dep / 2),
  ).at(face, default: (0, 0, 0))
  (ox + o.at(0), oy + o.at(1), oz + o.at(2))
}

// arrow3d: a projected polyline arrow through 3-D points `from` -> ..via -> `to`.
#let arrow3d(draw, from, to, ..via, cam: cam-iso, origin: (0, 0), color: rgb("#243038"), w: 1.4pt, scale: 0.75, dash: none) = {
  let pr = projector(cam: cam, origin: origin)
  let pts = (from,) + via.pos() + (to,)
  draw.line(
    ..pts.map(pr),
    stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: scale),
  )
}

// ribbon3d: a filled quad strip between two 3-D edges (e.g. a residual/conveyor band).
#let ribbon3d(draw, a1, a2, b1, b2, cam: cam-iso, origin: (0, 0), fill: rgb("#FFF2E3"), stroke: none) = {
  let pr = projector(cam: cam, origin: origin)
  draw.line(pr(a1), pr(a2), pr(b2), pr(b1), close: true, fill: fill, stroke: stroke)
}
