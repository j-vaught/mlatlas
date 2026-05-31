// scene() depth-sorts overlapping blocks far->near so occlusion is correct automatically.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#scene-canvas(cam: cam-iso, blocks: (
  (origin: (0, 0), w: 0.6, h: 2.2, dep: 1.6, base: rgb("#E2999B"), pos3: (0, 0, 0)),
  (origin: (1.0, 0.2), w: 0.6, h: 1.8, dep: 2.0, base: rgb("#9AA7E6"), pos3: (1.0, 0, 0)),
  (origin: (2.0, 0.4), w: 0.6, h: 1.4, dep: 2.4, base: rgb("#F4C58D"), pos3: (2.0, 0, 0)),
))
