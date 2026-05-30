// mlatlas · presets/vision.typ — CNN / vision architectures.

#import "../ir/ir.typ": ir-node, ir-edge, frag
#import "../prim/block.typ": block
#import "../prim/slab.typ": slab, conv
#import "../sugar/sugar.typ": seq, residual, merge

// One residual stage = `blocks` residual units (basic or bottleneck).
#let resnet-stage(blocks: 2, channels: 64, bottleneck: false) = {
  let unit(_) = {
    let inner = if bottleneck {
      seq(
        block(label: [1×1, #channels], role: "op"),
        block(label: [3×3, #channels], role: "op"),
        block(label: [1×1, #(channels * 4)], role: "op"),
      )
    } else {
      seq(block(label: [3×3, #channels], role: "op"), block(label: [3×3, #channels], role: "op"))
    }
    residual(inner)
  }
  seq(..range(blocks).map(unit))
}

// LeNet-style CNN as 3-D feature-map prisms (render with dir: "ltr").
#let lenet() = seq(
  slab(label: [], dims: [32×32×1], h: 58pt, w: 11pt, depth: 8pt, role: "data"),
  conv(label: [C1], spatial: [28×28], channels: 6, h: 52pt, role: "attention"),
  conv(label: [S2], spatial: [14×14], channels: 6, h: 30pt, role: "norm"),
  conv(label: [C3], spatial: [10×10], channels: 16, h: 22pt, role: "attention"),
  conv(label: [S4], spatial: [5×5], channels: 16, h: 14pt, role: "norm"),
  block(id: "fc", label: [FC\ 120], role: "op"),
  block(id: "out", label: [Softmax\ 10], role: "param", emphasis: true),
)

// A VGG-style block: `count` convs at the same resolution, then a pool.
#let vgg-block(count: 2, channels: 64, spatial: [224×224], h: 40pt) = seq(
  ..range(count).map(i => conv(label: [3×3], spatial: spatial, channels: channels, h: h, role: "attention")),
  conv(label: [pool], spatial: spatial, channels: channels, h: h * 0.6, role: "norm"),
)

// A U-Net: encoder (left, down), bottleneck (centre), decoder (right, up), with
// horizontal skip connections at each level.
#let unet(depth: 3, base: 32) = {
  let nodes = ()
  let edges = ()
  let chans(i) = base * calc.pow(2, i)
  for i in range(depth) {
    nodes.push(ir-node("e" + str(i), label: [Enc #(i + 1)\ #text(size: 0.8em)[#chans(i)]], role: "attention", pos: (0, i)))
    if i > 0 { edges.push(ir-edge("e" + str(i - 1), "e" + str(i), kind: "data")) }
  }
  nodes.push(ir-node("bn", label: [Bottleneck\ #text(size: 0.8em)[#chans(depth)]], role: "param", pos: (1, depth)))
  edges.push(ir-edge("e" + str(depth - 1), "bn", kind: "data"))
  for i in range(depth) {
    nodes.push(ir-node("d" + str(i), label: [Dec #(i + 1)\ #text(size: 0.8em)[#chans(i)]], role: "op", pos: (2, i)))
  }
  edges.push(ir-edge("bn", "d" + str(depth - 1), kind: "data"))
  for i in range(depth - 1) {
    let lvl = depth - 1 - i
    edges.push(ir-edge("d" + str(lvl), "d" + str(lvl - 1), kind: "data"))
  }
  for i in range(depth) {
    edges.push(ir-edge("e" + str(i), "d" + str(i), kind: "skip", route: "straight", label: [skip]))
  }
  frag(nodes: nodes, edges: edges, meta: ("in": "e0", "out": "d0"))
}

// Two-stream / multi-modal fusion helper.
#let two-stream(stream-a, stream-b, fusion: [Fusion], head: none, gap: 2) = {
  let m = merge(stream-a, stream-b, into: block(id: "fuse", label: fusion, role: "param", emphasis: true), gap: gap)
  if head != none { seq(m, head) } else { m }
}
