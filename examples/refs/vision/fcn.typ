// Fully Convolutional Network (FCN) for semantic segmentation (d2l-style).
// CNN backbone downsamples the input into a coarse feature map; a 1x1 conv maps every
// spatial location to class scores; a transposed convolution upsamples back to the input
// resolution, producing a dense per-pixel class map. No fully-connected layers anywhere.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let pal = cnn3d-palette
#let cam = cam-cabinet
#let y = 0.0
#let gap = 0.95

// layer specs, left to right
#let layers = (
  (sp: 320, ch: 3,   base: pal.input,      relu: false, label: [input],         sub: [320#sym.times 480#sym.times 3]),
  (sp: 160, ch: 64,  base: pal.conv,       relu: true,  label: [conv],          sub: [/2]),
  (sp: 80,  ch: 128, base: pal.conv,       relu: true,  label: [conv],          sub: [/4]),
  (sp: 40,  ch: 256, base: pal.conv,       relu: true,  label: [conv],          sub: [/8]),
  (sp: 20,  ch: 512, base: pal.conv,       relu: true,  label: [features],      sub: [/32]),
  (sp: 20,  ch: 21,  base: pal.fc,         relu: false, label: [1#sym.times 1 conv],  sub: [#sym.arrow.r K]),
  (sp: 320, ch: 21,  base: pal.up,         relu: false, label: [transp. conv],   sub: [#sym.times 32]),
  (sp: 320, ch: 21,  base: pal.bottleneck, relu: false, label: [prediction],     sub: [320#sym.times 480#sym.times K]),
)

// pre-compute the origin x of each volume (cumulative LTR layout)
#let origins = {
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

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // anchors per layer
  let anchors = ()
  for (i, L) in layers.enumerate() {
    anchors.push(vol-anchors((origins.at(i), y), L.sp, L.ch, cam: cam))
  }

  // flow arrows between consecutive volumes
  for i in range(layers.len() - 1) {
    let pe = ((anchors.at(i)).anchor)("east")
    let pw = ((anchors.at(i + 1)).anchor)("west")
    draw.line(
      (pe.at(0) + 0.04, y), (pw.at(0) - 0.04, y),
      stroke: 1.6pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
    )
  }

  // draw the volumes
  for (i, L) in layers.enumerate() {
    volume(
      draw, (origins.at(i), y), L.sp, L.ch,
      base: L.base, palette: pal, cam: cam, relu: L.relu, label: L.label, sub: L.sub,
    )
  }

  // ---- phase brackets / captions -------------------------------------------------------
  let topY = ((anchors.at(0)).anchor)("top-screen").at(1)
  let tagY = topY + 1.0
  let tag(x1, x2, body, col, lx: auto) = {
    let xm = if lx == auto { (x1 + x2) / 2 } else { lx }
    draw.line((x1, tagY - 0.18), (x1, tagY), (x2, tagY), (x2, tagY - 0.18), stroke: 0.9pt + col)
    draw.content((xm, tagY + 0.28), text(size: 8.5pt, weight: "bold", fill: col)[#body])
  }
  let xw(i) = ((anchors.at(i)).anchor)("west").at(0)
  let xe(i) = ((anchors.at(i)).anchor)("east").at(0)

  tag(xw(0), xe(4), [downsampling backbone (CNN)], pal.text)
  // narrow classifier bracket: caption sits below the bracket to avoid the neighbour tag
  tag(xw(5), xe(5), text(size: 7.5pt)[1#sym.times 1\ classifier], pal.muted)
  tag(xw(6), xe(7), [upsampling to full res], rgb("#1F414D"))

  // ---- title ---------------------------------------------------------------------------
  draw.content(
    (xw(0), tagY + 1.05),
    anchor: "west",
    text(size: 11pt, weight: "bold", fill: rgb("#73000A"))[Fully Convolutional Network — semantic segmentation],
  )
})
