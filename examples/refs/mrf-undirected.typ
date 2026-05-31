// Markov random field / undirected graphical model (MRF).
//   Random variables = round nodes; UNDIRECTED edges encode pairwise Markov
//   dependence (no arrowheads, no direction). By Hammersley–Clifford the joint
//   distribution factorizes over the MAXIMAL CLIQUES of the graph:
//        p(x) = (1/Z) prod_{C in cliques} psi_C(x_C),   Z = sum_x prod_C psi_C(x_C)
//   where psi_C >= 0 is a clique potential and Z the partition function.
//
//   Left panel : a small general MRF. A maximal 3-clique {x2,x3,x4} is shaded to
//                show the clique over which one potential factor is defined.
//   Right panel: a grid / lattice MRF (Ising-style) — each site connects to its
//                4 nearest neighbours; every edge is a pairwise clique. The local
//                Markov blanket (the 4 neighbours of a focal site) is highlighted.
//
// Built from the standard PGM convention (Bishop PRML §8.3; Koller & Friedman;
// Murphy book1; Barber BRML) in mlatlas's print-first house style. Original
// layout — not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet  = rgb("#73000A")
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let edgecol = rgb("#5C5C5C")
#let nodefil = rgb("#ECECEC")        // 10% black — node fill
#let cliquef = rgb("#73000A").transparentize(82%)  // translucent garnet clique shade
#let blanket = rgb("#466A9F").transparentize(82%)   // translucent blue Markov-blanket shade

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let r = 0.42        // node radius

  // ── helper: undirected edge between two centres, trimmed to the rims ──────
  let uedge(a, b, col: edgecol, th: 1.0pt) = {
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let len = calc.sqrt(dx * dx + dy * dy)
    let ux = dx / len
    let uy = dy / len
    line(
      (a.at(0) + ux * r, a.at(1) + uy * r),
      (b.at(0) - ux * r, b.at(1) - uy * r),
      stroke: (paint: col, thickness: th),   // NO mark: undirected
    )
  }

  // ── helper: a node (open circle + math label) ────────────────────────────
  let node(c, lbl, focal: false) = {
    circle(
      c, radius: r, fill: nodefil,
      stroke: if focal { 1.7pt + garnet } else { 1.2pt + ink },
    )
    content(c, text(size: 10pt, fill: ink)[#lbl])
  }

  // =========================================================================
  // LEFT PANEL — general MRF with a shaded maximal clique
  // =========================================================================
  // node coordinates (id -> centre)
  let L = (
    x1: (-0.2, 2.1),
    x2: (1.7,  2.1),
    x3: (1.7,  0.2),
    x4: (3.4,  1.15),
    x5: (3.4,  3.05),
  )

  // shaded maximal clique {x2, x3, x4} — translucent filled triangle behind nodes
  line(L.x2, L.x3, L.x4, close: true, fill: cliquef, stroke: (paint: garnet, thickness: 0.9pt))

  // undirected edges of the MRF
  uedge(L.x1, L.x2)
  uedge(L.x2, L.x3)
  uedge(L.x2, L.x4, col: garnet, th: 1.3pt)
  uedge(L.x3, L.x4, col: garnet, th: 1.3pt)
  uedge(L.x4, L.x5)
  uedge(L.x2, L.x5)

  // the clique edge x2–x3 sits on the shaded triangle: redraw in garnet on top
  uedge(L.x2, L.x3, col: garnet, th: 1.3pt)

  // nodes
  node(L.x1, [$x_1$])
  node(L.x2, [$x_2$])
  node(L.x3, [$x_3$])
  node(L.x4, [$x_4$])
  node(L.x5, [$x_5$])

  // clique label tucked at the triangle centroid-ish position
  content((2.27, 1.15), text(size: 8pt, fill: garnet, weight: "bold")[$psi_C$])
  content(
    (2.05, -0.55),
    text(size: 7.5pt, fill: garnet)[maximal clique $C = {x_2, x_3, x_4}$],
  )

  // panel title + factorization caption
  content((1.6, 3.7), text(size: 9.5pt, weight: "bold", fill: ink)[general MRF])
  content(
    (1.6, -1.35),
    text(size: 8.5pt, fill: ink)[
      $p(x) = 1 / Z product_(C) psi_C (x_C)$
    ],
  )
  content(
    (1.6, -2.0),
    text(size: 7.5pt, fill: muted)[$Z = sum_x product_C psi_C (x_C)$ (partition function)],
  )

  // =========================================================================
  // RIGHT PANEL — grid / lattice MRF (Ising-style), 4-neighbour connectivity
  // =========================================================================
  let gx0 = 6.6        // grid origin x
  let gy0 = -0.6       // grid origin y (bottom-left site)
  let gs  = 1.25       // grid spacing
  let n   = 3          // 3 x 3 lattice

  // site centre for column i (0..n-1), row j (0..n-1)
  let site(i, j) = (gx0 + i * gs, gy0 + j * gs)

  // focal site (centre) and its 4-neighbour Markov blanket
  let fi = 1
  let fj = 1

  // shaded Markov-blanket "plus" region behind the lattice: square per blanket cell
  for (di, dj) in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)) {
    let c = site(fi + di, fj + dj)
    rect(
      (c.at(0) - 0.6, c.at(1) - 0.6), (c.at(0) + 0.6, c.at(1) + 0.6),
      fill: blanket, stroke: none,
    )
  }

  // lattice edges: horizontal and vertical nearest-neighbour bonds
  for j in range(n) {
    for i in range(n) {
      if i < n - 1 { uedge(site(i, j), site(i + 1, j)) }
      if j < n - 1 { uedge(site(i, j), site(i, j + 1)) }
    }
  }

  // lattice nodes — generic sites blank; focal centre site highlighted as x_s
  for j in range(n) {
    for i in range(n) {
      let foc = (i == fi and j == fj)
      if foc {
        circle(site(i, j), radius: r, fill: nodefil, stroke: 1.7pt + garnet)
        content(site(i, j), text(size: 9pt, fill: garnet, weight: "bold")[$x_s$])
      } else {
        circle(site(i, j), radius: r, fill: nodefil, stroke: 1.2pt + ink)
      }
    }
  }

  // panel title + caption
  content((gx0 + gs, gy0 + 2 * gs + 1.05), text(size: 9.5pt, weight: "bold", fill: ink)[grid (lattice) MRF])
  content(
    (gx0 + gs, gy0 - 1.05),
    text(size: 7.5pt, fill: rgb("#466A9F"))[Markov blanket of $x_s$ = its 4 neighbours],
  )
  content(
    (gx0 + gs, gy0 - 1.72),
    text(size: 8pt, fill: ink)[$x_s perp x_("rest") thin | thin x_(N(s))$],
  )

  // =========================================================================
  // SHARED LEGEND (bottom strip)
  // =========================================================================
  let lx = -0.2
  let ly = -3.0
  // open node glyph
  circle((lx, ly), radius: 0.20, fill: nodefil, stroke: 1.1pt + ink)
  content((lx + 0.38, ly), anchor: "west", text(size: 7.5pt, fill: muted)[variable $x_i$])
  // undirected edge glyph
  line((lx + 2.55, ly), (lx + 3.15, ly), stroke: (paint: edgecol, thickness: 1.0pt))
  content((lx + 3.3, ly), anchor: "west", text(size: 7.5pt, fill: muted)[undirected edge (no direction)])
  // clique shade glyph
  rect((lx + 6.95, ly - 0.2), (lx + 7.35, ly + 0.2), fill: cliquef, stroke: (paint: garnet, thickness: 0.8pt))
  content((lx + 7.5, ly), anchor: "west", text(size: 7.5pt, fill: muted)[maximal clique (potential $psi_C$)])

  // overall title
  content(
    (4.0, 4.55),
    text(size: 11.5pt, weight: "bold", fill: ink)[Markov random field — undirected graphical model],
  )
})
