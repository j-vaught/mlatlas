// mlatlas · Image pyramid (Gaussian / Laplacian) — the multiscale representation.
//   A Gaussian pyramid G₀…G₃ is a stack of progressively HALF-resolution images:
//   each level is the previous one BLURRED (low-pass) and DOWNSAMPLED by 2, so the
//   spatial side shrinks 256 → 128 → 64 → 32 (area quarters every step). The
//   Laplacian pyramid is the BAND-PASS residual between adjacent scales,
//        Lₖ = Gₖ − upsample(G_{k+1}),
//   capturing the detail lost when going coarser; the chain is invertible —
//   reconstruct via  Gₖ = Lₖ + upsample(G_{k+1}), with the coarsest Gaussian G₃
//   kept as the residual base. Standard Szeliski / Foundations-of-Computer-Vision
//   teaching figure, built from scratch in mlatlas's print-first style. The little
//   level images are procedurally shaded (a deterministic radial+ripple field at
//   each resolution); no bitmap was traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ─────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // sparse focal accent — the downsample / blur arrows
#let blue   = rgb("#466A9F")   // Laplacian band-pass column
#let ink     = rgb("#222222")
#let muted   = rgb("#5C5C5C")
#let edgec   = rgb("#363636")
#let grid-c  = rgb("#C7C7C7")
#let beige   = rgb("#FFF2E3")

// ── the level pixel field ─────────────────────────────────────────────────────
// A deterministic scalar field on [0,1]² → [0,1]; sampled at n×n to fake a real
// image (a soft radial blob plus a low ripple). Coarser levels are SMOOTHER
// because they sample the SAME continuous field at fewer points (= blurred).
#let field(u, v) = {
  let dx = u - 0.42
  let dy = v - 0.52
  let r  = calc.sqrt(dx * dx + dy * dy)
  let blob = calc.exp(-(r * r) / 0.10)
  let rip  = 0.5 + 0.5 * calc.cos((u + 0.7 * v) * 7.5)
  calc.max(0.0, calc.min(1.0, 0.30 + 0.62 * blob + 0.18 * rip - 0.10))
}
// Gaussian-level ramp: light beige (t=0) → garnet (t=1).
#let gramp(t) = beige.mix((garnet, calc.max(0.0, calc.min(1.0, t)) * 100%), space: oklab)
// Laplacian (signed band-pass) ramp: blue (−) → white (0) → garnet (+).
#let lramp(s) = {
  let s = calc.max(-1.0, calc.min(1.0, s))
  if s >= 0 { white.mix((garnet, s * 100%), space: oklab) }
  else { white.mix((blue, (-s) * 100%), space: oklab) }
}

// Draw an n×n image patch of side `side` (cm) with lower-left at `pos`, using a
// cell-shading function `shade(t)` over the field value t∈[0,1]. If `signed`, the
// patch shows the band-pass residual Gₖ − upsample(G_{k+1}) instead of Gₖ.
#let patch(pos, side, n, shade, signed: false, n-coarse: 0) = {
  import cetz.draw: *
  let (x0, y0) = pos
  let c = side / n
  for i in range(n) {
    for j in range(n) {
      let u = (i + 0.5) / n
      let v = (j + 0.5) / n
      let t = field(u, v)
      let val = if signed {
        // residual against the next-coarser sampling (nearest-neighbour upsample)
        let ci = calc.min(n-coarse - 1, calc.floor(u * n-coarse))
        let cj = calc.min(n-coarse - 1, calc.floor(v * n-coarse))
        let uc = (ci + 0.5) / n-coarse
        let vc = (cj + 0.5) / n-coarse
        (t - field(uc, vc)) * 3.4
      } else { t }
      rect(
        (x0 + i * c, y0 + j * c), (x0 + (i + 1) * c, y0 + (j + 1) * c),
        fill: shade(val), stroke: none,
      )
    }
  }
  // crisp frame around the patch
  rect((x0, y0), (x0 + side, y0 + side), fill: none, stroke: 0.9pt + edgec)
}

// ── level geometry ────────────────────────────────────────────────────────────
// Four levels; `res` = pixel side, `side` = drawn size (cm). The drawn size
// halves each step → the classic pyramid frustum.
#let levels = (
  (res: 256, side: 3.20, grid: 16),
  (res: 128, side: 2.20, grid: 12),
  (res:  64, side: 1.45, grid:  8),
  (res:  32, side: 0.95, grid:  6),
)
#let GX = 0.0          // left edge of the Gaussian column
#let LX = 7.6          // left edge of the Laplacian column
#let top = 11.0        // y of the top (finest, G₀) row's TOP edge
#let vgap = 0.95       // vertical gap between consecutive level patches

