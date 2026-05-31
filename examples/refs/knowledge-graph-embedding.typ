// Knowledge-graph embedding (TransE) — relations as translations in vector space.
//   A knowledge graph is a set of triples  (h, r, t):  head entity h, relation r,
//   tail entity t. TransE embeds every entity as a point  bold(e) ∈ ℝ^d  and every
//   relation as a TRANSLATION vector  bold(r) ∈ ℝ^d, asking that
//        bold(h) + bold(r)  ≈  bold(t)        for every true triple.
//   The score of a triple is the (negative) distance  f(h,r,t) = -‖h + r − t‖ ;
//   true triples sit near zero residual, corrupted ones far. Crucially the SAME
//   relation vector r applies between many head/tail pairs — so "capital_of" is one
//   fixed arrow that carries Paris→France, Rome→Italy, Tokyo→Japan in parallel.
//   Left: a 2-D embedding plane with entity points, the shared relation arrow drawn
//   from each head (h + r), and the residual h+r→t. Right: the triple table + score.
//   Bespoke cetz vector scene; coordinates computed in Typst. Standard Hamilton-GRL
//   teaching figure, drawn from scratch in mlatlas's print-first style. No tracing.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")   // focal accent: the shared relation vector r
#let blue   = rgb("#466A9F")   // head entities + their + r translation
#let green  = rgb("#65780B")   // tail entities
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let grid-c = rgb("#ECECEC")

// ── the embedding: one shared relation vector r and three (h, t) pairs ──────────
//   r = "capital_of". Heads are capitals, tails are countries. By construction the
//   tails lie NEAR (but not exactly at) h + r, so a small residual is visible — the
//   thing TransE's loss drives toward zero.
#let r = (3.0, 1.4)            // shared relation translation vector

// (name, head point, tail point) — tails ≈ head + r with a little slack
#let triples = (
  (hn: "Paris", tn: "France", h: (0.8, 1.1), t: (4.2, 2.9)),
  (hn: "Rome",  tn: "Italy",  h: (1.4, 3.4), t: (4.1, 5.1)),
  (hn: "Tokyo", tn: "Japan",  h: (3.4, 0.7), t: (6.8, 2.5)),
)

// ── world → canvas mapping ───────────────────────────────────────────────────────
#let X0 = -0.4
#let X1 = 8.0
#let Y0 = -0.4
#let Y1 = 6.2
#let PW = 8.4
#let PH = 7.0
#let sx(x) = (x - X0) / (X1 - X0) * PW
#let sy(y) = (y - Y0) / (Y1 - Y0) * PH
#let S(p) = (sx(p.at(0)), sy(p.at(1)))   // map a world point to canvas

