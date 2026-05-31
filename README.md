# mlatlas

**Declarative, print-first machine-learning & neural-network diagrams for [Typst](https://typst.app).**

Describe the *model* — `transformer(blocks: 6)`, `mlp((4, 8, 8, 3))`, a two-stream fusion —
and get a clean, publication-quality figure. Batteries-included defaults so a simple diagram
is one line; full control (themes, per-element overrides, custom topologies, raw IR) when you
need it.

<p align="center"><img src="media/cnn-vgg.png" width="900" alt="VGG-16 and LeNet-5 as 3-D feature-map prisms"></p>

*Publication-grade figures from dedicated per-family renderers — VGG-16 / LeNet-5 above; LSTM
cells (Olah), GNN message passing, DDPM chains, and LDA plates below.*

<p align="center">
  <img src="media/lstm-cell.png" height="210" alt="LSTM cell">
  &nbsp;
  <img src="media/gnn.png" height="210" alt="GNN message passing">
  &nbsp;
  <img src="media/pgm.png" height="210" alt="LDA plate notation">
</p>

<p align="center"><img src="media/themes.png" width="820" alt="The same Transformer block in four themes"></p>

*The same diagram in four themes — one setting flips the whole look.*

## Print-first by design

The default **`mono`** theme is built for paper: **light fills, dark text, sharp orthogonal
edges, stealth arrows**, with garnet used only as a sparse accent. **Never a dark block with
white text.** Switch the entire look with one setting:

```typst
#render(ir)                       // mono (default) — restrained, print-safe
#render(ir, theme: colorful)      // Okabe-Ito light tints (colourblind-safe)
#render(ir, theme: grayscale)     // pure B&W, value + dash differentiation
#render(ir, theme: slides)        // opt-in dark (auto white text)
#render(ir, theme: palette-theme((op: rgb("#1F414D"), norm: rgb("#65780B"))))  // your own scheme
```

A luminance check picks readable text for *any* fill, so contrast is never wrong by accident.

## Quick start

```typst
#import "@preview/mlatlas:0.3.0": *   // or local: #import "mlatlas/lib.typ": *

// Simple is one line — auto-wired, auto-themed.
#render(seq(
  block(label: [Input], role: "data"),
  block(label: [Hidden Layer]),
  block(label: [Output], role: "output"),
))

#render(transformer(blocks: 6, heads: 8, rope: true))   // residual skips auto-routed
#render(mlp((4, 8, 8, 3)))                                // node-edge MLP
#render(lenet(), dir: "ltr")                              // CNN as 3-D feature-map prisms
```

## 3-D blocks, volumes & tensors

<p align="center"><img src="media/gallery-3d.png" width="900" alt="3-D figures: CNN, U-Net, attention cube, transformer, ResNet, kernel-slide, RNN/LSTM, generative"></p>

A small hand-rolled 3-D engine projects each block's eight corners itself — so back-face culling
and a single clean silhouette are correct at **any** camera angle (cetz's native 3-D can't manage
this cleanly, because it hides the projected coordinates: you get corner spikes and bow-tied
outlines). Flat by default — the crisp edges carry the depth — with opt-in directional shading.

```typst
#import "@preview/cetz:0.5.2"
#cetz.canvas(length: 1cm, {
  import cetz.draw
  block3d(draw, w: 1.4, h: 2.0, dep: 1.2, base: rgb("#FFF2E3"))         // one block, one call
  feature-map(draw, (4, 0), spatial: 112, channels: 128, relu: true)    // spatial->height, channels->depth
})
```

Architecture renderers compose it: `cnn` / `feature-stack` (feature-map rows), `resnet3d`,
`unet3d`, `fpn3d`, `attention-3d` (the multi-head QKᵀ score cube), `transformer-3d`,
`rnn-unroll3d`, `lstm-cell3d`, `voxel-grid`, `kernel-slide`, `vae3d` / `gan3d`. Or drop a 3-D
`tensor` straight into the IR for auto-layout + edges:
`render(seq(tensor(title: [x], axes: ([56], [56], [3])), tensor(title: [z], axes: ([1], [1], [128]))))`.

The camera is three angles `(pitch, yaw, roll)` — exactly like cetz's `ortho` — set once per
scene and overridable per block:

| preset | family | look |
|---|---|---|
| `cam-iso` *(default)* | rotation | isometric, corner-front — sculptural |
| `cam-dimetric` | rotation | gentle dimetric |
| `cam-top-down` | rotation | high-angle |
| `cam-cabinet` | oblique | upright front face, depth shears up-right — best for CNN rows |
| `cam-cavalier` | oblique | upright front, full-depth |
| `cam-face` | oblique | shallow oblique |

```typst
block3d(draw, w: 2, h: 2, dep: 2, cam: cam-cabinet, shade: true)   // a preset
block3d(draw, w: 2, h: 2, dep: 2, cam: (30deg, -40deg, 8deg))      // or raw angles
```

## Custom topologies are first-class

Dual-backbone, two-stream / multi-modal fusion, dual-head — a few readable calls, **no manual
coordinates**:

<p align="center">
  <img src="media/two-stream.png" height="330" alt="Two-stream multi-modal fusion">
  &nbsp;&nbsp;
  <img src="media/dual-head.png" height="330" alt="Dual-head architecture">
  &nbsp;&nbsp;
  <img src="media/unet.png" height="330" alt="U-Net with skip connections">
</p>

```typst
// two-stream / multi-modal fusion
#render(two-stream(image-stream, text-stream, fusion: [Fusion], head: head-stack))

// shared backbone, two task heads
#render(branch(backbone, cls-head, box-head))

// arbitrary fan-in / fan-out
#render(merge(arm-a, arm-b, arm-c, into: block(label: [Concat])))
```

## Customization — no forking

```typst
block(label: [Conv], style: (fill: rgb("#eee"), stroke: 2pt + rgb("#65780B")))  // per-node
block(label: [Focal], emphasis: true)                                            // sparse garnet accent
graph(edges: (("a", "b", (style: (stroke: 2pt + red), label: [grad])),))         // per-edge
render(ir, role-map: (attention: "param"))                                       // restyle a category
render(ir, theme: theme(spacing: (18mm, 12mm)))                                  // tweak any theme field
graph(nodes: (..ir-nodes..), edges: (..))                                        // full IR escape hatch
```

## Layout safety net

`render` warns (by default) when an edge crosses an unrelated block — a bbox-aware,
scale-independent check:

```typst
#render(ir)                  // check: "warn"  -> banner if a line crosses a block
#render(ir, check: "error")  // hard error
#render(ir, check: "off")
```

## What's here

| Layer | Pieces |
|---|---|
| Themes | `mono` (default), `colorful`, `colorblind`, `grayscale`/`bw`, `slides`; `theme(..)`, `palette-theme(..)`, `theme-swatch` |
| IR | `ir-node`, `ir-edge`, `frag`, `namespace`, `shift` (escape hatch) |
| Primitives | `block`, `op-node`, `slab`/`conv` (3-D prisms), `neuron-graph`, `tensor` (3-D IR node) |
| **3-D engine** | `block3d`, `feature-map`, `scene`, `project`, `tensor3d`, `arrow3d`/`dock`, `voxel-grid` + `cam-iso`/`cam-cabinet`/… presets |
| Composition | `seq`, `parallel`, `branch`, `merge`, `concat`, `residual`, `plate`, `graph` |
| Presets | `perceptron`, `mlp`, `feedforward`, `transformer`(`-block`), `attention-head`, `resnet-stage`, `unet`, `two-stream`, `gan`, `vae`, `rnn-unroll`, `gcn` |
| **Dedicated renderers** | `cnn`/`vgg16`/`alexnet`/`lenet5` (PlotNeuralNet-grade), `lstm-cell` (Olah), `message-passing` (GNN), `diffusion-chain` (DDPM), `lda-plate`/`hmm-chain` (PGM) |
| **3-D renderers** | `resnet3d`, `unet3d`, `fpn3d`, `attention-3d` (QKᵀ cube), `transformer-3d`, `rnn-unroll3d`, `lstm-cell3d`, `kernel-slide`, `vae3d`/`gan3d` |

Architecture: a plain-dict semantic IR is the contract; primitives/presets emit IR; the
renderer draws it via fletcher/cetz behind an adapter firewall. See
[`docs/design-spec.md`](docs/design-spec.md) for the full design and the roadmap toward the
broader ML-diagram atlas (sequence cells, attention internals, generative/graph/probabilistic
models, plots, audio/3-D, and the long tail).

## Building the examples

```bash
typst compile --root . examples/transformer.typ      # or any example
./tools/render-all.sh                                 # compile + rasterize all
```

## License

[MIT](LICENSE) © 2026 J.C. Vaught.
