// mlatlas · presets/transformer.typ — Transformer / LLM presets.

#import "../prim/block.typ": block
#import "../sugar/sugar.typ": seq, residual, plate

// One encoder/decoder block: pre-norm by default (x -> LN -> MHA +x -> LN -> FFN +x).
#let transformer-block(heads: 8, ff-mult: 4, pre-norm: true, rope: false) = {
  let extra = if rope { [RoPE, ] } else { [] }
  let attn = block(id: "attn", label: [Multi-Head Attention\ #text(size: 0.8em)[(#extra#heads heads)]], role: "attention")
  let mlp = block(id: "mlp", label: [Feed-Forward\ #text(size: 0.8em)[(#sym.times#ff-mult)]], role: "op")
  let ln1 = block(id: "ln1", label: [LayerNorm], role: "norm")
  let ln2 = block(id: "ln2", label: [LayerNorm], role: "norm")
  if pre-norm {
    seq(residual(seq(ln1, attn)), residual(seq(ln2, mlp)))
  } else {
    seq(seq(residual(attn), ln1), seq(residual(mlp), ln2))
  }
}

// A full encoder stack: embedding, ONE representative block in a "×N" plate (so the
// figure shows the repeated unit once, not N unrolled copies), final norm + head.
#let transformer(blocks: 6, heads: 8, ff-mult: 4, pre-norm: true, rope: false) = {
  let core = transformer-block(heads: heads, ff-mult: ff-mult, pre-norm: pre-norm, rope: rope)
  seq(
    block(id: "embed", label: [Token + Positional\ Embedding], role: "data"),
    plate(core, label: [Encoder block], count: blocks),
    block(id: "norm", label: [LayerNorm], role: "norm"),
    block(id: "head", label: [Linear + Softmax], role: "param", emphasis: true),
  )
}

// Scaled dot-product attention internals.
#let attention-head() = seq(
  block(id: "qk", label: [$Q K^top \/ sqrt(d_k)$], role: "op"),
  block(id: "softmax", label: [Softmax], role: "activation"),
  block(id: "av", label: [$dot.c V$], role: "op"),
)
