// mlatlas · SSD — Single-Shot multi-scale Detector (d2l-style).
// One CNN backbone (VGG base + a cascade of extra "feature" conv layers) emits a row of
// feature maps at SHRINKING spatial resolution. Detection happens in a single forward pass:
// at SEVERAL scales a small convolutional head taps the feature map and predicts, per anchor,
// a class-score vector (cls, A·(K+1) channels) and 4 box offsets (loc, A·4 channels). Small
// maps (low res, large receptive field) catch BIG objects; large maps catch small objects.
// All per-scale predictions are concatenated, decoded against their anchors, and reduced by
// non-maximum suppression into the final detection set.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let pal = cnn3d-palette
#let cam = cam-cabinet

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── local palette ──────────────────────────────────────────────────────────
  let p = (
    edge:   rgb("#363636"),
    text:   rgb("#1A1A1A"),
    muted:  rgb("#5C5C5C"),
    faint:  rgb("#A2A2A2"),
    garnet: rgb("#73000A"),     // focal accent: the tap lines / detection sink
    blue:   rgb("#466A9F"),     // cls head
    green:  rgb("#65780B"),     // loc head
    beige:  rgb("#FFF2E3"),
    cls-f:  rgb("#DCE5F1"),     // light blue head fill
    loc-f:  rgb("#E7ECCF"),     // light green head fill
  )

  let y0 = 0.0                  // backbone baseline
  let gap = 0.95

  // ── backbone feature layers (left → right, spatial shrinks) ────────────────
  // tap? = whether a detection head reads from this map. d2l/SSD: 6 detection scales.
  let layers = (
    (sp: 300, ch: 3,    base: pal.input, relu: false, tap: false, label: [input],   sub: [300²×3]),
    (sp: 38,  ch: 512,  base: pal.conv,  relu: true,  tap: true,  label: [conv4\_3], sub: [38²], pm: [4]),
    (sp: 19,  ch: 1024, base: pal.conv,  relu: true,  tap: true,  label: [conv7],    sub: [19²], pm: [6]),
    (sp: 10,  ch: 512,  base: pal.up,    relu: true,  tap: true,  label: [conv8],    sub: [10²], pm: [6]),
    (sp: 5,   ch: 256,  base: pal.up,    relu: true,  tap: true,  label: [conv9],    sub: [5²],  pm: [6]),
    (sp: 3,   ch: 256,  base: pal.up,    relu: true,  tap: true,  label: [conv10],   sub: [3²],  pm: [4]),
    (sp: 1,   ch: 256,  base: pal.up,    relu: true,  tap: true,  label: [conv11],   sub: [1²],  pm: [4]),
  )

  // pre-compute the origin x of each volume (cumulative LTR layout)
  let origins = {
    let xs = ()
    let cursor = 0.0
    let first = true
    for L in layers {
      let A0 = vol-anchors((0, 0), L.sp, L.ch, cam: cam)
      let sw = A0.umax - A0.umin
      if not first { cursor = cursor + gap }
      let ox = cursor + (-A0.umin)
      xs.push(ox)
      cursor = cursor + sw
      first = false
    }
    xs
  }

  // anchors per layer
  let anchors = ()
  for (i, L) in layers.enumerate() {
    anchors.push(vol-anchors((origins.at(i), y0), L.sp, L.ch, cam: cam))
  }

  // ── flow arrows along the backbone ─────────────────────────────────────────
  for i in range(layers.len() - 1) {
    let pe = ((anchors.at(i)).anchor)("east")
    let pw = ((anchors.at(i + 1)).anchor)("west")
    draw.line(
      (pe.at(0) + 0.04, y0), (pw.at(0) - 0.04, y0),
      stroke: 1.6pt + p.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
    )
  }

  // ── the backbone volumes ───────────────────────────────────────────────────
  for (i, L) in layers.enumerate() {
    volume(
      draw, (origins.at(i), y0), L.sp, L.ch,
      base: L.base, palette: pal, cam: cam, relu: L.relu, label: L.label, sub: L.sub,
    )
  }

  // ── per-scale detection heads above the backbone ───────────────────────────
  // each tapped map → small 3×3 conv predictor → two sibling outputs (cls, loc).
  // vertical order (bottom→top, data flows UP): feature map · 3×3 conv · {cls | loc} · rail
  let convY = 3.55                         // 3×3 conv box centre
  let outY  = 4.85                         // cls / loc box centre
  let cw = 1.30                            // conv box width
  let ch2 = 0.56                           // conv box height
  let ow = 0.62                            // output (cls/loc) box width
  let oh = 0.70                            // output (cls/loc) box height
  let o-gap = 0.10                         // gap between cls and loc

  // collect top-centre points of each head (for the collector rail) + tap x's
  let out-pts = ()
  let tap-xs = ()

  for (i, L) in layers.enumerate() {
    if not L.tap { continue }
    let A = anchors.at(i)
    let topp = (A.anchor)("top-screen")
    let tx = origins.at(i)
    tap-xs.push(tx)

    let clsX = tx - (ow / 2 + o-gap / 2)
    let locX = tx + (ow / 2 + o-gap / 2)

    // garnet lateral tap: from the feature map top up into the 3×3 conv predictor
    draw.line(
      (tx, topp.at(1) + 0.06), (tx, convY - ch2 / 2 - 0.02),
      stroke: 1.3pt + p.garnet, mark: (end: "stealth", scale: 0.6),
    )

    // 3×3 conv predictor box
    draw.rect(
      (tx - cw / 2, convY - ch2 / 2), (tx + cw / 2, convY + ch2 / 2),
      fill: p.beige, stroke: 1.1pt + p.edge, radius: 0pt,
    )
    draw.content((tx, convY + 0.09), text(size: 6.5pt, weight: "bold", fill: p.text)[3×3 conv])
    draw.content((tx, convY - 0.14), text(size: 5.5pt, fill: p.muted)[predictor])

    // conv → cls and conv → loc (split upward)
    draw.line((clsX, convY + ch2 / 2 + 0.01), (clsX, outY - oh / 2 - 0.01),
      stroke: 0.8pt + p.edge, mark: (end: "stealth", scale: 0.45))
    draw.line((locX, convY + ch2 / 2 + 0.01), (locX, outY - oh / 2 - 0.01),
      stroke: 0.8pt + p.edge, mark: (end: "stealth", scale: 0.45))

    // cls output (blue)
    draw.rect(
      (clsX - ow / 2, outY - oh / 2), (clsX + ow / 2, outY + oh / 2),
      fill: p.cls-f, stroke: 1.1pt + p.blue, radius: 0pt,
    )
    draw.content((clsX, outY + 0.11), text(size: 6.5pt, weight: "bold", fill: p.text)[cls])
    draw.content((clsX, outY - 0.16), text(size: 5.2pt, fill: p.muted)[$A(K{+}1)$])

    // loc output (green)
    draw.rect(
      (locX - ow / 2, outY - oh / 2), (locX + ow / 2, outY + oh / 2),
      fill: p.loc-f, stroke: 1.1pt + p.green, radius: 0pt,
    )
    draw.content((locX, outY + 0.11), text(size: 6.5pt, weight: "bold", fill: p.text)[loc])
    draw.content((locX, outY - 0.16), text(size: 5.2pt, fill: p.muted)[$A dot 4$])

    // both outputs feed the collector rail above
    out-pts.push((clsX, outY + oh / 2))
    out-pts.push((locX, outY + oh / 2))

    // anchors-per-cell note just right of this head's conv box
    draw.content(
      (tx + cw / 2 + 0.05, convY),
      anchor: "west",
      text(size: 5.8pt, fill: p.muted)[$A{=}$#L.pm],
    )
  }

  // ── collector rail + detection sink: concat → NMS → detections ─────────────
  let railY = outY + 0.95                  // horizontal "concat" bus above the heads
  let lastA = anchors.at(layers.len() - 1)
  let sinkX = ((lastA.anchor)("east").at(0)) + 2.45
  let sinkY = railY
  let sw2 = 1.95
  let sh2 = 1.0

  // each head output → up to the rail
  for pt in out-pts {
    draw.line(
      (pt.at(0), pt.at(1) + 0.02), (pt.at(0), railY),
      stroke: 0.8pt + p.garnet.transparentize(20%),
    )
  }
  // the rail itself, running into the sink
  let railX0 = out-pts.first().at(0)
  draw.line(
    (railX0, railY), (sinkX - sw2 / 2 - 0.02, railY),
    stroke: 1.3pt + p.garnet, mark: (end: "stealth", scale: 0.7),
  )

  // sink box (garnet focal node)
  draw.rect(
    (sinkX - sw2 / 2, sinkY - sh2 / 2), (sinkX + sw2 / 2, sinkY + sh2 / 2),
    fill: p.garnet, stroke: 1.2pt + p.garnet, radius: 0pt,
  )
  draw.content((sinkX, sinkY + 0.24), text(size: 8pt, weight: "bold", fill: white)[concat all])
  draw.content((sinkX, sinkY + 0.01), text(size: 7pt, fill: rgb("#FFE6D9"))[predictions])
  draw.content((sinkX, sinkY - 0.23), text(size: 6.5pt, fill: rgb("#FFE6D9"))[decode + NMS])

  // sink → detections output box
  let detX = sinkX + 2.45
  let detY = sinkY
  draw.line(
    (sinkX + sw2 / 2 + 0.04, sinkY), (detX - 1.0, detY),
    stroke: 1.6pt + p.edge, mark: (end: "stealth", scale: 0.8),
  )
  draw.rect(
    (detX - 0.95, detY - 0.62), (detX + 0.95, detY + 0.62),
    fill: white, stroke: 1.2pt + p.edge, radius: 0pt,
  )
  draw.content((detX, detY + 0.26), text(size: 8pt, weight: "bold", fill: p.text)[detections])
  draw.content((detX, detY - 0.02), text(size: 6.5pt, fill: p.muted)[class + box])
  draw.content((detX, detY - 0.26), text(size: 6.5pt, fill: p.muted)[per object])

  // ── scale-intuition strip under the tapped maps ────────────────────────────
  let stripY = (anchors.at(1).anchor)("bottom-screen").at(1) - 1.05
  let x1 = tap-xs.first()
  let x2 = tap-xs.last()
  draw.line(
    (x1, stripY), (x2, stripY),
    stroke: 1.0pt + p.faint, mark: (start: "stealth", end: "stealth", scale: 0.6),
  )
  draw.content((x1, stripY - 0.30), anchor: "north",
    text(size: 7pt, fill: p.text)[high-res maps])
  draw.content((x1, stripY - 0.58), anchor: "north",
    text(size: 6.5pt, fill: p.muted, style: "italic")[small objects])
  draw.content((x2, stripY - 0.30), anchor: "north",
    text(size: 7pt, fill: p.text)[low-res maps])
  draw.content((x2, stripY - 0.58), anchor: "north",
    text(size: 6.5pt, fill: p.muted, style: "italic")[large objects])

  // ── phase brackets / captions ──────────────────────────────────────────────
  let topY = ((anchors.at(0)).anchor)("top-screen").at(1)
  let tag(x1, x2, body, col) = {
    let xm = (x1 + x2) / 2
    draw.line((x1, topY + 0.40), (x1, topY + 0.58), (x2, topY + 0.58), (x2, topY + 0.40),
      stroke: 0.9pt + col)
    draw.content((xm, topY + 0.84), text(size: 8pt, weight: "bold", fill: col)[#body])
  }
  let xw(i) = ((anchors.at(i)).anchor)("west").at(0)
  let xe(i) = ((anchors.at(i)).anchor)("east").at(0)

  tag(xw(0), xe(2), [VGG base], p.muted)
  tag(xw(3), xe(6), [extra feature layers], p.muted)

  // ── titles ─────────────────────────────────────────────────────────────────
  let titleY = railY + 1.30
  draw.content(
    (xw(0), titleY),
    anchor: "west",
    text(size: 11.5pt, weight: "bold", fill: p.garnet)[SSD — single-shot multi-scale detector],
  )
  draw.content(
    (xw(0), titleY - 0.36),
    anchor: "west",
    text(size: 8pt, fill: p.muted, style: "italic")[one backbone · per-scale conv heads predict (class, box) for every anchor · single forward pass],
  )

  // band label for the head row + mini legend (cls / loc)
  let lgx = xw(0)
  let lgy = railY + 0.55
  draw.content((lgx, lgy), anchor: "west",
    text(size: 8pt, weight: "bold", fill: p.text)[detection heads])
  draw.rect((lgx + 2.55, lgy - 0.10), (lgx + 2.81, lgy + 0.10), fill: p.cls-f, stroke: 1pt + p.blue, radius: 0pt)
  draw.content((lgx + 2.91, lgy), anchor: "west", text(size: 6.5pt, fill: p.muted)[cls $A(K{+}1)$ logits])
  draw.rect((lgx + 5.30, lgy - 0.10), (lgx + 5.56, lgy + 0.10), fill: p.loc-f, stroke: 1pt + p.green, radius: 0pt)
  draw.content((lgx + 5.66, lgy), anchor: "west", text(size: 6.5pt, fill: p.muted)[loc $A dot 4$ box offsets])
})
