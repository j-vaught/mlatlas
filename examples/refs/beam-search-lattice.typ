// Beam search as a breadth-limited decoding lattice (beam width k = 2).
//
// Autoregressive decoding drawn as a layered tree/trellis: columns = decoding
// steps t, each surviving hypothesis is expanded by the vocabulary, candidates
// are scored by CUMULATIVE log-probability (parent score + token log-prob), and
// the frontier is PRUNED back to the k best. Surviving (kept) edges are solid and
// form the lattice; pruned branches are dashed grey and dropped. The single best
// complete hypothesis (ending in </s>) is highlighted in garnet.
//
// Original mlatlas figure of a standard NLP/decoding concept (D2L; Jurafsky &
// Martin SLP3; Eisenstein). Built from knowledge, not traced. The cumulative
// scores below are internally consistent: each child = parent + edge log-prob.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ───────────────────────────────────────────────────────────────
#let garnet  = rgb("#73000A")
#let ink     = rgb("#000000")
#let keepfil = white
#let keepstr = rgb("#363636")
#let bestfil = garnet.transparentize(88%)
#let pruncol = rgb("#A2A2A2")
#let prunfil = rgb("#ECECEC")
#let scoretx = rgb("#5C5C5C")
#let axiscol = rgb("#5C5C5C")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // layout constants
  let colsp = 3.4          // horizontal spacing between decoding steps
  let nw    = 1.06         // node half-width
  let nh    = 0.52         // node half-height

  // ── node data ─────────────────────────────────────────────────────────────
  // each node: (id) -> (x, y, token, score, kind)
  //   kind: "start" | "keep" | "best" | "prune"
  // y grows downward visually but we use math y (up = positive); rows from top.
  let X(c) = c * colsp
  let nodes = (
    // start
    "s":   (X(0),  0.0,  [`<s>`], none,    "start"),
    // step 1 frontier  (parent <s>)
    "A":   (X(1),  1.6,  [A],     [-0.4],  "keep"),
    "B":   (X(1),  0.0,  [B],     [-0.7],  "keep"),
    "C":   (X(1), -1.6,  [C],     [-1.6],  "prune"),
    // step 2 frontier  (expand A and B)
    "AB":  (X(2),  2.0,  [B],     [-0.9],  "keep"),
    "BA":  (X(2),  0.4,  [A],     [-1.3],  "keep"),
    "AA":  (X(2),  3.0,  [A],     [-1.6],  "prune"),
    "BC":  (X(2), -1.0,  [C],     [-1.6],  "prune"),
    "BB":  (X(2), -2.0,  [B],     [-2.2],  "prune"),
    // step 3 frontier  (expand AB and BA)
    "ABe": (X(3),  2.4,  [`</s>`],[-1.2],  "best"),
    "ABA": (X(3),  1.0,  [A],     [-1.7],  "keep"),
    "BAe": (X(3), -0.2,  [`</s>`],[-2.0],  "prune"),
    "BAB": (X(3), -1.4,  [B],     [-2.4],  "prune"),
  )

  // ── edges ────────────────────────────────────────────────────────────────
  // (from, to, edge-logprob, kept?)
  let edges = (
    ("s","A",   [-0.4], true),
    ("s","B",   [-0.7], true),
    ("s","C",   [-1.6], false),
    ("A","AB",  [-0.5], true),
    ("A","AA",  [-1.2], false),
    ("B","BA",  [-0.6], true),
    ("B","BC",  [-0.9], false),
    ("B","BB",  [-1.5], false),
    ("AB","ABe",[-0.3], true),
    ("AB","ABA",[-0.8], true),
    ("BA","BAe",[-0.7], true),
    ("BA","BAB",[-1.1], false),
  )

  // helper: right anchor of a node (exit point)
  let rx(id) = nodes.at(id).at(0) + nw
  let lx(id) = nodes.at(id).at(0) - nw
  let ny(id) = nodes.at(id).at(1)

  // ── draw edges first (under nodes) ─────────────────────────────────────────
  for e in edges {
    let (f, t, lp, kept) = e
    let p0 = (rx(f), ny(f))
    let p1 = (lx(t), ny(t))
    let mx = (p0.at(0) + p1.at(0)) / 2
    let best-edge = (f == "AB" and t == "ABe")
    let col = if best-edge { garnet } else if kept { keepstr } else { pruncol }
    let st  = if best-edge { 1.7pt + col }
              else if kept { 1.0pt + col }
              else { (paint: col, thickness: 0.8pt, dash: "dashed") }
    line(p0, p1, stroke: st, mark: (end: "stealth", scale: 0.7))
    // per-edge log-prob label, offset perpendicular to the edge so steep edges
    // do not collide with node borders.
    let dx = p1.at(0) - p0.at(0)
    let dy = p1.at(1) - p0.at(1)
    let len = calc.max(0.001, calc.sqrt(dx * dx + dy * dy))
    let off = 0.30
    let lxp = mx + (-dy / len) * off
    let lyp = (p0.at(1) + p1.at(1)) / 2 + (dx / len) * off
    content(
      (lxp, lyp),
      text(size: 7pt, fill: if kept { scoretx } else { pruncol })[#lp],
    )
  }

  // ── draw nodes ─────────────────────────────────────────────────────────────
  for (id, d) in nodes {
    let (x, y, tok, sc, kind) = d
    let fil = if kind == "prune" { prunfil }
              else if kind == "best" { bestfil }
              else { keepfil }
    let str = if kind == "prune" { (paint: pruncol, thickness: 0.7pt, dash: "dashed") }
              else if kind == "best" { 1.7pt + garnet }
              else if kind == "start" { 1.2pt + ink }
              else { 1.1pt + keepstr }
    rect((x - nw, y - nh), (x + nw, y + nh), fill: fil, stroke: str, radius: 0pt)
    // token (top line)
    let toktx = if kind == "prune" { pruncol }
                else if kind == "best" { garnet }
                else { ink }
    content((x, y + 0.14), text(size: 9pt, weight: "bold", fill: toktx)[#tok])
    // cumulative score (bottom line)
    if sc != none {
      content(
        (x, y - 0.18),
        text(size: 7pt, fill: if kind == "prune" { pruncol } else { scoretx })[Σ #sc],
      )
    }
  }

  // ── column (time-step) headers and pruning brackets ─────────────────────────
  let top-y = 3.95
  let hdrs = (
    (0, [start]),
    (1, [step $t=1$]),
    (2, [step $t=2$]),
    (3, [step $t=3$]),
  )
  for (c, lbl) in hdrs {
    content((X(c), top-y), text(size: 9pt, weight: "bold", fill: ink)[#lbl])
  }
  // light vertical guide lines per step column
  for c in (1, 2, 3) {
    line((X(c), -2.9), (X(c), top-y - 0.42),
      stroke: (paint: rgb("#ECECEC"), thickness: 0.8pt))
  }

  // "keep top-k" annotation under each expansion frontier
  let kk = -3.45
  content((X(1), kk), text(size: 8pt, fill: scoretx, style: "italic")[keep top-$k = 2$])
  content((X(2), kk), text(size: 8pt, fill: scoretx, style: "italic")[keep top-$k = 2$])
  content((X(3), kk), text(size: 8pt, fill: scoretx, style: "italic")[keep top-$k = 2$])

  // ── title ───────────────────────────────────────────────────────────────────
  content((X(1.5), top-y + 0.95),
    text(size: 11pt, weight: "bold", fill: ink)[Beam search decoding lattice ($k = 2$)])

  // ── score definition note ─────────────────────────────────────────────────
  content((X(1.5), top-y + 0.42),
    text(size: 8pt, fill: scoretx)[
      score $=$ $sum_t log p(y_t #h(0.1em) | #h(0.1em) y_(<t))$  (higher $=$ better) #h(0.6em)
      #box(baseline: 22%, width: 13pt, height: 1.6pt, fill: garnet)
      #text(fill: garnet)[ best complete hypothesis]
    ])

  // ── legend (bottom) ─────────────────────────────────────────────────────────
  let ly = -4.45
  let lx = X(0) - nw
  // kept node swatch
  rect((lx, ly - 0.22), (lx + 0.5, ly + 0.22), fill: keepfil, stroke: 1.1pt + keepstr)
  content((lx + 0.62, ly), anchor: "west", text(size: 8pt, fill: keepstr)[surviving hypothesis (in beam)])
  // pruned node swatch
  let lx2 = lx + 5.6
  rect((lx2, ly - 0.22), (lx2 + 0.5, ly + 0.22), fill: prunfil,
    stroke: (paint: pruncol, thickness: 0.7pt, dash: "dashed"))
  content((lx2 + 0.62, ly), anchor: "west", text(size: 8pt, fill: pruncol)[pruned (dropped from frontier)])
})
