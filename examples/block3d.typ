// The 3-D engine API at a glance: one block per camera preset, shade toggle, seams/band, and
// project() mixing with ordinary 2-D cetz drawing. A simple block is ONE call.
#import "../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 8pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw
  // (1) one block — iso, flat (the default)
  block3d(draw, origin: (0, 0), w: 1.4, h: 2.0, dep: 1.2, base: rgb("#FFF2E3"))
  draw.content((0, -1.5), [iso, flat (default)])
  // (2) cabinet + shade + seams + ReLU band
  block3d(draw, origin: (3.6, 0), w: 1.6, h: 2.0, dep: 1.3, base: rgb("#F4C58D"), cam: cam-cabinet, shade: true, seams: (0.33, 0.66), band: rgb("#C9542A"), band-frac: 0.2)
  draw.content((3.6, -1.5), [cabinet, shade, seams, band])
  // (3) feature-map shortcut
  feature-map(draw, (6.8, 0), spatial: 112, channels: 128, relu: true)
  draw.content((6.8, -1.5), [feature-map(112, 128)])
  // (4) project() — an arbitrary 3-D polygon mixed with the blocks
  draw.line(project((8.8, -1, 0)), project((10, -1, 1.6)), project((10, 1.4, 1.6)), project((8.8, 1.4, 0)), close: true, fill: rgb("#466A9F").transparentize(45%), stroke: 0.9pt + rgb("#1F414D"))
  draw.content((9.4, -1.5), [project() polygon])
})
