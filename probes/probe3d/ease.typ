// Ease-of-use demo: 3-D blocks and ordinary 2-D drawing in ONE canvas.
#import "@preview/cetz:0.5.2"
#import "proto3.typ": block3d // the engine helper (one call per solid)
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // (1) a 3-D block — ONE call: size + color + camera. No corner math.
  block3d(draw, origin: (0, 0), w: 1.6, h: 2.2, dep: 1.2, base: rgb("#F4C58D"), cam: (25deg, -30deg, 0deg))
  draw.content((0, -1.3), text(size: 8pt)[`block3d(.., w,h,dep, cam)`])

  // (2) a rectangle from ARBITRARY corners (raw cetz, always available)
  draw.line((4.2, 0), (6.6, 0.5), (6.3, 2.6), (3.9, 2.1), close: true, fill: rgb("#FFF2E3"), stroke: 1pt + rgb("#73000A"))
  draw.content((5.2, -1.3), text(size: 8pt)[`line(p1,p2,p3,p4, close)`])

  // (3) an axis-aligned rect from two corners
  draw.rect((7.6, 0.3), (9.6, 2.0), fill: rgb("#E9EDF0"), stroke: 1pt + rgb("#466A9F"))
  draw.content((8.6, -1.3), text(size: 8pt)[`rect(a, b)`])

  // (4) circle + label + stealth arrow, mixed in
  draw.line((9.8, 1.15), (10.7, 1.15), stroke: 1pt + black, mark: (end: "stealth"))
  draw.circle((11.6, 1.15), radius: 0.62, fill: white, stroke: 1pt + rgb("#363636"))
  draw.content((11.6, 1.15), text(size: 8pt)[$+$])
  draw.content((11.0, -1.3), text(size: 8pt)[`circle / content / arrow`])

  // (5) two blocks + a connector between them — composition stays trivial
  block3d(draw, origin: (13.6, 0.2), w: 0.5, h: 1.8, dep: 1.0, base: rgb("#E2999B"), cam: (25deg, -30deg, 0deg))
  block3d(draw, origin: (16.0, 0.2), w: 0.5, h: 1.2, dep: 1.6, base: rgb("#9AA7E6"), cam: (25deg, -30deg, 0deg))
  draw.line((15.0, 1.0), (15.7, 1.0), stroke: 1pt + black, mark: (end: "stealth"))
  draw.content((14.9, -1.3), text(size: 8pt)[`two blocks + arrow`])
})
