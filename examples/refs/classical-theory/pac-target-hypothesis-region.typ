// mlatlas · PAC learning — target concept, learned hypothesis, and the error region.
//   The PAC picture for learning axis-aligned rectangles (Kearns–Vazirani; Mohri;
//   Understanding Machine Learning). Instances live in a bounding box of the
//   instance space 𝒳. A target concept c (an axis-aligned rectangle, garnet) labels
//   points inside as + and outside as −. From a sample S ~ Dᵐ the learner returns the
//   TIGHTEST rectangle h enclosing all observed positives — the consistent ERM
//   hypothesis (blue). Because every positive sample lies in c, we have h ⊆ c, so the
//   symmetric difference c △ h = c ∖ h is the "frame" between them (hatched). The
//   generalization error is the probability mass D(c △ h) that a fresh draw lands in
//   that frame and is mislabeled. The PAC guarantee: with prob ≥ 1 − δ over S,
//   err(h) = D(c △ h) ≤ ε once  m ≥ (4/ε) ln(4/δ). No image traced; pure cetz geometry.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ─────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent — the target concept c
#let blue   = rgb("#466A9F")   // the learned hypothesis h
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let grid-c = rgb("#ECECEC")
#let plus-c = rgb("#73000A")   // positive points
#let minus-c = rgb("#5C5C5C")  // negative points

// ── instance-space box and the two rectangles (data coordinates 0..10) ─────────
// target concept  c = [cx0,cx1] × [cy0,cy1]
#let cx0 = 1.6
#let cx1 = 8.2
#let cy0 = 1.8
#let cy1 = 7.9
// learned hypothesis h = tightest rectangle around the sampled positives ⊆ c
#let hx0 = 2.9
#let hx1 = 7.1
#let hy0 = 3.1
#let hy1 = 6.7

