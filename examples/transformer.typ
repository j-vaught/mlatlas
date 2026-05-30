// A pre-norm Transformer encoder — residual skips routed automatically.
#import "../lib.typ": *

#standalone(transformer(blocks: 3, heads: 8, ff-mult: 4, pre-norm: true, rope: true))
