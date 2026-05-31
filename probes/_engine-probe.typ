// throwaway engine smoke-test (block3d / feature-map / scene / project / anchors)
#import "../src/adapters/3d.typ": *
#set page(width: auto, height: auto, margin: 14pt, fill: white)
#cetz.canvas(length: 1cm, {
  import cetz.draw
  block3d(draw, origin: (0, 0), w: 1.4, h: 2.0, dep: 1.2, base: rgb("#FFF2E3"))
  block3d(draw, origin: (4, 0), w: 1.6, h: 2.0, dep: 1.4, base: rgb("#F4C58D"), shade: true, seams: (0.33, 0.66), band: rgb("#C9542A"), band-frac: 0.2)
  feature-map(draw, (7.5, 0), spatial: 112, channels: 128, relu: true)
  draw.line(project((9, 0, 0)), project((10, 0, 1.5)), project((10, 2, 1.5)), close: true, fill: rgb("#466A9F").transparentize(40%), stroke: 0.8pt + rgb("#1F414D"))
})
#scene-canvas(blocks: (
  (origin: (0, 0), w: 0.5, h: 2.0, dep: 1.4, base: rgb("#E2999B"), pos3: (0, 0, 0)),
  (origin: (0.9, 0.2), w: 0.5, h: 1.6, dep: 1.8, base: rgb("#9AA7E6"), pos3: (0.9, 0, 0)),
))
