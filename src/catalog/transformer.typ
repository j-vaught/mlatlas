// mlatlas · catalog/transformer.typ
// Transformer presets. Each returns IR, so they splice into `seq`/`graph` and can be
// overridden by parameters, per-node style, or surgical IR edits.

#import "../ir.typ": *
#import "../primitives.typ": block
#import "../sugar.typ": seq, residual, plate

// One encoder/decoder block. Pre-norm by default: x -> (LN -> MHA) +x -> (LN -> MLP) +x.
#let transformer-block(heads: 8, ff-mult: 4, pre-norm: true, rope: false, label: none) = {
  let attn-label = if rope { [Multi-Head Attention\ #text(size: 0.8em)[(RoPE, #heads heads)]] } else { [Multi-Head Attention\ #text(size: 0.8em)[(#heads heads)]] }
  let mlp-label = [Feed-Forward\ #text(size: 0.8em)[(#sym.times#ff-mult)]]
  let attn = block(id: "attn", label: attn-label, role: "attn")
  let mlp = block(id: "mlp", label: mlp-label, role: "op")
  let ln1 = block(id: "ln1", label: [LayerNorm], role: "norm")
  let ln2 = block(id: "ln2", label: [LayerNorm], role: "norm")
  let attn-sub = if pre-norm { residual(seq(ln1, attn)) } else { seq(residual(attn), ln1) }
  let mlp-sub = if pre-norm { residual(seq(ln2, mlp)) } else { seq(residual(mlp), ln2) }
  seq(attn-sub, mlp-sub)
}

// A full encoder stack: token+pos embedding, N blocks (boxed as a plate), final norm.
#let transformer(blocks: 6, heads: 8, ff-mult: 4, pre-norm: true, rope: false) = {
  let core = seq(..range(blocks).map(i => transformer-block(heads: heads, ff-mult: ff-mult, pre-norm: pre-norm, rope: rope)))
  seq(
    block(id: "embed", label: [Token + Positional\ Embedding], role: "data"),
    plate(core, label: [Encoder block], count: blocks),
    block(id: "norm", label: [LayerNorm], role: "norm"),
    block(id: "head", label: [Linear + Softmax], role: "param"),
  )
}

// Scaled dot-product attention as an explicit small graph (Q, K, V -> ... -> out).
#let attention-head() = {
  seq(
    block(id: "qk", label: [$Q K^top \/ sqrt(d_k)$], role: "op"),
    block(id: "softmax", label: [Softmax], role: "op"),
    block(id: "av", label: [$dot.c V$], role: "op"),
  )
}
