// mlatlas — a Typst library for ML / neural-network / AI / vision diagrams.
// Entry point (work in progress — local install for now, not yet on the Typst registry):
//   #import "@local/mlatlas:0.3.0": *      // local install
//   #import "@preview/mlatlas:0.3.0": *    // once published
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
// NOTE: exported as `block2d` (pairs with `block3d`) so the package does not shadow
// Typst's built-in `block()` for users who `#import "@preview/mlatlas:..": *`.
#import "src/prim/block.typ": block as block2d
#import "src/prim/op.typ": op-node
#import "src/prim/slab.typ": slab, conv, tensor
#import "src/prim/neuron-graph.typ": neuron-graph

// 3-D block engine (hand-rolled projection: project 8 corners -> cull -> hull silhouette)
#import "src/adapters/3d.typ": (
  block3d, block3d-anchors, feature-map, scene, scene-canvas,
  project, project-z, projector, tensor3d-content,
  cam-iso, cam-dimetric, cam-cabinet, cam-cavalier, cam-face, cam-top-down, CAMERAS,
)

// 3-D tensor primitives + connectors
#import "src/prim/tensor3d.typ": tensor3d, tensor3d-fig, tensor3d-palette
#import "src/prim/connect3d.typ": arrow3d, dock, ribbon3d

// composition sugar
#import "src/sugar/sugar.typ": seq, parallel, branch, merge, concat, residual, plate, graph

// presets
#import "src/presets/nn.typ": perceptron, mlp, feedforward
#import "src/presets/transformer.typ": transformer, transformer-block, attention-head
#import "src/presets/vision.typ": resnet-stage, lenet, lenet5, vgg-block, vgg16, alexnet, unet
#import "src/renderers/cnn.typ": cnn, cnn-palette
#import "src/renderers/cnn3d.typ": (
  cnn3d-palette, volume, vol-anchors, feature-stack, feature-stack-fig,
  resnet3d, unet3d, fpn3d, vgg3d, alexnet3d,
)
#import "src/renderers/multistream.typ": dual-head, two-stream, ms-palette
#import "src/renderers/lstm.typ": lstm-cell, lstm-palette
#import "src/presets/generative.typ": gan, vae
#import "src/presets/sequence.typ": rnn-unroll
#import "src/presets/graph-models.typ": gcn
#import "src/renderers/diffusion.typ": diffusion-chain
#import "src/renderers/pgm.typ": lda-plate, hmm-chain, pgm-palette
#import "src/renderers/llm.typ": (
  llm-arch, llm-figure, llm-compare, llm-palette, llama3-8b, olmo2-7b, deepseek-v3, qwen3-235b,
)
#import "src/renderers/gnn.typ": message-passing, gnn-palette
#import "src/renderers/attention3d.typ": (
  attention-3d, attention-3d-figure, attn3d-palette, embedding-tensor3d, depth-plate, transformer-3d,
)
#import "src/renderers/rnn3d.typ": rnn-unroll3d, lstm-cell3d, rnn3d-palette
#import "src/prim/voxel.typ": voxel-grid, conv3d-kernel, kernel-slide, voxel-palette
#import "src/renderers/pyramid3d.typ": pyramid3d, vae3d, gan3d

#let mlatlas-version = "0.3.0"
