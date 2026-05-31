// Sequence-to-sequence encoder–decoder (Sutskever et al. 2014; Cho et al. 2014).
// Rebuilt in mlatlas print-first style from the standard textbook topology
// (D2L; Goodfellow et al.; Jurafsky & Martin SLP3; Eisenstein).
//
//   ENCODER  reads the source x_1..x_T with a recurrent cell, passing the hidden
//            state left-to-right. The FINAL hidden state is the CONTEXT / "thought"
//            vector c (garnet) — a fixed-length summary of the whole source.
//   CONTEXT  initializes the decoder state.
//   DECODER  autoregressively emits the target y_1..y_S. Each step takes the
//            previous *target* token as input; at training time that is the GROUND
//            TRUTH (teacher forcing, dashed gutter), at inference its own previous
//            prediction (autoregressive feedback, solid gutter).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let c-garnet = rgb("#73000A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let edge = rgb("#243038")
#let f-enc = rgb("#DCE6F2")   // pale blue  -> encoder cells
#let f-dec = rgb("#E5EFD9")   // pale green -> decoder cells
#let f-in = rgb("#ECECEC")    // neutral    -> token boxes
#let f-out = rgb("#FFF2E3")   // beige      -> emitted token boxes

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- geometry -------------------------------------------------------------
  let cw = 1.25            // cell width
  let ch = 1.1             // cell height
  let dx = 2.2             // step spacing
  let y-cell = 0.0         // recurrent-cell row
  let y-in = -2.3          // input-token row (below)
  let y-out = 2.3          // output-token / emission row (above)
  let gap = 2.3            // extra gap between encoder and decoder columns

  let enc-n = 4            // encoder steps (T)
  let dec-n = 4            // decoder steps (S)

  // x of cell i (encoder 0..enc-n-1, then a gap, then decoder)
  let enc-x(i) = i * dx
  let dec-x(j) = (enc-n - 1) * dx + gap + dx + j * dx
  let ctx-x = (enc-n - 1) * dx + gap + dx / 2 - 0.3  // context vector sits in the gap

  let arr(a, b, color: edge, w: 1.3pt, s: 0.7) = draw.line(
    a, b, stroke: w + color, mark: (end: "stealth", scale: s),
  )
  let wire(a, b, color: edge, w: 1.2pt) = draw.line(a, b, stroke: w + color)

  // a sharp-cornered labelled cell
  let cell(cx, cy, body, fill) = {
    draw.rect(
      (cx - cw / 2, cy - ch / 2), (cx + cw / 2, cy + ch / 2),
      fill: fill, stroke: 1.1pt + edge, radius: 0pt,
    )
    draw.content((cx, cy), text(size: 8.5pt, fill: ink)[#body])
  }
  // a small token box
  let token(cx, cy, body, fill) = {
    draw.rect(
      (cx - 0.62, cy - 0.34), (cx + 0.62, cy + 0.34),
      fill: fill, stroke: 0.9pt + edge, radius: 0pt,
    )
    draw.content((cx, cy), text(size: 8pt, fill: ink)[#body])
  }

  // source / target tokens
  let src = ([the], [cat], [sat], [\<eos\>])
  let tgt-in = ([\<bos\>], [le], [chat], [s'assit])      // decoder inputs (prev token)
  let tgt-out = ([le], [chat], [s'assit], [\<eos\>])     // decoder emissions

  // ============================================================== ENCODER
  for i in range(enc-n) {
    let cx = enc-x(i)
    cell(cx, y-cell, [Encoder\ RNN], f-enc)
    token(cx, y-in, src.at(i), f-in)
    // input -> cell
    arr((cx, y-in + 0.34), (cx, y-cell - ch / 2))
    // recurrent hidden state left -> right
    if i > 0 {
      arr((enc-x(i - 1) + cw / 2, y-cell), (cx - cw / 2, y-cell))
    }
  }
  // h label on the first encoder recurrence
  draw.content(
    (enc-x(0) + dx / 2, y-cell + 0.32), text(size: 7.5pt, fill: muted)[$h_t^"enc"$],
  )

  // ============================================================== CONTEXT VECTOR
  // final encoder hidden state -> context "thought" vector c
  let last-enc = enc-x(enc-n - 1)
  let first-dec = dec-x(0)
  // context node (garnet, the focal element)
  let cyc = y-cell
  draw.rect(
    (ctx-x - 0.55, cyc - 0.55), (ctx-x + 0.55, cyc + 0.55),
    fill: c-garnet, stroke: 1.2pt + edge, radius: 0pt,
  )
  draw.content((ctx-x, cyc), text(size: 12pt, weight: "bold", fill: white)[$c$])
  draw.content(
    (ctx-x, cyc + 1.0), text(size: 7.6pt, fill: c-garnet)[context\ vector],
  )
  // encoder final state -> context
  arr((last-enc + cw / 2, y-cell), (ctx-x - 0.55, cyc), color: c-garnet, w: 1.6pt)
  // context -> decoder initial state (initializes the decoder hidden state)
  arr((ctx-x + 0.55, cyc), (first-dec - cw / 2, y-cell), color: c-garnet, w: 1.6pt)
  draw.content(
    (ctx-x, cyc - 1.0), text(size: 7pt, fill: c-garnet)[init $h_0^"dec"$],
  )

  // ============================================================== DECODER
  for j in range(dec-n) {
    let cx = dec-x(j)
    cell(cx, y-cell, [Decoder\ RNN], f-dec)
    // decoder input token (previous target) below
    token(cx, y-in, tgt-in.at(j), f-in)
    arr((cx, y-in + 0.34), (cx, y-cell - ch / 2))
    // emitted token above
    token(cx, y-out, tgt-out.at(j), f-out)
    arr((cx, y-cell + ch / 2), (cx, y-out - 0.34))
    // softmax/argmax label on the emission arrow (first step only)
    if j == 0 {
      draw.content(
        (cx + 0.42, (y-cell + ch / 2 + y-out - 0.34) / 2),
        anchor: "west", text(size: 6.8pt, fill: muted)[softmax],
      )
    }
    // recurrent decoder hidden state left -> right
    if j > 0 {
      arr((dec-x(j - 1) + cw / 2, y-cell), (cx - cw / 2, y-cell))
    }
  }
  draw.content(
    (dec-x(0) + dx / 2, y-cell + 0.32), text(size: 7.5pt, fill: muted)[$h_s^"dec"$],
  )

  // ============================================================== FEEDBACK GUTTERS
  // (1) AUTOREGRESSIVE feedback (inference): emission y_s -> next decoder input.
  //     routed up to a high gutter, across, then DOWN the clear channel between
  //     cells and IN to the next input token from the left (solid grey).
  let gut-hi = y-out + 1.05
  for j in range(dec-n - 1) {
    let from-x = dec-x(j)
    let chan-x = dec-x(j + 1) - dx / 2   // clear channel between adjacent cells
    let box-left = dec-x(j + 1) - 0.62
    wire((from-x, y-out + 0.34), (from-x, gut-hi), color: muted, w: 1.0pt)
    wire((from-x, gut-hi), (chan-x, gut-hi), color: muted, w: 1.0pt)
    wire((chan-x, gut-hi), (chan-x, y-in), color: muted, w: 1.0pt)
    arr((chan-x, y-in), (box-left, y-in), color: muted, w: 1.0pt)
  }
  // (2) TEACHER FORCING (training): the ground-truth previous target token is fed
  //     in instead — shown as a dashed drop into each decoder input box.
  let gut-lo = y-in - 1.0
  for j in range(dec-n) {
    let cx = dec-x(j)
    draw.line(
      (cx + 0.62, gut-lo), (cx + 0.62, y-in),
      stroke: (paint: c-garnet, thickness: 1.0pt, dash: "dashed"),
      mark: (end: "stealth", fill: c-garnet, scale: 0.6),
    )
  }
  wire((dec-x(0) - 0.5, gut-lo), (dec-x(dec-n - 1) + 0.62, gut-lo),
    color: c-garnet, w: 1.0pt)
  draw.content(
    (dec-x(0) - 0.6, gut-lo), anchor: "east",
    text(size: 7pt, fill: c-garnet)[ground\ truth],
  )

  // gutter legend tags
  draw.content(
    (dec-x(dec-n - 1) + 0.9, gut-hi), anchor: "west",
    text(size: 7pt, fill: muted)[autoregressive\ feedback],
  )
  draw.content(
    (dec-x(dec-n - 1) + 0.9, gut-lo), anchor: "west",
    text(size: 7pt, fill: c-garnet)[teacher forcing\ (dashed)],
  )

  // ============================================================== PANEL TAGS
  let enc-mid = (enc-x(0) + enc-x(enc-n - 1)) / 2
  let dec-mid = (dec-x(0) + dec-x(dec-n - 1)) / 2
  draw.content(
    (enc-mid, y-in - 1.55), text(size: 10pt, weight: "bold", fill: ink)[ENCODER],
  )
  draw.content(
    (enc-mid, y-in - 2.05), text(size: 7.5pt, fill: muted)[reads source sequence],
  )
  draw.content(
    (dec-mid, y-out + 2.1), text(size: 10pt, weight: "bold", fill: ink)[DECODER],
  )
  draw.content(
    (dec-mid, y-out + 1.62), text(size: 7.5pt, fill: muted)[generates target autoregressively],
  )

  // row labels far left
  draw.content((enc-x(0) - 1.7, y-out), anchor: "east", text(size: 7.5pt, fill: muted)[emitted $hat(y)_s$])
  draw.content((enc-x(0) - 1.7, y-cell), anchor: "east", text(size: 7.5pt, fill: muted)[hidden state])
  draw.content((enc-x(0) - 1.7, y-in), anchor: "east", text(size: 7.5pt, fill: muted)[input token])
})
