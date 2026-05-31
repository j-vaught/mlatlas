// Deep Belief Network (DBN) vs Deep Boltzmann Machine (DBM) — stacked RBMs.
//
// Both models are built by STACKING restricted-Boltzmann-machine (RBM) layers:
// a visible layer v and successive hidden layers h^(1), h^(2), ..., with FULL
// bipartite connectivity between adjacent layers and NO intra-layer connections.
// The difference is the DIRECTIONALITY of the inter-layer connections:
//
//   DBN  — a HYBRID model. The top two layers (h^(2), h^(3)) form an UNDIRECTED
//          RBM; all lower connections are DIRECTED top-down generative weights
//          (W2^T, W1^T). It is a directed sigmoid belief net under an RBM prior.
//          Inference is fast/feed-forward (greedy layerwise pretraining target).
//
//   DBM  — a fully UNDIRECTED model: every adjacent pair (v,h^1,h^2,h^3) is an
//          undirected RBM coupling. Each unit's state depends on the layers BOTH
//          below and above it, so inference requires mean-field / variational
//          message passing (no single feed-forward pass).
//
// Built from the standard convention (Hinton 2006; Salakhutdinov & Hinton 2009;
// Goodfellow, Bengio & Courville, Deep Learning ch. 20) in mlatlas's print-first
// house style. Original layout — not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet  = rgb("#73000A")
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let dirc    = rgb("#363636")   // directed-edge colour (90% black)
#let undc    = rgb("#5C5C5C")   // undirected-edge colour (70% black)
#let vfill   = rgb("#C7C7C7")   // visible units (observed) — 30% black
#let hfill   = white            // hidden units (latent)
#let topfill = rgb("#ECECEC")   // top RBM pair tint (10% black)

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  // ── geometry shared by both panels ──────────────────────────────────────
  let r  = 0.24            // unit radius
  let n  = 4               // units per layer
  let dx = 0.92            // horizontal spacing between units
  let dy = 1.55            // vertical spacing between layers
  // layer y-positions: v at bottom, h3 at top
  let ly = (v: 0.0, h1: dy, h2: 2 * dy, h3: 3 * dy)
  // centred x-positions for n units
  let xs = range(n).map(i => (i - (n - 1) / 2) * dx)

  // unit centre for (panel origin ox, layer key, index i)
  let u(ox, lk, i) = (ox + xs.at(i), ly.at(lk))

  // full bipartite mesh between two adjacent layers ----------------------------
  // directed:true  -> top-down generative arrow (parent above -> child below)
  // directed:false -> undirected RBM coupling (plain line)
  // accent:true    -> garnet (the discriminating/top edges)
  let mesh(ox, top, bot, directed: false, accent: false) = {
    let col = if accent { garnet } else if directed { dirc } else { undc }
    let th  = if accent { 0.9pt } else { 0.6pt }
    for i in range(n) {
      for j in range(n) {
        let pt = u(ox, top, i)   // upper layer
        let pb = u(ox, bot, j)   // lower layer
        // trim to circle rims
        let ddx = pb.at(0) - pt.at(0)
        let ddy = pb.at(1) - pt.at(1)
        let L = calc.sqrt(ddx * ddx + ddy * ddy)
        let ux = ddx / L
        let uy = ddy / L
        let s = (pt.at(0) + ux * r, pt.at(1) + uy * r)
        let e = (pb.at(0) - ux * r, pb.at(1) - uy * r)
        if directed {
          line(s, e, stroke: (paint: col, thickness: th),
               mark: (end: "stealth", scale: 0.4, fill: col))
        } else {
          line(s, e, stroke: (paint: col, thickness: th))
        }
      }
    }
  }

  // draw one layer of n units -------------------------------------------------
  let layer(ox, lk, fill) = {
    for i in range(n) {
      circle(u(ox, lk, i), radius: r, fill: fill,
             stroke: (paint: ink, thickness: 0.9pt))
    }
  }

  // soft tint box behind the top undirected RBM pair --------------------------
  let toprbm-box(ox) = {
    let x0 = ox + xs.at(0) - r - 0.22
    let x1 = ox + xs.at(n - 1) + r + 0.22
    let y0 = ly.h2 - r - 0.20
    let y1 = ly.h3 + r + 0.20
    rect((x0, y0), (x1, y1), fill: topfill, stroke: (paint: garnet, thickness: 0.8pt))
  }

  // layer label at the left of a panel ----------------------------------------
  let llabel(ox, lk, lbl) = {
    content((ox + xs.at(0) - r - 0.5, ly.at(lk)), anchor: "east",
            text(size: 9pt, fill: ink)[#lbl])
  }
  // weight label between two layers, to the right of a panel ------------------
  let wlabel(ox, top, bot, lbl, col) = {
    let y = (ly.at(top) + ly.at(bot)) / 2
    content((ox + xs.at(n - 1) + r + 0.55, y), anchor: "west",
            text(size: 8pt, fill: col)[#lbl])
  }

  // ════════════════════════════════════════════════════════════════════════
  //  PANEL A — Deep Belief Network (hybrid: directed below, undirected top)
  // ════════════════════════════════════════════════════════════════════════
  let oxA = 0.0

  // top RBM tint first (behind everything in that band)
  toprbm-box(oxA)

  // edges (behind nodes)
  mesh(oxA, "h3", "h2", directed: false, accent: true)   // undirected top RBM
  mesh(oxA, "h2", "h1", directed: true)                  // directed W2^T
  mesh(oxA, "h1", "v",  directed: true)                  // directed W1^T

  // nodes
  layer(oxA, "h3", hfill)
  layer(oxA, "h2", hfill)
  layer(oxA, "h1", hfill)
  layer(oxA, "v",  vfill)

  // layer labels (left)
  llabel(oxA, "h3", [$h^((3))$])
  llabel(oxA, "h2", [$h^((2))$])
  llabel(oxA, "h1", [$h^((1))$])
  llabel(oxA, "v",  [$v$])

  // weight labels (right)
  wlabel(oxA, "h3", "h2", [$W_3$ (RBM)], garnet)
  wlabel(oxA, "h2", "h1", [$W_2^top$], dirc)
  wlabel(oxA, "h1", "v",  [$W_1^top$], dirc)

  // panel title
  content((oxA, ly.h3 + dy * 0.66), text(size: 10.5pt, weight: "bold", fill: ink)[DBN])
  content((oxA, ly.h3 + dy * 0.40), text(size: 8pt, fill: muted)[Deep Belief Network])

  // ════════════════════════════════════════════════════════════════════════
  //  PANEL B — Deep Boltzmann Machine (fully undirected)
  // ════════════════════════════════════════════════════════════════════════
  let oxB = 7.4

  // edges — all undirected RBM couplings
  mesh(oxB, "h3", "h2", directed: false)
  mesh(oxB, "h2", "h1", directed: false)
  mesh(oxB, "h1", "v",  directed: false)

  // nodes
  layer(oxB, "h3", hfill)
  layer(oxB, "h2", hfill)
  layer(oxB, "h1", hfill)
  layer(oxB, "v",  vfill)

  // layer labels (left)
  llabel(oxB, "h3", [$h^((3))$])
  llabel(oxB, "h2", [$h^((2))$])
  llabel(oxB, "h1", [$h^((1))$])
  llabel(oxB, "v",  [$v$])

  // weight labels (right) — all undirected
  wlabel(oxB, "h3", "h2", [$W_3$], undc)
  wlabel(oxB, "h2", "h1", [$W_2$], undc)
  wlabel(oxB, "h1", "v",  [$W_1$], undc)

  // panel title
  content((oxB, ly.h3 + dy * 0.66), text(size: 10.5pt, weight: "bold", fill: ink)[DBM])
  content((oxB, ly.h3 + dy * 0.40), text(size: 8pt, fill: muted)[Deep Boltzmann Machine])

  // ── shared title ────────────────────────────────────────────────────────
  content(((oxA + oxB) / 2, ly.h3 + dy * 1.18),
          text(size: 12pt, weight: "bold", fill: ink)[Stacked RBMs: DBN vs DBM])

  // ── legend (bottom, spanning both panels) ───────────────────────────────
  let lgx = oxA + xs.at(0) - r
  // row 1: node glyphs
  let lgy = ly.v - 1.40
  circle((lgx, lgy), radius: 0.20, fill: vfill, stroke: (paint: ink, thickness: 0.9pt))
  content((lgx + 0.34, lgy), anchor: "west", text(size: 8pt, fill: muted)[visible $v$ (observed)])
  circle((lgx + 4.4, lgy), radius: 0.20, fill: hfill, stroke: (paint: ink, thickness: 0.9pt))
  content((lgx + 4.74, lgy), anchor: "west", text(size: 8pt, fill: muted)[hidden $h^((l))$ (latent)])

  // row 2: edge glyphs — well spaced so labels never collide
  let lgy2 = lgy - 0.62
  // directed glyph
  line((lgx, lgy2), (lgx + 0.62, lgy2), stroke: (paint: dirc, thickness: 0.9pt),
       mark: (end: "stealth", scale: 0.5, fill: dirc))
  content((lgx + 0.80, lgy2), anchor: "west",
          text(size: 8pt, fill: muted)[directed generative $W^top$])
  // undirected glyph
  line((lgx + 4.4, lgy2), (lgx + 5.02, lgy2), stroke: (paint: undc, thickness: 0.9pt))
  content((lgx + 5.20, lgy2), anchor: "west",
          text(size: 8pt, fill: muted)[undirected RBM coupling])
  // top-RBM accent glyph
  line((lgx + 8.9, lgy2), (lgx + 9.52, lgy2), stroke: (paint: garnet, thickness: 0.9pt))
  content((lgx + 9.70, lgy2), anchor: "west",
          text(size: 8pt, fill: garnet)[DBN top RBM (undirected)])

  // ── one-line contrast caption ───────────────────────────────────────────
  content(((oxA + oxB) / 2, lgy2 - 0.66),
    text(size: 8.5pt, fill: ink)[
      DBN: directed top-down below + undirected top pair (feed-forward inference)
      #h(0.4em) $|$ #h(0.4em)
      DBM: all couplings undirected (mean-field inference)
    ])
})
