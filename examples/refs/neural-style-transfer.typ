// Neural style transfer (Gatys et al. 2016; Dive into Deep Learning §14.12).
// A single FROZEN pretrained CNN (e.g. VGG-19) is used as a fixed feature extractor.
// Three images are pushed through the SAME network with SHARED weights:
//   • content image  c   — supplies the target content (one DEEP layer)
//   • style image    s   — supplies the target style   (several layers, as Gram matrices)
//   • synthesized X      — the only thing that is OPTIMIZED (the pixels are the variables)
//
// Losses (computed by comparing X's features to the two reference images' features):
//   content loss  L_c = ‖ F^ℓ(X) − F^ℓ(c) ‖²            on a deep "content" layer ℓ
//   style   loss  L_s = Σ_ℓ ‖ G^ℓ(X) − G^ℓ(s) ‖²        Gram matrices on several layers
//   total          L  = α L_c + β L_s
// Gradient descent flows ∂L/∂X back onto the SYNTHESIZED IMAGE PIXELS (dashed garnet
// feedback edge); the CNN weights never change. Built from textbook knowledge in
// mlatlas's print-first house style — no image traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let blue   = rgb("#466A9F")
#let green  = rgb("#65780B")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")
#let b30    = rgb("#C7C7C7")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: ink)[Neural style transfer: optimizing an image through a frozen CNN]

  #v(3pt)
  #text(size: 9pt, fill: muted)[
    one pretrained, *frozen* CNN as a fixed extractor — only the synthesized pixels $bold(X)$ are trained
  ]

  #v(14pt)

  #cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // ── styling helpers ──────────────────────────────────────────────────────
    let fwd  = (stroke: 1.1pt + ink, mark: (end: "stealth", scale: 0.75))
    let tap  = (stroke: 1pt + muted, mark: (end: "stealth", scale: 0.7))
    let grad = (stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed"), mark: (end: "stealth", scale: 0.85))

    // a small framed "image" tile
    let tile(cx, cy, fill, accent, lbl, sub) = {
      let w = 1.05
      rect((cx - w/2, cy - w/2), (cx + w/2, cy + w/2), fill: fill, stroke: 1.4pt + accent, radius: 0pt)
      // a couple of interior strokes to read as a picture, not a plain box
      line((cx - w/2, cy - 0.1), (cx + w/2, cy - 0.1), stroke: 0.5pt + accent.transparentize(45%))
      line((cx + 0.05, cy - w/2), (cx + 0.05, cy + w/2), stroke: 0.5pt + accent.transparentize(45%))
      content((cx, cy - w/2 - 0.30), text(size: 8.5pt, weight: "bold", fill: ink)[#lbl])
      if sub != none { content((cx, cy - w/2 - 0.62), text(size: 6.5pt, fill: muted)[#sub]) }
    }

    // a conv "block" of the frozen CNN backbone (a thin upright slab + stacked echo)
    let convblk(cx, cy, w, lbl) = {
      let h = 1.5
      // back echo (depth)
      rect((cx - w/2 + 0.10, cy - h/2 + 0.10), (cx + w/2 + 0.10, cy + h/2 + 0.10),
           fill: b30.transparentize(30%), stroke: 0.7pt + muted, radius: 0pt)
      rect((cx - w/2, cy - h/2), (cx + w/2, cy + h/2),
           fill: b10, stroke: 1.1pt + ink, radius: 0pt)
      // vertical label inside the thin slab (so the through-arrows never clip it)
      content((cx, cy), angle: 90deg, text(size: 7pt, fill: ink)[#lbl])
    }

    // ── 1.  The three input images, stacked on the left ───────────────────────
    // STYLE on top (aligns with the Gram / style-loss row), CONTENT on the bottom
    // (aligns with the content-loss row): keeps the loss wiring crossing-free.
    let imgx = -5.6
    let cy-s =  3.0     // style image (top)
    let cy-x =  0.0     // synthesized image (middle, the variable)
    let cy-c = -3.0     // content image (bottom)

    tile(imgx, cy-s, beige,  green,  [style $bold(s)$],       [reference])
    tile(imgx, cy-c, beige,  blue,   [content $bold(c)$],     [reference])
    // synthesized image — the focal, garnet, the ONLY thing optimized
    tile(imgx, cy-x, white,  garnet, [synth $bold(X)$],       none)
    content((imgx, cy-x + 1.05/2 + 0.26), text(size: 6.5pt, fill: garnet)[init: noise / copy of $bold(c)$])

    // ── 2.  The shared, frozen CNN backbone (drawn ONCE in the middle) ────────
    // It is the same network applied to all three images; we draw the spine for X
    // and tap the layers. c and s are routed in to indicate "same weights".
    let bx0 = -3.35                      // first conv block x
    let dx  = 1.55                       // block spacing
    let names = ("conv1", "conv2", "conv3", "conv4", "conv5")
    let widths = (0.62, 0.58, 0.54, 0.50, 0.46)
    let bxs = range(names.len()).map(i => bx0 + i * dx)

    // frozen-CNN container plate
    let plx0 = bx0 - 0.95
    let plx1 = bxs.last() + 0.95
    let ply0 = cy-x - 1.30
    let ply1 = cy-x + 1.30
    rect((plx0, ply0), (plx1, ply1), fill: rgb("#FBFBFB"), stroke: (paint: muted, thickness: 0.8pt, dash: "densely-dashed"), radius: 0pt)
    content(((plx0 + plx1)/2, ply1 + 0.30), text(size: 8.5pt, weight: "bold", fill: ink)[frozen pretrained CNN  (VGG-19)])
    content((plx0 + 0.02, ply0 + 0.20), anchor: "west", text(size: 6.5pt, fill: muted)[weights fixed · no gradient])
    // frozen tag (snowflake-style marker, sharp)
    content((plx1 - 0.55, ply1 - 0.22), text(size: 7pt, weight: "bold", fill: muted)[FROZEN])

    // draw the conv blocks + forward arrows along the X spine
    for (i, nm) in names.enumerate() {
      convblk(bxs.at(i), cy-x, widths.at(i), nm)
      if i > 0 {
        line((bxs.at(i - 1) + widths.at(i - 1)/2, cy-x), (bxs.at(i) - widths.at(i)/2, cy-x), ..fwd)
      }
    }
    // X enters the backbone
    line((imgx + 1.05/2, cy-x), (bxs.at(0) - widths.at(0)/2, cy-x), ..fwd)

    // c and s feed the SAME frozen CNN (drawn as routed arrows into the first block,
    // labelled "shared weights").  Style (top) and content (bottom) merge into the
    // backbone entrance from above / below the synthesized spine.
    let into = (bxs.at(0) - widths.at(0)/2 - 0.05)
    let col  = into - 0.62
    line((imgx + 1.05/2, cy-s), (col, cy-s), (col, cy-x + 0.95), (into, cy-x + 0.55), ..tap)
    line((imgx + 1.05/2, cy-c), (col, cy-c), (col, cy-x - 0.95), (into, cy-x - 0.55), ..tap)
    content((col - 0.20, cy-x), anchor: "center", angle: 90deg, text(size: 6.5pt, fill: muted)[shared weights])

    // ── 3.  Taps.  Style taps = several layers; content tap = one deep layer ──
    // style taps come off conv1..conv4 (top), each into a Gram op node.
    let style-layers = (0, 1, 2, 3)
    let content-layer = 3            // a DEEP layer for content (conv4)

    // Gram operator nodes, in a row along the TOP (style path)
    let gramy = cy-s
    let gop(cx, cy, accent) = {
      circle((cx, cy), radius: 0.30, fill: white, stroke: 1.2pt + accent)
      content((cx, cy), text(size: 7.5pt, fill: ink)[$G$])
    }
    let gram-xs = ()
    for li in style-layers {
      let bx = bxs.at(li)
      let gxc = bx
      gram-xs.push(gxc)
      // tap upward from the top of the conv block into the Gram node
      line((bx, cy-x + 1.5/2 + 0.02), (gxc, gramy - 0.30 - 0.02), ..tap)
      gop(gxc, gramy, green)
    }
    // "Gram matrices" caption above the Gram row (no longer collides with the tiles)
    content(((gram-xs.first() + gram-xs.last())/2, gramy + 0.55), text(size: 7.5pt, fill: green)[Gram matrices  $bold(G)^ell = bold(F)^ell bold(F)^(ell top)$])

    // content tap: deep conv block taps DOWN (routed into the content-loss box below)
    let cbx = bxs.at(content-layer)

    // ── 4.  Loss nodes ────────────────────────────────────────────────────────
    let lossx = bxs.last() + 2.55
    let lbox(cx, cy, accent, title, formula, w: 2.7, h: 1.0) = {
      rect((cx - w/2, cy - h/2), (cx + w/2, cy + h/2), fill: b10, stroke: 1.4pt + accent, radius: 0pt)
      content((cx, cy + 0.22), text(size: 8pt, weight: "bold", fill: accent)[#title])
      content((cx, cy - 0.20), text(size: 7.5pt, fill: ink)[#formula])
    }

    // STYLE loss (top): compares Gram(X) vs Gram(s) over the style layers
    let sl-y = cy-s
    lbox(lossx, sl-y, green, [style loss $L_s$], $sum_ell norm(bold(G)^ell (bold(X)) - bold(G)^ell (bold(s)))_F^2$, w: 3.1)
    // route each Gram node into the style-loss box
    for gx in gram-xs {
      line((gx + 0.30, gramy), (lossx - 3.1/2, sl-y), ..tap)
    }

    // CONTENT loss (bottom): compares deep features F^ℓ(X) vs F^ℓ(c)
    let cl-y = cy-c
    lbox(lossx, cl-y, blue, [content loss $L_c$], $norm(bold(F)^ell (bold(X)) - bold(F)^ell (bold(c)))^2$, w: 3.1)
    // single L-route: from the bottom of the deep conv block down then right into the box
    line((cbx, cy-x - 1.5/2 - 0.02), (cbx, cl-y), (lossx - 3.1/2, cl-y), ..tap)

    // ── 5.  Total loss = α L_c + β L_s ────────────────────────────────────────
    let totx = lossx + 2.9
    let toty = cy-x
    rect((totx - 1.15, toty - 0.55), (totx + 1.15, toty + 0.55), fill: beige, stroke: 1.6pt + garnet, radius: 0pt)
    content((totx, toty + 0.20), text(size: 8.5pt, weight: "bold", fill: garnet)[total loss $L$])
    content((totx, toty - 0.22), text(size: 8pt, fill: ink)[$alpha L_c + beta L_s$])
    // style & content losses combine into total
    line((lossx + 3.1/2, sl-y), (totx, sl-y), (totx, toty + 0.55), ..fwd)
    line((lossx + 3.1/2, cl-y), (totx, cl-y), (totx, toty - 0.55), ..fwd)

    // ── 6.  Gradient feedback: ∂L/∂X back onto the SYNTHESIZED PIXELS ─────────
    // long dashed garnet edge wrapping the BOTTOM gutter from total loss back to the
    // synthesized tile.  It rises up the far-left margin and enters X from its WEST
    // side, so it never crosses the content/style image tiles.
    let gby  = cy-c - 1.55
    let leftx = imgx - 1.45
    line((totx, toty - 0.55 - 0.02), (totx, gby), (leftx, gby), (leftx, cy-x), (imgx - 1.05/2 - 0.02, cy-x),
         ..grad)
    content(((leftx + totx)/2, gby - 0.30), text(size: 8.5pt, fill: garnet)[update pixels:  $bold(X) <- bold(X) - eta thin (partial L) / (partial bold(X))$])
    content((leftx + 0.1, (cy-x + gby)/2), anchor: "west", angle: 90deg, text(size: 6.5pt, fill: garnet)[gradient → image, not weights])
  })

  #v(12pt)
  // ── legend ──────────────────────────────────────────────────────────────────
  #cetz.canvas(length: 1cm, {
    import cetz.draw: *
    let y = 0
    line((0, y), (1.0, y), stroke: 1.1pt + rgb("#1A1A1A"), mark: (end: "stealth", scale: 0.7))
    content((1.15, y), anchor: "west", text(size: 8pt, fill: rgb("#1A1A1A"))[forward])
    line((3.0, y), (4.0, y), stroke: 1pt + rgb("#5C5C5C"), mark: (end: "stealth", scale: 0.7))
    content((4.15, y), anchor: "west", text(size: 8pt, fill: rgb("#5C5C5C"))[feature tap])
    line((6.4, y), (7.4, y), stroke: (paint: garnet, thickness: 1.4pt, dash: "dashed"), mark: (end: "stealth", scale: 0.8))
    content((7.55, y), anchor: "west", text(size: 8pt, fill: garnet)[gradient → pixels $bold(X)$])
  })

  #v(4pt)
  #box(width: 17cm, [
    #set par(justify: false)
    #set align(center)
    #text(size: 8.5pt, fill: muted)[
      The same frozen CNN extracts features from all three images. *Content* is matched on one deep
      layer; *style* is matched by the #text(fill: green)[Gram matrices] (channel-wise feature correlations)
      across several layers. Only the #text(fill: garnet)[synthesized image $bold(X)$] is updated by gradient
      descent — its pixels are the optimization variables — while the network weights stay fixed.
    ]
  ])
]
