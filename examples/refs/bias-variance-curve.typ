// mlatlas · Bias–variance tradeoff (ESL ch.7; ISLR/ISLP §2.2; UML; UDL).
// Prediction error decomposed against model complexity:
//
//     E[(y - f̂(x))²]  =  Bias²[f̂]  +  Var[f̂]  +  σ²        (irreducible noise)
//
//   • Bias²       falls monotonically as the model grows more flexible.
//   • Variance    rises monotonically as the model grows more flexible.
//   • Test error  = bias² + variance + σ²  → U-shaped (the sum of the two).
//   • Train error falls monotonically toward 0 (overfitting the sample).
//   • The optimum complexity sits at the U-trough — the bias–variance sweet
//     spot, where ∂(bias²)/∂c = −∂(var)/∂c. Left of it: UNDERFIT (high bias);
//     right of it: OVERFIT (high variance).
//
// Curves are closed-form and sampled in Typst, then drawn in cetz (print-first
// house style: light panel, dark ink, sharp corners, garnet test curve accent).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── palette ───────────────────────────────────────────────────────────────
  let ink    = rgb("#1A1A1A")
  let axiscol = rgb("#363636")
  let muted  = rgb("#5C5C5C")
  let faint  = rgb("#A2A2A2")
  let grid   = rgb("#ECECEC")
  let garnet = rgb("#73000A")   // test / expected error  (focal accent)
  let blue   = rgb("#466A9F")   // variance
  let green  = rgb("#65780B")   // bias²
  let redx   = rgb("#CC2E40")   // train error
  let beige  = rgb("#FFF2E3")

  // ── plot frame in cetz units ──────────────────────────────────────────────
  // model complexity c ∈ [0,1] on x; error on y ∈ [0,1] mapped to the box.
  let W = 9.6           // panel width  (cm)
  let H = 6.2           // panel height (cm)
  let x0 = 0            // left
  let y0 = 0            // bottom
  let N  = 121          // samples per curve

  // map (c, e) in [0,1]×[0,1] to canvas coords
  let X(c) = x0 + c * W
  let Y(e) = y0 + e * H

  // ── component curves (closed form on c ∈ [0,1]) ───────────────────────────
  let sigma2 = 0.12                                  // irreducible noise floor
  // bias² : high at low complexity, decays toward ~0
  let bias2(c) = 0.62 * calc.pow(2.718281828, -3.4 * c)
  // variance : low at low complexity, grows (accelerating) with flexibility
  let varc(c) = 0.045 + 0.70 * calc.pow(c, 2.3)
  // expected test error = bias² + variance + σ²
  let test(c) = bias2(c) + varc(c) + sigma2
  // train error : monotone fall toward ~0 (overfits the sample), starting
  // below bias² and decaying faster so the two curves stay visually distinct.
  let train(c) = 0.50 * calc.pow(2.718281828, -5.2 * c) + 0.008

  // sample a curve f over the panel → array of (x,y) canvas points
  let samp(f) = range(N + 1).map(i => {
    let c = i / N
    (X(c), Y(f(c)))
  })

  // find the c that minimises test() on a fine grid (the optimum)
  let copt = 0
  let best = 1e9
  for i in range(N + 1) {
    let c = i / N
    let v = test(c)
    if v < best { best = v; copt = c }
  }

  // ── grid + panel ──────────────────────────────────────────────────────────
  rect((X(0), Y(0)), (X(1), Y(1)), fill: white, stroke: none)
  // faint horizontal gridlines
  for k in range(1, 5) {
    let e = k / 5
    line((X(0), Y(e)), (X(1), Y(e)), stroke: 0.4pt + grid)
  }

  // ── irreducible-error band (σ²) along the bottom ─────────────────────────
  rect(
    (X(0), Y(0)), (X(1), Y(sigma2)),
    fill: beige, stroke: none,
  )
  line((X(0), Y(sigma2)), (X(1), Y(sigma2)), stroke: (paint: faint, dash: "dashed", thickness: 0.6pt))
  content(
    (X(0.985), Y(sigma2 / 2)),
    text(fill: muted, size: 7.5pt)[#h(0pt)irreducible error $sigma^2$],
    anchor: "east",
  )

  // ── a curve as a polyline ─────────────────────────────────────────────────
  let curve(f, col, w: 1.6pt, dash: none) = {
    let pts = samp(f)
    line(..pts, stroke: (paint: col, thickness: w, dash: dash))
  }

  // draw component curves first (thinner), then the headline curves on top
  curve(bias2, green, w: 1.3pt)
  curve(varc,  blue,  w: 1.3pt)
  curve(train, redx,  w: 1.3pt, dash: "dashed")
  curve(test,  garnet, w: 2.2pt)            // focal: U-shaped expected error

  // ── optimum marker: vertical line + dot at the U-trough ──────────────────
  line(
    (X(copt), Y(0)), (X(copt), Y(test(copt))),
    stroke: (paint: garnet, dash: "dotted", thickness: 0.9pt),
  )
  circle((X(copt), Y(test(copt))), radius: 0.085, fill: garnet, stroke: 0.6pt + white)

  // ── under/over-fit zone labels ───────────────────────────────────────────
  content(
    (X(copt / 2), Y(0.93)),
    text(fill: muted, size: 8pt, style: "italic")[underfit],
  )
  content(
    (X(copt / 2), Y(0.865)),
    text(fill: faint, size: 6.8pt)[(high bias)],
  )
  content(
    (X(copt + (1 - copt) / 2), Y(0.93)),
    text(fill: muted, size: 8pt, style: "italic")[overfit],
  )
  content(
    (X(copt + (1 - copt) / 2), Y(0.865)),
    text(fill: faint, size: 6.8pt)[(high variance)],
  )
  // optimum tick label under the axis
  content(
    (X(copt), Y(0) - 0.34),
    text(fill: garnet, size: 7.5pt)[optimal],
    anchor: "north",
  )
  content(
    (X(copt), Y(0) - 0.66),
    text(fill: garnet, size: 7.5pt)[complexity],
    anchor: "north",
  )
  // small caret on the x-axis at the optimum
  line((X(copt), Y(0)), (X(copt), Y(0) - 0.14), stroke: 1pt + garnet)

  // ── inline curve labels (placed near each curve's right end) ──────────────
  // expected test error
  content(
    (X(1.0) + 0.18, Y(test(1.0))),
    text(fill: garnet, size: 8pt, weight: "bold")[expected],
    anchor: "west",
  )
  content(
    (X(1.0) + 0.18, Y(test(1.0)) - 0.34),
    text(fill: garnet, size: 8pt, weight: "bold")[test error],
    anchor: "west",
  )
  // variance
  content(
    (X(1.0) + 0.18, Y(varc(1.0))),
    text(fill: blue, size: 8pt)[variance],
    anchor: "west",
  )
  // bias² — label near its left/upper region where it dominates
  content(
    (X(0.135), Y(bias2(0.135)) + 0.34),
    text(fill: green, size: 8pt)[bias#super[2]],
    anchor: "west",
  )
  // train error  (in the white space just right of the steep descent)
  content(
    (X(0.235), Y(train(0.105))),
    text(fill: redx, size: 8pt)[train error],
    anchor: "west",
  )

  // ── axes (drawn last, on top) ─────────────────────────────────────────────
  // y-axis
  line((X(0), Y(0)), (X(0), Y(1)), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))
  // x-axis
  line((X(0), Y(0)), (X(1) + 0.05, Y(0)), stroke: 1pt + axiscol, mark: (end: "stealth", scale: 0.5))

  // axis titles
  content(
    (X(0.5), Y(0) - 1.02),
    text(fill: ink, size: 9.5pt)[model complexity / flexibility #h(0.4em) #text(fill: faint, size: 7.5pt)[(low #sym.arrow.r high)]],
    anchor: "north",
  )
  content(
    (X(0) - 0.62, Y(0.5)),
    angle: 90deg,
    text(fill: ink, size: 9.5pt)[prediction error],
    anchor: "south",
  )
})
