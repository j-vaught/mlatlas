// mlatlas · adapters/3d.typ
// Hand-rolled 3-D block engine (a backend adapter: allowed to import cetz; render.typ is not).
//
// WHY hand-rolled, not cetz native ortho/on-xy: cetz native hides the projected 2-D
// coordinates, so back-face culling and a clean single silhouette are impossible (native
// gives corner miter-spikes AND a self-intersecting "bowtie" outline). Here we project the
// 8 corners ourselves -> we always know screen positions -> correct cull + clean silhouette
// at ANY camera angle. Reference prototype: build/probe3d/proto3.typ (rendered clean at 6 angles).
//
// Pipeline per block: rotate (3-angle camera matrix) -> orthographic z-drop -> project the 8
// corners ONCE -> cull faces whose rotated normal faces away -> fill visible faces (stroke:none)
// -> band/seams overlays -> thin fold edges -> ONE convex-hull silhouette polyline drawn LAST.
//
// The engine is THEME-AGNOSTIC: it takes explicit base/edge colors. Renderers own theme lookup.

#import "@preview/cetz:0.5.2"
#import "../theme/contrast.typ": lum

// ---------------------------------------------------------------- linear algebra
#let _mm(A, B) = range(3).map(i => range(3).map(j => range(3).fold(0.0, (s, k) => s + A.at(i).at(k) * B.at(k).at(j))))
#let _mv(A, v) = range(3).map(i => range(3).fold(0.0, (s, k) => s + A.at(i).at(k) * v.at(k)))
#let _rot(ax, ay, az) = {
  let (cx, sx) = (calc.cos(ax), calc.sin(ax))
  let (cy, sy) = (calc.cos(ay), calc.sin(ay))
  let (cz, sz) = (calc.cos(az), calc.sin(az))
  let Rx = ((1, 0, 0), (0, cx, -sx), (0, sx, cx))
  let Ry = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
  let Rz = ((cz, -sz, 0), (sz, cz, 0), (0, 0, 1))
  _mm(Rz, _mm(Ry, Rx))
}

// ---------------------------------------------------------------- camera presets
// angle triple = (pitch about x, yaw about y, roll about z) — mirrors cetz ortho(x,y,z).
#let cam-iso = (35.264deg, 45deg, 0deg) // DEFAULT
#let cam-cabinet = (25deg, -30deg, 0deg)
#let cam-face = (22deg, -30deg, 0deg)
#let cam-top-down = (62deg, -28deg, 0deg)
#let CAMERAS = (iso: cam-iso, cabinet: cam-cabinet, face: cam-face, "top-down": cam-top-down)
#let _resolve-cam(cam) = if type(cam) == str { CAMERAS.at(cam, default: cam-iso) } else { cam }

// ---------------------------------------------------------------- box geometry (centered)
#let _CORNERS(w, h, d) = (
  (-w / 2, -h / 2, -d / 2), (w / 2, -h / 2, -d / 2), (w / 2, h / 2, -d / 2), (-w / 2, h / 2, -d / 2),
  (-w / 2, -h / 2, d / 2), (w / 2, -h / 2, d / 2), (w / 2, h / 2, d / 2), (-w / 2, h / 2, d / 2),
)
#let _FACES = (
  (n: (0, 0, -1), idx: (0, 1, 2, 3), name: "front"),
  (n: (0, 0, 1), idx: (4, 5, 6, 7), name: "back"),
  (n: (0, -1, 0), idx: (0, 1, 5, 4), name: "bottom"),
  (n: (0, 1, 0), idx: (3, 2, 6, 7), name: "top"),
  (n: (-1, 0, 0), idx: (0, 3, 7, 4), name: "left"),
  (n: (1, 0, 0), idx: (1, 2, 6, 5), name: "right"),
)

// ---------------------------------------------------------------- convex hull (silhouette)
#let _cross(o, a, b) = (a.at(0) - o.at(0)) * (b.at(1) - o.at(1)) - (a.at(1) - o.at(1)) * (b.at(0) - o.at(0))
#let _hull(pts) = {
  let P = pts.sorted(key: p => (p.at(0), p.at(1)))
  let lo = ()
  for p in P {
    while lo.len() >= 2 and _cross(lo.at(lo.len() - 2), lo.at(lo.len() - 1), p) <= 0 { let _ = lo.pop() }
    lo.push(p)
  }
  let up = ()
  for p in P.rev() {
    while up.len() >= 2 and _cross(up.at(up.len() - 2), up.at(up.len() - 1), p) <= 0 { let _ = up.pop() }
    up.push(p)
  }
  lo.slice(0, -1) + up.slice(0, -1)
}

