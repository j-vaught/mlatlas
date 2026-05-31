// Bayesian network / directed graphical model (DAG).
//   Random variables = nodes; directed edges encode conditional dependence.
//   Open circle = latent (unobserved) variable; shaded circle = observed variable.
//   Stealth directed arrows give the generative / causal order. The product over
//   nodes of P(node | parents) is the joint factorization the DAG asserts.
// Built from the standard PGM convention (Bishop PRML, Koller & Friedman, Murphy,
// Barber) in mlatlas's print-first house style. Original layout — not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet   = rgb("#73000A")
#let ink      = rgb("#1A1A1A")
#let muted    = rgb("#5C5C5C")
#let edgecol  = rgb("#363636")
#let shaded   = rgb("#C7C7C7")   // observed fill (30% black)
#let latfill  = white            // latent fill

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let r = 0.55

  // ── fixed node positions: id -> (x, y) so edges can be drawn id -> id ────
  let pos = (
    B: (0,    3.0),    // burglary   (latent root)
    E: (3.6,  3.0),    // earthquake (latent root)
    A: (1.8,  1.2),    // alarm      (focal latent)
    J: (0,   -0.8),    // John calls (observed)
    M: (3.6, -0.8),    // Mary calls (observed)
  )

  // node(id, label): draw circle + math label at its fixed position.
  //   observed -> shaded fill ; focal -> garnet ring (the queried variable).
  let node(id, lbl, observed: false, focal: false) = {
    let p = pos.at(id)
    let fill = if observed { shaded } else { latfill }
    let stroke = if focal { 1.7pt + garnet } else { 1.2pt + edgecol }
    circle(p, radius: r, fill: fill, stroke: stroke)
    content(p, text(size: 11pt, fill: ink)[#lbl])
  }

  // directed edge id_a -> id_b, trimmed to the circle rims along their line.
  let arr(a, b, accent: false) = {
    let pa = pos.at(a)
    let pb = pos.at(b)
    let dx = pb.at(0) - pa.at(0)
    let dy = pb.at(1) - pa.at(1)
    let len = calc.sqrt(dx * dx + dy * dy)
    let ux = dx / len
    let uy = dy / len
    let s = (pa.at(0) + ux * r, pa.at(1) + uy * r)
    let e = (pb.at(0) - ux * r, pb.at(1) - uy * r)
    let st = if accent { 1.5pt + garnet } else { 1.1pt + edgecol }
    line(s, e, stroke: st, mark: (end: "stealth", scale: 0.85))
  }

  // ── the DAG: a small "alarm / diagnosis" style network ──────────────────
  //   B,E latent root causes; A the alarm; J,M observed reports; the focal
  //   query node is A (did the alarm sound), highlighted in garnet.
  node("B", [$B$])                       // burglary   (latent root)
  node("E", [$E$])                       // earthquake (latent root)
  node("A", [$A$], focal: true)          // alarm      (focal latent)
  node("J", [$J$], observed: true)       // John calls (observed)
  node("M", [$M$], observed: true)       // Mary calls (observed)

  // directed edges (parents -> children)
  arr("B", "A")
  arr("E", "A")
  arr("A", "J", accent: true)
  arr("A", "M", accent: true)

  // ── small CPD captions beside the roots / focal node ────────────────────
  content((-1.35, 3.0), anchor: "east", text(size: 8pt, fill: muted)[$P(B)$])
  content((4.95,  3.0), anchor: "west", text(size: 8pt, fill: muted)[$P(E)$])
  content((1.8 + r + 0.18,  1.2 - 0.02), anchor: "west", text(size: 7.5pt, fill: garnet)[$P(A | B, E)$])
  content((0,   -0.8 - r - 0.34), text(size: 7.5pt, fill: muted)[$P(J | A)$])
  content((3.6, -0.8 - r - 0.34), text(size: 7.5pt, fill: muted)[$P(M | A)$])

  // ── joint factorization implied by the DAG ──────────────────────────────
  let jx = 1.8
  let jy = -2.55
  content(
    (jx, jy),
    text(size: 9.5pt, fill: ink)[
      $P(B, E, A, J, M) = P(B) thin P(E) thin P(A | B, E) thin P(J | A) thin P(M | A)$
    ],
  )

  // ── legend (right side): open vs shaded vs focal ────────────────────────
  let lx = 6.7
  let ly = 2.7
  let leg(y, fill, stroke, label) = {
    circle((lx, y), radius: 0.30, fill: fill, stroke: stroke)
    content((lx + 0.55, y), anchor: "west", text(size: 8pt, fill: ink)[#label])
  }
  // legend frame (sharp corners)
  rect((lx - 0.6, ly - 2.05), (lx + 3.25, ly + 0.55), stroke: 0.8pt + rgb("#A2A2A2"))
  leg(ly,         latfill, 1.2pt + edgecol, [latent (unobserved)])
  leg(ly - 0.85,  shaded,  1.2pt + edgecol, [observed (evidence)])
  leg(ly - 1.70,  latfill, 1.7pt + garnet,  [query variable])

  // title
  content(
    (1.8, 4.25),
    text(size: 10pt, weight: "bold", fill: ink)[Bayesian network (directed acyclic graph)],
  )
})
