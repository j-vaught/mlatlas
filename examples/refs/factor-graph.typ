// Factor graph — bipartite variable / factor representation of a joint distribution.
// Built from first principles in mlatlas print-first style (not traced).
//
// A factor graph makes the FACTORIZATION of a joint distribution explicit. For
//      p(x1,x2,x3,x4) ∝ f_a(x1,x2) · f_b(x2,x3) · f_c(x2,x4)
// it draws a BIPARTITE graph: round VARIABLE nodes (x_i) and small filled SQUARE
// FACTOR nodes (f_*), joined by an undirected incidence edge wherever a variable
// is an argument of a factor. There are no variable–variable or factor–factor edges.
// This is the substrate on which sum–product (belief propagation) passes messages:
//   - variable→factor:  mu_{x→f}(x) = prod over other factors of incoming messages
//   - factor→variable:  mu_{f→x}(x) = sum over the factor's other variables of
//                        f(..) · prod of their incoming messages
// One such message pair is drawn in garnet as the focal annotation.
// Sources confirm conventions only (Bishop PRML §8.4; MacKay; Barber BRML; Murphy).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let c-var = rgb("#ECECEC") // 10% black — variable-node fill
#let c-fac = rgb("#363636") // 90% black — filled factor square
#let edge = rgb("#5C5C5C")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let rv = 0.46 // variable circle radius
  let sf = 0.30 // factor square half-side

  // ---- node coordinates ------------------------------------------------------
  // Variables across the top row; factors sit between the variables they couple.
  // x2 is the hub variable (appears in all three factors).
  let X1 = (-3.2, 1.7)
  let X2 = (0.0, 1.7)
  let X3 = (3.2, 1.7)
  let X4 = (0.0, -1.7) // hangs below the hub

  let Fa = (-1.6, 1.7) // f_a(x1,x2)
  let Fb = (1.6, 1.7) // f_b(x2,x3)
  let Fc = (0.0, 0.0) // f_c(x2,x4)

  // ---- incidence edges (undirected) — drawn first, behind nodes --------------
  let inc(a, b) = draw.line(a, b, stroke: (paint: edge, thickness: 1.0pt))
  inc(X1, Fa)
  inc(Fa, X2)
  inc(X2, Fb)
  inc(Fb, X3)
  inc(X2, Fc)
  inc(Fc, X4)

  // ---- factor → variable message (the sum–product focal edge, garnet) --------
  // mu_{f_c -> x2}: a directed message flowing along the x2–f_c incidence edge.
  {
    let a = (Fc.at(0), Fc.at(1) + sf + 0.06)
    let b = (X2.at(0), X2.at(1) - rv - 0.04)
    let off = 0.34 // sit the arrow just to the right of the incidence edge
    draw.line(
      (a.at(0) + off, a.at(1)),
      (b.at(0) + off, b.at(1)),
      stroke: (paint: c-garnet, thickness: 1.15pt),
      mark: (end: "stealth", fill: c-garnet, scale: 0.8),
    )
    draw.content(
      (b.at(0) + off + 0.12, (a.at(1) + b.at(1)) / 2), anchor: "west",
      text(size: 8pt, fill: c-garnet, weight: "bold")[$mu_(f_c -> x_2)(x_2)$],
    )
  }

  // ---- factor nodes (small filled squares) -----------------------------------
  let factor(c, lbl, lpos) = {
    draw.rect(
      (c.at(0) - sf, c.at(1) - sf), (c.at(0) + sf, c.at(1) + sf),
      fill: c-fac, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt,
    )
    draw.content(lpos, text(size: 8.5pt, fill: ink)[#lbl])
  }
  factor(Fa, [$f_a$], (Fa.at(0), Fa.at(1) + sf + 0.34))
  factor(Fb, [$f_b$], (Fb.at(0), Fb.at(1) + sf + 0.34))
  factor(Fc, [$f_c$], (Fc.at(0) - sf - 0.34, Fc.at(1)))

  // ---- variable nodes (open circles) -----------------------------------------
  // x2 is the hub — accent its outline in garnet so the focal message is anchored.
  let variable(c, lbl, hub: false) = {
    draw.circle(
      c, radius: rv, fill: c-var,
      stroke: (paint: if hub { c-garnet } else { ink }, thickness: if hub { 1.4pt } else { 1.1pt }),
    )
    draw.content(c, text(size: 9.5pt, fill: ink)[#lbl])
  }
  variable(X1, [$x_1$])
  variable(X2, [$x_2$], hub: true)
  variable(X3, [$x_3$])
  variable(X4, [$x_4$])

  // ---- legend (bottom-left) --------------------------------------------------
  let lx = -3.55
  let ly = -2.55
  // variable glyph
  draw.circle((lx, ly), radius: 0.20, fill: c-var, stroke: (paint: ink, thickness: 1.0pt))
  draw.content((lx + 0.36, ly), anchor: "west", text(size: 8pt, fill: muted)[variable $x_i$])
  // factor glyph
  draw.rect((lx + 1.92, ly - 0.18), (lx + 2.28, ly + 0.18), fill: c-fac, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content((lx + 2.46, ly), anchor: "west", text(size: 8pt, fill: muted)[factor $f$])
  // edge glyph
  draw.line((lx + 3.92, ly), (lx + 4.42, ly), stroke: (paint: edge, thickness: 1.0pt))
  draw.content((lx + 4.56, ly), anchor: "west", text(size: 8pt, fill: muted)[incidence (undirected)])

  // ---- title + factorization caption -----------------------------------------
  draw.content(
    (0, 3.25),
    text(size: 12pt, weight: "bold", fill: ink)[Factor graph],
  )
  draw.content(
    (0, 2.72),
    text(size: 8.5pt, fill: muted)[bipartite: round variables, square factors; an edge wherever a variable is a factor's argument],
  )
  // the factorization the graph encodes
  draw.content(
    (0, -3.35),
    text(size: 9pt, fill: ink)[$p(x_1,x_2,x_3,x_4) prop f_a thin (x_1,x_2) dot.c f_b thin (x_2,x_3) dot.c f_c thin (x_2,x_4)$],
  )
})
