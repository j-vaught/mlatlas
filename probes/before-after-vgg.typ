// APPROVAL ARTIFACT — old (frozen) vs new (engine) for the same nets. The "before" PNGs were
// frozen from the pre-migration tree (media/before-*.png) since cnn.typ was rewritten in place.
#import "../lib.typ": *
#set page(width: 32cm, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let hd(t) = text(weight: "bold", fill: rgb("#73000A"))[#t]
#stack(
  dir: ttb, spacing: 14pt,
  hd[BEFORE — old prism (chopped sub-prisms, cap-on-last bug)],
  image("../media/before-vgg.png", width: 24cm),
  v(4pt),
  hd[AFTER — engine: one seamed block per conv group, log-channel depth (cam-cabinet)],
  align(left, vgg16()),
  v(10pt),
  hd[CONTROL — LeNet (n=1 groups, no seams): before then after],
  image("../media/before-lenet.png", width: 12cm),
  align(left, scale(120%, reflow: true, lenet5())),
)
