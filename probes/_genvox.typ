#import "../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)
*voxel grid* \
#cetz.canvas(length: 1cm, { import cetz.draw; voxel-grid(draw, dims: (4,4,4), cam: cam-iso) })
#v(8pt) *conv3d kernel in a volume* \
#cetz.canvas(length: 1cm, { import cetz.draw; conv3d-kernel(draw, vol: (6,6,6), kernel: (3,3,3), at: (1,1,1), cam: cam-iso) })
#v(8pt) *VAE* \
#vae3d()
#v(8pt) *GAN* \
#gan3d()
