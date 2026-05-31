// mlatlas · Orthogonal projection onto a subspace.
//
//   The geometric core of least squares and PCA: take a vector  b  and the closest
//   point  p = proj_U(b)  inside a subspace U. The displacement  r = b − p  (the
//   RESIDUAL) is orthogonal to every vector in U — that is the defining property and
//   the reason  p  is the unique nearest point ("foot of the perpendicular").
//
//   LEFT  — U = span{a}, a LINE through the origin (the 1-D case underlying simple
//           regression onto one feature). The projection has the closed form
//                p = (⟨a,b⟩ / ⟨a,a⟩) · a ,
//           computed here from the actual coordinates of a and b (not faked). The
//           dashed drop b → p meets the line at a right angle; r = b − p ⟂ a.
//
//   RIGHT — U = span{u₁,u₂}, a PLANE through the origin (the general subspace case
//           behind least squares  min‖Ax−b‖  and PCA reconstruction). The residual
//           r = b − p is normal to the plane: r ⟂ u₁ and r ⟂ u₂.
//
//   Standard teaching figure (Deisenroth/Faisal/Ong "Mathematics for Machine
//   Learning", §3.8; Strang "Linear Algebra"; Hastie ESL least squares). Built
//   print-first from scratch in cetz: light fills, dark ink, sharp corners, stealth
//   arrowheads, garnet a sparse accent on the residual (the key object). No image
//   was traced. The projection coordinates are computed from a and b below.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let grid-c = rgb("#ECECEC")
#let garnet = rgb("#73000A")   // focal accent: the RESIDUAL r = b − p
#let blue   = rgb("#466A9F")   // the projection p (lives in U)
#let green  = rgb("#65780B")   // subspace basis / spanning vector(s)
#let beige  = rgb("#FFF2E3")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ╔════════════════════════════════════════════════════════════════════════════╗
  // ║  LEFT PANEL — projection onto a LINE  U = span{a}                            ║
  // ╚════════════════════════════════════════════════════════════════════════════╝
  // world (math) coords are drawn directly in cm; the panel origin is the subspace
  // origin O. Everything is computed from the two vectors a and b.
  let Lox = 0.0
  let Loy = 0.0

  // spanning vector a (direction of the line) and the vector b to be projected
  let ax = 3.6
  let ay = 1.05
  let bx = 1.7
  let by = 2.9

  // closed-form projection of b onto span{a}:  p = (⟨a,b⟩/⟨a,a⟩) a
  let dot-ab = ax * bx + ay * by
  let dot-aa = ax * ax + ay * ay
  let t = dot-ab / dot-aa
  let px = t * ax
  let py = t * ay
  // residual r = b − p (orthogonal to a, by construction)
  let rx = bx - px
  let ry = by - py

  // helpers in panel coords
  let LP(x, y) = (Lox + x, Loy + y)

  // ── the subspace LINE (extends both ways through O) ────────────────────────────
  let La = calc.sqrt(dot-aa)
  let ux = ax / La
  let uy = ay / La
  let ext0 = -0.9
  let ext1 = 4.55
  // light shaded "ribbon" hint that U is a subspace (very subtle), then the line
  line(LP(ext0 * ux, ext0 * uy), LP(ext1 * ux, ext1 * uy),
    stroke: 1.6pt + green)
  // line label  U = span{a}
  content(LP(ext1 * ux + 0.10, ext1 * uy - 0.02), anchor: "west",
    text(size: 8pt, fill: green, weight: "bold")[$U = "span"{bold(a)}$])

  // ── axes through O (faint), for orientation only ───────────────────────────────
  line(LP(-1.0, 0), LP(4.6, 0), stroke: 0.6pt + grid-c)
  line(LP(0, -0.6), LP(0, 3.6), stroke: 0.6pt + grid-c)

  // ── spanning vector a (green arrow from O) ─────────────────────────────────────
  line(LP(0, 0), LP(ax, ay), stroke: 1.8pt + green,
    mark: (end: "stealth", fill: green, scale: 0.9))
  content(LP(ax * 0.82 + 0.05, ay * 0.82 - 0.30), anchor: "north",
    text(size: 9pt, fill: green, weight: "bold")[$bold(a)$])

  // ── original vector b (dark arrow from O) ──────────────────────────────────────
  line(LP(0, 0), LP(bx, by), stroke: 2pt + ink,
    mark: (end: "stealth", fill: ink, scale: 0.95))
  content(LP(bx - 0.30, by + 0.06), anchor: "south-east",
    text(size: 10pt, fill: ink, weight: "bold")[$bold(b)$])

  // ── projection p = proj_U(b) (blue arrow from O, lies ON the line) ─────────────
  line(LP(0, 0), LP(px, py), stroke: 2.2pt + blue,
    mark: (end: "stealth", fill: blue, scale: 0.9))
  content(LP(px * 0.5 + 0.02, py * 0.5 + 0.30), anchor: "south",
    text(size: 9pt, fill: blue, weight: "bold")[$bold(p)$])

  // ── the perpendicular drop  b → p  (dashed) and the residual r (garnet) ────────
  // residual vector r = b − p, drawn FROM p TO b so it reads as b = p + r.
  line(LP(px, py), LP(bx, by), stroke: (paint: garnet, thickness: 2pt),
    mark: (end: "stealth", fill: garnet, scale: 0.95))
  // residual label on a white plate, offset to the right of the drop
  content(LP((px + bx) / 2 + 0.18, (py + by) / 2 + 0.02), anchor: "west",
    box(fill: white.transparentize(8%), inset: 1.4pt,
      text(size: 9pt, fill: garnet, weight: "bold")[$bold(r) = bold(b) - bold(p)$]))

  // ── right-angle mark at p (the residual meets the line orthogonally) ───────────
  // unit vector along line is (ux,uy); unit along residual is (nx,ny).
  let Lr = calc.sqrt(rx * rx + ry * ry)
  let nx = rx / Lr
  let ny = ry / Lr
  let s = 0.34   // mark side length
  // square corner: p → p+s·u → p+s·u+s·n → p+s·n
  let c0 = (px, py)
  let c1 = (px + s * ux, py + s * uy)
  let c2 = (px + s * ux + s * nx, py + s * uy + s * ny)
  let c3 = (px + s * nx, py + s * ny)
  line(LP(c1.at(0), c1.at(1)), LP(c2.at(0), c2.at(1)), LP(c3.at(0), c3.at(1)),
    stroke: 1.1pt + muted)

  // ── origin marker O ────────────────────────────────────────────────────────────
  circle(LP(0, 0), radius: 0.055, fill: ink, stroke: none)
  content(LP(-0.16, -0.16), anchor: "north-east", text(size: 8pt, fill: muted)[$O$])

  // ── panel title + closed form ──────────────────────────────────────────────────
  content(LP(2.0, 5.05), anchor: "center",
    text(size: 10pt, weight: "bold", fill: ink)[onto a line])
  content(LP(2.0, 4.5), anchor: "center",
    text(size: 8pt, fill: ink)[$bold(p) = (chevron.l bold(a), bold(b) chevron.r) / (chevron.l bold(a), bold(a) chevron.r) bold(a)$])

  // ╔════════════════════════════════════════════════════════════════════════════╗
  // ║  RIGHT PANEL — projection onto a PLANE  U = span{u₁,u₂}                      ║
  // ╚════════════════════════════════════════════════════════════════════════════╝
  // A cabinet-style isometric scene. The plane U is the (x,y) ground; the residual
  // is the vertical (z) component of b. Screen mapping:
  let Rox = 9.3
  let Roy = 1.0
  let exX = 0.92            // u1 axis → mostly rightward
  let exY = 0.0
  let eyX = 0.46            // u2 axis → up-and-right (depth)
  let eyY = 0.40
  let ezY = 0.92            // z (normal) → straight up
  let P(x, y, z) = (
    Rox + x * exX + y * eyX,
    Roy + x * exY + y * eyY + z * ezY,
  )

  // b expressed in the (u1, u2, normal) frame: its in-plane part is p, its
  // out-of-plane (normal) part is the residual r. Coordinates chosen for clarity.
  let bu1 = 2.05           // ⟨b,u1⟩
  let bu2 = 1.55           // ⟨b,u2⟩
  let brn = 2.35           // component of b along the plane normal (= |r|)

  // ── the PLANE U (light filled parallelogram through O) ─────────────────────────
  let pe = 3.05
  line(
    P(-0.5, -0.5, 0), P(pe, -0.5, 0), P(pe, pe, 0), P(-0.5, pe, 0),
    close: true,
    fill: green.transparentize(90%), stroke: 0.9pt + green,
  )
  // a light grid on the plane to read it as a 2-D subspace
  for g in range(0, 4) {
    line(P(g, -0.5, 0), P(g, pe, 0), stroke: 0.5pt + grid-c)
    line(P(-0.5, g, 0), P(pe, g, 0), stroke: 0.5pt + grid-c)
  }
  // plane label
  content(P(pe, pe, 0), anchor: "west",
    text(size: 8pt, fill: green, weight: "bold")[$U = "span"{bold(u)_1, bold(u)_2}$])

  // ── basis vectors u1, u2 spanning the plane ────────────────────────────────────
  line(P(0, 0, 0), P(2.5, 0, 0), stroke: 1.5pt + green,
    mark: (end: "stealth", fill: green, scale: 0.85))
  content(P(2.5 + 0.1, 0, 0), anchor: "west",
    text(size: 8.5pt, fill: green, weight: "bold")[$bold(u)_1$])
  line(P(0, 0, 0), P(0, 2.5, 0), stroke: 1.5pt + green,
    mark: (end: "stealth", fill: green, scale: 0.85))
  content((P(0, 2.5, 0).at(0) - 0.18, P(0, 2.5, 0).at(1) + 0.10), anchor: "south-east",
    text(size: 8.5pt, fill: green, weight: "bold")[$bold(u)_2$])

  // ── projection p (in the plane), the residual r (vertical), and b = p + r ──────
  let foot   = P(bu1, bu2, 0)     // p, the foot of the perpendicular
  let tip    = P(bu1, bu2, brn)   // b, the original vector's head
  let origin = P(0, 0, 0)

  // p: blue arrow from O to the foot
  line(origin, foot, stroke: 2.2pt + blue,
    mark: (end: "stealth", fill: blue, scale: 0.85))
  content((foot.at(0) + 0.42, foot.at(1) - 0.20), anchor: "north-west",
    text(size: 9pt, fill: blue, weight: "bold")[$bold(p)$])

  // b: dark arrow from O to the lifted head
  line(origin, tip, stroke: 2pt + ink,
    mark: (end: "stealth", fill: ink, scale: 0.9))
  content((tip.at(0) - 0.12, tip.at(1) + 0.06), anchor: "south-east",
    text(size: 10pt, fill: ink, weight: "bold")[$bold(b)$])

  // r = b − p : garnet vertical arrow from foot to tip (orthogonal to the plane)
  line(foot, tip, stroke: (paint: garnet, thickness: 2pt),
    mark: (end: "stealth", fill: garnet, scale: 0.9))
  content(((foot.at(0) + tip.at(0)) / 2 + 0.14, (foot.at(1) + tip.at(1)) / 2), anchor: "west",
    box(fill: white.transparentize(8%), inset: 1.4pt,
      text(size: 9pt, fill: garnet, weight: "bold")[$bold(r) = bold(b) - bold(p)$]))

  // ── right-angle mark where the residual meets the plane (at the foot p) ────────
  // along-plane direction toward O: (−u1) screen vector; along-normal: +z screen.
  // build the small square from foot using a plane-edge direction and the z-up dir
  let a1 = P(bu1 - 0.42, bu2, 0)         // step back along u1 in the plane
  let a2 = P(bu1 - 0.42, bu2, 0.42)      // up along normal
  let a3 = P(bu1, bu2, 0.42)
  line(a1, a2, a3, stroke: 1.1pt + muted)

  // ── faint stem / shadow to reinforce that p is the foot directly below b ───────
  circle(foot, radius: 0.05, fill: blue, stroke: 0.5pt + white)

  // ── origin marker O ────────────────────────────────────────────────────────────
  circle(origin, radius: 0.055, fill: ink, stroke: none)
  content((origin.at(0) - 0.12, origin.at(1) - 0.14), anchor: "north-east",
    text(size: 8pt, fill: muted)[$O$])

  // ── panel title + orthogonality conditions ─────────────────────────────────────
  content(P(1.0, 1.0, 4.6), anchor: "center",
    text(size: 10pt, weight: "bold", fill: ink)[onto a plane])
  content(P(1.0, 1.0, 3.95), anchor: "center",
    text(size: 8pt, fill: ink)[$bold(r) perp bold(u)_1, thick bold(r) perp bold(u)_2$])

  // ╔════════════════════════════════════════════════════════════════════════════╗
  // ║  Shared title + the defining-property caption (top + bottom)                 ║
  // ╚════════════════════════════════════════════════════════════════════════════╝
  content((7.0, 6.55), anchor: "center",
    text(size: 12pt, weight: "bold", fill: ink)[Orthogonal projection onto a subspace])

  // bottom legend band
  let by0 = -1.25
  // b swatch
  line((0.1, by0), (0.7, by0), stroke: 2pt + ink, mark: (end: "stealth", fill: ink, scale: 0.85))
  content((0.85, by0), anchor: "west", text(size: 8pt, fill: ink)[$bold(b)$ — original vector])
  // p swatch
  line((4.0, by0), (4.6, by0), stroke: 2.2pt + blue, mark: (end: "stealth", fill: blue, scale: 0.85))
  content((4.75, by0), anchor: "west",
    text(size: 8pt, fill: ink)[$bold(p) = "proj"_U (bold(b)) in U$ — nearest point])
  // r swatch
  line((9.7, by0), (10.3, by0), stroke: 2pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.85))
  content((10.45, by0), anchor: "west",
    text(size: 8pt, fill: ink)[$bold(r) = bold(b) - bold(p) perp U$ — residual])

  // the punchline
  content((7.0, by0 - 0.78), anchor: "center",
    text(size: 8.5pt, fill: muted)[defining property: the residual is orthogonal to the whole subspace, so $bold(p)$ minimizes $norm(bold(b) - bold(x))$ over $bold(x) in U$ — the basis of least squares and PCA.])
})
