// Boosting as a staged additive model (AdaBoost; ESL ch.10, ISLP, Mohri, UML).
// A sequence of weak learners (decision stumps) is fit one stage at a time.
// At each stage t:
//   1. a stump h_t is fit to the CURRENT sample weights,
//   2. its weighted error sets the stage coefficient  alpha_t = 1/2 log((1-e_t)/e_t),
//   3. weights are UPDATED — misclassified points get heavier (bigger dots) — and
//      handed forward to the next stage (the reweight feedback loop below the chain).
// The final model is the WEIGHTED SUM of the stumps:  H(x) = sign( sum_t alpha_t h_t(x) ).
// Built from mlatlas knowledge in the print-first house style; stump glyphs, weight
// dots, the reweight loop, and the additive sink are all computed in cetz.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let panel  = rgb("#ECECEC")
#let blue   = rgb("#466A9F")
#let redx   = rgb("#CC2E40")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── layout constants ──────────────────────────────────────────────────────
  let n-stage = 3
  let dx      = 4.2            // horizontal pitch between stage panels
  let pw      = 2.7            // panel (data view) width
  let ph      = 2.7           // panel height
  let y0      = 0             // baseline (centre of the stage panels)

  // sample layout inside a stage panel: a small 2-D scatter of points, each
  // with a class (+/-) and a per-stage weight that scales the dot radius.
  // The split line of the stump is drawn through the panel; points on the wrong
  // side of the split (for this stump) are the "misclassified" ones that grow.
  let pts = (
    // (x, y, class)   class: +1 (garnet, filled) / -1 (blue, hollow)
    (-0.85,  0.78,  1),
    ( 0.10,  0.92,  1),
    ( 0.86,  0.55,  1),
    (-0.70,  0.05,  1),
    ( 0.55, -0.10, -1),
    (-0.90, -0.72, -1),
    ( 0.05, -0.85, -1),
    ( 0.88, -0.60, -1),
    (-0.10, -0.25,  1),
    ( 0.40,  0.30, -1),
  )

  // per-stage weight multipliers for each point (1.0 = base). Misclassified
  // points from the previous stump are boosted, giving the dot-size cue. Index
  // matches `pts`; three columns = three stages.
  let weights = (
    (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0),   // stage 1: uniform
    (0.7, 0.7, 1.9, 0.7, 1.8, 0.7, 0.7, 0.7, 1.7, 0.7),   // stage 2: boost 3 errors
    (0.6, 1.6, 0.6, 0.6, 0.6, 1.7, 0.6, 0.6, 0.6, 1.8),   // stage 3: boost new errors
  )

  // the stump for each stage: a vertical or horizontal axis-aligned split.
  // (kind, position) — "v" splits at x = pos, "h" splits at y = pos.
  let stumps = (
    ("v",  0.18),
    ("h", -0.18),
    ("v", -0.30),
  )

  let alphas = ([$alpha_1$], [$alpha_2$], [$alpha_3$])

  let r-base = 0.085          // base dot radius

  // ── draw one stage panel (data view + stump split + weighted dots) ────────
  let draw-stage(cx, idx) = {
    let half = pw / 2
    let halfh = ph / 2
    // panel frame (sharp corners)
    rect(
      (cx - half, y0 - halfh), (cx + half, y0 + halfh),
      fill: white, stroke: 0.9pt + ink,
    )
    // scale data coords (-1..1) into the inner panel (leave a margin)
    let m = 0.34
    let sx = half - m
    let sy = halfh - m
    let P(p) = (cx + p.at(0) * sx, y0 + p.at(1) * sy)

    // stump split line, drawn faint garnet across the panel
    let st = stumps.at(idx)
    if st.at(0) == "v" {
      let xx = cx + st.at(1) * sx
      line((xx, y0 - sy), (xx, y0 + sy), stroke: 1.2pt + garnet)
    } else {
      let yy = y0 + st.at(1) * sy
      line((cx - sx, yy), (cx + sx, yy), stroke: 1.2pt + garnet)
    }

    // sample dots, radius scaled by this stage's weight
    let ws = weights.at(idx)
    for (i, p) in pts.enumerate() {
      let c = P(p)
      let r = r-base * calc.sqrt(ws.at(i))
      if p.at(2) == 1 {
        circle(c, radius: r, fill: garnet, stroke: none)
      } else {
        circle(c, radius: r, fill: white, stroke: 0.9pt + blue)
      }
    }
  }

  // ── tiny decision-stump glyph (one split = root + two leaves) ─────────────
  // drawn above each panel as the "weak learner" h_t produced at that stage.
  let draw-stump(cx, cy, idx) = {
    let rt = (cx, cy)             // root
    let l = (cx - 0.55, cy - 0.7)
    let r = (cx + 0.55, cy - 0.7)
    line(rt, l, stroke: 1.1pt + ink)
    line(rt, r, stroke: 1.1pt + ink)
    circle(rt, radius: 0.13, fill: panel, stroke: 0.9pt + ink)
    // leaves: square +/- decisions
    rect((l.at(0) - 0.16, l.at(1) - 0.16), (l.at(0) + 0.16, l.at(1) + 0.16),
      fill: white, stroke: 0.9pt + blue)
    content((l.at(0), l.at(1)), text(size: 8pt, fill: blue)[$-$])
    rect((r.at(0) - 0.16, r.at(1) - 0.16), (r.at(0) + 0.16, r.at(1) + 0.16),
      fill: garnet, stroke: 0.9pt + garnet)
    content((r.at(0), r.at(1)), text(size: 8pt, fill: white)[$+$])
  }

  // ── place the three stages ────────────────────────────────────────────────
  let stage-x = range(n-stage).map(t => t * dx)
  let stump-y = y0 + ph / 2 + 1.55      // stump glyph centre, above each panel

  for (t, cx) in stage-x.enumerate() {
    draw-stage(cx, t)
    draw-stump(cx, stump-y, t)

    // stage caption under the panel
    content((cx, y0 - ph / 2 - 0.42),
      text(size: 8.5pt, fill: ink)[stage #(t + 1)])
    // weighted-data note (first stage = uniform weights)
    let note = if t == 0 { [uniform $w_i = 1\/n$] } else { [reweighted $w_i$] }
    content((cx, y0 - ph / 2 - 0.78), text(size: 6.5pt, fill: muted)[#note])

    // vertical connector: panel data -> the stump it fits
    line(
      (cx, y0 + ph / 2 + 0.06), (cx, stump-y - 0.92),
      stroke: 1.1pt + muted, mark: (end: "stealth", scale: 0.7),
    )
    // h_t label beside the stump
    let ti = str(t + 1)
    content((cx + 1.05, stump-y - 0.02),
      text(size: 9pt, fill: ink)[$h_#ti (bold(x))$])
    // weighted error feeding alpha_t
    content((cx + 1.05, stump-y - 0.5),
      text(size: 6.5pt, fill: muted)[err $epsilon_#ti$])
  }

  // ── forward chain arrows between stage panels (the staged sweep) ──────────
  for t in range(n-stage - 1) {
    let xa = stage-x.at(t) + pw / 2 + 0.06
    let xb = stage-x.at(t + 1) - pw / 2 - 0.06
    line((xa, y0), (xb, y0),
      stroke: 1.8pt + ink, mark: (end: "stealth", scale: 0.85))
  }

  // ── reweight feedback loop: misclassified -> heavier weights for next stage
  // a curved arc beneath the chain carrying the weight update D_{t+1}.
  let loop-y = y0 - ph / 2 - 1.55
  for t in range(n-stage - 1) {
    let xa = stage-x.at(t)
    let xb = stage-x.at(t + 1)
    // drop down, across, up into next panel
    line(
      (xa, y0 - ph / 2 - 1.02),
      (xa, loop-y),
      (xb, loop-y),
      (xb, y0 - ph / 2 - 1.02),
      stroke: (paint: redx, thickness: 1.3pt, dash: "dashed"),
      mark: (end: "stealth", scale: 0.75),
    )
  }
  content(((stage-x.at(0) + stage-x.at(1)) / 2, loop-y - 0.3),
    text(size: 7pt, fill: redx)[reweight $w_i arrow.l w_i e^(alpha_t bb(1)[y_i eq.not h_t])$])
  content(((stage-x.at(1) + stage-x.at(2)) / 2, loop-y - 0.3),
    text(size: 7pt, fill: redx)[misclassified $arrow.r$ heavier])

  // ── additive sink: weighted sum of the stumps ─────────────────────────────
  // each stump feeds an alpha_t-weighted edge into a (+) op-node, then sign().
  let sum-x = stage-x.at(-1) + dx + 0.2
  let sum-y = stump-y - 0.35
  // op-node circle
  circle((sum-x, sum-y), radius: 0.42, fill: panel, stroke: 1.1pt + garnet)
  content((sum-x, sum-y), text(size: 13pt, fill: garnet)[$+$])
  content((sum-x, sum-y + 1.42), text(size: 7.5pt, fill: ink)[weighted sum])

  // alpha-weighted edges from each stump to the sum node.
  // each stump lifts up to a shared "bus" rail above the labels, then runs
  // right and drops into the (+) node — keeps the lines off the h_t glyphs.
  let bus-y = stump-y + 0.62
  for (t, cx) in stage-x.enumerate() {
    let sp = (cx, stump-y + 0.18)               // top of stump root
    let lane = bus-y + t * 0.16                  // a lane per stage, no overlap
    let tp = (sum-x, sum-y + 0.42)               // top of the (+) node
    line(
      sp,
      (cx, lane),
      (sum-x, lane),
      tp,
      stroke: 1.0pt + faint, mark: (end: "stealth", scale: 0.6),
    )
    // alpha_t edge label, sitting on the vertical lift just above the stump
    content(
      (cx - 0.34, (stump-y + 0.18 + lane) / 2 + 0.04),
      anchor: "east",
      text(size: 8.5pt, fill: garnet, weight: "bold")[#alphas.at(t)],
    )
  }

  // sum -> sign() -> final prediction
  let out-x = sum-x + 1.7
  line((sum-x + 0.46, sum-y), (out-x - 0.62, sum-y),
    stroke: 1.6pt + ink, mark: (end: "stealth", scale: 0.8))
  content(((sum-x + 0.46 + out-x - 0.62) / 2, sum-y + 0.26),
    text(size: 7pt, fill: muted)[sign])

  // final model box
  let bw = 2.2
  let bh = 0.95
  rect((out-x - 0.0, sum-y - bh / 2), (out-x + bw, sum-y + bh / 2),
    fill: rgb("#FFF2E3"), stroke: 1.0pt + garnet)
  content((out-x + bw / 2, sum-y + 0.16),
    text(size: 9pt, fill: ink)[$H(bold(x))$])
  content((out-x + bw / 2, sum-y - 0.2),
    text(size: 8pt, fill: garnet)[$= "sign" sum_t alpha_t h_t(bold(x))$])

  // ── legend (class colours + dot-size = weight) ────────────────────────────
  let lx = stage-x.at(0) - pw / 2 - 0.1
  let ly = loop-y - 1.15
  circle((lx + 0.1, ly), radius: 0.085, fill: garnet, stroke: none)
  content((lx + 0.35, ly), anchor: "west", text(size: 7pt, fill: ink)[class $+1$])
  circle((lx + 1.7, ly), radius: 0.085, fill: white, stroke: 0.9pt + blue)
  content((lx + 1.95, ly), anchor: "west", text(size: 7pt, fill: ink)[class $-1$])
  // dot-size cue
  circle((lx + 3.45, ly), radius: 0.07, fill: muted, stroke: none)
  circle((lx + 3.75, ly), radius: 0.125, fill: muted, stroke: none)
  content((lx + 3.95, ly), anchor: "west",
    text(size: 7pt, fill: ink)[dot size $prop$ sample weight $w_i$])

  // ── title strip ───────────────────────────────────────────────────────────
  content((stage-x.at(0) - pw / 2 - 0.1, stump-y + 1.6), anchor: "west",
    text(size: 11pt, weight: "bold", fill: ink)[Boosting as a staged additive model])
})