// ── world → canvas mapping ─────────────────────────────────────────────────────
#let X0 = 0.0
#let X1 = 10.0
#let Y0 = 0.0
#let Y1 = 10.0
#let PW = 9.0
#let PH = 9.0
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── instance-space frame 𝒳 ───────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink, radius: 0pt)
  // faint reference grid
  for gx in range(1, 10) {
    line((sx(gx), 0), (sx(gx), PH), stroke: 0.4pt + grid-c)
  }
  for gy in range(1, 10) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.4pt + grid-c)
  }

  // ── the symmetric-difference frame  c △ h = c ∖ h  (hatched error region) ─────
  // Fill the four border strips of c that lie OUTSIDE h, then overlay hatching.
  let dh = rgb("#73000A")
  // light wash on the frame
  let frame-fill = garnet.transparentize(88%)
  // bottom strip
  rect((sx(cx0), sy(cy0)), (sx(cx1), sy(hy0)), fill: frame-fill, stroke: none)
  // top strip
  rect((sx(cx0), sy(hy1)), (sx(cx1), sy(cy1)), fill: frame-fill, stroke: none)
  // left strip
  rect((sx(cx0), sy(hy0)), (sx(hx0), sy(hy1)), fill: frame-fill, stroke: none)
  // right strip
  rect((sx(hx1), sy(hy0)), (sx(cx1), sy(hy1)), fill: frame-fill, stroke: none)

  // diagonal hatching over the frame, clipped to the c-rectangle but skipping h.
  // We draw 45° lines across c's bounding box and clip each segment to the strips
  // by testing the midpoint; simpler: draw hatch lines only within the frame region
  // using four clipped passes (one per strip) so nothing bleeds into h or outside c.
  let hatch-strip(x0, x1, y0, y1) = {
    // 45° lines spaced by step in canvas units across the strip
    let step = 0.26
    let cx0c = sx(x0)
    let cx1c = sx(x1)
    let cy0c = sy(y0)
    let cy1c = sy(y1)
    let w = cx1c - cx0c
    let hgt = cy1c - cy0c
    // lines of slope +1: param by offset b in x = y + b ; cover full strip
    let n = calc.ceil((w + hgt) / step) + 1
    for i in range(n + 1) {
      let b = cx0c - hgt + i * step
      // line  (x = y + b)  intersect strip [cx0c,cx1c]×[cy0c,cy1c]
      // at y=cy0c → x=cy0c+b ; at y=cy1c → x=cy1c+b
      let xa = cy0c + b
      let xb = cy1c + b
      let ya = cy0c
      let yb = cy1c
      // clip to vertical bounds of strip in x
      // compute entry/exit by clamping; if fully outside, skip
      // parametric: x(t) = xa + t*(xb-xa), y(t)=ya+t*(yb-ya), t in [0,1]
      let t0 = 0.0
      let t1 = 1.0
      // clip x >= cx0c
      if xb != xa {
        let tc = (cx0c - xa) / (xb - xa)
        if xa < cx0c { t0 = calc.max(t0, tc) } else { t1 = calc.min(t1, calc.max(tc, 0.0) + 1) }
      }
      // simpler robust clip against x∈[cx0c,cx1c]
      // recompute cleanly:
      let lo = 0.0
      let hi = 1.0
      let clipx(bound, keep-greater) = {
        if xb == xa {
          // vertical-in-x impossible here (slope1); skip
          (lo, hi)
        } else {
          let tt = (bound - xa) / (xb - xa)
          if keep-greater {
            // want x >= bound
            if xb - xa > 0 { (calc.max(lo, tt), hi) } else { (lo, calc.min(hi, tt)) }
          } else {
            if xb - xa > 0 { (lo, calc.min(hi, tt)) } else { (calc.max(lo, tt), hi) }
          }
        }
      }
      let r1 = clipx(cx0c, true)
      lo = r1.at(0); hi = r1.at(1)
      let r2 = clipx(cx1c, false)
      lo = calc.max(lo, r2.at(0)); hi = calc.min(hi, r2.at(1))
      if hi > lo {
        let px0 = xa + lo * (xb - xa)
        let py0 = ya + lo * (yb - ya)
        let px1 = xa + hi * (xb - xa)
        let py1 = ya + hi * (yb - ya)
        line((px0, py0), (px1, py1), stroke: 0.5pt + garnet.transparentize(25%))
      }
    }
  }
  hatch-strip(cx0, cx1, cy0, hy0)   // bottom
  hatch-strip(cx0, cx1, hy1, cy1)   // top
  hatch-strip(cx0, hx0, hy0, hy1)   // left
  hatch-strip(hx1, cx1, hy0, hy1)   // right

  // ── the two rectangles: target concept c (garnet) and hypothesis h (blue) ─────
  // c — drawn as outline only (its interior is partly the frame, partly h)
  rect((sx(cx0), sy(cy0)), (sx(cx1), sy(cy1)),
    fill: none, stroke: 2pt + garnet, radius: 0pt)
  // h — tight blue rectangle, light interior wash so positives inside read clearly
  rect((sx(hx0), sy(hy0)), (sx(hx1), sy(hy1)),
    fill: blue.transparentize(90%), stroke: 1.8pt + blue, radius: 0pt)

  // ── sample points: positives (inside c) and negatives (outside c) ─────────────
  // positives all lie inside c; the tightest enclosing rect of these IS h, so a few
  // positives must touch each side of h. Negatives are scattered outside c.
  let pos = (
    (2.9, 4.0), (3.2, 6.7), (7.1, 5.2), (5.0, 3.1), (6.4, 6.0),
    (4.1, 5.4), (5.6, 4.5), (3.8, 3.4), (6.8, 3.9), (4.6, 6.2),
    (5.9, 5.7), (3.5, 5.0),
  )
  let neg = (
    (0.8, 0.7), (1.0, 9.1), (9.2, 1.1), (9.0, 8.8), (8.8, 4.6),
    (0.6, 5.2), (4.9, 9.2), (5.2, 0.8), (1.3, 2.6), (8.4, 7.4),
    (2.0, 8.9), (9.4, 5.8),
  )
  // negatives — hollow grey circles
  for q in neg {
    circle((sx(q.at(0)), sy(q.at(1))), radius: 0.13,
      fill: white, stroke: 1pt + minus-c)
    let cxp = sx(q.at(0))
    let cyp = sy(q.at(1))
    line((cxp - 0.07, cyp), (cxp + 0.07, cyp), stroke: 1pt + minus-c)
  }
  // positives — filled garnet discs with a tiny white plus
  for q in pos {
    let cxp = sx(q.at(0))
    let cyp = sy(q.at(1))
    circle((cxp, cyp), radius: 0.14, fill: plus-c, stroke: 0.5pt + white)
    line((cxp - 0.07, cyp), (cxp + 0.07, cyp), stroke: 1pt + white)
    line((cxp, cyp - 0.07), (cxp, cyp + 0.07), stroke: 1pt + white)
  }

  // ── labels on small white plates ──────────────────────────────────────────────
  let plate(pos, body, col, sz: 9pt) = {
    content(pos, anchor: "center", box(
      fill: white.transparentize(6%), inset: 1.8pt,
      text(size: sz, weight: "bold", fill: col, body),
    ))
  }
  // c label — top-right inside the frame
  plate((sx(7.4), sy(7.4)), $c$, garnet, sz: 11pt)
  // h label — just inside the hypothesis, top-left
  plate((sx(3.5), sy(6.3)), $h$, blue, sz: 11pt)
  // error-region callout with ε, pointing into the bottom frame strip
  content((sx(5.0), sy(2.4)), anchor: "center", box(
    fill: white.transparentize(6%), inset: 2pt,
    text(size: 8.5pt, fill: garnet)[$c triangle.stroked.t h$]))

  // leader from ε callout (placed below the box) into the frame
  let elab = (sx(5.0), -1.05)
  content(elab, anchor: "north", box(
    fill: white, inset: 2.5pt, stroke: 0.8pt + garnet,
    text(size: 9pt, fill: garnet)[$"err"(h) = D(c triangle.stroked.t h) <= epsilon$]))
  line((sx(5.0), sy(2.4) - 0.18), (sx(5.0), -0.30),
    stroke: 0.8pt + garnet, mark: (start: "stealth", scale: 0.7, fill: garnet))

  // ── axis labels for the instance space ────────────────────────────────────────
  content((PW / 2, -2.15), text(size: 9pt, fill: ink)[instance space  $cal(X)$])
  content((PW + 0.32, PH / 2), anchor: "west",
    text(size: 8pt, fill: muted)[])

  // ── title + the sample-complexity bound ───────────────────────────────────────
  content((PW / 2, PH + 1.15),
    text(size: 11pt, weight: "bold", fill: ink)[PAC learning: target $c$, hypothesis $h$, error region])
  content((PW / 2, PH + 0.62),
    text(size: 8.5pt, fill: ink)[$Pr_(S ~ D^m)[thin "err"(h) <= epsilon thin] >= 1 - delta
      quad "when" quad m >= (4 / epsilon) ln (4 / delta)$])

  // ── side legend panel ─────────────────────────────────────────────────────────
  let lx = PW + 0.70
  let ly = PH - 0.30
  // target concept swatch
  rect((lx, ly - 0.12), (lx + 0.55, ly + 0.12), fill: none, stroke: 2pt + garnet, radius: 0pt)
  content((lx + 0.72, ly), anchor: "west",
    text(size: 8pt, fill: ink)[target concept $c$])
  // hypothesis swatch
  rect((lx, ly - 0.62), (lx + 0.55, ly - 0.38),
    fill: blue.transparentize(90%), stroke: 1.8pt + blue, radius: 0pt)
  content((lx + 0.72, ly - 0.5), anchor: "west",
    text(size: 8pt, fill: ink)[hypothesis $h$ (tightest fit)])
  // error region swatch (hatched)
  rect((lx, ly - 1.12), (lx + 0.55, ly - 0.88),
    fill: garnet.transparentize(88%), stroke: 0.6pt + muted, radius: 0pt)
  // a couple of hatch ticks in the swatch
  for i in range(4) {
    let xa = lx + 0.05 + i * 0.16
    line((xa, ly - 1.12), (calc.min(xa + 0.24, lx + 0.55), ly - 0.88),
      stroke: 0.5pt + garnet.transparentize(40%))
  }
  content((lx + 0.72, ly - 1.0), anchor: "west",
    text(size: 8pt, fill: ink)[error region $c triangle.stroked.t h$])
  // positive sample swatch
  circle((lx + 0.27, ly - 1.6), radius: 0.13, fill: plus-c, stroke: 0.5pt + white)
  line((lx + 0.20, ly - 1.6), (lx + 0.34, ly - 1.6), stroke: 1pt + white)
  line((lx + 0.27, ly - 1.67), (lx + 0.27, ly - 1.53), stroke: 1pt + white)
  content((lx + 0.72, ly - 1.6), anchor: "west",
    text(size: 8pt, fill: ink)[positive ($+$) sample])
  // negative sample swatch
  circle((lx + 0.27, ly - 2.1), radius: 0.13, fill: white, stroke: 1pt + minus-c)
  line((lx + 0.20, ly - 2.1), (lx + 0.34, ly - 2.1), stroke: 1pt + minus-c)
  content((lx + 0.72, ly - 2.1), anchor: "west",
    text(size: 8pt, fill: ink)[negative ($-$) sample])

  // small explanatory note
  content((lx, ly - 2.85), anchor: "north-west", box(width: 4.4cm,
    text(size: 7.5pt, fill: muted)[
      Every positive draw lies in $c$, so $h subset.eq c$ and
      $c triangle.stroked.t h = c without h$. Generalization error is the
      probability mass of this frame.
    ]))
})
