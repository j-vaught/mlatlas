// mlatlas — a Typst library for ML / neural-network / AI / vision / audio diagrams.
// Public entry point. Import everything with:
//   #import "@preview/mlatlas:0.1.0": *
//
// Design: a plain-dict Semantic IR is the contract; primitives and presets emit IR;
// `render` draws it with fletcher. Brand defaults (rectangular, garnet, high-contrast,
// sharp orthogonal edges) live in one theme and are inherited everywhere. Every default
// is overridable — by parameter, per-node/edge style, a custom theme, or by dropping to
// the raw `graph`/IR layer.

#import "src/theme.typ": brand, garnet-theme, code-theme, theme, style-of, edge-style-of, deep-merge
#import "src/ir.typ": ir-node, ir-edge, ir-group, frag, is-frag, namespace, shift, extent, frag-in, frag-out
#import "src/primitives.typ": block, op-node, slab, conv
#import "src/sugar.typ": seq, graph, residual, plate
#import "src/render.typ": render, standalone, check-collisions
#import "src/catalog/transformer.typ": transformer, transformer-block, attention-head
#import "src/catalog/resnet.typ": resnet-stage

#let mlatlas-version = "0.1.0"
