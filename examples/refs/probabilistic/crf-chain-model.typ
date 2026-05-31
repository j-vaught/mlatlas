// Linear-chain conditional random field (CRF) — the MODEL graph, not the inference lattice.
//
// A CRF is an UNDIRECTED, DISCRIMINATIVE model of p(y | x). Here the label
// sequence y = (y_1..y_T) forms a chain: each label node y_t is tied to its
// neighbours by an undirected pairwise (transition) potential ψ_t(y_{t-1}, y_t),
// and each y_t is tied to the observation x_t by a unary (emission/feature)
// potential φ_t(y_t, x). The observations x_t are always conditioned on (given),
// so they are drawn as a SHADED row — the CRF never models p(x). Edges are
// undirected (no arrowheads): unlike an HMM there is no generative direction.
//
//   p(y | x) = (1/Z(x)) · ∏_t φ_t(y_t, x) · ∏_t ψ_t(y_{t-1}, y_t)
//   Z(x) = Σ_{y'} ∏_t φ_t(y'_t, x) · ∏_t ψ_t(y'_{t-1}, y'_t)   (partition fn)
//
// Built from the standard PGM convention (Bishop PRML; Murphy; Barber BRML;
// Sutton & McCallum CRF tutorial; Eisenstein) in mlatlas print-first style.
// Original layout — not traced. Kept distinct from trellis-viterbi (inference view).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette: print-first, garnet a sparse focal accent ----------------
#let garnet  = rgb("#73000A")
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let edgecol = rgb("#363636")   // undirected potential edges
#let yfill   = white            // label node (unobserved) fill
#let xfill   = rgb("#C7C7C7")   // observed fill (30% black)
#let facfill = rgb("#363636")   // pairwise-factor square (90% black)

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let T = 4                 // chain length (y_1 .. y_4)
  let dx = 2.6              // column spacing
  let ry = 0.50            // label-node radius
  let yY = 2.2             // y-row height
  let yX = -0.6            // x-row height
  let rx = 0.50            // observation node "radius" (square half-side)

  // column centres ----------------------------------------------------------
  let cx(t) = (t - 1) * dx           // t = 1..T -> x positions
  let yp(t) = (cx(t), yY)            // label-node centre at step t
  let xp(t) = (cx(t), yX)            // observation centre at step t

  // ---- undirected edges (drawn first, behind nodes) -----------------------
  // unary emission edges  y_t — x_t  (vertical)
  for t in range(1, T + 1) {
    let a = yp(t)
    let b = xp(t)
    line(
      (a.at(0), a.at(1) - ry),
      (b.at(0), b.at(1) + rx),
      stroke: 1.0pt + muted,
    )
  }

  // pairwise transition edges  y_t — y_{t+1}  (horizontal), with a small
  // square factor node sitting on the focal edge to name the potential ψ.
  let sf = 0.20   // factor square half-side
  for t in range(1, T) {
    let a = yp(t)
    let b = yp(t + 1)
    let focal = (t == 1)            // accent the first transition in garnet
    let st = if focal { 1.6pt + garnet } else { 1.2pt + edgecol }
    line(
      (a.at(0) + ry, a.at(1)),
      (b.at(0) - ry, b.at(1)),
      stroke: st,
    )
  }

  // ---- label nodes y_t (open circles, top row) ----------------------------
  for t in range(1, T + 1) {
    let p = yp(t)
    let focal = (t == 1 or t == 2)   // the two endpoints of the focal ψ edge
    let st = if focal { 1.6pt + garnet } else { 1.2pt + edgecol }
    circle(p, radius: ry, fill: yfill, stroke: st)
    content(p, text(size: 10pt, fill: ink)[$y_#t$])
  }

  // ---- observation nodes x_t (shaded squares, bottom row) -----------------
  // squares (vs circles) emphasise these are fixed inputs, always conditioned on.
  for t in range(1, T + 1) {
    let p = xp(t)
    rect(
      (p.at(0) - rx, p.at(1) - rx),
      (p.at(0) + rx, p.at(1) + rx),
      fill: xfill, stroke: 1.2pt + edgecol, radius: 0pt,
    )
    content(p, text(size: 10pt, fill: ink)[$x_#t$])
  }

  // ---- potential labels ----------------------------------------------------
  // focal pairwise potential ψ on the first transition edge (garnet)
  content(
    ((cx(1) + cx(2)) / 2, yY + 0.48),
    text(size: 8.5pt, fill: garnet, weight: "bold")[$psi_t (y_(t-1), y_t)$],
  )
  // the other transition edges labelled lightly
  content(
    ((cx(2) + cx(3)) / 2, yY + 0.40),
    text(size: 8pt, fill: muted)[$psi$],
  )
  content(
    ((cx(3) + cx(4)) / 2, yY + 0.40),
    text(size: 8pt, fill: muted)[$psi$],
  )
  // unary emission potential φ on one vertical edge
  content(
    (cx(2) + 0.18, (yY + yX) / 2),
    anchor: "west",
    text(size: 8pt, fill: muted)[$phi_t (y_t, x)$],
  )

  // ---- row braces / labels -------------------------------------------------
  content(
    (cx(1) - ry - 0.55, yY), anchor: "east",
    text(size: 8.5pt, fill: ink)[labels #linebreak() (latent $y$)],
  )
  content(
    (cx(1) - rx - 0.55, yX), anchor: "east",
    text(size: 8.5pt, fill: ink)[inputs #linebreak() (observed $x$)],
  )

  // ---- "..." continuation hint after the chain? keep finite & clean -------

  // ---- legend (bottom) -----------------------------------------------------
  let lx = cx(1) - 0.1
  let ly = yX - 1.7
  // label-node glyph
  circle((lx, ly), radius: 0.22, fill: yfill, stroke: 1.2pt + edgecol)
  content((lx + 0.40, ly), anchor: "west", text(size: 8pt, fill: muted)[label node $y_t$ (modelled)])
  // observation glyph
  rect((lx + 3.55, ly - 0.22), (lx + 3.99, ly + 0.22), fill: xfill, stroke: 1.2pt + edgecol, radius: 0pt)
  content((lx + 4.15, ly), anchor: "west", text(size: 8pt, fill: muted)[observation $x_t$ (conditioned on)])

  let ly2 = ly - 0.7
  // undirected edge glyph
  line((lx - 0.05, ly2), (lx + 0.45, ly2), stroke: 1.2pt + edgecol)
  content((lx + 0.60, ly2), anchor: "west", text(size: 8pt, fill: muted)[undirected potential (no arrowheads)])
  // garnet glyph
  line((lx + 5.05, ly2), (lx + 5.55, ly2), stroke: 1.6pt + garnet)
  content((lx + 5.70, ly2), anchor: "west", text(size: 8pt, fill: garnet)[focal pairwise term])

  // ---- title + conditional-distribution caption ---------------------------
  content(
    ((cx(1) + cx(T)) / 2, yY + 1.35),
    text(size: 12pt, weight: "bold", fill: ink)[Linear-chain conditional random field],
  )
  content(
    ((cx(1) + cx(T)) / 2, yY + 0.92),
    text(size: 8.5pt, fill: muted)[undirected, discriminative: models $p(y | x)$ — observations are given, not generated],
  )
  content(
    ((cx(1) + cx(T)) / 2, yX - 1.0),
    text(size: 9.5pt, fill: ink)[$p(y | x) = 1 / (Z(x)) product_t phi_t (y_t, x) product_t psi_t (y_(t-1), y_t)$],
  )
})
