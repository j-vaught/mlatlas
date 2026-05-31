// mlatlas · renderers/cnn3d.typ
// 3-D vision-volume family on the hand-rolled engine (src/adapters/3d.typ): a themed `volume`
// atom, orthogonal (no-curve) skip routing, a generic `feature-stack`, and the architecture
// renderers `resnet3d` (shrink-and-deepen residual pyramid) and `unet3d` (encoder -> bottleneck
// -> decoder volumes with skips bracketed over the top). All print-first, sharp, stealth arrows.
//
// NOTE on the engine contract: block3d/volume DRAW (their content is collected by the cetz
// canvas) and must be called as statements. Anchor points are obtained from the PURE functions
// block3d-anchors / vol-anchors (no drawing) so geometry can be queried without a draw join.

#import "@preview/cetz:0.5.2"
#import "../adapters/3d.typ": block3d, block3d-anchors, project, cam-cabinet, cam-iso

#let cnn3d-palette = (
  input: rgb("#E9EDF0"),
  conv: rgb("#F4C58D"), conv-band: rgb("#E07B39"),
  pool: rgb("#E2999B"),
  up: rgb("#8FC7C7"),
  fc: rgb("#9AA7E6"),
  bottleneck: rgb("#C7B3E0"),
  skip: rgb("#73000A"),
  edge: rgb("#243038"), text: rgb("#222222"), muted: rgb("#5C5C5C"),
)

// spatial -> front-face height; channels -> depth (log). cm-scale (these renderers use length:1cm).
#let _vh(spatial) = calc.max(0.9, calc.min(3.6, 0.8 + spatial * 0.009))
#let _vd(channels) = calc.max(0.5, calc.min(2.7, 0.4 + calc.log(calc.max(channels, 1), base: 2) * 0.19))
#let _vdims(spatial, channels, n: 1, width: auto) = (
  if width == auto { 0.34 * n } else { width }, _vh(spatial), _vd(channels),
)
#let vol-anchors(origin, spatial, channels, n: 1, width: auto, cam: cam-cabinet) = {
  let (w, h, dep) = _vdims(spatial, channels, n: n, width: width)
  block3d-anchors(origin: origin, w: w, h: h, dep: dep, cam: cam)
}

