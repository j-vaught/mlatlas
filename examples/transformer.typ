// A pre-norm Transformer encoder (canonical paper-pastel palette); the repeated block
// is shown once inside a "×N" plate.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 10pt, fill: white)

#render(transformer(blocks: 6, heads: 8, ff-mult: 4, pre-norm: true, rope: true), theme: paper)
