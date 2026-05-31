// U-Net (Ronneberger et al. 2015), UDL / Prince "Understanding Deep Learning" style.
// Symmetric encoder/decoder. The contracting path applies 3x3 convs + 2x2 max-pool,
// halving spatial resolution and doubling channels (64 -> 128 -> 256 -> 512); a
// bottleneck at 1024 channels; the expansive path mirrors upward with 2x2 up-convs
// (transposed conv) that halve channels, each level fed by a "crop-and-concatenate"
// skip from the matching encoder level; a final 1x1 conv emits the segmentation map.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#align(center)[
  #text(size: 13pt, weight: "bold")[U-Net encoder--decoder]

  #v(2pt)

  #unet3d(
    levels: (
      (568, 64),
      (280, 128),
      (136, 256),
      (64, 512),
    ),
    bottleneck: (28, 1024),
  )

  #v(2pt)

  #text(size: 8.5pt, fill: rgb("#5C5C5C"))[
    Contracting path: 3#sym.times 3 convs + 2#sym.times 2 max-pool (spatial halves, channels double) ·
    1024-channel bottleneck · expansive path: 2#sym.times 2 up-convs ·
    #text(fill: rgb("#73000A"))[crop-and-concatenate skips] bridge matching levels · 1#sym.times 1 conv to the segmentation map
  ]
]
