#import "@preview/cetz:0.5.2"

// Probe (b): project a SINGLE rect via a 4x4 shear/scale matrix (set-transform / transform)
#set page(width: auto, height: auto, margin: 6pt)

#cetz.canvas({
  import cetz.draw: *
  import cetz.matrix

  // Reference un-transformed rect
  rect((0,0),(2,2), stroke: rgb("#C7C7C7"))

  // Apply a shear to a single rect to fake a side face (parallelogram)
  transform(matrix.transform-shear-x(0.5))
  rect((0,0),(2,2), fill: rgb("#466A9F"))
})

// Second canvas: hard set-transform to an arbitrary 4x4 (rotate-x composed with shear)
#cetz.canvas({
  import cetz.draw: *
  import cetz.matrix

  let m = matrix.mul-mat(
    matrix.transform-rotate-x(60deg),
    matrix.transform-shear-x(0.3),
  )
  set-transform(m)
  rect((0,0),(2,2), fill: rgb("#65780B"))
})
