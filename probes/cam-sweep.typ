// VERIFICATION PROBE — one block rendered at many cameras. Proves the engine produces a clean
// single silhouette and correct back-face culling at ANY angle (no corner spikes, no bowtie).
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 8pt)

#let blk = ((origin: (0, 0), w: 1.8, h: 2.4, dep: 1.3, base: rgb("#F4C58D")),)
#let demo(title, cam, shade: false) = [
  #set align(center)
  *#title* \
  #scene-canvas(cam: cam, shade: shade, blocks: blk)
]

#grid(
  columns: 5, gutter: 14pt, row-gutter: 18pt,
  demo("iso", cam-iso), demo("dimetric", cam-dimetric), demo("cabinet", cam-cabinet),
  demo("cavalier", cam-cavalier), demo("face", cam-face),
  demo("top-down", cam-top-down), demo("roll 12°", (20deg, -35deg, 12deg)),
  demo("steep", (15deg, -60deg, 0deg)), demo("yaw +70°", (30deg, 70deg, 0deg)),
  demo("near-degenerate", (4deg, -88deg, 0deg)),
  demo("iso shaded", cam-iso, shade: true), demo("cabinet shaded", cam-cabinet, shade: true),
  demo("top-down shaded", cam-top-down, shade: true), demo("roll −20°", (22deg, 40deg, -20deg)),
  demo("flat-ish", (8deg, -18deg, 0deg)),
)
