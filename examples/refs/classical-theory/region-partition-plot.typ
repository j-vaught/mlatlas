// mlatlas · ReLU region partition / piecewise-linear function.
// A deep ReLU network is continuous PIECEWISE-LINEAR: it carves input space into
// convex polytope regions, and on each region the network is a single AFFINE map.
//
//   PANEL A (1-D):  f(x) = w₂·ReLU(W₁x + b₁) + b₂  is a polyline.  Every hidden
//   unit i contributes a KINK (breakpoint) where its pre-activation crosses 0,
//   i.e. at x = −b₁ᵢ/W₁ᵢ.  Between consecutive kinks the slope is constant —
//   the active set (which units fire) is fixed, so f is affine there.
//
//   PANEL B (2-D):  each first-layer unit i defines a hyperplane aᵢ·x + cᵢ = 0.
//   The 5 lines tessellate the plane into convex polytopes; on each, the sign
//   pattern (active set) of all units is constant, so the net is affine.  Fill
//   tint encodes the NUMBER OF ACTIVE units (darker = more units firing).  The
//   number of regions grows fast with depth/width — the source of expressivity.
//
// All breakpoints, region polygons and hyperplane endpoints are computed exactly
// from the chosen weights; nothing is traced.  Built in the print-first style.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── palette ─────────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid-c = rgb("#ECECEC")
  let frame  = rgb("#363636")
  let garnet = rgb("#73000A")     // sparse focal accent
  let blue   = rgb("#466A9F")

  // five tints keyed by number of active ReLU units (0..4): light → less light
  let tint = (
    rgb("#FFFFFF"),   // 0 active
    rgb("#F1E7DA"),   // 1   (warm beige)
    rgb("#E2EAF1"),   // 2   (light blue)
    rgb("#D5CEDB"),   // 3   (light violet-grey)
    rgb("#C7C7C7"),   // 4   (30% black)
  )

  // ════════════════════════════════════════════════════════════════════════════
  //  PANEL A — 1-D piecewise-linear network output
  // ════════════════════════════════════════════════════════════════════════════
  // data box: x∈[0,10], y∈[0,3.6] → AW × AH cm.
  // raise it by AY0 so panel A is vertically centred against panel B (height ≈6.2)
  let AW = 8.0
  let AH = 4.2
  let AY0 = 1.0
  let ax(x) = x / 10 * AW
  let ay(y) = AY0 + y / 3.6 * AH

  // frame + light grid
  draw.rect((0, AY0), (AW, AY0 + AH), fill: white, stroke: 1pt + frame, radius: 0pt)
  for gx in (2, 4, 6, 8) {
    draw.line((ax(gx), AY0), (ax(gx), AY0 + AH), stroke: 0.5pt + grid-c)
  }
  for gy in (1, 2, 3) {
    draw.line((0, ay(gy)), (AW, ay(gy)), stroke: 0.5pt + grid-c)
  }

  // polyline nodes (endpoints + 5 kinks), computed from the chosen weights
  let nodes = (
    (0.0, 0.50), (1.4, 0.50), (3.1, 2.71), (4.8, 1.35),
    (6.6, 3.15), (8.3, 2.30), (10.0, 3.32),
  )
  let bps = (1.4, 3.1, 4.8, 6.6, 8.3)   // breakpoints (kink locations)

  // shade alternating affine pieces faintly to read them as distinct regions
  for i in range(nodes.len() - 1) {
    let x0 = nodes.at(i).at(0)
    let x1 = nodes.at(i + 1).at(0)
    let t = if calc.rem(i, 2) == 0 { rgb("#F6F6F6") } else { rgb("#FFFFFF") }
    draw.rect((ax(x0), AY0), (ax(x1), AY0 + AH), fill: t, stroke: none)
  }
  // re-draw grid on top of shading (so it stays visible)
  for gy in (1, 2, 3) {
    draw.line((0, ay(gy)), (AW, ay(gy)), stroke: 0.5pt + grid-c)
  }

  // dashed vertical drop-lines at each breakpoint
  for bx in bps {
    draw.line((ax(bx), AY0), (ax(bx), AY0 + AH),
      stroke: (paint: faint, thickness: 0.55pt, dash: "densely-dashed"))
  }

  // the piecewise-linear curve (garnet — the focal object)
  let pl = nodes.map(p => (ax(p.at(0)), ay(p.at(1))))
  draw.line(..pl, stroke: 1.6pt + garnet)

  // kink markers (open squares) at every breakpoint
  for (i, p) in nodes.enumerate() {
    if i == 0 or i == nodes.len() - 1 { continue }   // skip endpoints
    let cx = ax(p.at(0))
    let cy = ay(p.at(1))
    let m = 0.075
    draw.rect((cx - m, cy - m), (cx + m, cy + m),
      fill: white, stroke: 1pt + garnet, radius: 0pt)
  }

  // axes ticks + labels
  for gx in (0, 2, 4, 6, 8, 10) {
    draw.line((ax(gx), AY0), (ax(gx), AY0 - 0.12), stroke: 0.8pt + frame)
    draw.content((ax(gx), AY0 - 0.33), text(size: 7pt, fill: muted)[#gx])
  }
  for gy in (0, 1, 2, 3) {
    draw.line((0, ay(gy)), (-0.12, ay(gy)), stroke: 0.8pt + frame)
    draw.content((-0.30, ay(gy)), anchor: "east", text(size: 7pt, fill: muted)[#gy])
  }
  draw.content((AW / 2, AY0 - 0.72), text(size: 9pt, fill: ink)[input $x$])
  draw.content((-0.86, AY0 + AH / 2), text(size: 9pt, fill: ink)[$f(x)$])

  // annotate: a kink, and the affine-piece reading
  draw.content((ax(4.8), ay(1.35) - 0.46),
    text(size: 6.8pt, fill: garnet, style: "italic")[kink])
  draw.line((ax(4.8), ay(1.35) - 0.30), (ax(4.8), ay(1.35) - 0.12),
    stroke: 0.5pt + garnet)
  draw.content((ax(5.7), ay(3.32)),
    text(size: 6.8pt, fill: muted, style: "italic")[affine on each piece])

  // breakpoint formula
  draw.content((AW / 2, AY0 + AH + 0.92),
    text(size: 8pt, fill: muted)[$f(x) = bold(w)_2 dot "ReLU"(bold(W)_1 x + bold(b)_1) + b_2$ #h(0.6em) — #h(0.3em) #text(fill: ink)[5 hidden units → 5 kinks]])

  // panel title
  draw.content((AW / 2, AY0 + AH + 1.42),
    text(size: 9.5pt, weight: "bold", fill: ink)[A — 1-D piecewise-linear function])

  // ════════════════════════════════════════════════════════════════════════════
  //  PANEL B — 2-D input-plane tessellation into convex polytopes
  // ════════════════════════════════════════════════════════════════════════════
  // place to the right of panel A
  let ox = AW + 2.6           // left edge (canvas units)
  let oy = 0.0                // bottom edge
  let BS = 0.62               // 1 data unit = 0.62 cm  → 10 units ≈ 6.2 cm
  let bx(x) = ox + x * BS
  let by(y) = oy + y * BS

  // exact convex-polytope regions (computed from the 5 first-layer hyperplanes).
  // n = number of active ReLU units on that region (drives fill tint).
  let regions = (
    (n: 0, v: ((-0.000,2.700), (-0.000,0.000), (2.400,-0.000), (5.550,3.500), (4.397,5.596), (4.239,5.667))),
    (n: 1, v: ((4.397,5.596), (4.325,5.727), (4.239,5.667))),
    (n: 1, v: ((2.400,-0.000), (7.475,-0.000), (5.550,3.500))),
    (n: 1, v: ((-0.000,2.700), (4.239,5.667), (-0.000,7.575))),
    (n: 2, v: ((-0.000,7.575), (4.239,5.667), (4.325,5.727), (3.167,7.833), (1.000,10.000), (-0.000,10.000))),
    (n: 3, v: ((3.167,7.833), (1.975,10.000), (1.000,10.000))),
    (n: 1, v: ((5.550,3.500), (6.474,4.526), (6.227,4.773), (4.397,5.596))),
    (n: 2, v: ((6.474,4.526), (6.560,4.623), (6.227,4.773))),
    (n: 2, v: ((6.227,4.773), (4.882,6.118), (4.325,5.727), (4.397,5.596))),
    (n: 3, v: ((4.882,6.118), (6.227,4.773), (6.560,4.623), (10.000,8.444), (10.000,9.700))),
    (n: 2, v: ((7.475,-0.000), (10.000,-0.000), (10.000,1.000), (6.474,4.526), (5.550,3.500))),
    (n: 3, v: ((10.000,1.000), (10.000,3.075), (6.560,4.623), (6.474,4.526))),
    (n: 4, v: ((6.560,4.623), (10.000,3.075), (10.000,8.444))),
    (n: 3, v: ((4.325,5.727), (4.882,6.118), (3.167,7.833))),
    (n: 4, v: ((3.167,7.833), (4.882,6.118), (10.000,9.700), (10.000,10.000), (1.975,10.000))),
  )

  // fill every polytope (sign pattern constant ⇒ affine on it)
  for r in regions {
    let poly = r.v.map(p => (bx(p.at(0)), by(p.at(1))))
    draw.line(..poly, close: true,
      fill: tint.at(r.n), stroke: 0.4pt + rgb("#FFFFFF"))
  }

  // the 5 hidden-unit hyperplanes aᵢ·x + cᵢ = 0, clipped to the box.
  // unit 0 drawn in garnet as the focal accent; others neutral.
  let hyperplanes = (
    ((7.475,0.000), (1.975,10.000)),
    ((0.000,2.700), (10.000,9.700)),
    ((10.000,8.444), (2.400,0.000)),
    ((0.000,7.575), (10.000,3.075)),
    ((10.000,1.000), (1.000,10.000)),
  )
  for (i, h) in hyperplanes.enumerate() {
    let col = if i == 0 { garnet } else { frame }
    let w = if i == 0 { 1.5pt } else { 1pt }
    draw.line((bx(h.at(0).at(0)), by(h.at(0).at(1))),
              (bx(h.at(1).at(0)), by(h.at(1).at(1))),
      stroke: w + col)
  }
  // label the focal hyperplane
  draw.content((bx(2.4), by(9.6)), anchor: "south-west",
    text(size: 7pt, fill: garnet, style: "italic")[$bold(a)_1 dot bold(x) + c_1 = 0$])

  // box frame on top
  draw.rect((bx(0), by(0)), (bx(10), by(10)),
    fill: none, stroke: 1.1pt + frame, radius: 0pt)

  // axes ticks + labels
  for v in (0, 2, 4, 6, 8, 10) {
    draw.line((bx(v), by(0)), (bx(v), by(0) - 0.13), stroke: 0.8pt + frame)
    draw.content((bx(v), by(0) - 0.34), text(size: 7pt, fill: muted)[#v])
    draw.line((bx(0), by(v)), (bx(0) - 0.13, by(v)), stroke: 0.8pt + frame)
    draw.content((bx(0) - 0.32, by(v)), anchor: "east", text(size: 7pt, fill: muted)[#v])
  }
  draw.content((bx(5), by(0) - 0.74), text(size: 9pt, fill: ink)[$x_1$])
  draw.content((bx(0) - 0.82, by(5)), text(size: 9pt, fill: ink)[$x_2$])

  // annotate one polytope as "affine here"
  draw.content((bx(2.9), by(2.9)),
    text(size: 6.8pt, fill: muted, style: "italic")[net is\ affine\ here])

  // panel title + subtitle
  draw.content((bx(5), by(10) + 1.42),
    text(size: 9.5pt, weight: "bold", fill: ink)[B — 2-D polytope partition])
  draw.content((bx(5), by(10) + 0.92),
    text(size: 8pt, fill: muted)[5 first-layer units → #text(fill: ink)[15 convex regions]])

  // ── legend: tint ↔ number of active units ────────────────────────────────────
  let lx = bx(10) + 0.55
  let ly = by(10) - 0.1
  draw.content((lx, ly + 0.42), anchor: "west",
    text(size: 7.5pt, weight: "bold", fill: ink)[active ReLU units])
  for k in range(5) {
    let yy = ly - k * 0.58
    draw.rect((lx, yy - 0.18), (lx + 0.36, yy + 0.18),
      fill: tint.at(k), stroke: 0.7pt + frame, radius: 0pt)
    draw.content((lx + 0.52, yy), anchor: "west",
      text(size: 7.5pt, fill: muted)[#k])
  }
  // hyperplane key
  let ky = ly - 5 * 0.58 - 0.18
  draw.line((lx, ky), (lx + 0.36, ky), stroke: 1.5pt + garnet)
  draw.content((lx + 0.52, ky), anchor: "west",
    text(size: 7pt, fill: muted)[unit's\ hyperplane])

  // ── overall caption tying the two panels (centred across the whole figure) ───
  draw.content(((0 + (bx(10) + 2.2)) / 2, by(0) - 1.28),
    text(size: 7.5pt, fill: muted, style: "italic")[continuous piecewise-linear: the network is affine on each region; region boundaries are exactly where some ReLU switches sign])
})
