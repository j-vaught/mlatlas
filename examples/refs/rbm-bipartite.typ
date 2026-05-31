// Restricted Boltzmann Machine (RBM) — bipartite undirected graphical model.
//   Two layers of stochastic binary units: a VISIBLE layer v (data) and a HIDDEN
//   layer h (latent features). Every visible–hidden pair is joined by a SYMMETRIC,
//   undirected weighted edge W_{ij}; there are NO within-layer connections
//   (visible–visible or hidden–hidden) — that is the "restriction" that makes the
//   conditionals fully factorial, p(h|v) = prod_j p(h_j|v) and p(v|h) = prod_i p(v_i|h).
//   The model defines a Gibbs distribution over the joint energy
//       E(v,h) = - b^T v - c^T h - v^T W h,    p(v,h) = exp(-E)/Z.
//   Undirected edges are drawn with NO arrowheads (marks:'none'); one focal weight
//   W_{ij} and the two bias terms are accented in garnet. Built from the standard
//   PGM convention (Goodfellow et al. ch.16/20; Hinton; Bishop) in mlatlas's
//   print-first house style. Original layout — not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet  = rgb("#73000A")
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let edgecol = rgb("#C7C7C7")   // 30% black — the dense weight web sits quietly behind nodes
#let vfill   = rgb("#ECECEC")   // 10% black — visible unit (observed data)
#let hfill   = white            // hidden unit (latent)

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let r = 0.42          // unit radius
  let nv = 5            // visible units
  let nh = 4            // hidden units
  let vy = 0.0          // visible row height
  let hy = 3.4          // hidden row height
  let dx = 1.55         // horizontal unit spacing

  // ── unit centre coordinates, centred about x = 0 ────────────────────────
  let vx(i) = (i - (nv - 1) / 2) * dx
  let hx(j) = (j - (nh - 1) / 2) * dx
  let vpos(i) = (vx(i), vy)
  let hpos(j) = (hx(j), hy)

  // focal weighted edge: visible unit i*=2 <-> hidden unit j*=1
  let istar = 2
  let jstar = 1

  // ── complete bipartite weight web (undirected, no arrowheads) ───────────
  //   every v_i connects to every h_j; one edge (the focal W_{ij}) is garnet.
  for i in range(nv) {
    for j in range(nh) {
      let p = vpos(i)
      let q = hpos(j)
      // trim to circle rims so edges meet the outlines cleanly
      let ddx = q.at(0) - p.at(0)
      let ddy = q.at(1) - p.at(1)
      let len = calc.sqrt(ddx * ddx + ddy * ddy)
      let ux = ddx / len
      let uy = ddy / len
      let s = (p.at(0) + ux * r, p.at(1) + uy * r)
      let e = (q.at(0) - ux * r, q.at(1) - uy * r)
      let focal = (i == istar and j == jstar)
      let st = if focal { 1.5pt + garnet } else { 0.7pt + edgecol }
      line(s, e, stroke: st)   // NO mark -> undirected
    }
  }

  // ── focal weight label W_{ij} on its garnet edge ────────────────────────
  {
    let p = vpos(istar)
    let q = hpos(jstar)
    let mx = (p.at(0) + q.at(0)) / 2
    let my = (p.at(1) + q.at(1)) / 2
    content(
      (mx - 0.30, my), anchor: "east",
      text(size: 8.5pt, fill: garnet, weight: "bold")[$W_(i j)$],
    )
  }

  // ── hidden units h_j (latent features) ──────────────────────────────────
  for j in range(nh) {
    circle(hpos(j), radius: r, fill: hfill, stroke: 1.2pt + ink)
    content(hpos(j), text(size: 9pt, fill: ink)[$h_#(j + 1)$])
  }

  // ── visible units v_i (observed data) ───────────────────────────────────
  for i in range(nv) {
    circle(vpos(i), radius: r, fill: vfill, stroke: 1.2pt + ink)
    content(vpos(i), text(size: 9pt, fill: ink)[$v_#(i + 1)$])
  }

  // ── layer brackets + names ──────────────────────────────────────────────
  let leftx = vx(0) - r - 0.65
  let rightx = vx(nv - 1) + r + 0.65
  // hidden-layer label (left)
  content(
    (leftx - 0.05, hy), anchor: "east",
    text(size: 9.5pt, fill: muted)[hidden $h$],
  )
  // visible-layer label (left)
  content(
    (leftx - 0.05, vy), anchor: "east",
    text(size: 9.5pt, fill: muted)[visible $v$],
  )

  // ── bias annotations (garnet accents on the energy terms) ───────────────
  //   c_j on hidden units, b_i on visible units — shown once each at the right end.
  content(
    (hx(nh - 1) + r + 0.30, hy), anchor: "west",
    text(size: 8.5pt, fill: garnet)[$c_j$ #text(fill: muted, size: 7.5pt)[(hidden bias)]],
  )
  content(
    (vx(nv - 1) + r + 0.30, vy), anchor: "west",
    text(size: 8.5pt, fill: garnet)[$b_i$ #text(fill: muted, size: 7.5pt)[(visible bias)]],
  )

  // ── "no within-layer edges" annotation ──────────────────────────────────
  //   a faint dashed forbidden link between two hidden units, struck through.
  {
    let a = hpos(0)
    let b = hpos(1)
    let ay = a.at(1) + r + 0.42
    line(
      (a.at(0), ay), (b.at(0), ay),
      stroke: (paint: rgb("#A2A2A2"), thickness: 0.9pt, dash: "dashed"),
    )
    // strike-through cross
    let mx = (a.at(0) + b.at(0)) / 2
    line((mx - 0.18, ay - 0.18), (mx + 0.18, ay + 0.18), stroke: 1.2pt + garnet)
    line((mx - 0.18, ay + 0.18), (mx + 0.18, ay - 0.18), stroke: 1.2pt + garnet)
    content(
      (b.at(0) + 0.30, ay), anchor: "west",
      text(size: 7.5pt, fill: muted)[no within-layer edges],
    )
  }

  // ── title ───────────────────────────────────────────────────────────────
  content(
    (0, hy + 1.95),
    text(size: 11pt, weight: "bold", fill: ink)[Restricted Boltzmann Machine],
  )
  content(
    (0, hy + 1.42),
    text(size: 8pt, fill: muted)[bipartite undirected graph: every visible–hidden pair coupled by a symmetric weight $W_(i j)$],
  )

  // ── energy + conditional factorization caption ──────────────────────────
  let cy = vy - 1.55
  content(
    (0, cy),
    text(size: 9.5pt, fill: ink)[
      $E(v, h) = - b^top v - c^top h - v^top W h, quad p(v, h) = e^(-E(v, h)) \/ Z$
    ],
  )
  content(
    (0, cy - 0.72),
    text(size: 8.5pt, fill: muted)[
      restriction $=>$ factorial conditionals: #h(0.3em)
      $p(h | v) = product_j p(h_j | v)$, #h(0.5em) $p(v | h) = product_i p(v_i | h)$
    ],
  )

  // ── legend (top-right) ──────────────────────────────────────────────────
  let lx = rightx + 1.65
  let ly = hy + 0.55
  rect((lx - 0.45, ly - 2.55), (lx + 3.05, ly + 0.55), stroke: 0.8pt + rgb("#A2A2A2"), radius: 0pt)
  // hidden glyph
  circle((lx, ly), radius: 0.24, fill: hfill, stroke: 1.1pt + ink)
  content((lx + 0.50, ly), anchor: "west", text(size: 8pt, fill: ink)[hidden unit (latent)])
  // visible glyph
  circle((lx, ly - 0.85), radius: 0.24, fill: vfill, stroke: 1.1pt + ink)
  content((lx + 0.50, ly - 0.85), anchor: "west", text(size: 8pt, fill: ink)[visible unit (data)])
  // undirected edge glyph
  line((lx - 0.24, ly - 1.70), (lx + 0.24, ly - 1.70), stroke: 0.9pt + edgecol)
  content((lx + 0.50, ly - 1.70), anchor: "west", text(size: 8pt, fill: ink)[weight (undirected)])
  // focal weight glyph
  line((lx - 0.24, ly - 2.30), (lx + 0.24, ly - 2.30), stroke: 1.5pt + garnet)
  content((lx + 0.50, ly - 2.30), anchor: "west", text(size: 8pt, fill: ink)[focal weight $W_(i j)$])
})
