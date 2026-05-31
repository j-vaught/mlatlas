// mlatlas · K-means clustering and its induced Voronoi partition.
//   K-means minimises within-cluster scatter  Σ_k Σ_{x∈C_k} ‖x − μ_k‖²
//   by alternating (E) hard nearest-centroid assignment and (M) centroid update
//   μ_k = mean of the points assigned to cluster k.
// Because assignment is "nearest centroid in Euclidean distance", the cluster
// regions are exactly the VORONOI cells of the centroids: each cell boundary is
// a segment of the perpendicular bisector between two centroids, and (for K=3)
// all three bisectors meet at one Voronoi vertex equidistant from every μ_k.
// Standard ESL / ISLP / MML teaching figure, built from scratch in mlatlas's
// print-first house style. No image was traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── cluster colours (garnet accent + brand blue + dark-green) ────────────────
#let c0 = rgb("#73000A") // garnet  — cluster 1 (focal accent)
#let c1 = rgb("#466A9F") // blue    — cluster 2
#let c2 = rgb("#65780B") // green   — cluster 3
#let cols = (c0, c1, c2)
// light cell tints (the desaturated cousins of the marker colours)
#let tints = (rgb("#F4DADC"), rgb("#DCE4EF"), rgb("#E8ECD2"))
#let ink   = rgb("#222222")
#let muted = rgb("#5C5C5C")
#let grid-c = rgb("#ECECEC")
#let bd-c   = rgb("#363636")  // Voronoi boundary

// data world [0,10]×[0,10] → canvas box
#let X0 = 0
#let X1 = 10
#let Y0 = 0
#let Y1 = 10
#let PW = 8.2   // plot width  (cm)
#let PH = 8.2   // plot height (cm)
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH

// ── the data: (x, y, cluster) after K-means has converged ────────────────────
#let pts = (
  (1.585, 6.427, 0), (2.458, 7.565, 0), (3.137, 7.759, 0), (3.116, 6.628, 0),
  (1.731, 7.202, 0), (3.076, 7.608, 0), (2.333, 7.056, 0), (3.192, 6.870, 0),
  (2.186, 7.203, 0), (2.861, 6.603, 0), (1.430, 6.718, 0), (2.268, 8.469, 0),
  (3.057, 6.782, 0), (3.548, 6.576, 0), (2.008, 6.740, 0), (2.791, 8.209, 0),
  (8.760, 6.146, 1), (8.482, 5.432, 1), (8.903, 6.781, 1), (6.463, 8.005, 1),
  (7.049, 7.469, 1), (6.959, 7.080, 1), (7.795, 5.230, 1), (8.342, 8.091, 1),
  (7.224, 6.975, 1), (6.623, 8.311, 1), (7.650, 7.160, 1), (7.543, 6.799, 1),
  (8.623, 6.272, 1), (8.162, 7.388, 1), (6.995, 6.047, 1),
  (4.869, 3.723, 2), (5.429, 2.081, 2), (6.119, 2.106, 2), (5.396, 1.879, 2),
  (3.797, 2.177, 2), (4.730, 3.520, 2), (3.783, 2.222, 2), (4.633, 3.026, 2),
  (5.383, 1.472, 2), (4.346, 3.078, 2), (4.772, 1.932, 2), (5.236, 2.246, 2),
  (5.085, 3.493, 2), (3.651, 2.793, 2), (4.461, 2.953, 2), (5.020, 2.553, 2),
  (5.564, 2.671, 2),
)

// converged centroids μ_k = mean of cluster k
#let cents = (
  (2.548, 7.151),
  (7.705, 6.879),
  (4.840, 2.584),
)

// Voronoi vertex (circumcentre of the centroid triangle — equidistant from all μ_k)
#let vor = (5.049, 5.547)

// the three boundary segments: from the Voronoi vertex out to the plot edge
// (each on the perpendicular bisector of a centroid pair)
#let bisectors = (
  (vor, (5.284, 10.000)),   // μ₁ | μ₂
  (vor, (10.000, 2.245)),   // μ₂ | μ₃
  (vor, (0.000, 3.013)),    // μ₁ | μ₃
)

