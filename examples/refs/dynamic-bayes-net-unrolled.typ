// Dynamic Bayesian network (DBN) — the 2-time-slice template (2-TBN) UNROLLED in time.
//
// A DBN is a directed graphical model of a temporal process. It is specified
// COMPACTLY by a two-time-slice template: the structure within one slice
// (INTRA-slice arcs) plus the structure linking slice t to slice t+1
// (INTER-slice arcs). Unrolling the template across t = 1, 2, 3, … reproduces
// the full directed acyclic graph over the whole sequence.
//
// Here each slice carries MULTIPLE interacting hidden variables — a_t and b_t —
// instead of the single hidden state of an HMM. That is the generalisation an
// HMM does NOT have: within a slice a_t → b_t (an intra-slice arc), and the
// state factorises and evolves with separate inter-slice transitions
// a_t → a_{t+1}, b_t → b_{t+1}, plus a coupling arc a_t → b_{t+1}. Each slice
// emits an observation x_t (shaded = observed) from b_t.
//
//   joint  P(a_{1:T}, b_{1:T}, x_{1:T}) =
//       P(a_1) P(b_1 | a_1) P(x_1 | b_1) ·
//       ∏_{t≥2} P(a_t | a_{t-1}) P(b_t | b_{t-1}, a_{t-1}, a_t) P(x_t | b_t)
//
// The two-time-slice template (the boxed t-1 → t pair) is the repeating unit;
// everything to its right is just that unit copied. An HMM is the special case
// of a single hidden chain (one variable per slice) — a DBN keeps several.
//
// Built from the standard DBN convention (Murphy thesis & "Machine Learning";
// Koller & Friedman; Barber BRML) in mlatlas's print-first house style.
// Original layout — not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette: print-first, garnet a sparse focal accent ----------------
#let garnet  = rgb("#73000A")
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let edgecol = rgb("#363636")    // intra/inter directed arcs
#let shaded  = rgb("#C7C7C7")    // observed fill (30% black)
#let latfill = white             // latent fill
#let tmplcol = rgb("#A2A2A2")    // template-box outline

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let T  = 3                 // number of drawn slices (t = 1, 2, 3)
  let dx = 3.2               // column (slice) spacing
  let r  = 0.50              // node radius
  // row heights (per slice, top -> bottom): a, b, x
  let yA = 3.0
  let yB = 1.2
  let yX = -0.7

  // slice column centre (t = 1..T)
  let cx(t) = (t - 1) * dx

  // node centres by (row, slice)
  let aP(t) = (cx(t), yA)
  let bP(t) = (cx(t), yB)
  let xP(t) = (cx(t), yX)

  // ---- directed edge between two centres, trimmed to the rims ---------------
  let arr(pa, pb, accent: false, ra: r, rb: r) = {
    let ax = pa.at(0); let ay = pa.at(1)
    let bx = pb.at(0); let by = pb.at(1)
    let ddx = bx - ax; let ddy = by - ay
    let len = calc.sqrt(ddx * ddx + ddy * ddy)
    let ux = ddx / len; let uy = ddy / len
    let s = (ax + ux * ra, ay + uy * ra)
    let e = (bx - ux * rb, by - uy * rb)
    let st = if accent { 1.6pt + garnet } else { 1.1pt + edgecol }
    line(s, e, stroke: st, mark: (end: "stealth", scale: 0.85))
  }

  // ---- 2-time-slice TEMPLATE box around slices 1 and 2 ----------------------
  // (drawn first, behind everything; sharp corners, dashed light grey)
  rect(
    (cx(1) - r - 0.55, yX - r - 0.45),
    (cx(2) + r + 0.55, yA + r + 0.55),
    stroke: (paint: tmplcol, thickness: 1.0pt, dash: "dashed"),
    radius: 0pt,
  )
  content(
    ((cx(1) + cx(2)) / 2, yA + r + 0.22),
    anchor: "south",
    text(size: 8pt, fill: muted, style: "italic")[2-time-slice template (2-TBN)],
  )

  // ============================ EDGES ========================================
  // Draw all arcs before nodes so rims sit on top cleanly.

  // INTRA-slice arc a_t -> b_t  (within every slice) — focal in slice 2 (garnet)
  for t in range(1, T + 1) {
    arr(aP(t), bP(t), accent: (t == 2))
  }
  // emission  b_t -> x_t  (within every slice)
  for t in range(1, T + 1) {
    arr(bP(t), xP(t))
  }

  // INTER-slice arcs, slice t -> t+1
  for t in range(1, T) {
    arr(aP(t), aP(t + 1))                 // a_{t} -> a_{t+1}
    arr(bP(t), bP(t + 1))                 // b_{t} -> b_{t+1}
    arr(aP(t), bP(t + 1), accent: (t == 1)) // coupling a_{t} -> b_{t+1} (focal)
  }

  // ============================ NODES ========================================
  // hidden a_t (top, open circles)
  for t in range(1, T + 1) {
    circle(aP(t), radius: r, fill: latfill, stroke: 1.2pt + edgecol)
    content(aP(t), text(size: 10pt, fill: ink)[$a_#t$])
  }
  // hidden b_t (middle, open circles)
  for t in range(1, T + 1) {
    let focal = (t == 2)
    let st = if focal { 1.6pt + garnet } else { 1.2pt + edgecol }
    circle(bP(t), radius: r, fill: latfill, stroke: st)
    content(bP(t), text(size: 10pt, fill: ink)[$b_#t$])
  }
  // observed x_t (bottom, shaded circles)
  for t in range(1, T + 1) {
    circle(xP(t), radius: r, fill: shaded, stroke: 1.2pt + edgecol)
    content(xP(t), text(size: 10pt, fill: ink)[$x_#t$])
  }

  // ---- "unroll" continuation to the right (…) -------------------------------
  // stub inter-slice arcs leaving slice T, then ellipsis dots.
  let stub = 0.95
  let stubarr(p) = {
    line(
      (p.at(0) + r, p.at(1)),
      (p.at(0) + stub, p.at(1)),
      stroke: 1.1pt + edgecol, mark: (end: "stealth", scale: 0.85),
    )
  }
  stubarr(aP(T))
  stubarr(bP(T))
  // coupling stub a_T -> (b_{T+1})
  line(
    (aP(T).at(0) + r * 0.7, aP(T).at(1) - r * 0.7),
    (aP(T).at(0) + stub, yB + 0.35),
    stroke: 1.1pt + edgecol, mark: (end: "stealth", scale: 0.85),
  )
  for (yy) in (yA, yB, yX) {
    content((cx(T) + stub + 0.55, yy), text(size: 12pt, fill: muted)[$dots.h$])
  }

  // ---- row labels (left) ----------------------------------------------------
  content(
    (cx(1) - r - 0.75, yA), anchor: "east",
    text(size: 8.5pt, fill: ink)[hidden $a_t$],
  )
  content(
    (cx(1) - r - 0.75, yB), anchor: "east",
    text(size: 8.5pt, fill: ink)[hidden $b_t$],
  )
  content(
    (cx(1) - r - 0.75, yX), anchor: "east",
    text(size: 8.5pt, fill: ink)[observed $x_t$],
  )

  // ---- slice (time) labels under each column --------------------------------
  for t in range(1, T + 1) {
    content(
      (cx(t), yX - r - 0.82),
      text(size: 8.5pt, fill: muted)[$t = #t$],
    )
  }

  // ---- arc-type annotations -------------------------------------------------
  // intra-slice (focal, slice 2)
  content(
    (cx(2) + 0.20, (yA + yB) / 2),
    anchor: "west",
    text(size: 7.5pt, fill: garnet)[intra-slice],
  )
  // inter-slice coupling (focal, slice 1->2)
  content(
    ((cx(1) + cx(2)) / 2 - 0.55, yB + 0.92),
    text(size: 7.5pt, fill: garnet)[inter-slice],
  )

  // ============================ LEGEND =======================================
  let lx = cx(1) - 0.05
  let ly = yX - 2.05
  // latent glyph
  circle((lx, ly), radius: 0.24, fill: latfill, stroke: 1.2pt + edgecol)
  content((lx + 0.42, ly), anchor: "west", text(size: 8pt, fill: muted)[hidden / latent variable])
  // observed glyph
  circle((lx + 4.05, ly), radius: 0.24, fill: shaded, stroke: 1.2pt + edgecol)
  content((lx + 4.47, ly), anchor: "west", text(size: 8pt, fill: muted)[observed variable])

  let ly2 = ly - 0.72
  // directed-edge glyph
  line((lx - 0.05, ly2), (lx + 0.48, ly2), stroke: 1.1pt + edgecol, mark: (end: "stealth", scale: 0.85))
  content((lx + 0.62, ly2), anchor: "west", text(size: 8pt, fill: muted)[directed conditional dependence])
  // garnet glyph
  line((lx + 4.05, ly2), (lx + 4.58, ly2), stroke: 1.6pt + garnet, mark: (end: "stealth", scale: 0.85))
  content((lx + 4.72, ly2), anchor: "west", text(size: 8pt, fill: garnet)[focal template arcs])

  // ---- title + caption ------------------------------------------------------
  let midx = (cx(1) + cx(T)) / 2 - 0.2
  content(
    (midx, yA + 2.0),
    text(size: 12pt, weight: "bold", fill: ink)[Dynamic Bayesian network — 2-TBN unrolled in time],
  )
  content(
    (midx, yA + 1.55),
    text(size: 8.5pt, fill: muted)[directed, generative: a repeating 2-slice template copied across $t$ — multiple hidden variables per slice generalise the HMM],
  )

  // joint factorisation implied by the unrolled DAG
  content(
    (midx, yX - 3.35),
    text(size: 9.5pt, fill: ink)[
      $P(a_(1:T), b_(1:T), x_(1:T)) = P(a_1) P(b_1 | a_1) P(x_1 | b_1) product_(t >= 2) P(a_t | a_(t-1)) thin P(b_t | b_(t-1), a_(t-1), a_t) thin P(x_t | b_t)$
    ],
  )
})
