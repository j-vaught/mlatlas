// mlatlas · prim/tensor3d.typ
// A labeled N-D tensor as a 3-D box: the most reusable new primitive. Axis dimension labels
// (e.g. seq / dim / heads, or B×C×H×W) are placed at the projected edge midpoints; optional
// title above. Draws via the engine (takes `draw`); tensor3d-fig opens its own canvas.
#import "@preview/cetz:0.5.2"
#import "../adapters/3d.typ": block3d, block3d-anchors, project, cam-iso

#let tensor3d-palette = (
  fill: rgb("#FFF2E3"), edge: rgb("#243038"), text: rgb("#222222"), muted: rgb("#5C5C5C"), accent: rgb("#73000A"),
)

#let tensor3d(
  draw, origin: (0, 0), w: 2.2, h: 2.4, dep: 1.4,
  base: rgb("#FFF2E3"), edge: rgb("#243038"), cam: cam-iso, shade: false, seams: (),
  x-label: none, y-label: none, z-label: none, title: none, muted: rgb("#5C5C5C"), text-fill: rgb("#222222"),
) = {
  block3d(draw, origin: origin, w: w, h: h, dep: dep, base: base, edge: edge, cam: cam, shade: shade, seams: seams)
  let pr(p) = project(p, cam: cam, origin: origin)
  // axis labels at the front-edge midpoints
  if x-label != none {
    let p = pr((0, -h / 2, -dep / 2))
    draw.content((p.at(0), p.at(1) - 0.26), text(size: 7.5pt, fill: muted)[#x-label])
  }
  if y-label != none {
    let p = pr((-w / 2, 0, -dep / 2))
    draw.content((p.at(0) - 0.24, p.at(1)), anchor: "east", text(size: 7.5pt, fill: muted)[#y-label])
  }
  if z-label != none {
    let p = pr((w / 2, h / 2, 0))
    draw.content((p.at(0) + 0.24, p.at(1)), anchor: "west", text(size: 7.5pt, fill: muted)[#z-label])
  }
  if title != none {
    let A = block3d-anchors(origin: origin, w: w, h: h, dep: dep, cam: cam)
    draw.content((origin.at(0), (A.anchor)("top-screen").at(1) + 0.34), text(size: 8.5pt, weight: "bold", fill: text-fill)[#title])
  }
}
#let tensor3d-fig(..args) = cetz.canvas(length: 1cm, {
  import cetz.draw
  tensor3d(draw, ..args)
})