// one themed feature-volume + optional external label/sublabel. DRAWS ONLY (no return).
#let volume(
  draw, origin, spatial, channels,
  base: none, palette: cnn3d-palette, cam: cam-cabinet,
  n: 1, relu: false, shade: false, width: auto, label: none, sub: none, label-gap: 0.34,
) = {
  let (w, h, dep) = _vdims(spatial, channels, n: n, width: width)
  let seams = if n > 1 { range(1, n).map(k => k / n) } else { () }
  let fill = if base == none { palette.conv } else { base }
  block3d(
    draw, origin: origin, w: w, h: h, dep: dep, base: fill, edge: palette.edge, cam: cam, shade: shade,
    seams: seams, band: if relu { palette.conv-band } else { none }, band-frac: if relu { 0.16 } else { 0.0 },
  )
  if label != none {
    let A = block3d-anchors(origin: origin, w: w, h: h, dep: dep, cam: cam)
    let ly = (A.anchor)("bottom-screen").at(1) - label-gap
    draw.content((origin.at(0), ly), text(size: 8pt, weight: "bold", fill: palette.text)[#label])
    if sub != none { draw.content((origin.at(0), ly - 0.3), text(size: 6.5pt, fill: palette.muted)[#sub]) }
  }
}

// orthogonal skip route (NO curves): up to `lift`, across, down into the target. Stealth, garnet.
#let _skip(draw, p1, p2, lift, color: rgb("#73000A"), w: 1.1pt) = {
  draw.line(p1, (p1.at(0), lift), (p2.at(0), lift), p2, stroke: w + color, mark: (end: "stealth", scale: 0.6))
}
// stealth flow connector between two screen points
#let _arrow(draw, p1, p2, color: rgb("#243038")) = {
  draw.line(p1, p2, stroke: 1.6pt + color.transparentize(10%), mark: (end: "stealth", scale: 0.8))
}

// ---------------------------------------------------------------- feature-stack (generic LTR)
// layers: array of dicts (spatial, channels, n?, relu?, base?, label?, sub?). cm-scale cousin of
// the pt-scale cnn(); returns nothing (draws). Use inside your own cetz.canvas, or feature-stack-fig.
#let feature-stack(draw, layers, palette: cnn3d-palette, cam: cam-cabinet, gap: 0.85, origin: (0, 0)) = {
  let cursor = origin.at(0)
  let prev = none
  for L in layers {
    let sp = L.at("spatial", default: 28)
    let ch = L.at("channels", default: 16)
    let n = L.at("n", default: 1)
    let w-ov = L.at("width", default: auto)
    let A0 = vol-anchors((0, 0), sp, ch, n: n, width: w-ov, cam: cam)
    let sw = A0.umax - A0.umin
    if prev != none { cursor = cursor + gap }
    let ox = cursor + (-A0.umin)
    let A = vol-anchors((ox, origin.at(1)), sp, ch, n: n, width: w-ov, cam: cam)
    if prev != none {
      _arrow(draw, (prev.at(0) + 0.04, origin.at(1)), ((A.anchor)("west").at(0) - 0.04, origin.at(1)), color: palette.edge)
    }
    volume(
      draw, (ox, origin.at(1)), sp, ch, base: L.at("base", default: palette.conv), palette: palette, cam: cam,
      n: n, relu: L.at("relu", default: false), label: L.at("label", default: none), sub: L.at("sub", default: none),
      width: w-ov,
    )
    cursor = cursor + sw
    prev = (A.anchor)("east")
  }
}
#let feature-stack-fig(layers, ..args) = cetz.canvas(length: 1cm, {
  import cetz.draw
  feature-stack(draw, layers, ..args)
})

// ---------------------------------------------------------------- resnet3d (residual pyramid)
#let resnet3d(
  stages: (
    (56, 64, [stage1], 3), (28, 128, [stage2], 4),
    (14, 256, [stage3], 6), (7, 512, [stage4], 3),
  ),
  palette: cnn3d-palette, cam: cam-cabinet, gap: 0.9,
) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let lift = 2.6
  let cursor = 0.0
  let prev = none
  // stem
  let sa = vol-anchors((0, 0), 112, 3, cam: cam)
  let sox = cursor + (-sa.umin)
  volume(draw, (sox, 0), 112, 3, base: palette.input, palette: palette, cam: cam, label: [input], sub: [224²×3])
  let SA = vol-anchors((sox, 0), 112, 3, cam: cam)
  cursor = cursor + (SA.umax - SA.umin) + gap
  prev = (SA.anchor)("east")
  for st in stages {
    let (sp, ch, lab, n) = st
    let A0 = vol-anchors((0, 0), sp, ch, n: n, cam: cam)
    let ox = cursor + (-A0.umin)
    let A = vol-anchors((ox, 0), sp, ch, n: n, cam: cam)
    _arrow(draw, (prev.at(0) + 0.04, 0), ((A.anchor)("west").at(0) - 0.04, 0), color: palette.edge)
    volume(draw, (ox, 0), sp, ch, base: palette.conv, palette: palette, cam: cam, n: n, relu: true, label: lab, sub: [#sp²×#ch])
    let ty = (A.anchor)("top-screen").at(1) + 0.1
    _skip(draw, ((A.anchor)("west").at(0), ty), ((A.anchor)("east").at(0), ty), lift, color: palette.skip)
    cursor = cursor + (A0.umax - A0.umin) + gap
    prev = (A.anchor)("east")
  }
  // head
  let ha = vol-anchors((0, 0), 7, 1000, width: 0.22, cam: cam)
  let hox = cursor + (-ha.umin)
  _arrow(draw, (prev.at(0) + 0.04, 0), ((vol-anchors((hox, 0), 7, 1000, width: 0.22, cam: cam).anchor)("west").at(0) - 0.04, 0), color: palette.edge)
  volume(draw, (hox, 0), 7, 1000, base: palette.fc, palette: palette, cam: cam, width: 0.22, label: [fc], sub: [1000])
})

