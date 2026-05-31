// Influence diagram (decision network).
//   A Bayesian network augmented with two extra glyph roles so it can encode a
//   sequential decision problem under uncertainty:
//     - oval / circle  = CHANCE node    (a random variable, P(node | parents))
//     - rectangle      = DECISION node  (a choice the agent controls)
//     - diamond        = UTILITY node   (the objective; deterministic fn of parents)
//   Two arc types: solid conditional/functional arcs, and dashed INFORMATION arcs
//   into a decision (what is observed before that decision is made).
//   Canonical diagnose-and-treat network in mlatlas's print-first house style.
//   Built from the standard convention (Howard & Matheson; Koller & Friedman;
//   Barber BRML; Murphy; Kochenderfer DMU). Original layout — not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet   = rgb("#73000A")
#let ink      = rgb("#1A1A1A")
#let muted    = rgb("#5C5C5C")
#let edgecol  = rgb("#363636")
#let infocol  = rgb("#466A9F")   // information-arc accent (blue)
#let chancefl = white            // chance fill
#let decfill  = rgb("#ECECEC")   // decision fill (10% black)
#let utilfill = rgb("#FFF2E3")   // utility fill (beige)

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  // ── fixed node positions: id -> (x, y) ──────────────────────────────────
  let pos = (
    D:  (0,    2.0),    // Disease state      (chance, hidden root)
    T:  (3.4,  3.6),    // Test result        (chance, observed)
    C:  (3.4,  0.4),    // Treat?             (DECISION)
    U:  (7.6,  2.0),    // Utility            (UTILITY diamond)
    O:  (0,   -1.2),    // Treatment cost     (chance)
  )

  let rc = 0.62          // chance-node radius (ellipse-ish circle)
  let dw = 1.05          // decision half-width
  let dh = 0.55          // decision half-height
  let uh = 0.95          // utility diamond half-extent

  // ---- node geometry helpers: return rim point toward a target -----------
  // chance node = circle
  let chance(id, lbl, observed: false, focal: false) = {
    let p = pos.at(id)
    let fill = if observed { rgb("#C7C7C7") } else { chancefl }
    let stroke = if focal { 1.7pt + garnet } else { 1.2pt + edgecol }
    circle(p, radius: rc, fill: fill, stroke: stroke)
    content(p, text(size: 9pt, fill: ink)[#lbl])
  }
  // decision node = sharp rectangle
  let decision(id, lbl, focal: false) = {
    let p = pos.at(id)
    let stroke = if focal { 1.7pt + garnet } else { 1.3pt + edgecol }
    rect(
      (p.at(0) - dw, p.at(1) - dh),
      (p.at(0) + dw, p.at(1) + dh),
      fill: decfill, stroke: stroke, radius: 0pt,
    )
    content(p, text(size: 9pt, fill: ink)[#lbl])
  }
  // utility node = diamond (rotated square via 4 corner polygon)
  let utility(id, lbl) = {
    let p = pos.at(id)
    let cx = p.at(0)
    let cy = p.at(1)
    line(
      (cx, cy + uh), (cx + 1.35 * uh, cy),
      (cx, cy - uh), (cx - 1.35 * uh, cy),
      close: true, fill: utilfill, stroke: 1.5pt + garnet,
    )
    content(p, text(size: 9pt, fill: ink)[#lbl])
  }

  // approximate rim offset along a direction for each node kind
  // returns the point on the boundary of node `id` toward point `tp`
  let rim(id, tp) = {
    let p = pos.at(id)
    let dx = tp.at(0) - p.at(0)
    let dy = tp.at(1) - p.at(1)
    let len = calc.max(calc.sqrt(dx * dx + dy * dy), 0.0001)
    let ux = dx / len
    let uy = dy / len
    // kind lookup by id
    if id == "C" {
      // rectangle: scale to box boundary
      let sx = if ux != 0 { dw / calc.abs(ux) } else { 1e6 }
      let sy = if uy != 0 { dh / calc.abs(uy) } else { 1e6 }
      let s = calc.min(sx, sy)
      (p.at(0) + ux * s, p.at(1) + uy * s)
    } else if id == "U" {
      // diamond: |x|/a + |y|/b = 1, a = 1.35*uh, b = uh
      let a = 1.35 * uh
      let b = uh
      let denom = calc.abs(ux) / a + calc.abs(uy) / b
      let s = 1 / calc.max(denom, 0.0001)
      (p.at(0) + ux * s, p.at(1) + uy * s)
    } else {
      // circle
      (p.at(0) + ux * rc, p.at(1) + uy * rc)
    }
  }

  // directed edge id_a -> id_b, trimmed to each node's rim.
  //   info = dashed information arc into a decision (blue).
  let arr(a, b, info: false) = {
    let s = rim(a, pos.at(b))
    let e = rim(b, pos.at(a))
    let st = if info {
      (paint: infocol, thickness: 1.2pt, dash: "dashed")
    } else {
      1.2pt + edgecol
    }
    line(s, e, stroke: st, mark: (end: "stealth", scale: 0.85))
  }

  // ── draw the network ────────────────────────────────────────────────────
  chance("D", [Disease], focal: true)        // hidden state we reason about
  chance("T", [Test])                          // its observation feeds the decision
  chance("O", [Cost])                         // a second chance influence on utility
  decision("C", [Treat?])                     // the controllable choice
  utility("U", [$U$])                          // objective

  // conditional / functional arcs (solid)
  arr("D", "T")          // disease causes test result
  arr("D", "U")          // outcome utility depends on true disease
  arr("C", "U")          // ... and on the treatment decision
  arr("C", "O")          // treatment incurs a cost
  arr("O", "U")          // cost contributes to utility

  // information arc (dashed): test result is known before deciding to treat
  arr("T", "C", info: true)

  // ── CPD / utility captions ───────────────────────────────────────────────
  content((-0.95, 2.0), anchor: "east", text(size: 7.5pt, fill: muted)[$P(D)$])
  content((4.3, 4.0), anchor: "west", text(size: 7.5pt, fill: muted)[$P(T | D)$])
  content((3.4, -0.55), text(size: 7.5pt, fill: garnet)[decision rule $delta(T)$])
  content((7.6, 0.75), text(size: 7.5pt, fill: muted)[$U(D, "Treat", "Cost")$])
  content((-0.95, -1.2), anchor: "east", text(size: 7.5pt, fill: muted)[$P("Cost" | "Treat")$])

  // ── objective: maximize expected utility ─────────────────────────────────
  content(
    (2.6, -3.05),
    anchor: "center",
    text(size: 9.5pt, fill: ink)[
      $delta^* = arg max_delta thin EE[U] = arg max_delta sum_(D) P(D) thin
       U(D, delta(T), "Cost")$
    ],
  )

  // ── legend (lower-right): the three glyph roles + two arc types ──────────
  let lx = 6.15
  let ly = -0.30
  // frame (sharp corners)
  rect((lx - 0.55, ly - 3.55), (lx + 4.55, ly + 0.45), stroke: 0.8pt + rgb("#A2A2A2"))
  // chance glyph
  circle((lx, ly), radius: 0.24, fill: white, stroke: 1.1pt + edgecol)
  content((lx + 0.5, ly), anchor: "west", text(size: 8pt, fill: ink)[chance (random variable)])
  // decision glyph
  rect((lx - 0.32, ly - 0.78 - 0.19), (lx + 0.32, ly - 0.78 + 0.19),
       fill: decfill, stroke: 1.2pt + edgecol, radius: 0pt)
  content((lx + 0.5, ly - 0.78), anchor: "west", text(size: 8pt, fill: ink)[decision (controllable choice)])
  // utility glyph
  line((lx, ly - 1.56 + 0.25), (lx + 0.33, ly - 1.56), (lx, ly - 1.56 - 0.25),
       (lx - 0.33, ly - 1.56), close: true, fill: utilfill, stroke: 1.3pt + garnet)
  content((lx + 0.5, ly - 1.56), anchor: "west", text(size: 8pt, fill: ink)[utility (objective)])
  // solid arc
  line((lx - 0.28, ly - 2.34), (lx + 0.30, ly - 2.34),
       stroke: 1.1pt + edgecol, mark: (end: "stealth", scale: 0.7))
  content((lx + 0.5, ly - 2.34), anchor: "west", text(size: 8pt, fill: ink)[conditional / functional arc])
  // info arc
  line((lx - 0.28, ly - 3.12), (lx + 0.30, ly - 3.12),
       stroke: (paint: infocol, thickness: 1.1pt, dash: "dashed"),
       mark: (end: "stealth", scale: 0.7))
  content((lx + 0.5, ly - 3.12), anchor: "west", text(size: 8pt, fill: ink)[information arc (known before decision)])

  // title
  content(
    (3.0, 5.55),
    anchor: "west",
    text(size: 10.5pt, weight: "bold", fill: ink)[Influence diagram (decision network)],
  )
})
