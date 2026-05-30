// mlatlas · catalog/resnet.typ
// Residual / CNN-stage presets.

#import "../ir.typ": *
#import "../primitives.typ": block
#import "../sugar.typ": seq, residual

// One residual stage = `blocks` residual units. `bottleneck` uses the 1x1 -> 3x3 ->
// 1x1 design; `downsample` is reserved for the projected-skip variant (Phase 1).
#let resnet-stage(blocks: 2, channels: 64, bottleneck: false, downsample: false) = {
  let unit(i) = {
    let inner = if bottleneck {
      seq(
        block(id: "c1", label: [1#sym.times 1, #channels], role: "op"),
        block(id: "c2", label: [3#sym.times 3, #channels], role: "op"),
        block(id: "c3", label: [1#sym.times 1, #(channels * 4)], role: "op"),
      )
    } else {
      seq(
        block(id: "c1", label: [3#sym.times 3, #channels], role: "op"),
        block(id: "c2", label: [3#sym.times 3, #channels], role: "op"),
      )
    }
    residual(inner)
  }
  seq(..range(blocks).map(unit))
}
