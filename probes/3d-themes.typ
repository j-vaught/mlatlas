// VERIFICATION — the engine is print-first: legible in monochrome (brand grey/beige, edges +
// bands carry category) AND in colour, AND survives B&W (the rendered PNG is greyscaled below).
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let mono-pal = (
  input: rgb("#ECECEC"), conv: rgb("#FFF2E3"), conv-band: rgb("#C7C7C7"),
  pool: rgb("#D8D8D8"), up: rgb("#E4E4E4"), fc: rgb("#EDEDED"),
  bottleneck: rgb("#DCDCDC"), skip: rgb("#73000A"),
  edge: rgb("#243038"), text: rgb("#222222"), muted: rgb("#5C5C5C"),
)
#let net = (
  (spatial: 224, channels: 3, label: [in]),
  (spatial: 224, channels: 64, n: 2, relu: true, label: [conv1]),
  (spatial: 112, channels: 128, n: 2, relu: true, label: [conv2]),
  (spatial: 56, channels: 256, n: 3, relu: true, label: [conv3]),
)
*monochrome (default brand — value + edges + bands distinguish layers)*
#feature-stack-fig(net, palette: mono-pal, cam: cam-cabinet)
#v(10pt)
*colourful (one-switch hues)*
#feature-stack-fig(net, palette: cnn3d-palette, cam: cam-cabinet)