// ---------------------------------------------------------------- projection (public)
#let project(p, cam: cam-iso, origin: (0, 0)) = {
  let c = _resolve-cam(cam)
  let r = _mv(_rot(c.at(0), c.at(1), c.at(2)), p)
  (origin.at(0) + r.at(0), origin.at(1) + r.at(1))
}
#let project-z(p, cam: cam-iso) = {
  let c = _resolve-cam(cam)
  _mv(_rot(c.at(0), c.at(1), c.at(2)), p).at(2)
}
#let projector(cam: cam-iso, origin: (0, 0)) = {
  let c = _resolve-cam(cam)
  let R = _rot(c.at(0), c.at(1), c.at(2))
  (p) => { let r = _mv(R, p); (origin.at(0) + r.at(0), origin.at(1) + r.at(1)) }
}

// Anchor handle (pure computation — NO drawing). block3d itself returns drawn content (a cetz
// constraint), so attach-points are computed here. Returns projected bbox + per-face centers + far-z.
#let block3d-anchors(origin: (0, 0), w: 2, h: 2, dep: 2, cam: cam-iso) = {
  let c = _resolve-cam(cam)
  let R = _rot(c.at(0), c.at(1), c.at(2))
  let pr(p) = { let r = _mv(R, p); (origin.at(0) + r.at(0), origin.at(1) + r.at(1)) }
  let C = _CORNERS(w, h, dep)
  let P = C.map(pr)
  let us = P.map(p => p.at(0))
  let vs = P.map(p => p.at(1))
  let vis = _FACES.filter(f => _mv(R, f.n).at(2) > 0.0).map(f => f.name)
  (
    proj: P,
    center: origin,
    umin: calc.min(..us), umax: calc.max(..us), vmin: calc.min(..vs), vmax: calc.max(..vs),
    "far-z": C.fold(0.0, (s, p) => s + _mv(R, p).at(2)) / 8,
    vis: vis,
    // projected face-center anchors (named) + screen-bbox anchors for connectors/labels
    anchor: (name) => {
      let fc = (
        right: (w / 2, 0, 0), left: (-w / 2, 0, 0), top: (0, h / 2, 0), bottom: (0, -h / 2, 0),
        front: (0, 0, -dep / 2), back: (0, 0, dep / 2),
        "front-top": (0, h / 2, -dep / 2), "front-bottom": (0, -h / 2, -dep / 2),
      )
      if name == "east" { (calc.max(..us), origin.at(1)) } else if name == "west" {
        (calc.min(..us), origin.at(1))
      } else if name == "bottom-screen" { (origin.at(0), calc.min(..vs)) } else if name == "top-screen" {
        (origin.at(0), calc.max(..vs))
      } else { pr(fc.at(name, default: (0, 0, 0))) }
    },
  )
}

// ---------------------------------------------------------------- the block (draws; returns content)
#let block3d(
  draw,
  origin: (0, 0), w: 2, h: 2, dep: 2,
  base: rgb("#FFF2E3"), edge: rgb("#243038"),
  cam: cam-iso, shade: false,
  seams: (), band: none, band-frac: 0.0,
  sil-weight: 0.95pt, fold-weight: 0.45pt, opacity: 100%,
) = {
  let c = _resolve-cam(cam)
  let R = _rot(c.at(0), c.at(1), c.at(2))
  let pr(p) = { let r = _mv(R, p); (origin.at(0) + r.at(0), origin.at(1) + r.at(1)) }
  let C = _CORNERS(w, h, dep)
  let P = C.map(pr)
  // global light (object space) for shade — consistent across all blocks regardless of camera
  let L = { let l = (0.4, 0.7, 0.65); let m = calc.sqrt(0.4 * 0.4 + 0.7 * 0.7 + 0.65 * 0.65); l.map(v => v / m) }
  let face-fill(n) = {
    if not shade { base } else {
      let nr = _mv(R, n)
      let d = calc.max(0.0, nr.at(0) * L.at(0) + nr.at(1) * L.at(1) + nr.at(2) * L.at(2))
      let pct = 0.55 + 0.5 * d - 0.8
      if pct >= 0 { base.lighten(calc.round(pct * 100) * 1%) } else { base.darken(calc.round(-pct * 100) * 1%) }
    }
  }
  let vis = _FACES.filter(f => _mv(R, f.n).at(2) > 0.0)
  let vis-names = vis.map(f => f.name)
  let bf = if opacity == 100% { (col) => col } else { (col) => col.transparentize(100% - opacity) }
  // (1) visible face fills, stroke:none
  for f in vis {
    draw.line(..f.idx.map(i => P.at(i)), close: true, fill: bf(face-fill(f.n)), stroke: none)
  }
  // (2) ReLU band: clamp each visible face to x in [x_b, w/2] and fill the trailing region
  if band != none and band-frac > 0 {
    let x-b = w / 2 - band-frac * w
    for f in vis {
      let cs = f.idx.map(i => C.at(i))
      if cs.map(p => p.at(0)).fold(false, (a, p) => a or p > x-b) {
        let q = cs.map(p => pr((calc.max(p.at(0), x-b), p.at(1), p.at(2))))
        draw.line(..q, close: true, fill: bf(if f.name == "top" { band.lighten(12%) } else { band }), stroke: none)
      }
    }
  }
  // (3) internal fold edges (shared by two visible faces) + seam ribs
  let fe = fold-weight + edge.lighten(40%)
  for i in range(vis.len()) {
    for j in range(i + 1, vis.len()) {
      let common = vis.at(i).idx.filter(k => vis.at(j).idx.contains(k))
      if common.len() == 2 {
        let a = P.at(common.at(0))
        let b = P.at(common.at(1))
        if calc.abs(a.at(0) - b.at(0)) > 1e-6 or calc.abs(a.at(1) - b.at(1)) > 1e-6 {
          draw.line(a, b, stroke: fe)
        }
      }
    }
  }
  for t in seams {
    let xt = -w / 2 + t * w
    let segs = (
      ("top", (xt, h / 2, -dep / 2), (xt, h / 2, dep / 2)),
      ("bottom", (xt, -h / 2, -dep / 2), (xt, -h / 2, dep / 2)),
      ("front", (xt, -h / 2, -dep / 2), (xt, h / 2, -dep / 2)),
      ("back", (xt, -h / 2, dep / 2), (xt, h / 2, dep / 2)),
    )
    for (nm, a, b) in segs {
      if vis-names.contains(nm) { draw.line(pr(a), pr(b), stroke: fe) }
    }
  }
  // (4) silhouette = convex hull, ONE closed polyline, drawn LAST
  let H = _hull(P)
  if H.len() >= 3 { draw.line(..H, close: true, stroke: sil-weight + edge) }
}