// Precompute each level's bottom-left y and its centre, top-down.
#let rows = {
  let ys = ()
  let cy = top
  for L in levels {
    let y0 = cy - L.side          // bottom of this patch
    ys.push((y0: y0, cx: GX + L.side / 2, cyc: y0 + L.side / 2, side: L.side))
    cy = y0 - vgap                // next patch top
  }
  ys
}

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── column headers ───────────────────────────────────────────────────────────
  content((GX + 1.6, top + 0.95), text(weight: "bold", size: 11pt)[Gaussian pyramid])
  content((GX + 1.6, top + 0.55), text(fill: muted, size: 8.5pt)[low-pass · blur + downsample ↓2])
  content((LX + 1.6, top + 0.95), text(weight: "bold", size: 11pt, fill: blue)[Laplacian pyramid])
  content((LX + 1.6, top + 0.55), text(fill: muted, size: 8.5pt)[band-pass · $L_k = G_k - "up"(G_(k+1))$])

  // ── Gaussian column: the four nested image patches ──────────────────────────
  for (k, L) in levels.enumerate() {
    let r = rows.at(k)
    patch((GX, r.y0), L.side, L.grid, gramp)
    // level label + resolution to the right of the patch
    content(
      (GX + L.side + 0.42, r.cyc + 0.16),
      text(weight: "bold")[$G_#k$],
      anchor: "west",
    )
    content(
      (GX + L.side + 0.42, r.cyc - 0.22),
      text(fill: muted, size: 8pt)[#L.res#sym.times#L.res],
      anchor: "west",
    )
  }

  // ── downsample arrows between adjacent Gaussian levels ──────────────────────
  for k in range(levels.len() - 1) {
    let a = rows.at(k)
    let b = rows.at(k + 1)
    let xa = a.cx
    line(
      (xa, a.y0 - 0.06), (xa, b.y0 + b.side + 0.06),
      stroke: 1.5pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.9),
    )
    // op tag on the arrow
    content(
      (xa - 0.18, (a.y0 + b.y0 + b.side) / 2),
      box(fill: white, inset: (x: 2pt, y: 1pt))[#text(fill: garnet, size: 7.5pt)[blur, ↓2]],
      anchor: "east",
    )
  }

  // ── Laplacian column: band-pass residual patches, aligned to G₀…G₂ ─────────
  // Lₖ = Gₖ − up(G_{k+1}); the coarsest level L₃ ≡ G₃ is the kept residual base.
  for k in range(levels.len()) {
    let r = rows.at(k)
    let L = levels.at(k)
    let x0 = LX
    if k < levels.len() - 1 {
      patch((x0, r.y0), L.side, L.grid, lramp, signed: true, n-coarse: levels.at(k + 1).grid)
      content(
        (x0 + L.side + 0.42, r.cyc + 0.16),
        text(weight: "bold", fill: blue)[$L_#k$],
        anchor: "west",
      )
      content(
        (x0 + L.side + 0.42, r.cyc - 0.22),
        text(fill: muted, size: 8pt)[detail],
        anchor: "west",
      )
    } else {
      // coarsest residual base = the coarsest Gaussian itself
      patch((x0, r.y0), L.side, L.grid, gramp)
      content(
        (x0 + L.side + 0.42, r.cyc + 0.16),
        text(weight: "bold", fill: blue)[$L_#k = G_#k$],
        anchor: "west",
      )
      content(
        (x0 + L.side + 0.42, r.cyc - 0.22),
        text(fill: muted, size: 8pt)[residual base],
        anchor: "west",
      )
    }
  }

  // ── subtraction connectors: G_k ─ up(G_{k+1}) → L_k ─────────────────────────
  // A small ⊖ op-node sits between the two columns at each fine level; arrows in
  // from Gₖ (plus) and the upsampled Gₖ₊₁ (minus), arrow out to Lₖ.
  for k in range(levels.len() - 1) {
    let r  = rows.at(k)
    let rb = rows.at(k + 1)
    let opx = (GX + levels.at(k).side + LX) / 2 + 0.15
    let opy = r.cyc
    // node
    circle((opx, opy), radius: 0.26, fill: white, stroke: 1.1pt + edgec)
    content((opx, opy), text(size: 11pt)[$-$])
    // Gₖ  → ⊖  (minuend)
    line(
      (GX + levels.at(k).side + 0.04, r.cyc), (opx - 0.27, opy),
      stroke: 1.0pt + edgec, mark: (end: "stealth", scale: 0.8),
    )
    // up(Gₖ₊₁) → ⊖  (subtrahend) — comes up from the coarser Gaussian
    line(
      (rb.cx + levels.at(k + 1).side / 2 + 0.04, rb.cyc),
      (opx - 0.18, opy - 0.24),
      stroke: 1.0pt + muted, mark: (end: "stealth", scale: 0.8),
    )
    content(
      (opx - 0.42, opy - 0.42),
      box(fill: white, inset: (x: 1.5pt, y: 0.5pt))[#text(fill: muted, size: 7pt)[$"up"(G_#{k + 1})$]],
      anchor: "north-east",
    )
    // ⊖ → Lₖ  (the band-pass residual)
    line(
      (opx + 0.27, opy), (LX - 0.04, r.cyc),
      stroke: 1.3pt + blue, mark: (end: "stealth", fill: blue, scale: 0.85),
    )
  }

  // ── reconstruction note (collapse arrow back up the Laplacian) ──────────────
  content(
    (LX + 1.6, rows.at(levels.len() - 1).y0 - 0.85),
    box(width: 5.4cm)[#text(size: 7.6pt, fill: muted)[
      Invertible: $G_k = L_k + "up"(G_(k+1))$ rebuilds every Gaussian
      level from the coarse base $G_3$ upward.
    ]],
    anchor: "north",
  )
})
