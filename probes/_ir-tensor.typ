#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 18pt, fill: white)
// 3-D tensors flowing through the IR (auto-layout + edges via render())
#render(seq(
  tensor(id: "x", title: [input], axes: ([56], [56], [3]), cam: "iso"),
  tensor(id: "h", title: [hidden], axes: ([28], [28], [64]), cam: "iso", seams: (0.5,)),
  tensor(id: "z", title: [latent], axes: ([1], [1], [128]), cam: "iso"),
))