// ---------------------------------------------------------------- feature-map (ML shortcut, cm-scale)
#let _fm-h(spatial) = calc.max(0.8, calc.min(3.4, 0.7 + spatial * 0.009))
#let _fm-dep(channels) = calc.max(0.4, calc.min(2.4, 0.3 + calc.log(calc.max(channels, 1), base: 2) * 0.19))
#let feature-map(
  draw, origin,
  spatial: 28, channels: 16,
  base: rgb("#F4C58D"), edge: rgb("#243038"),
  cam: cam-iso, shade: false, relu: false, seams: (),
  width: 0.34, h-fn: auto, dep-fn: auto, band-frac: 0.18,
) = {
  let h = if h-fn == auto { _fm-h(spatial) } else { (h-fn)(spatial) }
  let dep = if dep-fn == auto { _fm-dep(channels) } else { (dep-fn)(channels) }
  block3d(
    draw, origin: origin, w: width, h: h, dep: dep, base: base, edge: edge, cam: cam, shade: shade,
    seams: seams, band: if relu { base.darken(24%).saturate(18%) } else { none }, band-frac: if relu { band-frac } else { 0.0 },
  )
}

// ---------------------------------------------------------------- scene (depth-sorted blocks)
// blocks = array of spec dicts: (origin, w, h, dep, base?, edge?, cam?, shade?, seams?, band?, band-frac?, pos3?)
// Painter's order: draw FAR first (ascending rotated-z of pos3/center), then `extras` on top.
#let scene(draw, cam: cam-iso, shade: false, edge: rgb("#243038"), blocks: (), extras: none) = {
  let c = _resolve-cam(cam)
  let R = _rot(c.at(0), c.at(1), c.at(2))
  let keyed = blocks.map(b => {
    let p3 = b.at("pos3", default: (b.origin.at(0), b.origin.at(1), 0))
    (b: b, z: _mv(R, p3).at(2))
  })
  let ordered = keyed.sorted(key: e => e.z)
  for e in ordered {
    let b = e.b
    block3d(
      draw,
      origin: b.origin, w: b.w, h: b.h, dep: b.dep,
      base: b.at("base", default: rgb("#FFF2E3")), edge: b.at("edge", default: edge),
      cam: b.at("cam", default: cam), shade: b.at("shade", default: shade),
      seams: b.at("seams", default: ()), band: b.at("band", default: none), band-frac: b.at("band-frac", default: 0.0),
    )
  }
  if extras != none { extras }
}

// the ONLY function here that opens a cetz canvas (so non-canvas callers stay backend-blind)
#let scene-canvas(cam: cam-iso, length: 1cm, shade: false, edge: rgb("#243038"), blocks: (), extras: none) = {
  cetz.canvas(length: length, {
    import cetz.draw
    scene(draw, cam: cam, shade: shade, edge: edge, blocks: blocks, extras: extras)
  })
}

// ---------------------------------------------------------------- IR bridge (keeps render.typ cetz-free)
#let tensor3d-content(dims: (), axes: (), base: rgb("#FFF2E3"), edge: rgb("#243038"), cam: cam-iso, shade: false, seams: ()) = {
  let w = dims.at(0, default: 1.2)
  let h = dims.at(1, default: 1.6)
  let dep = dims.at(2, default: 1.0)
  cetz.canvas(length: 1cm, {
    import cetz.draw
    block3d(draw, origin: (0, 0), w: w, h: h, dep: dep, base: base, edge: edge, cam: cam, shade: shade, seams: seams)
  })
}
