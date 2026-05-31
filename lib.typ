// mlatlas — a Typst library for ML / neural-network / AI / vision diagrams.
// Public entry point:  #import "@preview/mlatlas:0.2.0": *
//
// Print-first by default (light fills, dark text, sharp orthogonal edges, stealth
// arrows). Switch the whole look with one setting — `theme: colorful` / `grayscale` /
// `slides` — or define your own scheme with `palette-theme(..)`. Build custom topologies
// (dual-backbone, two-stream, dual-head) with `parallel` / `branch` / `merge`.

// themes & customization
#import "src/theme/themes.typ": (
  mono, colorful, colorblind, grayscale, bw, slides, paper, theme, palette-theme, style-of, edge-style-of,
)
#import "src/theme/tokens.typ": neutral, okabe, colorful-hues
#import "src/theme/contrast.typ": lum, pick-text, tint, deep-merge
#import "src/theme/roles.typ": color-roles
#import "src/theme/swatch.typ": theme-swatch

// IR (escape hatch)
#import "src/ir/ir.typ": ir-node, ir-edge, ir-group, frag, namespace, shift, extent, frag-in, frag-out, is-frag

// render
#import "src/render/render.typ": render, standalone

// primitives
#import "src/prim/block.typ": block
#import "src/prim/op.typ": op-node, add-op, mul-op
#import "src/prim/slab.typ": slab, conv
#import "src/prim/neuron-graph.typ": neuron-graph

// composition sugar
#import "src/sugar/sugar.typ": seq, parallel, branch, merge, concat, residual, plate, graph

// presets
#import "src/presets/nn.typ": perceptron, mlp, feedforward
#import "src/presets/transformer.typ": transformer, transformer-block, attention-head
#import "src/presets/vision.typ": resnet-stage, lenet, lenet5, vgg-block, vgg16, alexnet, unet, two-stream
#import "src/renderers/cnn.typ": cnn, cnn-palette
#import "src/renderers/lstm.typ": lstm-cell, lstm-palette
#import "src/presets/generative.typ": gan, vae, diffusion-chain
#import "src/presets/sequence.typ": rnn-unroll
#import "src/presets/graph-models.typ": gcn
#import "src/renderers/gnn.typ": message-passing, gnn-palette

#let mlatlas-version = "0.2.0"
