# ML Diagram Atlas — Library Design Spec

**Author:** J.C. Vaught
**Status:** Authoritative design (v1). Supersedes the five competing architecture proposals.
**Scope:** A Typst-first library that renders the 208-type ML/AI diagram atlas (17 sections, A–Q) as standalone, brand-styled, publication-quality figures.
**Target stack (verified May 2026):** `fletcher 0.5.9`, `cetz 0.5.2`, `cetz-plot 0.1.3`, `lilaq 0.5.0`, `quill 0.7.2`, `neural-netz 0.3.0`, `autograph 0.1.0`, `diagraph` / `diagraph-layout` (Graphviz-WASM), `plotsy-3d`.

---

## 0. How this spec resolves the five proposals

Five architects pitched competing centers of gravity. This spec is a deliberate synthesis, not a vote. The resolved positions:

| Tension | Proposals | Resolution (this spec) | Reasoning |
|---|---|---|---|
| What is the contract? | *primitive-first* (opaque `prim` record) vs *declarative-DSL* / *backend-abstraction* (plain-dict IR) | **Plain-dict Semantic IR** is the contract. Primitives are *constructors that emit IR*, not opaque records. | A dict IR is serializable, mergeable with `+`, inspectable, and survives a future LaTeX backend. An opaque record locks behavior into closures and kills override ergonomics. The primitive-first *catalog of ~12 builders* is excellent and is kept — but as IR emitters. |
| Layout ownership | *primitive-first* / *ecosystem-reuse* (delegate to fletcher's elastic grid) vs *backend-abstraction* (port Sugiyama into Typst, layout-above-emitter) | **Delegate metric layout to fletcher's elastic (u,v) grid; never hand-roll Sugiyama.** Use `autograph`/Graphviz only as a guarded escape hatch for large *unlabeled* graphs. | The feasibility skeptic is decisive here: a homegrown Sugiyama is the single most likely thing to blow the schedule, and `autograph 0.1.0` cannot do labeled edges (which most ML graphs need). Layout-above-emitter is the *right* abstraction for true dual-backend, but we are Typst-first, so we buy nothing today by reimplementing what fletcher already does well. We keep the IR seam so a future LaTeX backend *can* own layout. |
| One backend or two? | *backend-abstraction* (dual Typst+LaTeX) vs everyone else (Typst-first) | **Typst-first. The IR + emitter seam is designed in, the LaTeX emitter is deferred/stubbed.** | LaTeX parity mainly buys true-3D and quantum/string-diagram maturity — exactly the ~30 types already exempted from the IR. Doubling catalog cost for that is a bad trade. The seam keeps us honest without the tax. |
| Build vs wrap | *primitive-first* (12 primitives + composition) vs *ecosystem-reuse* (wrap ~150, build ~18) | **Wrap aggressively; build only the genuine long tail.** The 12-primitive catalog is how we *compose*, but pictorial/3D/raster types delegate to `neural-netz`, `lilaq`, `quill`, `plotsy-3d`, or embedded rasters. | "Forcing the long tail through 12 primitives yields ugly output" (primitive-first's own risk #3). The honest coverage split is ~70% native graph/plot, ~15% bespoke cetz, ~10% raster, ~5% interop. |
| DSL form | *declarative-DSL* (model.seq / model.graph) vs *backend-abstraction* (named constructors, "Typst is the DSL") | **Named-function catalog + two composition sugars (`seq`, `graph`).** No custom text parser. | Typst functions already *are* a typed DSL with editor support and good errors. A custom parser is all cost. But the `seq`/`graph`/`residual()` sugar from declarative-DSL is genuinely better ergonomics than bare constructors, so we keep it as thin sugar over IR.

The result: **plain-dict IR contract · 12 composable primitive-emitters · fletcher-owned metric layout · aggressive wrapping · Typst-only execution with a designed-in LaTeX seam.**

---

## 1. Vision & Non-Goals

### Vision
A single import — `mlatlas` — from which an author can produce any of the 208 atlas figures as a **standalone PDF** (per the user's "standalone images imported into the document" rule), in a uniform **rectangular, high-contrast, garnet** house style, by *declaring model semantics* rather than placing boxes. Authors write `transformer(encoder: 6, decoder: 6)` or `roc-curve(data: csv("runs.csv"))`; they never name a color, a coordinate, or a stroke weight.

### Goals
- **Semantic-first.** The author describes *what the model is*; the library decides *how it looks*.
- **Brand-enforced.** Rectangular nodes (`corner-radius: 0pt`), garnet accent (`#73000A`), high contrast, no rounded edges anywhere — encoded once, inherited by all 208 presets.
- **Buildable today.** Every primitive maps to a verified, current package capability. No speculative dependencies.
- **Composable.** ~12 primitives + ~30 sub-builders compose into 208 presets. Presets compose into bigger presets by IR concatenation (`unet` calls `resnet_stage`; `diffusion_chain` embeds a `unet`).
- **Escape hatches everywhere.** Any preset → `graph(...)` → raw `fletcher`/`cetz`. Auto-layout is a default, never a cage.
- **Standalone outputs.** Each figure compiles to its own `.typ` → `.pdf`, so the master document never re-renders the whole atlas.

### Non-Goals
- **No custom text DSL / parser.** Typst functions are the DSL.
- **No homegrown graph-layout engine.** We do not reimplement Sugiyama or force-directed layout in Typst. (See §4.)
- **No computing raster content in Typst.** Grad-CAM, saliency, spectrograms, NeRF/3DGS renders, segmentation masks are *supplied* as images and annotated — never computed.
- **No CI/CD, no automated test runners on push.** (Visual regression is a local, manual golden-image step — see §11.)
- **No LaTeX backend in v1.** The IR seam is built; the emitter is a stub.
- **No true-3D at scale.** Loss landscapes default to 2D contour/heatmap; at most 1–2 hero surfaces use `plotsy-3d`.
- **Not a general drawing tool.** This is an ML-diagram catalog. General-purpose figures stay in raw cetz.

---

## 2. Layered Architecture

Five layers with a **hard boundary at the IR (L3)**. Everything above L3 is backend-blind; everything below is backend-specific. The IR is plain Typst dictionaries.

```
L5  Catalog        208 named generators: transformer(), lstm-cell(), roc-curve(), unet() ...
                   thin presets; pure semantics in -> IR out.   (mlatlas/catalog/*.typ)
─────────────────────────────────────────────────────────────────────────────────────
L4  Primitives     ~12 composable emitters: block stack slab neuron-graph matrix chain
    + sub-builders plate branch/merge attention gate memory loop  +  ~30 mixins
                   (encoder-stack, attention-block, residual-wrap, cellgate, plate-box…)
                   Each is (args) -> IR.                          (mlatlas/prim/*.typ)
─────────────────────────────────────────────────────────────────────────────────────
L3  SEMANTIC IR    THE CONTRACT. Plain dict: { kind, nodes, edges, groups, layout, meta }.
                   Pure data. Serializable. Mergeable with `+`. Backend-agnostic.
─────────────────────────────────────────────────────────────────────────────────────
L2  Layout pass    Resolves layout HINTS -> elastic (u,v) grid coords + lane/gutter
                   assignment for skips. Delegates METRIC layout to the backend.
                   Three regimes: elastic-grid (default) · graphviz (escape) · plot/grid.
─────────────────────────────────────────────────────────────────────────────────────
L1  Theme          brand.typ: palette, stroke weights, corner-radius:0pt, fonts, marks,
                   role->style table. Injected via ctx; never hard-coded in L4/L5.
─────────────────────────────────────────────────────────────────────────────────────
L0  Emitters       IR.kind -> drawing calls:
    (backends)       graph -> fletcher (+cetz bodies inside nodes, +neural-netz for prisms)
                     plot  -> lilaq (primary) / cetz-plot (bar/pie) / plotsy-3d (3D)
                     grid  -> lilaq.colormesh / cetz mesh
                     circuit -> quill
                     raster -> image() in cetz content() + annotation overlay
                   LaTeX emitter: STUBBED (designed-in, deferred).
```

**Why the boundary is at L3, not at the renderer.** The *backend-abstraction* architect wanted layout above the emitter so two backends render the identical picture. We keep the IR boundary (so presets are backend-blind) but **let L2 emit layout *hints* and let fletcher resolve metric positions**, rather than resolving absolute coordinates ourselves. Today this is strictly better (no Sugiyama to maintain). The cost — a future LaTeX backend must re-derive metric layout — is acceptable because (a) we are not building LaTeX in v1, and (b) the ~30 types where LaTeX wins are exempt from the IR anyway.

**The two-backend coordinate seam (primitive-first's risk #1) is resolved by a rule:** *fletcher always owns top-level layout.* cetz/neural-netz/lilaq bodies are only ever painted *inside a reserved fletcher node box* (`fletcher.node(.., shape: custom-cetz-body)`). cetz never positions a top-level element that fletcher must then align to. This eliminates the UV-grid-vs-absolute-XY handoff drift.

---

## 3. Primitive Catalog (the 12 emitters + anchors/ports)

Every primitive is a function `(args, ctx) -> IR-fragment`. Each emits **nodes** (with a uniform anchor grammar) and **edges**, plus optional **groups**. The anchor grammar is shared by all kinds: **compass** (`n s e w ne nw se sw c`) for geometry, plus **semantic ports** per kind for wiring. Ports carry a direction so edges snap to the outline correctly.

```typst
// IR node shape (L3 contract)
#let node = (
  id: "attn",                       // unique within the (namespaced) IR
  label: [Multi-Head\nAttention],   // arbitrary Typst content incl. $math$
  kind: "rect",                     // geometry: rect|circle|ellipse|cylinder|stadium|
                                    //           diamond|trapezoid|plate|stack|slab|hex
  role: "op",                       // semantics -> drives styling: op|data|param|loss|io|ctrl
  shape-body: none,                 // optional cetz/neural-netz painter drawn INSIDE the box
  pos: none,                        // filled by L2 (elastic (u,v) or absolute)
  size: auto,
  group: "encoder",                 // membership -> enclose/plate box
  ports: ("in", "out"),             // semantic ports beyond compass
)
#let edge = (
  from: "x", to: "attn",
  kind: "data",                     // data|control|grad|skip|attention|sample|residual
  from-port: "out", to-port: "in",
  head: "arrow", dash: "solid", bend: 0deg, label: [],
)
```

| Primitive | Atlas coverage | Semantic ports (beyond compass) | Nests? | Backed by |
|---|---|---|---|---|
| `block` | labeled op: Conv, Norm, MLP, Linear, Embed | `.in .out` | leaf/container | fletcher node (`corner-radius:0`) |
| `stack` | vertical layer pile: VGG, MLP-as-bars, Inception parallel arms | `.in .out .layer(i)` | holds blocks | fletcher column |
| `slab` | 3-D tensor cuboid C×H×W: CNN feature map, ViT patches | `.front .depth-lo .depth-hi` | leaf | **cetz cuboid helper** (or neural-netz) inside fletcher node |
| `neuron-graph` | node–edge net: perceptron, MLP, Hopfield, GNN, factor graph, Bayes net | `.node(l,i) .layer(l)` | leaf | fletcher (or autograph for big DAGs) |
| `matrix` | grid/heatmap: attention map, confusion matrix, conv kernel, plate grid | `.cell(r,c) .colorbar` | leaf | **lilaq.colormesh** / cetz mesh |
| `chain` | sequential flow w/ auto arrows: pipeline, diffusion, seq2seq | `.step(i) .head .tail` | holds any prim | fletcher elastic row/col |
| `plate` | replication rectangle "×N": LDA, Bayes plate | `.body .count` | container | fletcher **enclose** node |
| `branch` / `merge` | fan-out / fan-in: residual, two-stream, MoE, U-Net skips | `.trunk .arm(i)` | router | fletcher edges + gutter lanes |
| `attention` | Q·Kᵀ→softmax→·V bipartite ribbon; multi-head concat | `.q .k .v .out .head(i)` | leaf/container | cetz body inside fletcher node |
| `gate` | σ/tanh gate glyphs + elementwise ⊙ ⊕ : LSTM/GRU cell internals | `.in[] .ctrl .out` | leaf | **cetz cellgate helper** |
| `memory` | read/write cell bank: NTM, KV-cache, Transformer-XL | `.read .write .slot(i)` | leaf | cetz grid + weighted arrows |
| `loop` | recurrence/feedback arc: RNN unroll, agent–env, EM | `.body .back` | wrapper | fletcher bent edge, z-behind |

**Exotic leaves (honest scope — the long tail the 12 cannot cleanly express):** `surface` (loss landscape → plotsy-3d/contour), `scatter` (t-SNE/UMAP → lilaq), `ray-field` (NeRF rays → cetz quiver), `tensor-leg` (Penrose/string diagram → bespoke cetz), `raster` (Grad-CAM/spectrogram/NeRF render → `image()` + overlay). These exist precisely because primitive-first's risk #3 is real: forcing pictorial/continuous types through node/edge primitives produces ugly output.

**Math-in-nodes is free.** fletcher and cetz nodes accept arbitrary Typst content, so `$h_t = sigma(W x_t + U h_(t-1))$` inside a box "just works." This is a genuine advantage over hand-tuned TikZ and is treated as a load-bearing feature, not a risk.

---

## 4. Layout Strategy (and the DAG-layout decision)

**Two-pass, primitive-local, fletcher-delegated.**

1. **Pass 1 — measure.** Each primitive emits its IR fragment with a known bbox + anchor dict. cetz groups already expose child bboxes as anchors; we lean on that. Containers (`chain`, `stack`, `plate`, `branch`) translate child anchors into parent space.
2. **Pass 2 — place.** L2 resolves layout *hints* into an **elastic (u,v) grid** and hands metric layout to **fletcher's elastic table layout**. A `flow` directive (`ltr`/`ttb`) does greedy 1-D packing of siblings along the main axis at a fixed `gap`, cross-axis centered. **We delegate physical spacing rather than reinventing it.**

**Skip / branch routing.** Residual, dense, and U-Net skips reserve **outer gutter lanes**: skip edges route in the margin via a lane-assignment allocator and are z-ordered behind trunk blocks using cetz `on-layer`. This is the single fiddliest piece of the build (primitive-first risk #5, declarative risk #1) — naive "bend above trunk" produces spaghetti on dense/Transformer-XL/U-Net diagrams. **Mitigation:** lane assignment is a real allocator (greedy interval-graph coloring of overlapping skip spans), and every primitive accepts a `lane:`/`coords:` override so a hero figure can pin routing.

### The DAG-layout decision (explicit)

Three architects wanted automatic graph layout; they disagreed on how. **Decision, in priority order:**

1. **Default: fletcher elastic (u,v) grid, hand-authored ranks.** For the sizes that actually occur in the atlas (most figures are 5–30 nodes; cap at ~40), authored elastic coordinates produce clean, *deterministic, reproducible* layouts. Determinism beats prettiness — reproducible PDFs matter.
2. **Escape hatch for large *unlabeled* DAGs: `diagraph` (pure Graphviz→SVG, labels work) or `autograph` (Graphviz layout rendered via fletcher).** Used only for a genuinely large graph (big Bayes net, MDP state graph, NAS supernet).
3. **We do NOT build a Sugiyama/force-directed engine in Typst.** This is the explicit rejection of *backend-abstraction*'s central bet. The feasibility skeptic is decisive: reimplementing Sugiyama is the project's likeliest schedule-killer, and the abstraction it buys (identical picture across two backends) is worthless while we ship one backend.
4. **`autograph 0.1.0` is NOT trusted for labeled edges.** Verified limitation: as of 0.1.0 it has no edge labels, no undirected graphs, no graph-direction attribute, and cannot enclose multiple subgraphs. Most ML graphs need labeled edges, so autograph is a *narrow* fallback, not the default. Pin its version; re-verify before relying on it.

**Other regimes:** `grid` layout (trivial (r,c)) for heatmaps/confusion/attention/plate replication; `plot` data-space (axes auto-scale from data) for O/Q. `manual`/`free` coordinates for the ~20 irreducibly hand-drawn types (NeRF, Penrose tensor nets, loss surfaces) authored directly in cetz.

---

## 5. Declarative DSL & Preset Catalog

**No custom parser.** Two composition sugars over the IR, plus a named-function catalog. The sugars and the catalog all return the same plain-dict IR, so they interoperate and splice freely.

### 5.1 The two sugars

```typst
#import "mlatlas.typ": *

// Sequential sugar — chains layers along the flow axis with implicit edges (~70% of atlas)
#let enc = seq(
  block("embed", shape: (L, d), label: [Token + Pos Embed]),
  ..range(6).map(i => transformer-block(heads: 8, ff-mult: 4, pre-norm: true, label: [Block #(i+1)])),
  block("norm", label: [LayerNorm]),
)

// Graph form — explicit nodes/edges for skips, branches, two-stream, GAN loops
#let gan = graph(
  nodes: (block("z", role:"io"), generator(), discriminator(), block("loss", role:"loss")),
  edges: (("z","G"), ("G","D"), ("D","loss",(kind:"grad"))),
)
```

`seq(...)` returns IR you can splice into `graph(...)`. **Residuals are first-class:** `residual(body)` wraps a sub-IR and auto-emits the skip edge + ⊕ add node, so the author never hand-routes the bypass.

### 5.2 Preset catalog (each is `(args) -> IR`)

| Preset | Atlas types it covers | Key params |
|---|---|---|
| `transformer-block` / `transformer` | Transformer enc/dec, MHA, GQA/MQA, LLM stacks (E) | `pre-norm, heads, ff-mult, rope` |
| `attention-head` | scaled dot-product, cross-attn (E) | `mask, softmax` |
| `resnet-stage` | residual block, bottleneck, ConvNeXt (C) | `blocks, bottleneck, downsample` |
| `unet` | U-Net, FCN, hourglass (C, F) | `depth, skips, bottleneck` |
| `gan` / `vae` | GAN game, VAE + reparam (F) | `latent, discriminator` |
| `diffusion-chain` | forward/reverse, DiT (F) | `steps, direction, cond` |
| `moe` | MoE routing, top-k experts (E) | `experts, top-k, router` |
| `rnn-unroll` / `lstm-cell` / `gru-cell` | unrolled RNN/LSTM/GRU, cell internals (D) | `cell, steps, bidir` |
| `agent-loop` | ReAct, Reflexion, RL agent–env (H) | `tools, memory, reflect` |
| `feature-maps` | LeNet/AlexNet/VGG/ViT prism stacks (A, C, E) | `layers` → **neural-netz** |
| `roc-curve` / `confusion-matrix` / `calibration` / `learning-curve` | eval plots (O) | `data, baseline` → **lilaq** |

**Presets compose by IR concatenation + edge-stitching at named ports** (`.in .out .skip[i]`): `unet` internally calls `resnet-stage` per level; `diffusion-chain` embeds a `unet` as its denoiser; `moe` swaps a `transformer-block`'s MLP slot. To avoid the dict-merge ID collision (declarative risk #5), **composition auto-suffixes child IDs into a namespace** (`enc/block3/attn`), so two nested presets that both define `mlp` never clash.

### 5.3 Concrete examples

**ResNet block (decomposition proof: `branch{over: stack, skip: ident, merge: ⊕}`):**
```typst
#let stage = seq(
  block("conv", shape: (56, 56, 64), label: [7×7 conv, /2]),
  block("pool", label: [maxpool /2]),
  resnet-stage(blocks: 3, channels: 64,  bottleneck: true),
  resnet-stage(blocks: 4, channels: 128, downsample: true),  // skip -> 1×1 projection auto-swapped
)
#render(stage, theme: garnet)
```
`resnet-stage` emits per block `conv→BN→ReLU→conv→BN` + identity skip + post-add ReLU; `downsample:true` swaps the skip for a 1×1 projection automatically.

**Transformer encoder, pre-norm, 6 blocks:**
```typst
#let enc = seq(
  block("embed", shape: (L, d), label: [Token + Pos Embed]),
  ..range(6).map(i => transformer-block(heads: 8, ff-mult: 4, pre-norm: true, rope: true)),
  block("norm", label: [LayerNorm]),
)
#render(enc, theme: garnet, direction: ttb)
```
Each `transformer-block` expands to `LN→MHA→⊕→LN→MLP→⊕` with both skip edges auto-emitted.

**Three-tier override (no fork needed):**
```typst
transformer-block(heads: 12)                                  // 1. parameter
transformer-block(style: (mlp: (fill: blue.lighten(60%))))    // 2. per-role style patch
transformer-block().with-layer("attn", label: [Flash-Attn])   // 3. surgical IR edit by id
graph(...)  // 4. full escape to explicit nodes/edges
raw: (backend: "fletcher", body: { ... })                     // 5. inline backend escape
```

---

## 6. Theming (brand: rectangular, garnet, high-contrast)

Brand compliance lives in **one** default theme, injected through `ctx`, never hard-coded in a preset. **The author never names a color** — they set `role:`, and the theme decides. This is the only way to keep 208 figures consistent.

```typst
#let garnet = (
  // palette (from brand guide)
  accent:     rgb("#73000A"),   // garnet — focal / param role only
  ink:        rgb("#000000"),
  paper:      rgb("#FFF2E3"),   // beige
  fill:       rgb("#ECECEC"),   // 10% black — default node fill
  muted:      rgb("#A2A2A2"),   // 50% black
  // accents for multi-class differentiation
  blue:       rgb("#466A9F"), dark-blue: rgb("#1F414D"),
  pink-red:   rgb("#CC2E40"), dark-green: rgb("#65780B"), lime: rgb("#CED318"),
  // hard brand rules
  stroke:        1pt + rgb("#000000"),
  corner-radius: 0pt,                          // NEVER rounded — anywhere
  mark:          (symbol: ">", fill: rgb("#73000A")),
  font:          "New Computer Modern",
  fill-scale:    gradient.linear(rgb("#FFF2E3"), rgb("#73000A")),  // beige -> garnet ramp
)

// role -> concrete style, mapped ONCE, consumed by every emitter
#let style-of(role, th) = (
  "op":    (fill: th.fill,   stroke: th.stroke),
  "param": (fill: th.accent, stroke: th.stroke, text-fill: white),  // garnet reserved for focal
  "data":  (fill: th.paper,  stroke: th.stroke),
  "loss":  (fill: th.pink-red, stroke: th.stroke),
  "io":    (fill: white,     stroke: th.stroke),
  "ctrl":  (fill: th.muted,  stroke: (paint: th.ink, dash: "dashed")),
).at(role)
```

**Brand-rule enforcement (ecosystem-reuse risk #2 is real):** several wrapped packages default to rounded nodes or pastel palettes (`neural-netz` warm/cold, fletcher pills). Every L0 wrapper must (a) force `corner-radius: 0pt`, (b) override the package palette to the garnet ramp, (c) thread `style-of(role, th)`. A golden-image snapshot per section (see §11) catches drift when a package updates. The `role`/`kind` enum is the brand firewall; if it can't span a diagram, that override is policed in review (acceptable, bounded risk).

---

## 7. Plot Adapters

Plots are a first-class IR kind (`kind: "plot"` / `"grid"`), not an afterthought. **lilaq is the primary plot backend** (native Typst, clean publication axes, perceptual colormaps); `cetz-plot` is reserved for simple bar/pie/business charts; `plotsy-3d` is the last-resort 3D surface plotter.

| Plot family | Atlas items | Adapter |
|---|---|---|
| Line / curve | ROC/PR, calibration, learning curves, scaling laws, double-descent, grokking, activation curves, mode-connectivity path (O, Q, B) | **lilaq** line/region |
| 2-D heatmap / colormesh | attention map, confusion matrix, positional-encoding heatmap, spectrogram-from-array (O, E, I, J) | **lilaq.colormesh** |
| Scatter | t-SNE / UMAP embeddings, persistence diagram (N, P) | **lilaq** scatter |
| Vector field / contour | normalizing-flow field, score-SDE, GP surface, energy landscape, loss landscape (default view) (F, I, N) | **lilaq** quiver/contour |
| True 3-D surface | loss landscape / IB plane / EBM landscape (≤2 hero figures only) (N) | **plotsy-3d** (else contour) |

**Brand styling applies to plots too:** garnet primary series, high-contrast secondary accents from the brand palette, square (non-rounded) markers, `1pt` axes, no chartjunk. Loss landscapes **default to a 2-D contour/heatmap "plane" view** — which is also the more readable convention — reserving the immature `plotsy-3d` path for at most one or two hero surfaces with extra time budget. lilaq has no 3D (confirmed open feature request); we design around that, not against it.

---

## 8. Coverage Matrix (17 sections, with difficulty tiers)

Counts are exact, from `data/atlas_full.json` (208 types). **Tiers:** TRIVIAL (one primitive) · EASY (a few labeled boxes/arrows) · MEDIUM (custom glyphs, careful routing, gating math) · HARD (heavy bespoke geometry) · RASTER (core content is a learned/photographic image — embed via `image()`) · INTEROP (no Typst-native primitive — wrap a dedicated package or LaTeX).

| § | Section (n) | Primary capability / package | Tier range | Layout regime |
|---|---|---|---|---|
| A | Foundational & Historical (15) | fletcher node–edge; cetz `tree` (decision tree/forest); cetz line+region (SVM margin); cetz (RBM/DBN/Hopfield) | EASY→MEDIUM | DAG, tree, plot, freeform |
| B | Core building blocks (7) | fletcher blocks + skip arrows; cetz (dropout cross-out); lilaq (activation curves) | TRIVIAL→EASY | sequential, plot |
| C | Conv & vision (24) | **neural-netz** / cetz cuboid (feature-map stacks); fletcher (detector pipelines); cetz grid (conv arithmetic) | EASY→HARD (R-CNN/Mask/FPN/capsule HARD) | sequential, DAG, grid |
| D | Sequence models / RNN era (11) | fletcher (unrolled chains, seq2seq); **cetz cellgate** (LSTM/GRU internals); lattice grid (CTC/RNN-T) | MEDIUM→HARD | sequential, grid/lattice |
| E | Transformers & LLMs (26) | fletcher stacks + head fan-out; lilaq heatmaps; cetz (RoPE glyphs); trees (ToT) | EASY→HARD (MHA/MoE/MLA/sparse-attn HARD) | sequential, DAG, tree, grid |
| F | Generative models (17) | fletcher (G/D, enc–dec); cetz chains (diffusion); lilaq (flow/OT fields) | MEDIUM→HARD (flows/score-SDE/ControlNet HARD); samples RASTER | chain, DAG, plot |
| G | Graph & geometric (6) | autograph/fletcher (message passing, GCN/GAT); cetz (point cloud, Poincaré disk) | EASY→MEDIUM | DAG/graph, freeform |
| H | Reinforcement learning (9) | fletcher (agent–env loop, actor–critic, MDP graph); cetz `tree` (MCTS/PRM) | EASY→MEDIUM | DAG, tree |
| I | Probabilistic & graphical (12) | fletcher DAG (Bayes net, CRF); cetz plates; trellis grid (HMM); lilaq (GP, info-bottleneck) | EASY→HARD (factor graph/plate-LDA/stick-breaking HARD) | DAG, grid/trellis, plot |
| J | Audio & speech (8) | **lilaq.colormesh** (spectrogram); cetz (dilated-conv fans); fletcher (TTS/codec pipelines) | MEDIUM→HARD (WaveNet/HiFi-GAN HARD); spectrogram RASTER-leaning | sequential, plot |
| K | Video, 3D & multimodal (11) | fletcher (dual-pathway); **NeRF/3DGS/SAM/instant-NGP are learned renders** | EASY→RASTER | sequential, DAG, raster |
| L | Self-supervised & repr. (8) | fletcher (twin/Siamese, stop-grad/EMA arrows); cetz (sparse-coding bases) | MEDIUM; sparse-coding RASTER-leaning | DAG (two-branch) |
| M | Training, optim & systems (16) | fletcher (parallelism, KD); lilaq (scaling laws, roofline); cetz grid (systolic/crossbar/MZI) | EASY→HARD (ZeRO/Megatron/systolic/MZI HARD) | DAG, grid, plot |
| N | Interpretability & viz (13) | **saliency/Grad-CAM/feature-viz are learned images**; lilaq scatter (t-SNE/UMAP); lilaq/plotsy-3d (loss landscape); fletcher (MI circuit) | RASTER + plot + DAG | raster, plot, DAG |
| O | Evaluation & analysis plots (5) | **lilaq** (ROC/PR, calibration, learning curves); lilaq grid (confusion matrix) | TRIVIAL→EASY | plot, grid |
| P | Tangential fields (17) | fletcher (signal-flow/control/Kalman); **quill** (VQC); cetz (spiking, Hodgkin–Huxley, NCA); **INTEROP** (tensor-network, string diagram) | EASY→HARD + INTEROP | DAG, plot, freeform |
| Q | Training dynamics & loss-geometry (3) | **lilaq** line plots (double-descent, grokking) + annotated path (mode connectivity) | EASY→MEDIUM | plot |

**Net assessment:** ~70% (A, B, most C/D/E/F/G/H, O, Q) is buildable natively with **fletcher + cetz + lilaq**. ~15% is HARD bespoke cetz geometry (see §9). ~10% is RASTER (embed pre-rendered images). ~5% is INTEROP (quill for quantum; LaTeX/bespoke cetz for tensor-network & string diagrams).

---

## 9. Hard Problems & Mitigations

### The ~15 hardest individual types (and why)
1. **LSTM / GRU cell internals** (D) — dense bespoke geometry: σ/tanh gate blocks, ⊙/⊕ operators, gated highways through one cell boundary. → `gate`/`cellgate` cetz helper; tight alignment.
2. **Neural Turing Machine** (D) — controller + external memory matrix + differentiable read/write heads with addressing weights. → `memory` primitive + weighted-arrow attention.
3. **CTC / RNN-T alignment lattice** (D) — full trellis with blank/emit transitions over a time×label grid; combinatorial edge routing. → `grid` regime + lane allocator.
4. **Capsule network / dynamic routing** (C) — vector capsules + routing-by-agreement bipartite mesh. → bespoke cetz.
5. **Faster / Mask R-CNN** (C) — backbone→RPN(anchors)→RoIAlign→parallel heads; raster backbone. → fletcher pipeline + RASTER backbone.
6. **Feature Pyramid Network** (C) — multi-scale prism stack with lateral + top-down merges. → neural-netz prisms + precise vertical alignment.
7. **Mixture-of-Experts routing** (E) — router fan-out to N experts with top-k highlighted paths. → `branch`/`merge` + gutter lanes.
8. **Scaled dot-product + multi-head attention** (E) — nested Q·Kᵀ/√d→softmax→·V *and* h-head concat; the most-scrutinized figure. → `attention` primitive (two nested diagrams).
9. **Normalizing flow / score-SDE / flow matching** (F) — invertible couplings + Jacobian annotations or continuous vector field. → lilaq quiver + bespoke geometry.
10. **ControlNet (zero-convolutions)** (F) — locked + trainable encoder copies, cross-injection into frozen UNet. → two parallel deep stacks.
11. **Factor graph / CRF / plate-LDA** (I) — bipartite variable–factor incidence + nested subscript-indexed plates; correctness-critical. → `neuron-graph` (bipartite) + `plate`.
12. **Stick-breaking / CRP** (I) — proportional broken-stick + seating metaphor. → bespoke proportional cetz geometry.
13. **WaveNet dilated causal convolutions** (J) — exponentially dilated skip fan (binary-tree receptive field). → many precisely spaced curved cetz edges.
14. **Systolic array / Megatron-TP / ZeRO sharding** (M) — 2-D PE grid with synchronized flow, or sharded/colored matrices with collective-comm arrows. → `grid` + heavy bookkeeping.
15. **Photonic Mach-Zehnder mesh** (M/P) — tessellated MZI cells (phase shifters + beam-splitters); no package. → fully bespoke cetz.

*(Runner-ups: AlphaFold Evoformer, mechanistic-interp circuit, Mamba/S4 SSM scan, Spatial Transformer, shifted-window ViT.)*

### Cross-cutting hard problems & mitigations
| Problem | Mitigation |
|---|---|
| **Two-backend coordinate seam** (cetz body inside fletcher node) | Rule: fletcher always owns top-level layout; cetz/neural-netz/lilaq paint *only inside a reserved fletcher node box*. cetz never positions a top-level element. |
| **fletcher API churn** (pre-1.0, 0.5.x, mutating enclose anchors) | The L0 adapter is the firewall: pin exact versions in `typst.toml`, wrap every fletcher call so a breaking release touches one file. Vendor critical packages. |
| **Skip-edge routing collisions** (dense/U-Net/Transformer-XL spaghetti) | Real lane-assignment allocator (interval-graph coloring of overlapping skip spans) + per-primitive `lane:`/`coords:` override. Highest build-budget risk; prototype early. |
| **No graph auto-layout in fletcher; autograph can't do labeled edges** | Hand-author elastic-grid ranks (clean at ≤40 nodes); `diagraph` (Graphviz→SVG, labels OK) as fallback for a single large unlabeled graph. Never build Sugiyama. |
| **True-3D weakness** (lilaq no 3D, plotsy-3d immature) | Loss surfaces default to 2-D contour/heatmap (more readable anyway); ≤2 hero surfaces via plotsy-3d with extra budget. |
| **Performance >100 nodes** (no published benchmarks; cetz re-measures content) | Cap any figure at ~40 nodes; split mega-architectures into stacked sub-blocks; compile each diagram as a **standalone `.typ`** so the master never re-renders everything. |
| **Raster content can't be computed in Typst** | Grad-CAM/saliency/spectrogram/NeRF/3DGS/masks are *supplied* images: `image()` inside cetz `content()` + garnet annotation overlay (mind cetz Y-up vs Typst Y-down). |
| **Auto-layout vs canonical-layout mismatch** (HMM trellis, CTC lattice, MRF grid) | Auto-layout is a default, never a cage: `grid()`/`coords:` escape hatch on every primitive. |
| **Dict-merge ID collisions on composition** (nested presets share `mlp`) | Auto-suffix child IDs into a namespace path (`enc/block3/attn`) during IR concatenation. |
| **Brand leakage** (packages default to rounded/pastel) | Every wrapper forces `corner-radius:0pt` + garnet palette + `style-of(role)`; golden-image snapshot per section catches drift. |

---

## 10. Build-vs-Wrap Dependency Table

The load-bearing decision: **wrap aggressively, build only the genuine long tail.** Net: **WRAP ≈ 150 types · EXTEND ≈ 40 · BUILD ≈ 18.**

| Capability (sections) | Strategy | Package(s) — pinned | Notes |
|---|---|---|---|
| Node–edge graphs, pipelines, enc/dec, MoE, RAG, RLHF, agent loops, distillation, parallelism (A, E, H, M, most B/L) | **WRAP** | **fletcher 0.5.9** | Elastic (u,v) grid = layout; `corner:` right-angle edges; `enclose` for groups/plates; custom shapes/marks. The workhorse. |
| Cell-gate internals (LSTM/GRU), residual/SE/inception, U-Net, attention math, custom geometry (B/C/D internals) | **WRAP→EXTEND** | **cetz 0.5.2** | Painted inside fletcher nodes via custom shape body. Build small `cellgate`/`attention`/`cuboid` helpers. |
| 3-D conv/feature-map prisms (LeNet, AlexNet, VGG, ViT patches, ConvNeXt) (A, C, E) | **WRAP** | **neural-netz 0.3.0** | PlotNeuralNet-style 3-D blocks. Re-theme palette to garnet. |
| Scientific plots: ROC/PR, calibration, learning/scaling curves, double-descent, grokking, confusion, attention heatmap, t-SNE/UMAP, spectrogram colormesh (O, Q, E, I, J, N) | **WRAP** | **lilaq 0.5.0** (primary) | Matplotlib-like, native, clean axes, perceptual colormaps. `cetz-plot 0.1.3` only for bar/pie. |
| True-3-D surfaces: loss landscape, EBM landscape, IB plane (N, F, I) | **WRAP (guarded)** | **plotsy-3d** + lilaq contour | plotsy-3d immature; default to 2-D contour, ≤2 hero surfaces. |
| Variational quantum circuit / quantum classifier (P) | **WRAP** | **quill 0.7.2** | Tequila instruction model; auto-packing. One type, fully solved. |
| Large auto-laid DAGs/trees: big Bayes net, MDP graph, NAS, MCTS/ToT (G, H, I, N) | **WRAP (fallback only)** | **autograph 0.1.0** → diagraph-layout (Graphviz-WASM); **diagraph** for labeled | autograph 0.1.0 = NO edge labels → use `diagraph` when labels needed. cetz `tree` for clean trees. |
| Plate notation, signal-flow, control/Kalman block diagrams (I, P) | **WRAP** | **fletcher** | Plates = `enclose`; block diagrams native. |
| Tensor-network (Penrose), category-theory string/commutative diagrams (P) | **EXTEND / INTEROP** | bespoke **cetz** (no Typst pkg exists) or wrap LaTeX `tikz-cd`/DisCoPy | Verified: no dedicated Typst package. Thin `tensor-leg`/`string-diagram` archetype. |
| Penrose/hyperbolic disk, 3D-Gaussian-splat, NeRF ray render, persistence barcode, memristor crossbar, systolic/TPU dataflow, photonic mesh (G, K, M, P) | **BUILD** | **cetz** primitives | The genuine long tail (~15–18 types). No reuse possible; thin bespoke cetz. |
| Learned/photographic content: Grad-CAM, saliency, feature-viz, NeRF/3DGS/SAM/instant-NGP renders, generator samples, spectrograms (N, K, F, J) | **EMBED** | Typst native `image()` + cetz overlay | Supplied as files; library draws annotation skeleton only. |

---

## 11. Phased Roadmap (MVP → Stretch)

Sequenced to retire risk early (skip-routing and the IR contract first) and to maximize buildable coverage per phase. Each diagram compiles to a standalone `.typ` → `.pdf`.

**Phase 0 — Foundation & contract (de-risk the IR + layout).**
- Freeze the L3 IR schema (`node`, `edge`, `group`, `layout`, `meta`) and the `role`/`kind` enums.
- `brand.typ` (garnet theme, `style-of`, `corner-radius:0pt`) + `render()` dispatcher (`IR.kind` → emitter).
- fletcher L0 emitter for `block`/`stack`/`chain` + elastic-grid layout.
- **Prototype the skip-edge lane allocator** (highest-risk piece) on a residual + a U-Net skip.
- Pin all package versions in `typst.toml`; thin compat shim per wrapped package.
- Golden-image harness (local, manual): render → PNG → diff. *(No CI.)*
- **Exit:** ResNet block + 6-block transformer encoder render clean, deterministically.

**Phase 1 — MVP, the ~70% native core.**
- Remaining graph primitives: `branch/merge`, `plate`, `attention`, `neuron-graph`, `loop`.
- Sub-builder mixins (`encoder-stack`, `attention-block`, `residual-wrap`).
- Presets: `transformer`, `resnet-stage`, `unet`, `gan`, `vae`, `diffusion-chain`, `moe`, `rnn-unroll`, `agent-loop`.
- lilaq plot adapter: `roc-curve`, `confusion-matrix`, `calibration`, `learning-curve` + colormesh heatmaps.
- **Coverage target:** sections A, B, O, Q complete; most of E, F, G, H, M; ~70% of atlas.

**Phase 2 — Bespoke geometry + wrapped pictorials (the ~15% HARD + prisms).**
- cetz helpers: `slab`/cuboid, `gate`/`cellgate` (LSTM/GRU), `matrix`/trellis (CTC, HMM), `memory` (NTM).
- Wrap **neural-netz** for C feature-map prism stacks (LeNet→ViT), re-themed garnet.
- Hard list: capsule routing, FPN, R-CNN family, WaveNet dilation, systolic/Megatron/ZeRO grids.
- **Coverage target:** sections C, D, J, I complete; ~85% cumulative.

**Phase 3 — Raster, interop, exotic leaves (the ~15% RASTER + INTEROP).**
- `raster` leaf: `image()` + annotation overlay template (Grad-CAM, saliency, spectrogram, NeRF/3DGS, masks).
- Wrap **quill** for the VQC type.
- Exotic leaves: `surface` (plotsy-3d / contour), `scatter`, `ray-field`, `tensor-leg`/`string-diagram` (bespoke cetz).
- `diagraph` escape hatch for any single large unlabeled DAG.
- **Coverage target:** sections K, L, N, P complete; **all 208 types renderable.**

**Stretch (post-1.0, deferred by design).**
- LaTeX/TikZ L0 emitter behind the existing IR seam (re-derives metric layout; ~30 exempt types remain backend-native).
- Optional shape/semantics inference (tensor-shape propagation in labels, e.g. `(L,d)→(L,4d)`) — **opt-in only**, never inferred unless input dims are supplied, to avoid figures that silently lie.
- Hero true-3D surfaces (≤2) via plotsy-3d.
- Photonic-mesh and Penrose-disk polish.

---

## Appendix — Sources

fletcher (https://typst.app/universe/package/fletcher/) · fletcher ML-architecture gallery (github.com/Jollywatt/typst-fletcher) · cetz (https://typst.app/universe/package/cetz/) · cetz CHANGES (github.com/cetz-package/cetz) · cetz-plot (https://typst.app/universe/package/cetz-plot/) · lilaq (https://lilaq.org/) + 3D feature request (github.com/lilaq-project/lilaq/issues/31) · quill (https://typst.app/universe/package/quill/) · neural-netz (https://typst.app/universe/package/neural-netz/) · autograph (https://typst.app/universe/package/autograph/) · diagraph-layout (https://typst.app/universe/package/diagraph-layout/) · diagraph (github.com/Robotechnic/diagraph) · plotsy-3d (https://typst.app/universe/package/plotsy-3d/) · TikZ layered layouts (https://tikz.dev/gd-layered).
