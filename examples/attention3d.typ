// Scaled dot-product attention in 3-D: Q/K/V slabs -> QKᵀ score cube (heads in depth) -> softmax -> output.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#attention-3d(seq: 6, d-k: 64, heads: 4)