// Voronoi cell polygons (data coords) — for the light region fills
#let cells = (
  ((0.000, 3.013), (5.049, 5.547), (5.284, 10.000), (0.000, 10.000)),
  ((5.049, 5.547), (10.000, 2.245), (10.000, 10.000), (5.284, 10.000)),
  ((0.000, 0.000), (10.000, 0.000), (10.000, 2.245), (5.049, 5.547), (0.000, 3.013)),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── Voronoi cell fills (drawn first, sit under grid + points) ───────────────
  for (k, poly) in cells.enumerate() {
    let scr = poly.map(p => (sx(p.at(0)), sy(p.at(1))))
    line(..scr, close: true, fill: tints.at(k), stroke: none)
  }

  // light interior grid (every world unit), sharp, behind the points
  for gx in range(1, 10) {
    line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c)
  }
  for gy in range(1, 10) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c)
  }

  // ── Voronoi boundaries (perpendicular bisectors) ────────────────────────────
  for seg in bisectors {
    let a = seg.at(0)
    let b = seg.at(1)
    line((sx(a.at(0)), sy(a.at(1))), (sx(b.at(0)), sy(b.at(1))),
      stroke: (paint: bd-c, thickness: 1.5pt, dash: "dashed"))
  }

  // ── data points, square markers coloured by hard cluster assignment ─────────
  let hm = 0.085   // marker half-width
  for p in pts {
    let (x, y, k) = p
    let cx = sx(x)
    let cy = sy(y)
    rect((cx - hm, cy - hm), (cx + hm, cy + hm),
      fill: cols.at(k), stroke: 0.4pt + white)
  }

  // ── centroids: bold X glyph (+ white halo) and label μ_k ────────────────────
  for (k, m) in cents.enumerate() {
    let mx = sx(m.at(0))
    let my = sy(m.at(1))
    let h = 0.26
    // white halo so the X reads over the tinted cell
    line((mx - h, my - h), (mx + h, my + h), stroke: 3pt + white)
    line((mx - h, my + h), (mx + h, my - h), stroke: 3pt + white)
    line((mx - h, my - h), (mx + h, my + h), stroke: 2pt + cols.at(k))
    line((mx - h, my + h), (mx + h, my - h), stroke: 2pt + cols.at(k))
  }
  // labels placed manually to avoid the centroid glyphs
  let lab(m, dx, dy, k, body) = {
    let lp = (sx(m.at(0)) + dx, sy(m.at(1)) + dy)
    rect((lp.at(0) - 0.30, lp.at(1) - 0.19), (lp.at(0) + 0.30, lp.at(1) + 0.19),
      fill: white.transparentize(10%), stroke: none)
    content(lp, text(size: 9pt, weight: "bold", fill: cols.at(k))[#body])
  }
  lab(cents.at(0), 0.62, 0.46, 0, $bold(mu)_1$)
  lab(cents.at(1), 0.70, 0.48, 1, $bold(mu)_2$)
  lab(cents.at(2), 0.70, 0.44, 2, $bold(mu)_3$)

  // mark the Voronoi vertex (equidistant point)
  circle((sx(vor.at(0)), sy(vor.at(1))), radius: 0.075,
    fill: white, stroke: 1pt + bd-c)
  content((sx(vor.at(0)) + 0.05, sy(vor.at(1)) - 0.40),
    text(size: 6.5pt, fill: muted, style: "italic")[equidistant])

  // ── plot frame + axis ticks/labels (over the fills) ─────────────────────────
  rect((0, 0), (PW, PH), fill: none, stroke: 1pt + ink)
  for gx in range(0, 11, step: 2) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    content((sx(gx), -0.34), text(size: 7pt, fill: muted)[#gx])
  }
  for gy in range(0, 11, step: 2) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    content((-0.32, sy(gy)), text(size: 7pt, fill: muted)[#gy])
  }
  content((PW / 2, -0.82), text(size: 9pt, fill: ink)[$x_1$])
  content((-0.92, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title + objective ───────────────────────────────────────────────────────
  content((PW / 2, PH + 0.80),
    text(size: 11pt, weight: "bold", fill: ink)[K-means clustering — Voronoi assignment regions])
  content((PW / 2, PH + 0.38),
    text(size: 8pt, fill: muted)[$min_({C_k}, {bold(mu)_k}) sum_(k=1)^3 sum_(bold(x) in C_k) norm(bold(x) - bold(mu)_k)^2$])

  // ── legend (right side) ─────────────────────────────────────────────────────
  let lx = PW + 0.55
  let ly = PH - 0.4
  let hmL = 0.12
  let row(i, k, lbl) = {
    let yy = ly - i * 0.62
    rect((lx - hmL, yy - hmL), (lx + hmL, yy + hmL),
      fill: cols.at(k), stroke: 0.4pt + white)
    content((lx + 0.34, yy), anchor: "west", text(size: 8pt, fill: ink)[#lbl])
  }
  row(0, 0, [cluster $C_1$])
  row(1, 1, [cluster $C_2$])
  row(2, 2, [cluster $C_3$])

  // centroid key
  let cy0 = ly - 3.0
  let h = 0.13
  line((lx - h, cy0 - h), (lx + h, cy0 + h), stroke: 1.8pt + ink)
  line((lx - h, cy0 + h), (lx + h, cy0 - h), stroke: 1.8pt + ink)
  content((lx + 0.34, cy0), anchor: "west", text(size: 8pt, fill: ink)[centroid $bold(mu)_k$])

  // boundary key
  let cy1 = ly - 3.62
  line((lx - 0.18, cy1), (lx + 0.18, cy1),
    stroke: (paint: bd-c, thickness: 1.5pt, dash: "dashed"))
  content((lx + 0.34, cy1), anchor: "west", text(size: 8pt, fill: ink)[cell boundary])
  content((lx - 0.18, cy1 - 0.46), anchor: "west",
    text(size: 6.8pt, fill: muted)[perp. bisector])
  content((lx - 0.18, cy1 - 0.86), anchor: "west",
    text(size: 6.8pt, fill: muted)[of $bold(mu)_i, bold(mu)_j$])

  // assignment rule note
  content((lx - 0.18, cy1 - 1.6), anchor: "west",
    text(size: 7.5pt, fill: ink)[assign $bold(x)$ to])
  content((lx - 0.18, cy1 - 2.0), anchor: "west",
    text(size: 7.5pt, fill: ink)[$arg min_k norm(bold(x) - bold(mu)_k)$])
})