// alias the standard-library rotate so it survives the cetz.draw import shadow
#let std-rotate = rotate

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── plot frame ─────────────────────────────────────────────────────────────────
  rect((0, 0), (PW, PH), fill: white, stroke: 1pt + ink)

  // light interior grid (every world unit)
  for gx in range(0, 9) {
    line((sx(gx), 0), (sx(gx), PH), stroke: 0.5pt + grid-c)
  }
  for gy in range(0, 7) {
    line((0, sy(gy)), (PW, sy(gy)), stroke: 0.5pt + grid-c)
  }

  // ── helpers ──────────────────────────────────────────────────────────────────
  let halo-dot(p, rad, col) = {
    let q = S(p)
    circle(q, radius: rad + 0.05, fill: white, stroke: none)
    circle(q, radius: rad, fill: col, stroke: 0.6pt + col)
  }
  let lbl(p, body, col, dx: 0, dy: 0, anc: "center") = {
    let q = S(p)
    content((q.at(0) + dx, q.at(1) + dy), anchor: anc,
      box(fill: white.transparentize(10%), inset: 1.4pt,
        text(size: 8pt, fill: col, weight: "bold", body)))
  }

  // ── per-triple geometry: translation arrow (h → h+r) and residual (h+r → t) ────
  for tr in triples {
    let h = tr.h
    let t = tr.t
    let hr = (h.at(0) + r.at(0), h.at(1) + r.at(1))   // h + r  (translated head)

    // relation translation arrow  h → h+r  (garnet, the focal shared structure)
    line(S(h), S(hr),
      stroke: 2pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.9))

    // residual  h+r → t  : what the TransE loss pushes to zero  (dashed, muted)
    line(S(hr), S(t),
      stroke: (paint: faint, thickness: 1.1pt, dash: "dashed"),
      mark: (end: "stealth", fill: faint, scale: 0.7))

    // small hollow tick at the translated head h+r
    let qhr = S(hr)
    circle(qhr, radius: 0.07, fill: white, stroke: 0.9pt + garnet)
  }

  // ── entity points + labels (drawn above the arrows) ───────────────────────────
  for tr in triples {
    halo-dot(tr.h, 0.10, blue)
    halo-dot(tr.t, 0.10, green)
  }
  // labels placed individually to avoid overlap
  lbl(triples.at(0).h, [Paris], blue, dx: -0.16, dy: -0.16, anc: "north-east")
  lbl(triples.at(0).t, [France], green, dx: 0.20, dy: 0.16, anc: "south-west")
  lbl(triples.at(1).h, [Rome], blue, dx: -0.16, dy: 0.14, anc: "south-east")
  lbl(triples.at(1).t, [Italy], green, dx: 0.18, dy: 0.12, anc: "south-west")
  lbl(triples.at(2).h, [Tokyo], blue, dx: 0.16, dy: -0.18, anc: "north-west")
  lbl(triples.at(2).t, [Japan], green, dx: 0.18, dy: -0.10, anc: "north-west")

  // ── tag the shared relation vector on the middle (Paris) arrow ────────────────
  let h0 = triples.at(0).h
  let hr0 = (h0.at(0) + r.at(0), h0.at(1) + r.at(1))
  let mid = ((h0.at(0) + hr0.at(0)) / 2, (h0.at(1) + hr0.at(1)) / 2)
  lbl(mid, $bold(r)$, garnet, dx: 0.05, dy: 0.34, anc: "south")
  content((sx(mid.at(0)) + 0.05, sy(mid.at(1)) + 0.70), anchor: "south",
    text(size: 7pt, fill: garnet, style: "italic")[capital#sym.space.thin of])

  // residual tag near the Paris triple's dashed segment
  let t0 = triples.at(0).t
  let rmid = ((hr0.at(0) + t0.at(0)) / 2, (hr0.at(1) + t0.at(1)) / 2)
  content((sx(rmid.at(0)) - 0.22, sy(rmid.at(1)) + 0.02), anchor: "east",
    box(fill: white.transparentize(12%), inset: 1.2pt,
      text(size: 6.5pt, fill: muted)[$norm(bold(h) + bold(r) - bold(t))$]))

  // ── axis ticks + labels ──────────────────────────────────────────────────────
  for gx in range(0, 9) {
    line((sx(gx), 0), (sx(gx), -0.12), stroke: 0.8pt + ink)
  }
  for gy in range(0, 7) {
    line((0, sy(gy)), (-0.12, sy(gy)), stroke: 0.8pt + ink)
  }
  content((PW / 2, -0.66), text(size: 8.5pt, fill: muted)[embedding dim $1$])
  content((-0.66, PH / 2), std-rotate(-90deg, reflow: true,
    text(size: 8.5pt, fill: muted)[embedding dim $2$]))

  // ── title + defining relation, top of the embedding plane ─────────────────────
  content((PW / 2, PH + 1.18),
    text(size: 12pt, weight: "bold", fill: ink)[Knowledge-graph embedding — TransE])
  content((PW / 2, PH + 0.62),
    text(size: 10pt, fill: garnet)[$bold(h) + bold(r) approx bold(t)$])
  content((PW / 2, PH + 0.22),
    text(size: 7.5pt, fill: muted)[one relation = one translation vector, shared across all its triples])

  // ── side panel: triple table + score ──────────────────────────────────────────
  let lx = PW + 0.70
  let ty = PH + 0.55

  content((lx, ty), anchor: "north-west",
    text(size: 9.5pt, weight: "bold", fill: ink)[Triples $(h, r, t)$])

  // table header rule
  let tw = 4.7
  let row-h = 0.52
  let col-h = lx + 0.10        // head column x
  let col-r = lx + 1.55        // relation column x
  let col-t = lx + 3.25        // tail column x
  let hdr-y = ty - 0.70

  content((col-h, hdr-y), anchor: "north-west", text(size: 7.5pt, fill: muted)[head $h$])
  content((col-r, hdr-y), anchor: "north-west", text(size: 7.5pt, fill: muted)[relation $r$])
  content((col-t, hdr-y), anchor: "north-west", text(size: 7.5pt, fill: muted)[tail $t$])
  line((lx, hdr-y - 0.28), (lx + tw, hdr-y - 0.28), stroke: 0.8pt + ink)

  let rows = (
    ([Paris], [France]),
    ([Rome],  [Italy]),
    ([Tokyo], [Japan]),
  )
  for (i, rw) in rows.enumerate() {
    let yy = hdr-y - 0.28 - row-h * (i + 0.75)
    content((col-h, yy), anchor: "west", text(size: 8pt, fill: blue)[#rw.at(0)])
    content((col-r, yy), anchor: "west", text(size: 8pt, fill: garnet, style: "italic")[capital#sym.space.thin of])
    content((col-t, yy), anchor: "west", text(size: 8pt, fill: green)[#rw.at(1)])
    if i < rows.len() - 1 {
      line((lx, yy - row-h / 2), (lx + tw, yy - row-h / 2), stroke: 0.4pt + grid-c)
    }
  }
  let tbl-bot = hdr-y - 0.28 - row-h * (rows.len() + 0.25)
  line((lx, tbl-bot), (lx + tw, tbl-bot), stroke: 0.8pt + ink)
  // table side borders
  line((lx, hdr-y - 0.28), (lx, tbl-bot), stroke: 0.8pt + ink)
  line((lx + tw, hdr-y - 0.28), (lx + tw, tbl-bot), stroke: 0.8pt + ink)

  // ── scoring function block ─────────────────────────────────────────────────────
  let sy0 = tbl-bot - 0.62
  content((lx, sy0), anchor: "north-west",
    text(size: 9.5pt, weight: "bold", fill: ink)[Scoring a triple])
  content((lx, sy0 - 0.55), anchor: "north-west",
    text(size: 9pt, fill: ink)[$f(h, r, t) = -norm(bold(h) + bold(r) - bold(t))_(1 slash 2)$])
  content((lx, sy0 - 1.20), anchor: "north-west",
    text(size: 7.5pt, fill: muted)[high score (#sym.tilde.op 0): true triple])
  content((lx, sy0 - 1.62), anchor: "north-west",
    text(size: 7.5pt, fill: muted)[low score: corrupted triple $(h, r, t')$])

  // ── margin ranking loss block ──────────────────────────────────────────────────
  let ly0 = sy0 - 2.30
  content((lx, ly0), anchor: "north-west",
    text(size: 9.5pt, weight: "bold", fill: ink)[Margin loss])
  content((lx, ly0 - 0.58), anchor: "north-west",
    text(size: 8.5pt, fill: ink)[$cal(L) = sum [gamma + d(bold(h){+}bold(r), bold(t)) - d(bold(h){+}bold(r), bold(t)')]_+$])
  content((lx, ly0 - 1.18), anchor: "north-west",
    text(size: 7.5pt, fill: muted)[push true tail closer than a corrupted tail $t'$ by margin $gamma$])

  // ── legend ──────────────────────────────────────────────────────────────────────
  let gy0 = ly0 - 1.95
  let leg(yy, drawer, lbl-body) = {
    drawer(yy)
    content((lx + 0.95, yy), anchor: "west", text(size: 7.5pt, fill: muted, lbl-body))
  }
  leg(gy0, yy => {
    line((lx, yy), (lx + 0.78, yy),
      stroke: 2pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.8))
  }, [relation translation $bold(r)$])
  leg(gy0 - 0.46, yy => {
    line((lx, yy), (lx + 0.78, yy),
      stroke: (paint: faint, thickness: 1.1pt, dash: "dashed"),
      mark: (end: "stealth", fill: faint, scale: 0.6))
  }, [residual $bold(h){+}bold(r){-}bold(t)$])
  leg(gy0 - 0.92, yy => {
    circle((lx + 0.39, yy), radius: 0.10, fill: blue, stroke: 0.6pt + blue)
  }, [head entity (capital)])
  leg(gy0 - 1.38, yy => {
    circle((lx + 0.39, yy), radius: 0.10, fill: green, stroke: 0.6pt + green)
  }, [tail entity (country)])
})
