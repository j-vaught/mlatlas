# Changelog

All notable changes to **mlatlas** are documented here.

## [Unreleased]

### Changed (breaking)
- **`block` renamed to `block2d`.** The public node primitive is now exported as `block2d`
  (pairing with `block3d`), so a wildcard `#import "@preview/mlatlas:..": *` no longer shadows
  Typst's built-in `block()` layout container — downstream `block(inset:.., fill:..)` works
  again. Migration: `block(..)` → `block2d(..)`. Internal scoped imports of the primitive are
  unchanged. (#2)

### Added
- **Vision refs for LaMa inpainting:** `examples/refs/vision/ffc-block.typ` (a Fast Fourier
  Convolution layer — local/global channel split, the four cross-domain conv paths, and an
  expanded Spectral Transform: real 2-D FFT → concat(Re,Im) → 1×1 conv → inverse FFT) and
  `examples/refs/vision/lama-inpainting.typ` (the LaMa generator as an encoder→FFC-bottleneck→
  decoder hourglass plus the training objective: HRF perceptual, PatchGAN adversarial,
  discriminator feature-matching, R1, and L1-on-known).

## [0.3.0] — 2026-05-31

A hand-rolled 3-D block engine and a library-wide 3-D expansion.

### Added
- **3-D engine** (`src/adapters/3d.typ`): `block3d` (projects the 8 corners itself → correct
  back-face culling + a single convex-hull silhouette at any camera angle), `feature-map`,
  `scene` (depth-sorts overlapping blocks), `project`/`projector`, `block3d-anchors`. Two
  projection families — rotation (`cam-iso`/`cam-dimetric`/`cam-top-down`) and oblique
  (`cam-cabinet`/`cam-cavalier`/`cam-face`). Flat by default, opt-in `shade`; `seams` (ribbed
  sub-layers) and `band` (ReLU stripe) overlays.
- **3-D primitives:** `tensor3d` (labeled N-D box), `connect3d` (`arrow3d`/`dock`/`ribbon3d`),
  `voxel-grid` + `conv3d-kernel` + `kernel-slide`.
- **3-D renderers:** `resnet3d`, `unet3d`, `fpn3d`, `feature-stack`, `attention-3d` (multi-head
  QKᵀ score cube), `transformer-3d` (`depth-plate` ×N), `rnn-unroll3d`, `lstm-cell3d`,
  `vae3d`/`gan3d`, `vgg3d`/`alexnet3d`.
- **IR integration:** a first-class `tensor` node (`kind: tensor3d`) that auto-layouts and
  auto-edges through `render()`; the backend firewall holds (render.typ pulls a content-only
  block from `adapters/3d.typ`, never cetz).
- Verification probes (`probes/cam-sweep`, `before-after-vgg`, `3d-themes`) + many examples.

### Changed
- **`cnn` migrated onto the engine:** each conv group is now ONE block with internal `seams`
  (not N chopped sub-prisms), depth reads `log(channels)`, one clean silhouette per group.
  Default camera `cam-cabinet`. Public `#cnn(layers, ..)` signature unchanged.
- **`two-stream` migrated:** prisms via `block3d`; the fusion node no longer pierced by the
  merge arrows. `dual-head` and all public signatures unchanged.

### Fixed
- The conv-group "cap-on-last" bug and the stacked-card look (structurally impossible now).
- Two-stream merge arrows piercing the fusion box.

## [0.2.0] — 2026-05-30

A print-first rewrite. The library is now genuinely usable and broadly customizable.

### Changed (breaking)
- **Print-first theming.** Default `mono` theme uses LIGHT fills + DARK text + sharp
  orthogonal edges; garnet is a sparse accent only. Replaces the old dark-fill/white-text
  scheme (which is now confined to the opt-in `slides` theme). Three-tier tokens
  (palette → roles → theme).
- **Module restructure.** Flat `src/*.typ` split into `src/theme`, `src/ir`,
  `src/adapters` (fletcher/cetz firewall), `src/layout`, `src/render`, `src/prim`,
  `src/sugar`, `src/presets`.

### Added
- **Themes:** `colorful` (Okabe-Ito, colourblind-safe), `colorblind`, `grayscale`/`bw`,
  `slides`; `theme()` / `palette-theme()` constructors; `theme-swatch()`; luminance
  `pick-text` auto-contrast.
- **Custom topologies:** `parallel`, `branch`, `merge`, `concat` — dual-backbone,
  two-stream / multi-modal fusion, dual-head in a few calls.
- **Primitives:** `neuron-graph` (perceptron/MLP), luminance-adaptive `slab`/`conv`.
- **Presets:** `perceptron`, `mlp`, `feedforward`, `attention-head`, `lenet`, `vgg-block`,
  `unet`, `two-stream`.
- **Fixes:** per-edge `style` now honoured; bbox-aware, scale-independent collision
  checker; gutter lane allocator (interval-graph colouring) for overlapping skips;
  IR validation (duplicate-id / dangling-edge); fletcher/cetz behind an adapter firewall.

## [0.1.0] — 2026-05-30

Phase 0 — foundation & contract. The semantic IR, the brand theme, the fletcher
emitter, and enough primitives/presets to render real architecture figures.

### Added
- **Semantic IR** (`ir.typ`): plain-dict `node` / `edge` / `group` / `fragment`
  contract, with helpers (`shift`, `namespace`, `extent`, port lookup).
- **Theme** (`theme.typ`): the default garnet theme — rectangular nodes
  (`corner-radius: 0pt`), high-contrast palette, role→style and edge-kind→style
  tables — plus a `theme(..)` constructor and `deep-merge`.
- **Renderer** (`render.typ`): fletcher L0 emitter with sharp, orthogonal edge
  routing — straight where aligned, deterministic gutter lanes for skips
  (relative-anchored so they never flip sides), L-corners otherwise. `ltr`
  transpose and a `standalone()` helper.
- **Primitives**: `block`, `op-node`.
- **Sugars**: `seq` (auto-wired sequential), `graph` (explicit), `residual`
  (first-class skip + ⊕), `plate` (dashed "×N" enclosure).
- **Presets**: `transformer` / `transformer-block` / `attention-head`,
  `resnet-stage`.
- **Examples**: `simple`, `transformer-encoder`, `resnet-block`.

### Notes
- Pinned dependencies: `fletcher 0.5.8`, `cetz 0.5.2` (via fletcher).
- Every default is overridable: by parameter, per-node/edge `style`, a custom
  `theme`, or by dropping to the raw `graph`/IR layer.
