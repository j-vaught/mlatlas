// A pre-norm Transformer encoder: token+pos embedding, N blocks (each LN -> MHA -> +x,
// LN -> FFN -> +x with auto-routed residual skips), final norm + head.
#import "../lib.typ": *

#standalone(transformer(blocks: 3, heads: 8, ff-mult: 4, pre-norm: true, rope: true))
