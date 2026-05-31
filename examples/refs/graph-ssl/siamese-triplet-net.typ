// Siamese / triplet contrastive network (Bromley 1993; Schroff et al. FaceNet 2015;
//   Foundations of Computer Vision; Understanding Deep Learning — standard teaching figure).
// Three WEIGHT-SHARED encoder towers f_θ embed an anchor a, a positive p (same class) and a
// negative n (different class) into a common embedding space. The triplet loss pulls the
// anchor–positive distance d(a,p) DOWN and pushes the anchor–negative distance d(a,n) UP,
// past a margin α:   L = max( d(a,p) − d(a,n) + α , 0 ).
// LEFT  — the two/three-stream architecture: identical towers tied by dashed "shared θ" links,
//          producing ℓ2-normalised embeddings that flow into the triplet-loss node.
// RIGHT — the geometry on the unit sphere: the pull (a→p, garnet) and push (a→n) the loss induces.
// Built from textbook knowledge in mlatlas's print-first house style; no image was traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let pal = (
  edge:  rgb("#243038"),
  ink:   rgb("#222222"),
  muted: rgb("#5C5C5C"),
  faint: rgb("#A2A2A2"),
  accent: rgb("#73000A"), // garnet — the anchor / the pull / the tie
  blue:  rgb("#466A9F"),  // the push / negative
  hair:  rgb("#ECECEC"),  // light fills
  beige: rgb("#FFF2E3"),  // loss node fill
  emb:   rgb("#E7B7BB"),  // garnet-tinted embedding cells
  embn:  rgb("#C3D0E2"),  // blue-tinted negative embedding cells
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let p = pal

  // ---- helpers ----------------------------------------------------------------
  let arr(a, b, color: p.edge, w: 1.3pt, dash: none, scale: 0.7) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: scale),
  )
  // PURE geometry: returns an anchor dict, draws nothing.
  let geo(cx, cy, w, h) = (
    w: (cx - w / 2, cy), e: (cx + w / 2, cy),
    n: (cx, cy + h / 2), s: (cx, cy - h / 2), c: (cx, cy),
    top: cy + h / 2, bot: cy - h / 2, hw: w / 2, hh: h / 2,
  )
  // sharp rectangle node centred on (cx,cy)
  let node(cx, cy, w, h, fill: p.hair, stroke: p.edge, sw: 0.9pt) = {
    draw.rect((cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), fill: fill, stroke: sw + stroke)
  }
  // a small image-thumbnail: a framed square with a couple of strokes inside
  let thumb(cx, cy, s, tint: p.hair) = {
    draw.rect((cx - s / 2, cy - s / 2), (cx + s / 2, cy + s / 2), fill: tint, stroke: 0.8pt + p.edge)
    draw.circle((cx - s * 0.12, cy + s * 0.16), radius: s * 0.14, fill: white, stroke: 0.5pt + p.muted)
    draw.line((cx - s / 2, cy - s * 0.12), (cx - s * 0.1, cy - s * 0.28), (cx + s * 0.14, cy + s * 0.02),
      (cx + s / 2, cy - s * 0.22), stroke: 0.5pt + p.muted)
  }
  // a dense embedding column vector of n cells (draw-only)
  let dense-cw = 0.40
  let dense-ch = 0.26
  let dense(cx, cy, n, cw: dense-cw, ch: dense-ch, fill: p.emb) = {
    let H = n * ch
    let top = cy + H / 2
    for i in range(n) {
      let yt = top - i * ch
      draw.rect((cx - cw / 2, yt - ch), (cx + cw / 2, yt), fill: fill, stroke: 0.5pt + p.edge)
    }
  }
  // pure geometry of a dense column
  let dense-geo(cx, cy, n, cw: dense-cw, ch: dense-ch) = geo(cx, cy, cw, n * ch)

  // an encoder tower drawn as a tapering CNN trapezoid stack -> labelled "f_θ" (draw-only)
  let tower(cx, cy) = {
    // three contracting slabs to read as "deep encoder"
    let slabs = ((1.30, 0.05), (1.02, 0.34), (0.74, 0.60))
    for s in slabs {
      let hh = s.at(0) / 2
      let ox = s.at(1)
      draw.rect((cx - 0.18 + ox, cy - hh), (cx + 0.18 + ox, cy + hh),
        fill: p.hair, stroke: 0.8pt + p.edge)
    }
  }
  // pure geometry: the tower body box, slightly right of its left slab
  let tower-geo(cx, cy) = geo(cx + 0.30, cy, 1.30, 1.30)

  // =====================================================================================
  //  LEFT PANEL — the three weight-shared towers + triplet loss
  // =====================================================================================

  // vertical positions of the three streams
  let yA =  2.55   // anchor   (focal, garnet)
  let yP =  0.0    // positive (same identity)
  let yN = -2.55   // negative (different identity)

  let x-in   = 0.0     // input thumbnails
  let x-tow  = 2.0     // encoder towers f_θ
  let x-emb  = 4.55    // embedding vectors
  let x-loss = 7.2     // triplet-loss node

  // stream metadata
  let streams = (
    (y: yA, lab: [anchor $bold(a)$], col: p.accent, emb: p.emb,  sym: [$f_theta (bold(a))$], cls: [class $c$]),
    (y: yP, lab: [positive $bold(p)$], col: p.edge, emb: p.emb,  sym: [$f_theta (bold(p))$], cls: [class $c$]),
    (y: yN, lab: [negative $bold(n)$], col: p.blue, emb: p.embn, sym: [$f_theta (bold(n))$], cls: [class $c' eq.not c$]),
  )

  // panel title
  draw.content((x-tow + 0.3, 4.7), text(size: 12pt, weight: "bold", fill: p.accent)[Triplet network])
  draw.content((x-tow + 0.3, 4.18), text(size: 8pt, fill: p.muted)[weight-shared encoders · contrastive embedding])

  // -- draw each stream: thumbnail -> tower -> embedding -> arrow to loss --
  let tow-tops = ()
  let emb-handles = ()
  for s in streams {
    // input thumbnail
    let th = geo(x-in, s.y, 1.0, 1.0)
    thumb(x-in, s.y, 1.0, tint: p.hair)
    draw.content((x-in, th.bot - 0.16), text(size: 8.5pt, fill: s.col)[#s.lab])
    draw.content((x-in, th.bot - 0.6), text(size: 6.5pt, fill: p.muted)[#s.cls])

    // encoder tower
    tower(x-tow, s.y)
    let tw = tower-geo(x-tow, s.y)
    arr(th.e, (tw.c.at(0) - 0.62, s.y), color: p.edge, w: 1.3pt)
    // f_θ label centred under the tower
    draw.content((x-tow + 0.30, tw.bot - 0.18), text(size: 9pt, fill: p.ink)[$f_theta$])

    // embedding vector (ℓ2-normalised)
    dense(x-emb, s.y, 5, fill: s.emb)
    let em = dense-geo(x-emb, s.y, 5)
    arr(tw.e, em.w, color: s.col, w: 1.45pt)
    draw.content((x-emb, em.bot - 0.18), text(size: 8pt, fill: s.col)[#s.sym])

    tow-tops.push(tw)
    emb-handles.push(em)
  }

  // -- dashed WEIGHT-SHARING ties between the three towers (the defining feature) --
  let txc = x-tow + 0.30
  let tieA = tow-tops.at(0)
  let tieP = tow-tops.at(1)
  let tieN = tow-tops.at(2)
  // anchor<->positive and positive<->negative tie links, drawn just left of the towers
  let tie-x = txc - 0.95
  draw.line((tie-x, tieA.c.at(1)), (tie-x, tieP.c.at(1)),
    stroke: (paint: p.accent, thickness: 1.1pt, dash: "dashed"))
  draw.line((tie-x, tieP.c.at(1)), (tie-x, tieN.c.at(1)),
    stroke: (paint: p.accent, thickness: 1.1pt, dash: "dashed"))
  // small tick stubs into each tower
  for tw in tow-tops {
    draw.line((tie-x, tw.c.at(1)), (tw.c.at(0) - 0.62, tw.c.at(1)),
      stroke: (paint: p.accent, thickness: 1.1pt, dash: "dashed"))
  }
  // tie annotation — sit it just to the RIGHT of the tie line, tucked between the
  // anchor and positive towers, so it never collides with the input labels at x≈0.
  let tie-lab-y = (yA + yP) / 2 - 0.05
  draw.content((tie-x + 0.14, tie-lab-y), anchor: "west",
    text(size: 7.5pt, weight: "bold", fill: p.accent)[shared $theta$])
  draw.content((tie-x + 0.14, tie-lab-y - 0.40), anchor: "west",
    text(size: 6.3pt, fill: p.muted)[same weights])

  // =====================================================================================
  //  TRIPLET-LOSS NODE — embeddings flow in, scalar loss flows out
  // =====================================================================================
  let emA = emb-handles.at(0)
  let emP = emb-handles.at(1)
  let emN = emb-handles.at(2)

  let loss = geo(x-loss, yP, 1.9, 2.2)
  node(x-loss, yP, 1.9, 2.2, fill: p.beige, sw: 1.1pt, stroke: p.accent)
  draw.content((x-loss, yP + 0.62), text(size: 8.5pt, weight: "bold", fill: p.accent)[triplet])
  draw.content((x-loss, yP + 0.30), text(size: 8.5pt, weight: "bold", fill: p.accent)[loss])
  draw.content((x-loss, yP - 0.18), text(size: 7pt, fill: p.ink)[$d(bold(a),bold(p))$])
  draw.content((x-loss, yP - 0.5), text(size: 7pt, fill: p.ink)[$- d(bold(a),bold(n))$])
  draw.content((x-loss, yP - 0.84), text(size: 7pt, fill: p.ink)[$+ alpha$])

  // route each embedding into the loss node (orthogonal feed)
  // anchor (top) and negative (bottom) bend in; positive goes straight.
  let lin-x = loss.w.at(0)
  arr(emA.e, (emA.e.at(0) + 0.55, emA.e.at(1)), color: p.accent, w: 1.3pt, scale: 0)
  draw.line((emA.e.at(0) + 0.55, emA.e.at(1)), (emA.e.at(0) + 0.55, loss.top - 0.35),
    (lin-x - 0.04, loss.top - 0.35), stroke: (paint: p.accent, thickness: 1.3pt),
    mark: (end: "stealth", scale: 0.7))
  arr(emP.e, (lin-x - 0.04, yP), color: p.edge, w: 1.3pt)
  arr(emN.e, (emN.e.at(0) + 0.55, emN.e.at(1)), color: p.blue, w: 1.3pt, scale: 0)
  draw.line((emN.e.at(0) + 0.55, emN.e.at(1)), (emN.e.at(0) + 0.55, loss.bot + 0.35),
    (lin-x - 0.04, loss.bot + 0.35), stroke: (paint: p.blue, thickness: 1.3pt),
    mark: (end: "stealth", scale: 0.7))

  // scalar loss out -> objective (kept entirely between the node and the divider)
  arr(loss.e, (loss.e.at(0) + 0.7, yP), color: p.edge, w: 1.4pt)
  let obj-x = loss.e.at(0) + 1.95
  draw.content((obj-x, yP + 0.78), text(size: 8.5pt, fill: p.ink)[$cal(L) =$])
  draw.content((obj-x, yP + 0.40), text(size: 8.5pt, fill: p.ink)[
    $[d(bold(a),bold(p)) - d(bold(a),bold(n)) + alpha]_+$])
  draw.content((obj-x, yP - 0.10), text(size: 6.6pt, fill: p.muted)[
    $d(dot,dot) = norm(dot - dot)_2^2$])
  draw.content((obj-x, yP - 0.44), text(size: 6.6pt, fill: p.muted)[
    $[x]_+ = max(x, 0)$])
  draw.content((obj-x, yP - 0.86), text(size: 6.6pt, fill: p.muted)[
    pull $bold(a),bold(p)$ near · push $bold(n)$ far])

  // =====================================================================================
  //  RIGHT PANEL — the embedding-space geometry (the effect of the loss)
  // =====================================================================================
  let gx = 13.4      // panel origin x
  let gy = 0.0       // panel origin y
  draw.line((gx - 1.15, -4.0), (gx - 1.15, 5.0),
    stroke: (paint: p.faint, thickness: 0.6pt, dash: "dashed"))

  draw.content((gx + 2.1, 4.7), text(size: 12pt, weight: "bold", fill: p.blue)[Embedding space])
  draw.content((gx + 2.1, 4.18), text(size: 8pt, fill: p.muted)[learned $ell_2$-normalised metric])

  // the unit sphere / hypersphere on which embeddings live
  let ux = gx + 2.0
  let uy = gy + 0.4
  let R  = 2.6
  // sphere outline + a faint equator ellipse for "unit hypersphere" read
  draw.circle((ux, uy), radius: R, fill: p.hair.lighten(35%), stroke: 0.9pt + p.faint)
  let eq = range(49).map(i => {
    let t = i / 48 * 360 * 1deg
    (ux + R * calc.cos(t), uy + 0.36 * R * calc.sin(t))
  })
  draw.line(..eq, stroke: (paint: p.faint, thickness: 0.5pt, dash: "dotted"))
  draw.content((ux + R * 0.62, uy + R * 0.74), text(size: 6.5pt, fill: p.muted)[$norm(f_theta (dot)) = 1$])

  // anchor / positive / negative points on the sphere
  let pa = (ux - 0.55, uy + 0.65)     // anchor
  let pp = (ux + 0.85, uy + 1.05)     // positive — pulled close
  let pn = (ux + 1.05, uy - 1.75)     // negative — pushed far

  // the margin ring around the anchor: positive must be inside, negative outside
  let mr = 1.75
  let ring = range(49).map(i => {
    let t = i / 48 * 360 * 1deg
    (pa.at(0) + mr * calc.cos(t), pa.at(1) + mr * calc.sin(t))
  })
  draw.line(..ring, close: true, stroke: (paint: p.muted, thickness: 0.7pt, dash: "dashed"))
  draw.content((pa.at(0) - mr * 0.72, pa.at(1) - mr * 0.72), anchor: "north-east",
    text(size: 6.3pt, fill: p.muted)[margin $alpha$])

  // pull (anchor -> positive, garnet, solid, short = small d(a,p))
  arr(pa, pp, color: p.accent, w: 1.6pt, scale: 0.8)
  draw.content(((pa.at(0) + pp.at(0)) / 2 + 0.30, (pa.at(1) + pp.at(1)) / 2 - 0.40),
    anchor: "west", text(size: 6.8pt, fill: p.accent)[pull · $d(bold(a),bold(p))$])
  // push (anchor -> negative, blue, long = large d(a,n))
  arr(pa, pn, color: p.blue, w: 1.6pt, scale: 0.8)
  draw.content(((pa.at(0) + pn.at(0)) / 2 + 0.62, (pa.at(1) + pn.at(1)) / 2),
    anchor: "west", text(size: 6.8pt, fill: p.blue)[push · $d(bold(a),bold(n))$])

  // the three embedding points
  let pt(c, col, lab, dx: 0.0, dy: 0.34, anch: "south") = {
    draw.circle(c, radius: 0.13, fill: col, stroke: 0.6pt + white)
    draw.content((c.at(0) + dx, c.at(1) + dy), anchor: anch, text(size: 8pt, fill: col)[#lab])
  }
  pt(pa, p.accent, [$bold(a)$], dx: -0.30, anch: "south-east")
  pt(pp, p.accent, [$bold(p)$], dx: 0.22, dy: 0.10, anch: "west")
  pt(pn, p.blue,  [$bold(n)$], dy: -0.36, anch: "north")

  // before/after caption strip
  draw.content((ux, uy - R - 0.85), text(size: 7.3pt, fill: p.muted)[
    same identity drawn near · different identity beyond the margin])
})
