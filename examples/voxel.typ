// A voxel lattice and a 3-D conv kernel highlighted inside a volume.
#import "../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#cetz.canvas(length: 1cm, { import cetz.draw; voxel-grid(draw, dims: (4,4,4), cam: cam-iso) })
#h(24pt)
#cetz.canvas(length: 1cm, { import cetz.draw; conv3d-kernel(draw, vol: (6,6,6), kernel: (3,3,3), at: (1,1,1), cam: cam-iso) })
