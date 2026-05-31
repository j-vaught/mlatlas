// mlatlas · The kernel trick / feature-space lift.
//
//   A canonical illustration of why a non-linear classifier in input space is a
//   LINEAR classifier in a lifted feature space. The data are two concentric
//   clouds in the plane: an INNER blob (class ⊕, near the origin) wrapped by an
//   OUTER ring (class ⊖). No straight line separates them — only a closed CURVE
//   (a circle x₁²+x₂² = r²) does. Apply the explicit feature map
//
//        φ(x) = ( x₁ ,  x₂ ,  x₁² + x₂² )        (the "lift")
//
//   which adds a radius² coordinate z. In this 3-D feature space the inner cloud
//   sits LOW (small radius) and the outer ring sits HIGH, so a single FLAT plane
//   z = b separates them linearly. Pulling that plane back to input space gives
//   exactly the circular boundary on the left. The kernel trick is the further
//   observation that a linear learner only needs inner products ⟨φ(x),φ(x')⟩,
//   which here equal a closed-form kernel k(x,x') — so φ never has to be formed.
//
//   Standard teaching figure (Mohri "Foundations of ML"; Deisenroth MML;
//   Shalev-Shwartz & Ben-David UML; Hastie ESL). Built print-first from scratch
//   in cetz: light fills, dark ink, sharp corners, garnet a sparse accent on the
//   separating boundary/plane. The lifted z-coordinates are COMPUTED here from
//   the same 2-D points (z = x₁²+x₂²), not faked. No image was traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ────────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid   = rgb("#ECECEC")
  let garnet = rgb("#73000A")   // focal accent: the separating boundary / plane
  let blue   = rgb("#466A9F")   // class ⊕  (inner / low)
  let green  = rgb("#65780B")   // class ⊖  (outer / high)
  let beige  = rgb("#FFF2E3")

  // ── deterministic point cloud  (small LCG → uniforms) ───────────────────────
  //   inner class (⊕): radius ∈ [0, 1.1]   →  low z
  //   outer class (⊖): radius ∈ [1.9, 2.7] →  high z
  let lcg(seed, n) = {
    let st = seed
    let out = ()
    for _ in range(n) {
      st = calc.rem(st * 1103515245 + 12345, 2147483648)
      out.push(st / 2147483648.0)
    }
    out
  }
  let n-in  = 20
  let n-out = 30
  // build (x1, x2) points from (radius, angle) so classes are cleanly concentric
  let ru-in  = lcg(7, n-in)
  let au-in  = lcg(91, n-in)
  let ru-out = lcg(401, n-out)
  let au-out = lcg(523, n-out)
  let inner = range(n-in).map(i => {
    let r = 0.20 + 0.95 * calc.sqrt(ru-in.at(i))
    let t = 2 * calc.pi * au-in.at(i)
    (r * calc.cos(t), r * calc.sin(t))
  })
  let outer = range(n-out).map(i => {
    let r = 1.95 + 0.70 * ru-out.at(i)
    let t = 2 * calc.pi * au-out.at(i)
    (r * calc.cos(t), r * calc.sin(t))
  })
  // the separating radius (between the clouds): boundary circle in input space
  let r-sep = 1.55

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║  LEFT PANEL — input space ℝ², non-linearly separable                       ║
  // ╚══════════════════════════════════════════════════════════════════════════╝
  let LPW = 6.2          // left panel width  (cm)
  let LPH = 6.2          // left panel height
  let lox = 0.0          // left panel origin x
  let loy = 0.0          // left panel origin y
  // data range [-3,3] mapped into the box
  let DLO = -3.0
  let DHI = 3.0
  let Lx(x) = lox + (x - DLO) / (DHI - DLO) * LPW
  let Ly(y) = loy + (y - DLO) / (DHI - DLO) * LPH

  // panel frame + light grid
  rect((lox, loy), (lox + LPW, loy + LPH), fill: white, stroke: 0.8pt + ink)
  for g in range(-2, 3) {
    line((Lx(g), loy), (Lx(g), loy + LPH), stroke: 0.5pt + grid)
    line((lox, Ly(g)), (lox + LPW, Ly(g)), stroke: 0.5pt + grid)
  }
  // central axes
  line((Lx(DLO), Ly(0)), (Lx(DHI), Ly(0)), stroke: 0.6pt + rgb("#C7C7C7"))
  line((Lx(0), Ly(DLO)), (Lx(0), Ly(DHI)), stroke: 0.6pt + rgb("#C7C7C7"))

  // shaded inner disk (the region the curved boundary encloses)
  let disk = range(65).map(i => {
    let t = i / 64 * 2 * calc.pi
    (Lx(r-sep * calc.cos(t)), Ly(r-sep * calc.sin(t)))
  })
  line(..disk, close: true, fill: garnet.transparentize(93%), stroke: none)

  // the NON-LINEAR decision boundary: circle of radius r-sep (focal garnet)
  let bnd = range(97).map(i => {
    let t = i / 96 * 2 * calc.pi
    (Lx(r-sep * calc.cos(t)), Ly(r-sep * calc.sin(t)))
  })
  line(..bnd, close: true, stroke: (paint: garnet, thickness: 2pt))

  // points: inner ⊕ (blue filled), outer ⊖ (green hollow)
  for p in inner {
    circle((Lx(p.at(0)), Ly(p.at(1))), radius: 0.085, fill: blue, stroke: 0.5pt + white)
  }
  for p in outer {
    circle((Lx(p.at(0)), Ly(p.at(1))), radius: 0.085, fill: white, stroke: 1.1pt + green)
  }

  // axis ticks + labels
  for g in (-2, 0, 2) {
    line((Lx(g), loy), (Lx(g), loy - 0.12), stroke: 0.8pt + ink)
    content((Lx(g), loy - 0.32), text(size: 7pt, fill: muted)[$#g$])
    line((lox, Ly(g)), (lox - 0.12, Ly(g)), stroke: 0.8pt + ink)
    content((lox - 0.3, Ly(g)), text(size: 7pt, fill: muted)[$#g$])
  }
  content((lox + LPW - 0.05, loy - 0.34), anchor: "north-east", text(size: 8.5pt, fill: ink)[$x_1$])
  content((lox - 0.34, loy + LPH - 0.05), anchor: "north-east", text(size: 8.5pt, fill: ink)[$x_2$])

  // boundary callout
  content((Lx(0), Ly(0)), anchor: "center",
    box(fill: white.transparentize(12%), inset: 1.4pt,
      text(size: 7.5pt, fill: garnet, weight: "bold")[$x_1^2 + x_2^2 = r^2$]))

  // panel title
  content((lox + LPW / 2, loy + LPH + 0.92),
    text(size: 10pt, weight: "bold", fill: ink)[input space $bb(R)^2$])
  content((lox + LPW / 2, loy + LPH + 0.5),
    text(size: 7.5pt, fill: muted)[not linearly separable — needs a curved boundary])

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║  MIDDLE — the lift  φ : ℝ² → ℝ³                                            ║
  // ╚══════════════════════════════════════════════════════════════════════════╝
  let amx0 = lox + LPW + 0.55     // arrow start x
  let amx1 = lox + LPW + 2.6      // arrow end x
  let amy  = loy + LPH / 2 + 0.35 // arrow y
  let amc  = (amx0 + amx1) / 2
  line((amx0, amy), (amx1, amy), stroke: 2pt + ink,
    mark: (end: "stealth", fill: ink, scale: 1.1))
  content((amc, amy + 0.95), anchor: "south",
    text(size: 14pt, weight: "bold", fill: garnet)[$phi$])
  content((amc, amy + 0.55), anchor: "south",
    text(size: 7pt, fill: muted)[lift])
  content((amc, amy - 0.36), anchor: "north",
    box(fill: white, inset: (x: 1pt),
      text(size: 6.8pt, fill: ink)[$(x_1, x_2) arrow.r$]))
  content((amc, amy - 0.78), anchor: "north",
    box(fill: white, inset: (x: 1pt),
      text(size: 6.8pt, fill: ink)[$(x_1, x_2, x_1^2 + x_2^2)$]))

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║  RIGHT PANEL — feature space ℝ³, linearly separable (isometric view)        ║
  // ╚══════════════════════════════════════════════════════════════════════════╝
  // cabinet-style projection of (X, Y, Z) → screen (sx, sy).
  //   X = x1 axis runs along screen-x; the x2 ("depth") axis recedes up-right at
  //   a shallow angle; Z is PURELY VERTICAL on screen, so the separating plane
  //   z = b reads as a near-horizontal slab and the lift is clearly upward.
  let rox = amx1 + 2.35           // right scene origin x (screen)
  let roy = loy + 1.55            // right scene origin y (screen, floor at z=0)
  // axis screen-vectors (cm per data unit)
  let exX = 0.78                  // x1 → mostly rightward
  let exY = 0.0
  let eyX = 0.34                  // x2 → up-and-right (shallow depth)
  let eyY = 0.30
  let ezY = 0.66                  // z  → straight up; compresses the r² range
  let P(x, y, z) = (
    rox + x * exX + y * eyX,
    roy + x * exY + y * eyY + z * ezY,
  )

  // z extent of the data: r∈[0,2.7] → z=r²∈[0,7.29]; plane at z = r_sep²
  let z-plane = r-sep * r-sep      // ≈ 2.40

  // ── ground grid on the z = 0 floor (the x1–x2 plane embedded in ℝ³) ─────────
  let gmin = -3.0
  let gmax = 3.0
  for g in range(-3, 4) {
    line(P(g, gmin, 0), P(g, gmax, 0), stroke: 0.5pt + grid)
    line(P(gmin, g, 0), P(gmax, g, 0), stroke: 0.5pt + grid)
  }
  // floor border
  line(P(gmin, gmin, 0), P(gmax, gmin, 0), P(gmax, gmax, 0), P(gmin, gmax, 0),
    close: true, stroke: 0.7pt + faint)

  // ── the separating PLANE  z = b  (a flat translucent slab, focal garnet) ────
  let pe = 2.85   // plane half-extent
  line(
    P(-pe, -pe, z-plane), P(pe, -pe, z-plane),
    P(pe, pe, z-plane), P(-pe, pe, z-plane),
    close: true,
    fill: garnet.transparentize(86%), stroke: (paint: garnet, thickness: 1.4pt),
  )

  // ── stems + lifted points ───────────────────────────────────────────────────
  //   inner (⊕) lift LOW (below plane); outer (⊖) lift HIGH (above plane).
  //   draw far points first (rough painter's order by screen-y of the floor pt).
  let lifted = ()
  for p in inner {
    let z = p.at(0) * p.at(0) + p.at(1) * p.at(1)
    lifted.push((x: p.at(0), y: p.at(1), z: z, cls: "in"))
  }
  for p in outer {
    let z = p.at(0) * p.at(0) + p.at(1) * p.at(1)
    lifted.push((x: p.at(0), y: p.at(1), z: z, cls: "out"))
  }
  // depth sort: smaller (x+y) is farther back → draw first
  let lifted = lifted.sorted(key: q => -(q.x + q.y))

  for q in lifted {
    let fp = P(q.x, q.y, 0)         // foot on floor
    let tp = P(q.x, q.y, q.z)       // lifted point
    // faint stem
    line(fp, tp, stroke: 0.5pt + rgb("#C7C7C7"))
    // floor shadow
    circle(fp, radius: 0.035, fill: rgb("#D7D7D7"), stroke: none)
    if q.cls == "in" {
      circle(tp, radius: 0.085, fill: blue, stroke: 0.5pt + white)
    } else {
      circle(tp, radius: 0.085, fill: white, stroke: 1.1pt + green)
    }
  }

  // ── feature-space axes (drawn on top, from origin) ──────────────────────────
  let aL = 3.35
  // x1 axis
  line(P(0, 0, 0), P(aL, 0, 0), stroke: 1pt + ink, mark: (end: "stealth", fill: ink, scale: 0.8))
  content(P(aL + 0.25, 0, 0), text(size: 8pt, fill: ink)[$x_1$])
  // x2 axis
  line(P(0, 0, 0), P(0, aL, 0), stroke: 1pt + ink, mark: (end: "stealth", fill: ink, scale: 0.8))
  content(P(0, aL + 0.35, 0), text(size: 8pt, fill: ink)[$x_2$])
  // z axis (the new radius² coordinate)
  let zL = 6.7
  line(P(0, 0, 0), P(0, 0, zL), stroke: 1.2pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.85))
  content((P(0, 0, zL).at(0) - 0.18, P(0, 0, zL).at(1) - 0.02), anchor: "east",
    box(fill: white.transparentize(10%), inset: 1pt,
      text(size: 8pt, fill: garnet, weight: "bold")[$z = x_1^2 + x_2^2$]))

  // plane label
  content(P(pe, pe, z-plane), anchor: "west",
    box(inset: 1.2pt, fill: white.transparentize(15%),
      text(size: 7.5pt, fill: garnet, weight: "bold")[$z = b$]))

  // panel title  (centered over the right scene)
  let rtx = rox + 1.55
  content((rtx, loy + LPH + 0.92), anchor: "center",
    text(size: 10pt, weight: "bold", fill: ink)[feature space $bb(R)^3$])
  content((rtx, loy + LPH + 0.5), anchor: "center",
    text(size: 7.5pt, fill: muted)[linearly separable — a flat plane suffices])

  // ╔══════════════════════════════════════════════════════════════════════════╗
  // ║  Shared legend + the kernel-trick punchline (bottom band)                   ║
  // ╚══════════════════════════════════════════════════════════════════════════╝
  let by = loy - 1.35
  let bx = lox + 0.1
  // class ⊕
  circle((bx, by), radius: 0.09, fill: blue, stroke: 0.5pt + white)
  content((bx + 0.22, by), anchor: "west",
    text(size: 7.5pt, fill: ink)[class $plus.o$ (inner, low $z$)])
  // class ⊖
  circle((bx + 4.05, by), radius: 0.09, fill: white, stroke: 1.1pt + green)
  content((bx + 4.27, by), anchor: "west",
    text(size: 7.5pt, fill: ink)[class $minus.o$ (outer, high $z$)])
  // boundary swatch
  line((bx + 8.4, by), (bx + 8.9, by), stroke: 2pt + garnet)
  content((bx + 9.05, by), anchor: "west",
    text(size: 7.5pt, fill: ink)[separator: curve $arrow.l.r$ plane])

  // kernel-trick line
  content((lox + (rtx - lox) / 2, by - 0.92), anchor: "center",
    text(size: 8.5pt, fill: ink)[kernel trick: a linear learner needs only
      $chevron.l phi(bold(x)), phi(bold(x')) chevron.r = k(bold(x), bold(x'))$ —
      so $phi$ is never formed explicitly.])
})
