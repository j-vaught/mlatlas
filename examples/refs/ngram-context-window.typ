// n-gram language model as a SLIDING fixed-width context window.
//
// An n-gram LM approximates the next-token distribution by conditioning only on
// the previous n-1 tokens (the Markov assumption): instead of
//   P(w_t | w_1 … w_{t-1})  it uses  P(w_t | w_{t-n+1} … w_{t-1}).
// Here n = 4, so the context window has fixed width n-1 = 3. The window is the
// plate drawn around three consecutive tokens; an arrow carries that context
// into a prediction node that emits a probability over the next token w_t.
//
// The two stacked rows show the defining property: the window SLIDES one
// position to the right per word. In row 1 the context is (w_{t-3}, w_{t-2},
// w_{t-1}) predicting w_t; in row 2 the realised token w_t has joined the
// history, the oldest token w_{t-3} has fallen out, and the window now covers
// (w_{t-2}, w_{t-1}, w_t) predicting w_{t+1}. Fixed width, one-step stride.
//
// Original mlatlas figure of a standard NLP concept (Jurafsky & Martin SLP3,
// ch. "N-gram Language Models"). Built from knowledge, not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette: print-first, garnet a sparse focal accent ----------------
#let garnet  = rgb("#73000A")
#let ink     = rgb("#000000")
#let muted   = rgb("#5C5C5C")
#let faint   = rgb("#A2A2A2")
#let edgecol = rgb("#363636")
#let tokfill = white               // token in the window
#let pastfil = rgb("#ECECEC")      // history outside the window
#let dropfil = rgb("#ECECEC")      // token that has fallen out of the window
#let predfil = garnet.transparentize(90%)  // prediction node, sparse accent
#let platecol = garnet             // the sliding window outline (focal)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ---- layout constants ------------------------------------------------------
  let tw   = 1.35     // token cell width
  let th   = 0.78     // token cell height
  let gap  = 0.18     // horizontal gap between cells
  let step = tw + gap // x-stride between token centers
  let x0   = 0.0      // x of first token center

  // token sequence (a short sentence)
  let toks = ([the], [cat], [sat], [on], [the], [mat])
  // index i = 0..5 maps to positions w_{t-3} … w_{t+2}
  let sublabels = (
    [#text(size: 7pt, fill: muted)[$w_(t-3)$]],
    [#text(size: 7pt, fill: muted)[$w_(t-2)$]],
    [#text(size: 7pt, fill: muted)[$w_(t-1)$]],
    [#text(size: 7pt, fill: muted)[$w_t$]],
    [#text(size: 7pt, fill: muted)[$w_(t+1)$]],
    [#text(size: 7pt, fill: muted)[$w_(t+2)$]],
  )

  let cx(i) = x0 + i * step

  // draw one token cell at (center-x, center-y) with fill + outline + label
  let cell(i, y, idx, fill: tokfill, stroke: edgecol, txt: muted) = {
    let cxv = cx(i)
    rect(
      (cxv - tw/2, y - th/2), (cxv + tw/2, y + th/2),
      fill: fill, stroke: 0.7pt + stroke, radius: 0pt,
    )
    content((cxv, y + 0.02), text(fill: txt, size: 9.5pt)[#toks.at(idx)])
    content((cxv, y - th/2 - 0.26), sublabels.at(idx))
  }

  // ---- ROW 1: predicting w_t from context (w_{t-3}, w_{t-2}, w_{t-1}) --------
  let y1 = 0.0
  // tokens 0,1,2 = active window ; token 3 = the next token being predicted
  // window spans cells 0..2
  // draw history/context cells
  cell(0, y1, 0)
  cell(1, y1, 1)
  cell(2, y1, 2)
  // the cell to be predicted (drawn faint / dashed to mark it as unknown target)
  let cxp = cx(3)
  rect(
    (cxp - tw/2, y1 - th/2), (cxp + tw/2, y1 + th/2),
    fill: white, stroke: (paint: faint, thickness: 0.7pt, dash: "dashed"), radius: 0pt,
  )
  content((cxp, y1 + 0.02), text(fill: faint, size: 9.5pt)[?])
  content((cxp, y1 - th/2 - 0.26), sublabels.at(3))

  // sliding-window plate around cells 0..2 (the n-1 context)
  let pl = 0.20  // plate padding
  rect(
    (cx(0) - tw/2 - pl, y1 - th/2 - pl), (cx(2) + tw/2 + pl, y1 + th/2 + pl),
    stroke: 1.4pt + platecol, radius: 0pt,
  )
  content(
    (cx(1), y1 + th/2 + pl + 0.26),
    text(fill: platecol, size: 8pt, weight: "bold")[context window  ($n-1 = 3$)],
  )

  // arrow from window into the prediction node
  let predx = cx(3) + 0.5
  let predy = y1 - 2.0
  // route: down from middle of window, then into pred node
  line(
    (cx(1), y1 - th/2 - pl), (cx(1), predy + 0.40),
    stroke: 0.9pt + edgecol,
  )
  line(
    (cx(1), predy + 0.40), (predx - 1.55, predy + 0.40),
    stroke: 0.9pt + edgecol, mark: (end: "stealth", fill: edgecol, scale: 0.7),
  )

  // prediction node: P(w_t | context)
  let pw = 3.45
  let ph = 0.95
  rect(
    (predx - pw/2, predy - ph/2), (predx + pw/2, predy + ph/2),
    fill: predfil, stroke: 1.0pt + garnet, radius: 0pt,
  )
  content((predx, predy + 0.17), text(fill: ink, size: 9pt)[$P(w_t mid(|) w_(t-3), w_(t-2), w_(t-1))$])
  content((predx, predy - 0.24), text(fill: muted, size: 7.5pt)[softmax over vocabulary])

  // arrow from prediction node up to the realised next token (fills the ? cell)
  // route up the RIGHT side, clear of the node body, into the bottom of the ? cell
  let upx = cxp + tw/2 + 0.55
  line(
    (predx + pw/2, predy), (upx, predy),
    stroke: 0.9pt + garnet,
  )
  line(
    (upx, predy), (upx, y1 - th/2 - 0.20),
    stroke: 0.9pt + garnet,
  )
  line(
    (upx, y1 - th/2 - 0.20), (cxp + tw/2 - 0.18, y1 - th/2 - 0.20),
    stroke: 0.9pt + garnet,
  )
  line(
    (cxp + tw/2 - 0.18, y1 - th/2 - 0.20), (cxp + tw/2 - 0.18, y1 - th/2 - 0.02),
    stroke: 0.9pt + garnet, mark: (end: "stealth", fill: garnet, scale: 0.7),
  )
  content(
    (upx + 0.22, (predy + ph/2 + (y1 - th/2 - 0.20))/2),
    anchor: "west",
    text(fill: garnet, size: 7.5pt, style: "italic")[argmax /\ sample],
  )

  // ---- divider / "slide one position" connector -----------------------------
  let y2 = -4.4
  // big down arrow between the rows, placed at the far left clear of the nodes
  let slidex = cx(0) - tw/2 - 0.55
  line(
    (slidex, y1 - th/2 - 0.95), (slidex, y2 + th/2 + 0.55),
    stroke: 1.1pt + muted, mark: (end: "stealth", fill: muted, scale: 0.8),
  )
  content(
    (slidex - 0.05, (y1 + y2)/2 - 0.45),
    anchor: "east",
    text(fill: muted, size: 8pt)[slide\ window\ +1\ token],
  )

  // ---- ROW 2: window slid one step right — predicting w_{t+1} ----------------
  // now token 0 (w_{t-3}) has fallen OUT of the window; window covers cells 1..3
  // token 3 (w_t) is now REALISED (it was the prediction above)
  // dropped token (faded, marked as out of context)
  cell(0, y2, 0, fill: dropfil, stroke: faint, txt: faint)
  cell(1, y2, 1)
  cell(2, y2, 2)
  cell(3, y2, 3)
  // next prediction target w_{t+1}
  let cxp2 = cx(4)
  rect(
    (cxp2 - tw/2, y2 - th/2), (cxp2 + tw/2, y2 + th/2),
    fill: white, stroke: (paint: faint, thickness: 0.7pt, dash: "dashed"), radius: 0pt,
  )
  content((cxp2, y2 + 0.02), text(fill: faint, size: 9.5pt)[?])
  content((cxp2, y2 - th/2 - 0.26), sublabels.at(4))

  // sliding-window plate around cells 1..3
  rect(
    (cx(1) - tw/2 - pl, y2 - th/2 - pl), (cx(3) + tw/2 + pl, y2 + th/2 + pl),
    stroke: 1.4pt + platecol, radius: 0pt,
  )
  content(
    (cx(2), y2 + th/2 + pl + 0.26),
    text(fill: platecol, size: 8pt, weight: "bold")[context window  (slid +1)],
  )

  // "fell out of window" annotation on dropped token
  content(
    (cx(0), y2 + th/2 + pl + 0.26),
    text(fill: faint, size: 7.5pt, style: "italic")[dropped],
  )

  // arrow from window 2 into prediction node 2
  let predx2 = cx(4) + 0.5
  let predy2 = y2 - 2.0
  line(
    (cx(2), y2 - th/2 - pl), (cx(2), predy2 + 0.40),
    stroke: 0.9pt + edgecol,
  )
  line(
    (cx(2), predy2 + 0.40), (predx2 - 1.55, predy2 + 0.40),
    stroke: 0.9pt + edgecol, mark: (end: "stealth", fill: edgecol, scale: 0.7),
  )
  rect(
    (predx2 - pw/2, predy2 - ph/2), (predx2 + pw/2, predy2 + ph/2),
    fill: predfil, stroke: 1.0pt + garnet, radius: 0pt,
  )
  content((predx2, predy2 + 0.16), text(fill: ink, size: 9pt)[$P(w_(t+1) mid(|) w_(t-2), w_(t-1), w_t)$])
  content((predx2, predy2 - 0.22), text(fill: muted, size: 7.5pt)[softmax over vocabulary])
})

#v(4pt)
#align(center)[#text(size: 8pt, fill: rgb("#5C5C5C"))[
  4-gram model: $P(w_t mid(|) w_1 ... w_(t-1)) approx P(w_t mid(|) w_(t-3), w_(t-2), w_(t-1))$ — fixed width $n-1$, stride $1$
]]
