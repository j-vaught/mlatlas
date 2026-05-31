// mlatlas · presets/vision.typ — CNN / vision architectures.

#import "../ir/ir.typ": ir-node, ir-edge, frag
#import "../prim/block.typ": block
#import "../prim/slab.typ": slab, conv
#import "../sugar/sugar.typ": seq, residual, merge
#import "../renderers/cnn.typ": cnn

// Publication-grade CNN figures via the dedicated cetz prism renderer.
#let lenet5() = cnn((
  (kind: "input", spatial: 32, channels: 1),
  (kind: "conv", spatial: 28, channels: 6, n: 1, relu: true, label: [C1]),
  (kind: "pool", spatial: 14, channels: 6),
  (kind: "conv", spatial: 10, channels: 16, n: 1, relu: true, label: [C3]),
  (kind: "pool", spatial: 5, channels: 16),
  (kind: "fc", units: 120, label: [F6]),
  (kind: "fc", units: 84, label: [F7]),
  (kind: "softmax", units: 10, label: [out]),
))

#let vgg16() = cnn((
  (kind: "input", spatial: 224, channels: 3),
  (kind: "conv", spatial: 224, channels: 64, n: 2, relu: true, label: [conv1]),
  (kind: "pool", spatial: 112, channels: 64),
  (kind: "conv", spatial: 112, channels: 128, n: 2, relu: true, label: [conv2]),
  (kind: "pool", spatial: 56, channels: 128),
  (kind: "conv", spatial: 56, channels: 256, n: 3, relu: true, label: [conv3]),
  (kind: "pool", spatial: 28, channels: 256),
  (kind: "conv", spatial: 28, channels: 512, n: 3, relu: true, label: [conv4]),
  (kind: "pool", spatial: 14, channels: 512),
  (kind: "conv", spatial: 14, channels: 512, n: 3, relu: true, label: [conv5]),
  (kind: "pool", spatial: 7, channels: 512),
  (kind: "fc", units: 4096, label: [fc6]),
  (kind: "fc", units: 4096, label: [fc7]),
  (kind: "softmax", units: 1000, label: [softmax]),
))

#let alexnet() = cnn((
  (kind: "input", spatial: 227, channels: 3),
  (kind: "conv", spatial: 55, channels: 96, n: 1, relu: true, label: [conv1]),
  (kind: "pool", spatial: 27, channels: 96),
  (kind: "conv", spatial: 27, channels: 256, n: 1, relu: true, label: [conv2]),
  (kind: "pool", spatial: 13, channels: 256),
  (kind: "conv", spatial: 13, channels: 384, n: 3, relu: true, label: [conv3-5]),
  (kind: "pool", spatial: 6, channels: 256),
  (kind: "fc", units: 4096, label: [fc6]),
  (kind: "fc", units: 4096, label: [fc7]),
  (kind: "softmax", units: 1000, label: [softmax]),
))

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

// LeNet-style CNN as 3-D feature-map prisms (render with dir: "ltr"): the front face
// shrinks with spatial size, the depth grows with channels.
#let lenet() = seq(
  conv(label: [Input], spatial: 32, channels: 1, role: "data"),
  conv(label: [C1], spatial: 28, channels: 6, role: "data"),
  conv(label: [S2], spatial: 14, channels: 6, role: "norm"),
  conv(label: [C3], spatial: 10, channels: 16, role: "data"),
  conv(label: [S4], spatial: 5, channels: 16, role: "norm"),
  block(id: "fc", label: [FC\ 120], role: "op"),
  block(id: "out", label: [Softmax\ 10], role: "param", emphasis: true),
)

// A VGG-style block: `count` convs at one resolution, then a pool (halved resolution).
#let vgg-block(count: 2, channels: 64, spatial: 56, name: none) = seq(
  ..range(count).map(_ => conv(label: name, spatial: spatial, channels: channels, role: "data")),
  conv(label: [pool], spatial: calc.max(1, calc.floor(spatial / 2)), channels: channels, role: "norm"),
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
