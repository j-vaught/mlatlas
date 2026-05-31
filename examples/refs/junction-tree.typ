// Junction tree (clique tree) — the data structure for EXACT inference in PGMs.
//
// Starting from a (chordal / triangulated) undirected graph, its maximal CLIQUES
// become the nodes of a tree. Each tree EDGE carries a SEPARATOR SET (sepset):
// the intersection of the two cliques it joins. A valid junction tree obeys the
// RUNNING-INTERSECTION PROPERTY: for any variable, the cliques containing it form
// a connected subtree (so a variable cannot "disappear then reappear").
//
// On this structure, the Hugin / Shafer–Shenoy message-passing scheme performs
// exact inference: a clique sends a message to a neighbour by marginalising out
// everything outside their shared sepset and dividing by the stored sepset
// potential. Two collect/distribute sweeps calibrate every clique to its marginal.
// One such clique -> sepset -> clique message is drawn in garnet as the focal cue.
//
// House style: light fills, dark text, sharp corners, stealth arrows, garnet a
// sparse accent. Cliques = rounded-but-orthogonal "pill" boxes (drawn as rects),
// sepsets = small rectangles mid-edge. Built from standard PGM convention
// (Barber BRML; Bishop PRML; Koller & Friedman). Original layout — not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet  = rgb("#73000A")
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let edgecol = rgb("#5C5C5C")
#let cliquefill = rgb("#ECECEC")   // 10% black — clique node fill
#let sepfill    = rgb("#FFF2E3")   // beige — sepset box fill
#let focalfill  = rgb("#FFF2E3")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── clique centres (id -> (x,y)) ────────────────────────────────────────
  // A small tree: a chain C1–C2–C3 with a branch C4 off C2.
  //   C1 {A,B,C}   C2 {B,C,D}   C3 {C,D,E}   C4 {D,F}
  let pos = (
    C1: (-4.6,  1.7),
    C2: (-1.0,  1.7),
    C3: ( 2.6,  1.7),
    C4: (-1.0, -1.6),
  )
  // variable list shown inside each clique
  let vars = (
    C1: $A,B,C$,
    C2: $B,C,D$,
    C3: $C,D,E$,
    C4: $D,F$,
  )

  // ── tree edges as (clique_a, clique_b, sepset-content) ──────────────────
  // sepset = intersection of the two adjacent cliques.
  let edges = (
    ("C1", "C2", $B,C$),
    ("C2", "C3", $C,D$),
    ("C2", "C4", $D$),
  )

  let hw = 0.92   // clique half-width
  let hh = 0.52   // clique half-height

  // ── undirected tree edges (behind everything) ───────────────────────────
  for e in edges {
    draw.line(pos.at(e.at(0)), pos.at(e.at(1)),
      stroke: (paint: edgecol, thickness: 1.0pt))
  }

  // ── focal message: C1 --(sepset B,C)--> C2, drawn in garnet ─────────────
  // mu_{C1 -> C2}(B,C) = sum over A of psi_{C1}(A,B,C) ; flows along the edge,
  // arcing above the sepset box so the directionality is unambiguous.
  {
    let a = pos.C1
    let b = pos.C2
    let y = a.at(1) + 0.95          // ride well above the tree edge / sepset
    let xs = a.at(0) + hw + 0.04
    let xe = b.at(0) - hw - 0.04
    draw.line(
      (xs, a.at(1) + hh + 0.02),
      (xs, y),
      stroke: (paint: garnet, thickness: 1.25pt),
    )
    draw.line(
      (xs, y), (xe, y),
      stroke: (paint: garnet, thickness: 1.25pt),
    )
    draw.line(
      (xe, y), (xe, b.at(1) + hh + 0.02),
      stroke: (paint: garnet, thickness: 1.25pt),
      mark: (end: "stealth", fill: garnet, scale: 0.8),
    )
    draw.content(
      ((xs + xe) / 2, y + 0.28),
      text(size: 7.5pt, fill: garnet, weight: "bold")[$mu_(C_1 -> C_2)(B,C)$],
    )
  }

  // ── separator-set boxes (small rects mid-edge) ──────────────────────────
  let sepset(a, b, lbl, focal: false) = {
    let pa = pos.at(a)
    let pb = pos.at(b)
    let m = ((pa.at(0) + pb.at(0)) / 2, (pa.at(1) + pb.at(1)) / 2)
    let sw = 0.62
    let sh = 0.40
    draw.rect(
      (m.at(0) - sw, m.at(1) - sh), (m.at(0) + sw, m.at(1) + sh),
      fill: sepfill,
      stroke: (paint: if focal { garnet } else { ink }, thickness: if focal { 1.4pt } else { 1.0pt }),
      radius: 0pt,
    )
    draw.content(m, text(size: 8.5pt, fill: ink)[#lbl])
  }
  sepset("C1", "C2", $B,C$, focal: true)
  sepset("C2", "C3", $C,D$)
  sepset("C2", "C4", $D$)

  // ── clique nodes (sharp orthogonal rectangles — print-first house style) ─
  // The spec's "rounded clusters" yields to the brand rule: sharp corners only.
  // C2 is the focal (sending) clique -> garnet outline.
  let clique(id, focal: false) = {
    let c = pos.at(id)
    let st = if focal { (paint: garnet, thickness: 1.5pt) } else { (paint: ink, thickness: 1.1pt) }
    draw.rect((c.at(0) - hw, c.at(1) - hh), (c.at(0) + hw, c.at(1) + hh),
      fill: cliquefill, stroke: st, radius: 0pt)
    // contents
    draw.content((c.at(0), c.at(1) + 0.17), text(size: 10pt, fill: ink)[#vars.at(id)])
    draw.content((c.at(0), c.at(1) - 0.25), text(size: 6.5pt, fill: muted)[clique #id.slice(1)])
  }
  clique("C1")
  clique("C2", focal: true)
  clique("C3")
  clique("C4")

  // ── title + subtitle ────────────────────────────────────────────────────
  draw.content((-1.0, 3.95),
    text(size: 12pt, weight: "bold", fill: ink)[Junction tree (clique tree)])
  draw.content((-1.0, 3.42),
    text(size: 8pt, fill: muted)[maximal cliques are tree nodes; each edge stores the sepset = clique intersection])

  // ── running-intersection callout (variable C lives on the C1–C2–C3 path) ─
  draw.content(
    (2.6, 0.55), anchor: "north",
    text(size: 7pt, fill: muted)[running intersection:\ $C in C_1,C_2,C_3$\ forms a connected path],
  )

  // ── legend (bottom-left) ────────────────────────────────────────────────
  let lx = -4.65
  let ly = -2.75
  // clique glyph (small stadium-ish rect)
  draw.rect((lx - 0.05, ly - 0.18), (lx + 0.55, ly + 0.18),
    fill: cliquefill, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content((lx + 0.78, ly), anchor: "west", text(size: 8pt, fill: muted)[clique (variable set)])
  // sepset glyph
  draw.rect((lx + 3.15, ly - 0.16), (lx + 3.6, ly + 0.16),
    fill: sepfill, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content((lx + 3.78, ly), anchor: "west", text(size: 8pt, fill: muted)[separator set])
  // message glyph
  draw.line((lx + 5.6, ly), (lx + 6.2, ly), stroke: (paint: garnet, thickness: 1.25pt),
    mark: (end: "stealth", fill: garnet, scale: 0.7))
  draw.content((lx + 6.4, ly), anchor: "west", text(size: 8pt, fill: muted)[message $mu$])

  // ── message-passing rule (bottom) ───────────────────────────────────────
  draw.content(
    (-1.0, -3.55),
    text(size: 9pt, fill: ink)[$mu_(C_i -> C_j)(S_(i j)) = sum_(C_i without S_(i j)) psi_(C_i)$],
  )
})
