// mlatlas · Gradient-descent trajectories on a 2-D loss surface.
// The loss is an anisotropic quadratic bowl  f(x) = ½(a x₁² + b x₂²)  with a ≪ b,
// i.e. a narrow ravine: gentle along x₁, steep along x₂.  Its level sets  f = c  are
// concentric, axis-aligned ELLIPSES with semi-axes (√(2c/a), √(2c/b)).
//
// From the shared start ●, three first-order optimizers descend toward the minimum ★:
//   · plain GD  — large step ⇒ ZIG-ZAG bouncing across the steep walls (slow in x₁)
//   · momentum  — the velocity term damps the transverse oscillation, glides down the valley
//   · Adam      — per-coordinate adaptive step ⇒ a smooth, near-diagonal path
// Each iterate is a square marker; consecutive iterates are joined by a stealth step arrow
// (the negative-gradient update −η∇f).  Built from first principles in the print-first style.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ────────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid-c = rgb("#ECECEC")
  let cont-c = rgb("#C7C7C7")     // contour lines
  let garnet = rgb("#73000A")     // plain GD — focal accent
  let blue   = rgb("#466A9F")     // momentum
  let green  = rgb("#65780B")     // Adam

  // ── loss surface  f = ½(a x² + b y²) ─────────────────────────────────────────
  let a = 0.6
  let b = 5.0

  // data → canvas mapping.  x∈[X0,X1], y∈[Y0,Y1] onto a PW×PH box.
  let X0 = -4.3
  let X1 = 4.3
  let Y0 = -2.35
  let Y1 = 2.35
  let PW = 9.6
  let PH = 5.25
  let sx(x) = (x - X0) / (X1 - X0) * PW
  let sy(y) = (y - Y0) / (Y1 - Y0) * PH

  // ── plot frame + light grid ──────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)
  for gx in range(-4, 5) {
    if gx > -4 and gx < 4 and calc.abs(sx(gx)) < PW {
      line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c)
    }
  }
  for gy in (-2, -1, 0, 1, 2) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c)
  }

  // ── concentric ellipse level sets  f = c ─────────────────────────────────────
  let n-seg = 96
  let levels = (0.3, 0.9, 1.8, 3.0, 4.5, 6.4)
  for c in levels {
    let ea = calc.sqrt(2 * c / a)   // semi-axis along x
    let eb = calc.sqrt(2 * c / b)   // semi-axis along y
    let ring = range(n-seg + 1).map(i => {
      let t = i / n-seg * 2 * calc.pi
      (sx(ea * calc.cos(t)), sy(eb * calc.sin(t)))
    })
    line(..ring, close: true, stroke: 0.8pt + cont-c)
  }
  // contour direction annotation: f decreases inward toward the minimum
  content((sx(2.95), sy(-1.62)), anchor: "west",
    text(size: 6.5pt, fill: faint, style: "italic")[$f$ decreases inward])

  // ── the trajectories (computed in Python, hard-coded iterates) ───────────────
  let gd = (
    (-3.400, 1.550), (-2.666, -1.240), (-2.090, 0.992), (-1.638, -0.794),
    (-1.285, 0.635), (-1.007, -0.508), (-0.790, 0.406), (-0.619, -0.325),
    (-0.485, 0.260), (-0.380, -0.208),
  )
  let mom = (
    (-3.400, 1.550), (-3.165, 0.659), (-2.802, -0.273), (-2.383, -0.693),
    (-1.959, -0.555), (-1.560, -0.151), (-1.206, 0.187), (-0.903, 0.289),
    (-0.653, 0.186), (-0.453, 0.015), (-0.297, -0.099), (-0.181, -0.113),
    (-0.096, -0.057),
  )
  let adm = (
    (-3.400, 1.550), (-3.100, 1.250), (-2.801, 0.953), (-2.504, 0.664),
    (-2.210, 0.386), (-1.920, 0.128), (-1.635, -0.103), (-1.357, -0.298),
    (-1.088, -0.449), (-0.829, -0.554), (-0.582, -0.612), (-0.350, -0.628),
    (-0.135, -0.607), (0.062, -0.555), (0.239, -0.481), (0.394, -0.389),
  )

  // draw one optimizer path: stealth step arrows + square iterate markers
  let traj(path, col, msz: 0.066, last: false) = {
    // step arrows first (so markers sit on top)
    for i in range(path.len() - 1) {
      let p = (sx(path.at(i).at(0)),     sy(path.at(i).at(1)))
      let q = (sx(path.at(i + 1).at(0)), sy(path.at(i + 1).at(1)))
      line(p, q, stroke: 1.15pt + col, mark: (end: "stealth", scale: 0.42))
    }
    // square markers
    for (j, pt) in path.enumerate() {
      let cx = sx(pt.at(0))
      let cy = sy(pt.at(1))
      if j == 0 { continue }       // start drawn once, separately
      let m = msz
      rect((cx - m, cy - m), (cx + m, cy + m),
        fill: white, stroke: 0.9pt + col, radius: 0pt)
    }
  }

  // draw in back-to-front order; garnet GD on top as the focal path
  traj(adm, green)
  traj(mom, blue)
  traj(gd,  garnet)

  // ── shared start point ● ─────────────────────────────────────────────────────
  let sp = gd.at(0)
  circle((sx(sp.at(0)), sy(sp.at(1))), radius: 0.115, fill: ink, stroke: none)
  content((sx(sp.at(0)) - 0.18, sy(sp.at(1)) + 0.30), anchor: "south-east",
    text(size: 8pt, fill: ink)[$bold(x)^((0))$])

  // ── minimum ★ at the origin ──────────────────────────────────────────────────
  let star(cx, cy, r, col) = {
    let pts = range(10).map(k => {
      let ang = calc.pi / 2 + k * calc.pi / 5
      let rr = if calc.rem(k, 2) == 0 { r } else { r * 0.42 }
      (cx + rr * calc.cos(ang), cy + rr * calc.sin(ang))
    })
    line(..pts, close: true, fill: col, stroke: 0.5pt + col)
  }
  star(sx(0), sy(0), 0.26, garnet)
  content((sx(0) + 0.28, sy(0) - 0.34), anchor: "north-west",
    text(size: 8pt, fill: garnet)[$bold(x)^*$])

  // ── axes: ticks + labels ─────────────────────────────────────────────────────
  for gx in range(-4, 5) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
    content((sx(gx), -0.34), text(size: 7pt, fill: muted)[#gx])
  }
  for gy in (-2, -1, 0, 1, 2) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
    content((-0.30, sy(gy)), anchor: "east", text(size: 7pt, fill: muted)[#gy])
  }
  content((PW / 2, -0.78), text(size: 9pt, fill: ink)[$x_1$ #h(0.3em) (gentle direction)])
  content((-1.02, PH / 2), text(size: 9pt, fill: ink)[$x_2$])

  // ── title + subtitle ─────────────────────────────────────────────────────────
  content((PW / 2, PH + 1.04),
    text(size: 11pt, weight: "bold", fill: ink)[Gradient-descent trajectories on a loss surface])
  content((PW / 2, PH + 0.58),
    text(size: 8pt, fill: muted)[update $bold(x)^((t+1)) = bold(x)^((t)) - eta thin gradient f(bold(x)^((t)))$  on the bowl  $f(bold(x)) = 1/2(a thin x_1^2 + b thin x_2^2),  a << b$])

  // ── legend (right side) ──────────────────────────────────────────────────────
  let lx = PW + 0.55
  let ly = PH - 0.25
  let leg(i, col, name, note) = {
    let yy = ly - i * 1.02
    // a short sample segment with a square marker
    line((lx, yy), (lx + 0.66, yy), stroke: 1.15pt + col, mark: (end: "stealth", scale: 0.42))
    let m = 0.066
    rect((lx + 0.30 - m, yy - m), (lx + 0.30 + m, yy + m),
      fill: white, stroke: 0.9pt + col, radius: 0pt)
    content((lx + 0.86, yy + 0.005), anchor: "west",
      text(size: 8.5pt, weight: "bold", fill: col)[#name])
    content((lx, yy - 0.40), anchor: "west",
      text(size: 7pt, fill: muted)[#note])
  }
  leg(0, garnet, [plain GD],  [large step → zig-zag])
  leg(1, blue,   [momentum],  [velocity damps oscillation])
  leg(2, green,  [Adam],      [per-coord. adaptive step])

  // start / minimum keys
  let ky = ly - 3.28
  circle((lx + 0.30, ky), radius: 0.10, fill: ink, stroke: none)
  content((lx + 0.86, ky), anchor: "west", text(size: 8pt, fill: ink)[start $bold(x)^((0))$])
  star(lx + 0.30, ky - 0.62, 0.18, garnet)
  content((lx + 0.86, ky - 0.62), anchor: "west", text(size: 8pt, fill: ink)[minimum $bold(x)^*$])

  // contour key
  line((lx + 0.04, ky - 1.32), (lx + 0.56, ky - 1.32), stroke: 0.8pt + cont-c)
  content((lx + 0.86, ky - 1.32), anchor: "west",
    text(size: 7.5pt, fill: muted)[level set $f = c$])
})
