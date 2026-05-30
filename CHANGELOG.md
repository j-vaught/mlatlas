# Changelog

All notable changes to **mlatlas** are documented here.

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
