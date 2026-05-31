// mlatlas · renderers/cnn.typ
// PlotNeuralNet-grade CNN renderer, now built on the hand-rolled 3-D engine
// (src/adapters/3d.typ): ONE block3d per conv group with internal `seams` for the ribbed
// multi-slice look (no chopped sub-prisms, so the old cap-on-last bug is structurally gone),
// depth mapped to log(channels) (decoupled from spatial height), a single clean convex-hull
// silhouette per group, and a screen-space layout so any camera lays the row out without
// overlap. Public #cnn(layers, ..) signature stays back-compatible; presets unchanged.
//
//   #cnn((
//     (kind: "input",   spatial: 224, channels: 3),
//     (kind: "conv",    spatial: 224, channels: 64,  n: 2, relu: true, label: [conv1]),
//     (kind: "pool",    spatial: 112, channels: 64),
//     (kind: "fc",      units: 4096, label: [fc6]),
//     (kind: "softmax", units: 1000, label: [softmax]),
//   ))

#import "@preview/cetz:0.5.2"
#import "../adapters/3d.typ": block3d, block3d-anchors, cam-iso, cam-cabinet

#let cnn-palette = (
  input: rgb("#E9EDF0"),
  conv: rgb("#F4C58D"), conv-band: rgb("#E07B39"),
  pool: rgb("#E2999B"),
  unpool: rgb("#8FC7C7"),
  fc: rgb("#9AA7E6"), fc-band: rgb("#6E7DD6"),
  softmax: rgb("#BE86BE"),
  edge: rgb("#33474C"),
  text: rgb("#222222"),
  muted: rgb("#5C5C5C"),
)

#let _hsize(spatial) = calc.max(15, calc.min(58, 13 + spatial * 0.16))
#let _wsize(channels) = calc.max(7, calc.min(24, 4 + calc.log(calc.max(channels, 1), base: 2) * 2.4))
// depth now reads CHANNEL COUNT (log), clamped so deep 512-ch blocks don't overrun the gap.
#let _depsize(channels) = calc.max(6, calc.min(34, 5 + calc.log(calc.max(channels, 1), base: 2) * 3.0))

// `cam` defaults to ISO (the engine/brand default); pass cam: cam-cabinet for a near-vertical,
// label-on-row look. `depth-k` is kept for back-compat but ignored (depth now = log channels).
#let cnn(layers, palette: cnn-palette, gap: 16, depth-k: 0.38, caption-gap: 12, theme: none, cam: cam-cabinet, shade: false) = {
  let pal = palette
  cetz.canvas(length: 1pt, {
    import cetz.draw
    let edge = pal.edge
    let cursor = 0.0
    let prev = none // previous group's projected east anchor (screen point)
    for L in layers {
      let kind = L.kind
      let flush = kind == "pool" or kind == "unpool"

      // ---- resolve this layer's geometry + labels ----
      let gw = 0.0
      let h = 0.0
      let dep = 0.0
      let base = white
      let band = none
      let seams = ()
      let lab1 = none
      let lab2 = none
      if kind == "input" or kind == "conv" or kind == "unpool" {
        let sp = L.at("spatial", default: 32)
        let ch = L.at("channels", default: 16)
        let n = L.at("n", default: 1)
        h = _hsize(sp)
        gw = _wsize(ch) * n
        dep = _depsize(ch)
        base = if kind == "input" { pal.input } else if kind == "unpool" { pal.unpool } else { pal.conv }
        if L.at("relu", default: false) { band = pal.conv-band }
        if n > 1 { seams = range(1, n).map(k => k / n) }
        lab1 = L.at("label", default: none)
        lab2 = [#sp#sym.times#sp#sym.times#ch]
      } else if kind == "pool" {
        let sp = L.at("spatial", default: 16)
        let ch = L.at("channels", default: 16)
        h = _hsize(sp)
        gw = 5.0
        dep = _depsize(ch)
        base = pal.pool
      } else if kind == "fc" {
        h = 50.0
        gw = 6.0
        dep = 18.0
        base = pal.fc
        band = pal.fc-band
        lab1 = L.at("label", default: [fc])
        lab2 = [#L.at("units", default: 4096)]
      } else if kind == "softmax" {
        h = 28.0
        gw = 7.0
        dep = 11.0
        base = pal.softmax
        lab1 = L.at("label", default: [softmax])
        lab2 = [#L.at("units", default: 1000)]
      }

      // ---- screen-space placement (camera-agnostic; no overlap at any angle) ----
      let a0 = block3d-anchors(origin: (0, 0), w: gw, h: h, dep: dep, cam: cam)
      let sw = a0.umax - a0.umin
      let left-pad = -a0.umin
      if not flush and prev != none { cursor = cursor + gap }
      let ox = cursor + left-pad
      let A = block3d-anchors(origin: (ox, 0), w: gw, h: h, dep: dep, cam: cam)

      // connector across the gap (stealth), from the previous east to this west, at mid-height
      if not flush and prev != none {
        draw.line(
          (prev.at(0) + 2, 0), ((A.anchor)("west").at(0) - 2, 0),
          stroke: 2pt + edge.transparentize(15%), mark: (end: "stealth", scale: 0.85),
        )
      }

      block3d(
        draw, origin: (ox, 0), w: gw, h: h, dep: dep, base: base, edge: edge, cam: cam, shade: shade,
        seams: seams, band: band, band-frac: if band != none { 0.18 } else { 0.0 },
      )

      // ---- labels below the projected silhouette ----
      let lb = (A.anchor)("bottom-screen").at(1) - caption-gap
      if lab1 != none {
        draw.content((ox, lb), text(size: 8pt, weight: "bold", fill: pal.text)[#lab1])
      }
      if lab2 != none {
        let ly = if lab1 != none { lb - 9 } else { lb }
        draw.content((ox, ly), text(size: 6.5pt, fill: pal.muted)[#lab2])
      }

      cursor = cursor + sw
      prev = (A.anchor)("east")
    }
  })
}
