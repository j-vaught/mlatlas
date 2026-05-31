// mlatlas · renderers/cnn.typ
// A dedicated PlotNeuralNet-grade CNN renderer drawn in ONE cetz canvas (not generic
// fletcher boxes) for full control over the cabinet-oblique 3-D prisms. Recipe matches
// PlotNeuralNet: front face upright, depth sheared up-right ×0.38, three edge-bounded
// faces with directional lighting (top lighter, side darker), ReLU "trailing band",
// flush-mounted pools, channel/spatial labels, stealth connectors across group gaps.
//
//   #cnn((
//     (kind: "input",   spatial: 224, channels: 3),
//     (kind: "conv",    spatial: 224, channels: 64,  n: 2, relu: true, label: [conv1]),
//     (kind: "pool",    spatial: 112, channels: 64),
//     (kind: "conv",    spatial: 112, channels: 128, n: 2, relu: true, label: [conv2]),
//     (kind: "pool",    spatial: 56,  channels: 128),
//     (kind: "fc",      units: 4096, label: [fc6]),
//     (kind: "softmax", units: 1000, label: [softmax]),
//   ))

#import "@preview/cetz:0.5.2"

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

// draw one prism; returns nothing, draws into the surrounding cetz canvas
#let _prism(draw, cx, w, h, front, stroke, depth-k: 0.38, cap: true, band: none) = {
  let dx = h * depth-k
  let dy = h * depth-k
  let y0 = -h / 2
  let y1 = h / 2
  let top = front.lighten(13%).saturate(20%) // lighten but keep hue/chroma (no bleach to white)
  let side = front.darken(15%)
  // top face
  draw.line((cx, y1), (cx + w, y1), (cx + w + dx, y1 + dy), (cx + dx, y1 + dy), close: true, fill: top, stroke: stroke)
  // right cap
  if cap {
    draw.line((cx + w, y0), (cx + w, y1), (cx + w + dx, y1 + dy), (cx + w + dx, y0 + dy), close: true, fill: side, stroke: stroke)
  }
  // front face
  draw.rect((cx, y0), (cx + w, y1), fill: front, stroke: stroke)
  // ReLU band on the trailing third of front + top
  if band != none {
    let bx = cx + w * 2 / 3
    draw.line((bx, y1), (cx + w, y1), (cx + w + dx, y1 + dy), (bx + dx, y1 + dy), close: true, fill: band.lighten(13%), stroke: none)
    draw.rect((bx, y0), (cx + w, y1), fill: band, stroke: none)
    draw.rect((cx, y0), (cx + w, y1), fill: none, stroke: stroke) // re-stroke outline
  }
}

#let cnn(layers, palette: cnn-palette, gap: 16, depth-k: 0.38, caption-gap: 12) = {
  let pal = palette
  cetz.canvas(length: 1pt, {
    import cetz.draw
    let stroke = 0.6pt + pal.edge
    let cx = 0.0
    let prev-east = none // (x, y-center) to draw connector from
    let i = 0
    for L in layers {
      let kind = L.kind
      let flush = kind == "pool" or kind == "unpool"
      // gap + connector arrow before a non-flush group (except the first)
      if not flush and prev-east != none {
        let x1 = cx + gap
        draw.line(
          (prev-east + 2, 0), (x1 - 4, 0),
          stroke: 2pt + pal.edge.transparentize(15%),
          mark: (end: "stealth", scale: 0.85),
        )
        cx = x1
      }

      if kind == "input" or kind == "conv" or kind == "unpool" {
        let sp = L.at("spatial", default: 32)
        let ch = L.at("channels", default: 16)
        let n = L.at("n", default: 1)
        let h = _hsize(sp)
        let w = _wsize(ch)
        let base = if kind == "input" { pal.input } else if kind == "unpool" { pal.unpool } else { pal.conv }
        let band = if L.at("relu", default: false) { pal.conv-band } else { none }
        let gstart = cx
        for k in range(n) {
          // ReLU band only on the LAST sub-prism (one activation per group, not a barcode)
          _prism(draw, cx, w, h, base, stroke, depth-k: depth-k, cap: k == n - 1, band: if k == n - 1 { band } else { none })
          cx = cx + w
        }
        let gcenter = (gstart + cx) / 2
        // labels
        let cap-text = L.at("label", default: none)
        if cap-text != none {
          draw.content((gcenter, -h / 2 - caption-gap), text(size: 8pt, weight: "bold", fill: pal.text)[#cap-text])
        }
        draw.content((gcenter, -h / 2 - caption-gap - 9), text(size: 6.5pt, fill: pal.muted)[#sp#sym.times#sp#sym.times#ch])
        prev-east = cx
      } else if kind == "pool" {
        let sp = L.at("spatial", default: 16)
        let ch = L.at("channels", default: 16)
        let h = _hsize(sp)
        let w = 5.0
        _prism(draw, cx, w, h, pal.pool, stroke, depth-k: depth-k, cap: true)
        cx = cx + w
        prev-east = cx
      } else if kind == "fc" {
        let units = L.at("units", default: 4096)
        let h = 50.0
        let w = 6.0
        _prism(draw, cx, w, h, pal.fc, stroke, depth-k: depth-k, cap: true, band: pal.fc-band)
        let gcenter = cx + w / 2
        let cap-text = L.at("label", default: [fc])
        draw.content((gcenter, -h / 2 - caption-gap), text(size: 8pt, weight: "bold", fill: pal.text)[#cap-text])
        draw.content((gcenter, -h / 2 - caption-gap - 9), text(size: 6.5pt, fill: pal.muted)[#units])
        cx = cx + w
        prev-east = cx
      } else if kind == "softmax" {
        let units = L.at("units", default: 1000)
        let h = 28.0
        let w = 7.0
        _prism(draw, cx, w, h, pal.softmax, stroke, depth-k: depth-k, cap: true)
        let gcenter = cx + w / 2
        draw.content((gcenter, -h / 2 - caption-gap), text(size: 8pt, weight: "bold", fill: pal.text)[#L.at("label", default: [softmax])])
        draw.content((gcenter, -h / 2 - caption-gap - 9), text(size: 6.5pt, fill: pal.muted)[#units])
        cx = cx + w
        prev-east = cx
      }
      i = i + 1
    }
  })
}
