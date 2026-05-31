// Sum–product / belief-propagation message passing — the ALGORITHMIC overlay on a
// factor graph. Built from first principles in mlatlas print-first style (not traced).
//
// On a factor graph, sum–product computes marginals by passing two kinds of
// directed messages along the (undirected) incidence edges:
//   variable → factor:  mu_{x->f}(x) = prod_{g in ne(x)\f} mu_{g->x}(x)
//   factor → variable:  mu_{f->x}(x) = sum_{x' : ne(f)\x}  f(x, x') * prod mu_{x'->f}(x')
// The marginal of any variable is the product of ALL messages arriving at its node:
//   p(x) ∝ prod_{f in ne(x)} mu_{f->x}(x).
// We overlay BOTH message directions (garnet stealth arrows) on a 4-variable chain
// factor graph and annotate the two update rules + the marginal read-out.
// Sources confirm conventions only (Bishop PRML §8.4.4; MacKay ITILA §26; Barber BRML).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let c-blue = rgb("#466A9F")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let c-var = rgb("#ECECEC") // 10% black — variable-node fill
#let c-fac = rgb("#363636") // 90% black — filled factor square
#let edge = rgb("#A2A2A2") // 50% black — incidence edge (recedes behind messages)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let rv = 0.46 // variable circle radius
  let sf = 0.30 // factor square half-side
  let dy = 0.40 // vertical offset of a message arrow above / below the edge line

  // ---- node coordinates: a chain  x1 — f_a — x2 — f_b — x3 — f_c — x4 ---------
  let dx = 2.15
  let X1 = (-3.0 * dx, 0.0)
  let Fa = (-2.5 * dx, 0.0)
  let X2 = (-2.0 * dx, 0.0)
  let Fb = (-1.5 * dx, 0.0)
  let X3 = (-1.0 * dx, 0.0)
  let Fc = (-0.5 * dx, 0.0)
  let X4 = (0.0 * dx, 0.0)

  // ---- incidence edges (undirected) — drawn first, behind everything ---------
  let inc(a, b) = draw.line(a, b, stroke: (paint: edge, thickness: 1.1pt))
  inc(X1, Fa); inc(Fa, X2); inc(Fb, X2); inc(Fb, X3); inc(Fc, X3); inc(Fc, X4)

  // ---- directed messages: forward (above, garnet) & backward (below, blue) ----
  // A message lives on one incidence edge; we draw it parallel to that edge,
  // offset up (forward, left→right) or down (backward, right→left).
  let msg-fwd(a, b, lbl) = {
    let pa = (a.at(0), a.at(1) + dy)
    let pb = (b.at(0), b.at(1) + dy)
    draw.line(pa, pb, stroke: (paint: c-garnet, thickness: 1.3pt),
      mark: (end: "stealth", fill: c-garnet, scale: 0.85))
    draw.content(((a.at(0) + b.at(0)) / 2, a.at(1) + dy + 0.32),
      text(size: 7pt, fill: c-garnet)[#lbl])
  }
  let msg-bwd(a, b, lbl) = {
    let pa = (a.at(0), a.at(1) - dy)
    let pb = (b.at(0), b.at(1) - dy)
    draw.line(pa, pb, stroke: (paint: c-blue, thickness: 1.3pt),
      mark: (end: "stealth", fill: c-blue, scale: 0.85))
    draw.content(((a.at(0) + b.at(0)) / 2, a.at(1) - dy - 0.32),
      text(size: 7pt, fill: c-blue)[#lbl])
  }

  // forward sweep (left → right): alternating x->f and f->x
  msg-fwd(X1, Fa, [$mu_(x_1 -> f_a)$])
  msg-fwd(Fa, X2, [$mu_(f_a -> x_2)$])
  msg-fwd(X2, Fb, [$mu_(x_2 -> f_b)$])
  msg-fwd(Fb, X3, [$mu_(f_b -> x_3)$])
  msg-fwd(X3, Fc, [$mu_(x_3 -> f_c)$])
  msg-fwd(Fc, X4, [$mu_(f_c -> x_4)$])

  // backward sweep (right → left)
  msg-bwd(X4, Fc, [$mu_(x_4 -> f_c)$])
  msg-bwd(Fc, X3, [$mu_(f_c -> x_3)$])
  msg-bwd(X3, Fb, [$mu_(x_3 -> f_b)$])
  msg-bwd(Fb, X2, [$mu_(f_b -> x_2)$])
  msg-bwd(X2, Fa, [$mu_(x_2 -> f_a)$])
  msg-bwd(Fa, X1, [$mu_(f_a -> x_1)$])

  // ---- factor nodes (small filled squares) -----------------------------------
  let factor(c, lbl) = {
    draw.rect((c.at(0) - sf, c.at(1) - sf), (c.at(0) + sf, c.at(1) + sf),
      fill: c-fac, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
    // factor identity sits in its own row, well below the backward-message labels
    draw.content((c.at(0), -1.32), text(size: 8.5pt, fill: ink, weight: "bold")[#lbl])
  }
  factor(Fa, [$f_a$]); factor(Fb, [$f_b$]); factor(Fc, [$f_c$])

  // ---- variable nodes (open circles); x3 is focal (its marginal is read out) --
  let variable(c, lbl, hub: false) = {
    draw.circle(c, radius: rv, fill: c-var,
      stroke: (paint: if hub { c-garnet } else { ink }, thickness: if hub { 1.5pt } else { 1.1pt }))
    draw.content(c, text(size: 9.5pt, fill: ink)[#lbl])
  }
  variable(X1, [$x_1$]); variable(X2, [$x_2$])
  variable(X3, [$x_3$], hub: true); variable(X4, [$x_4$])

  // ---- title -----------------------------------------------------------------
  draw.content((-3.0 * dx, 3.55), anchor: "west",
    text(size: 12.5pt, weight: "bold", fill: ink)[Sum–product message passing])
  draw.content((-3.0 * dx, 2.95), anchor: "north-west",
    box(width: 11.4cm, text(size: 8.5pt, fill: muted)[two directed messages per edge of a factor graph; on a chain, a forward sweep ($x_1 -> x_4$) and a backward sweep ($x_4 -> x_1$) give every marginal as the product of its arriving messages]))

  // ---- the two update rules (boxed, right side) -------------------------------
  let rule-x = 2.55 * dx
  let rule-w = 6.05
  let rbox(cy, h, title, body, accent) = {
    draw.rect((rule-x - 0.18, cy - h / 2), (rule-x - 0.18 + rule-w, cy + h / 2),
      fill: rgb("#FAFAFA"), stroke: (paint: muted, thickness: 0.8pt), radius: 0pt)
    draw.line((rule-x - 0.18, cy + h / 2), (rule-x - 0.18, cy - h / 2),
      stroke: (paint: accent, thickness: 2.4pt))
    draw.content((rule-x + 0.06, cy + h / 2 - 0.30), anchor: "north-west",
      text(size: 8pt, fill: accent, weight: "bold")[#title])
    draw.content((rule-x + 0.06, cy - 0.06), anchor: "north-west", body)
  }
  rbox(2.05, 1.5,
    [variable → factor],
    text(size: 9pt, fill: ink)[$mu_(x -> f)(x) = product_(g in n e(x) without f) mu_(g -> x)(x)$],
    c-garnet)
  rbox(0.20, 1.5,
    [factor → variable],
    text(size: 8.5pt, fill: ink)[$mu_(f -> x)(x) = sum_(x' \\ x) f(x, x') product_(y in n e(f) without x) mu_(y -> f)(y)$],
    c-blue)
  rbox(-1.65, 1.5,
    [marginal (read-out)],
    text(size: 9pt, fill: ink)[$p(x) prop product_(f in n e(x)) mu_(f -> x)(x)$],
    ink)

  // ---- legend (bottom-left) --------------------------------------------------
  let lx = -3.0 * dx
  let ly = -2.45
  let leg(x, paint, lbl, arrow: true) = {
    if arrow {
      draw.line((x, ly), (x + 0.62, ly), stroke: (paint: paint, thickness: 1.3pt),
        mark: (end: "stealth", fill: paint, scale: 0.85))
    } else {
      draw.line((x, ly), (x + 0.62, ly), stroke: (paint: paint, thickness: 1.1pt))
    }
    draw.content((x + 0.78, ly), anchor: "west", text(size: 8pt, fill: muted)[#lbl])
  }
  leg(lx, c-garnet, [forward sweep])
  leg(lx + 2.95, c-blue, [backward sweep])
  leg(lx + 6.05, edge, [incidence edge], arrow: false)
})
