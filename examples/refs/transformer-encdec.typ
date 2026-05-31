// Encoder-decoder transformer (the original "Attention Is All You Need" /
// UDL textbook topology), rebuilt in mlatlas style from architectural knowledge.
//
//   ENCODER:  source embeddings -> N× [bidirectional self-attn + FFN] -> memory
//   DECODER:  target embeddings -> M× [masked self-attn + cross-attn(memory) + FFN]
//             -> Linear+softmax -> next-token probabilities
//
// The defining feature vs a decoder-only stack is the CROSS-ATTENTION link: the
// encoder memory feeds the K,V of every decoder block (the garnet arrow).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let edge = rgb("#243038")
#let f-embed = rgb("#DCE6F2") // pale blue  -> embeddings
#let f-enc = rgb("#E5EFD9") // pale green -> encoder stack
#let f-dec = rgb("#F4E7CF") // pale amber -> decoder stack
#let f-mem = rgb("#ECECEC") // neutral    -> memory tensor
#let f-out = rgb("#F1D9DC") // pale garnet-> output probs

#let CAM = cam-cabinet // upright front face, depth shears up-right

// pure anchor handle for a box at (x,y)
#let A(x, y, w, h, d) = block3d-anchors(origin: (x, y), w: w, h: h, dep: d, cam: CAM)