// ---------------------------------------------------------------- unet3d (encoder/decoder U)
// Encoder volumes descend the left arm (spatial down, channels up), a bottleneck at the base,
// decoder volumes mirror up the right arm; skip connections bridge each level horizontally.
#let unet3d(
  levels: ((224, 64), (112, 128), (56, 256), (28, 512)),
  bottleneck: (14, 1024),
  palette: cnn3d-palette, cam: cam-cabinet, dy: 3.0, arm: 7.5,
) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let L = levels.len()
  let encx = 0.0
  let decx = arm
  let yof(i) = -i * dy
  let by = yof(L - 1) - dy * 1.1 // bottleneck sits below the lowest level
  let bx = (encx + decx) / 2

  let down(p1, p2) = draw.line(p1, p2, stroke: 1.5pt + palette.edge.transparentize(10%), mark: (end: "stealth", scale: 0.75))

  // ENCODER (left, descending) + DECODER (right, ascending); collect anchors for skips
  let encA = ()
  let decA = ()
  for (i, lv) in levels.enumerate() {
    let (sp, ch) = lv
    let y = yof(i)
    volume(draw, (encx, y), sp, ch, base: palette.conv, palette: palette, cam: cam, relu: true)
    volume(draw, (decx, y), sp, ch, base: palette.up, palette: palette, cam: cam, relu: false)
    encA.push(vol-anchors((encx, y), sp, ch, cam: cam))
    decA.push(vol-anchors((decx, y), sp, ch, cam: cam))
  }
  // bottleneck
  let (bsp, bch) = bottleneck
  volume(draw, (bx, by), bsp, bch, base: palette.bottleneck, palette: palette, cam: cam, relu: true)
  let bA = vol-anchors((bx, by), bsp, bch, cam: cam)

  // encoder down-arrows, decoder up-arrows
  for i in range(L - 1) {
    down(((encA.at(i)).anchor)("bottom-screen"), ((encA.at(i + 1)).anchor)("top-screen"))
    down(((decA.at(i + 1)).anchor)("bottom-screen"), ((decA.at(i)).anchor)("top-screen"))
  }
  // into / out of the bottleneck
  down(((encA.at(L - 1)).anchor)("bottom-screen"), ((bA.anchor)("west")))
  down(((bA.anchor)("east")), ((decA.at(L - 1)).anchor)("bottom-screen"))

  // skip connections (horizontal, garnet, dashed — copy-and-concatenate)
  for i in range(L) {
    let p1 = ((encA.at(i)).anchor)("east")
    let p2 = ((decA.at(i)).anchor)("west")
    draw.line(
      (p1.at(0) + 0.05, yof(i)), (p2.at(0) - 0.05, yof(i)),
      stroke: (paint: palette.skip, thickness: 1.1pt, dash: "dashed"), mark: (end: "stealth", scale: 0.6),
    )
  }
  // level labels (channels) just left of the encoder arm
  for (i, lv) in levels.enumerate() {
    let (sp, ch) = lv
    draw.content((((encA.at(i)).anchor)("west").at(0) - 0.35, yof(i)), anchor: "east", text(size: 7pt, fill: palette.muted)[#sp²×#ch])
  }
  draw.content((bx, ((bA.anchor)("bottom-screen").at(1)) - 0.32), text(size: 7pt, weight: "bold", fill: palette.text)[bottleneck #text(fill: palette.muted)[#bsp²×#bch]])
  draw.content((encx, ((encA.at(0)).anchor)("top-screen").at(1) + 0.3), text(size: 8pt, weight: "bold", fill: palette.text)[encoder])
  draw.content((decx, ((decA.at(0)).anchor)("top-screen").at(1) + 0.3), text(size: 8pt, weight: "bold", fill: palette.text)[decoder])
})

// ---------------------------------------------------------------- fpn3d (feature pyramid)
// Bottom-up backbone (left column, C-levels) + top-down pyramid (right column, P-levels) with
// 1x1 lateral connections per level. Backbone deepens going up; pyramid is uniform-channel.
#let fpn3d(
  levels: ((52, 256, [C2]), (26, 512, [C3]), (13, 1024, [C4]), (7, 2048, [C5])),
  pyr-channels: 256, palette: cnn3d-palette, cam: cam-cabinet, dy: 2.6, arm: 5.5,
) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let L = levels.len()
  let bx = 0.0
  let px = arm
  let yof(i) = i * dy
  let bb = ()
  let py = ()
  for (i, lv) in levels.enumerate() {
    let (sp, ch, lab) = lv
    let y = yof(i)
    volume(draw, (bx, y), sp, ch, base: palette.conv, palette: palette, cam: cam, relu: true)
    volume(draw, (px, y), sp, pyr-channels, base: palette.up, palette: palette, cam: cam, width: 0.3)
    bb.push(vol-anchors((bx, y), sp, ch, cam: cam))
    py.push(vol-anchors((px, y), sp, pyr-channels, width: 0.3, cam: cam))
  }
  for i in range(L - 1) {
    draw.line(((bb.at(i)).anchor)("top-screen"), ((bb.at(i + 1)).anchor)("bottom-screen"), stroke: 1.5pt + palette.edge.transparentize(10%), mark: (end: "stealth", scale: 0.7))
    draw.line(((py.at(i + 1)).anchor)("bottom-screen"), ((py.at(i)).anchor)("top-screen"), stroke: 1.5pt + palette.edge.transparentize(10%), mark: (end: "stealth", scale: 0.7))
  }
  for i in range(L) {
    let p1 = ((bb.at(i)).anchor)("east")
    let p2 = ((py.at(i)).anchor)("west")
    draw.line((p1.at(0) + 0.05, yof(i)), (p2.at(0) - 0.05, yof(i)), stroke: 1.1pt + palette.skip, mark: (end: "stealth", scale: 0.6))
  }
  for (i, lv) in levels.enumerate() {
    let (sp, ch, lab) = lv
    draw.content((((bb.at(i)).anchor)("west").at(0) - 0.3, yof(i)), anchor: "east", text(size: 7.5pt, weight: "bold", fill: palette.text)[#lab])
    draw.content((((py.at(i)).anchor)("east").at(0) + 0.3, yof(i)), anchor: "west", text(size: 7.5pt, weight: "bold", fill: palette.text)[P#(i + 2)])
  }
  draw.content((bx, yof(L - 1) + 1.6), text(size: 8pt, weight: "bold", fill: palette.text)[backbone])
  draw.content((px, yof(L - 1) + 1.6), text(size: 8pt, weight: "bold", fill: palette.text)[pyramid])
})

// thin 3-D preset wrappers (the 2-D cnn() presets in vision.typ stay untouched)
#let vgg3d() = feature-stack-fig((
  (spatial: 224, channels: 3, base: cnn3d-palette.input, label: [input]),
  (spatial: 224, channels: 64, n: 2, relu: true, label: [conv1]),
  (spatial: 112, channels: 128, n: 2, relu: true, label: [conv2]),
  (spatial: 56, channels: 256, n: 3, relu: true, label: [conv3]),
  (spatial: 28, channels: 512, n: 3, relu: true, label: [conv4]),
  (spatial: 14, channels: 512, n: 3, relu: true, label: [conv5]),
  (spatial: 7, channels: 4096, base: cnn3d-palette.fc, width: 0.24, label: [fc]),
))
#let alexnet3d() = feature-stack-fig((
  (spatial: 227, channels: 3, base: cnn3d-palette.input, label: [input]),
  (spatial: 55, channels: 96, relu: true, label: [conv1]),
  (spatial: 27, channels: 256, relu: true, label: [conv2]),
  (spatial: 13, channels: 384, n: 3, relu: true, label: [conv3-5]),
  (spatial: 6, channels: 4096, base: cnn3d-palette.fc, width: 0.24, label: [fc6-7]),
))