// a depth-stacked block (N× repeated layer) with ghost copies behind it
#let stack(draw, x, y, w, h, d, fill, n, title, lines) = {
  for k in (2, 1) {
    block3d(
      draw,
      origin: (x + 0.17 * k, y + 0.17 * k),
      w: w, h: h, dep: d,
      base: fill.lighten(8%), edge: edge.lighten(40%), cam: CAM,
    )
  }
  block3d(draw, origin: (x, y), w: w, h: h, dep: d, base: fill, edge: edge, cam: CAM)
  let a = A(x, y, w, h, d)
  // N× multiplier on the left
  draw.content(
    ((a.anchor)("west").at(0) - 0.22, y),
    anchor: "east",
    text(size: 12pt, weight: "bold", fill: c-garnet)[#n#sym.times],
  )
  // title above
  draw.content(
    (x, (a.anchor)("top-screen").at(1) + 0.34),
    text(size: 9.5pt, weight: "bold", fill: ink)[#title],
  )
  // sublayer labels stacked on the front face
  let m = lines.len()
  for (i, s) in lines.enumerate() {
    let yy = y + (m - 1) / 2 * 0.56 - i * 0.56
    draw.content((x - 0.15, yy), text(size: 7.6pt, fill: ink)[#s])
  }
}

#let arr(draw, a, b, color: edge, w: 1.3pt) = draw.line(
  a, b, stroke: w + color, mark: (end: "stealth", scale: 0.8),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // geometry
  let ew = 0.95 // embedding slab width
  let eh = 3.0 // embedding slab height
  let ed = 0.5 // embedding slab depth
  let sw = 2.3 // stack width
  let sh = 3.4 // stack height
  let sd = 1.9 // stack depth
  let mw = 0.9 // memory slab width
  let md = 0.5

  let y-enc = 5.7 // encoder row centre
  let y-dec = 0.0 // decoder row centre

  // x positions
  let x-emb = 0.0
  let x-stk = 3.5
  let x-mem-enc = 7.0 // encoder memory tensor
  let x-emb-d = x-emb
  let x-stk-d = x-stk
  let x-out = 7.6 // logits / softmax
  let x-prob = 10.6 // probability bars

  // ===================================================================== ENCODER
  // source embeddings
  tensor3d(
    draw, origin: (x-emb, y-enc), w: ew, h: eh, dep: ed,
    base: f-embed, edge: edge, cam: CAM,
    title: [Source\ embeddings], x-label: [d],
  )
  let e-emb = A(x-emb, y-enc, ew, eh, ed)
  // token labels (source) down the left edge
  let src = ([\<s\>], [The], [soup], [tasted], [like], [socks])
  for (i, t) in src.enumerate() {
    let yy = y-enc + eh / 2 - 0.34 - i * (eh - 0.68) / (src.len() - 1)
    draw.content(((e-emb.anchor)("west").at(0) - 0.30, yy), anchor: "east", text(size: 7pt, fill: muted)[#t])
  }

  // encoder stack
  stack(
    draw, x-stk, y-enc, sw, sh, sd, f-enc, "N",
    [Encoder block],
    ([Self-attention], [(bidirectional)], [Add & norm], [Feed-forward], [Add & norm]),
  )
  let e-stk = A(x-stk, y-enc, sw, sh, sd)

  // encoder memory (the source encoding handed to the decoder)
  tensor3d(
    draw, origin: (x-mem-enc, y-enc), w: mw, h: eh, dep: md,
    base: f-mem, edge: edge, cam: CAM,
    title: [Memory], x-label: [d],
  )
  let e-mem = A(x-mem-enc, y-enc, mw, eh, md)

  arr(draw, (e-emb.anchor)("east"), (e-stk.anchor)("west"))
  arr(draw, (e-stk.anchor)("east"), (e-mem.anchor)("west"))

  // ===================================================================== DECODER
  // target embeddings
  tensor3d(
    draw, origin: (x-emb-d, y-dec), w: ew, h: eh, dep: ed,
    base: f-embed, edge: edge, cam: CAM,
    title: [Target\ embeddings], x-label: [d],
  )
  let d-emb = A(x-emb-d, y-dec, ew, eh, ed)
  let tgt = ([\<s\>], [la], [soupe], [avait], [le], [goût])
  for (i, t) in tgt.enumerate() {
    let yy = y-dec + eh / 2 - 0.34 - i * (eh - 0.68) / (tgt.len() - 1)
    draw.content(((d-emb.anchor)("west").at(0) - 0.30, yy), anchor: "east", text(size: 7pt, fill: muted)[#t])
  }

  // decoder stack (masked self-attn + cross-attn + FFN)
  stack(
    draw, x-stk-d, y-dec, sw, sh, sd, f-dec, "M",
    [Decoder block],
    ([Masked self-attn], [Add & norm], [Cross-attention], [Add & norm], [Feed-forward]),
  )
  let d-stk = A(x-stk-d, y-dec, sw, sh, sd)

  arr(draw, (d-emb.anchor)("east"), (d-stk.anchor)("west"))

  // Linear + softmax head
  tensor3d(
    draw, origin: (x-out, y-dec), w: mw, h: eh, dep: md,
    base: f-out, edge: edge, cam: CAM,
    title: [Linear\ + softmax], x-label: [vocab],
  )
  let d-out = A(x-out, y-dec, mw, eh, md)
  arr(draw, (d-stk.anchor)("east"), (d-out.anchor)("west"))

  // probability bars (next target token, per position)
  let probs = ([la], [soupe], [avait], [le], [goût], [\<end\>])
  let pb-h = 0.30
  let pb-w = 1.7
  for (i, t) in probs.enumerate() {
    let yy = y-dec + eh / 2 - 0.32 - i * (eh - 0.64) / (probs.len() - 1)
    // a thin distribution bar with one filled (winning) cell
    draw.rect(
      (x-prob, yy - pb-h / 2), (x-prob + pb-w, yy + pb-h / 2),
      fill: rgb("#E9EDF0"), stroke: 0.7pt + edge,
    )
    let win = calc.rem(i * 2 + 1, 5)
    draw.rect(
      (x-prob + win * pb-w / 5, yy - pb-h / 2),
      (x-prob + (win + 1) * pb-w / 5, yy + pb-h / 2),
      fill: c-garnet, stroke: 0.7pt + edge,
    )
    draw.content((x-prob + pb-w + 0.18, yy), anchor: "west", text(size: 7pt, fill: ink)[#t])
  }
  arr(draw, (d-out.anchor)("east"), (x-prob - 0.12, y-dec + eh / 2 - 0.1))
  draw.content(
    (x-prob + pb-w / 2, y-dec + eh / 2 + 0.55),
    text(size: 8pt, fill: muted)[Target-token probabilities],
  )

  // ============================================================ CROSS-ATTENTION
  // encoder memory K,V feed the cross-attention of every decoder block.
  let m-bot = (e-mem.anchor)("bottom-screen")
  let route-x = x-mem-enc
  let d-top = (d-stk.anchor)("top")
  draw.line(
    (m-bot.at(0), m-bot.at(1) - 0.05),
    (route-x, y-dec + sh / 2 + 0.85),
    (d-top.at(0), y-dec + sh / 2 + 0.85),
    (d-top.at(0), d-top.at(1) + 0.04),
    stroke: 1.5pt + c-garnet,
    mark: (end: "stealth", fill: c-garnet, scale: 0.85),
  )
  draw.content(
    ((route-x + d-top.at(0)) / 2, y-dec + sh / 2 + 1.12),
    text(size: 8pt, weight: "bold", fill: c-garnet)[Cross-attention (encoder memory \u{2192} decoder K,V)],
  )

  // panel tags — bold rules + labels far left, clear of the embedding titles
  let tag-x = x-emb - 2.2
  draw.content(
    (tag-x, y-enc), anchor: "center",
    rotate(-90deg, reflow: true, text(size: 13pt, weight: "bold", fill: c-garnet)[ENCODER]),
  )
  draw.content(
    (tag-x, y-dec), anchor: "center",
    rotate(-90deg, reflow: true, text(size: 13pt, weight: "bold", fill: c-garnet)[DECODER]),
  )
  draw.line((tag-x + 0.45, y-enc + eh / 2), (tag-x + 0.45, y-enc - eh / 2), stroke: 1.6pt + c-garnet)
  draw.line((tag-x + 0.45, y-dec + eh / 2), (tag-x + 0.45, y-dec - eh / 2), stroke: 1.6pt + c-garnet)
})
