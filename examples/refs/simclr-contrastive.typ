// SimCLR — a simple framework for contrastive learning of visual representations
//   (Chen et al. 2020; Foundations of Computer Vision; Understanding Deep Learning —
//   standard teaching figure). Built from textbook knowledge in mlatlas's print-first
//   house style; no image was traced.
//
// ONE image x is passed through TWO independently sampled augmentations t, t' ~ T to
// give a correlated pair of views x̃_i, x̃_j. A WEIGHT-SHARED encoder f(·) maps each view
// to a representation h, and a shared projection head g(·) maps h to a normalised
// projection z. For a minibatch of N images we obtain 2N projections; the matching
// (i, j) pair is the single POSITIVE, every other view in the batch is a NEGATIVE.
//
// LEFT  — the Siamese two-stream pipeline: x → {t,t'} → f → h → g → z, with the dashed
//          "shared weights" ties that make the towers identical.
// RIGHT — the NT-Xent objective as a 2N×2N cosine-similarity matrix: maximise the
//          similarity of the positive pair (garnet) against all in-batch negatives
//          (neutral), temperature τ.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let pal = (
  edge:   rgb("#243038"),
  ink:    rgb("#222222"),
  muted:  rgb("#5C5C5C"),
  faint:  rgb("#A2A2A2"),
  accent: rgb("#73000A"), // garnet — the positive pair / the pull
  blue:   rgb("#466A9F"), // the second view i↔j
  hair:   rgb("#ECECEC"), // light fills
  beige:  rgb("#FFF2E3"), // loss / projection fill
  embi:   rgb("#E7B7BB"), // garnet-tinted projection z_i
  embj:   rgb("#C3D0E2"), // blue-tinted projection z_j
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let p = pal

  // ── helpers ──────────────────────────────────────────────────────────────────
  let arr(a, b, color: p.edge, w: 1.3pt, dash: none, scale: 0.7) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: scale),
  )
  // PURE geometry: returns an anchor dict, draws nothing.
  let geo(cx, cy, w, h) = (
    w: (cx - w / 2, cy), e: (cx + w / 2, cy),
    n: (cx, cy + h / 2), s: (cx, cy - h / 2), c: (cx, cy),
    top: cy + h / 2, bot: cy - h / 2, hw: w / 2, hh: h / 2,
  )
  let node(cx, cy, w, h, fill: p.hair, stroke: p.edge, sw: 0.9pt) = {
    draw.rect((cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), fill: fill, stroke: sw + stroke)
  }
  // a small image-thumbnail: framed square with a couple of strokes inside
  let thumb(cx, cy, s, tint: p.hair) = {
    draw.rect((cx - s / 2, cy - s / 2), (cx + s / 2, cy + s / 2), fill: tint, stroke: 0.8pt + p.edge)
    draw.circle((cx - s * 0.12, cy + s * 0.16), radius: s * 0.14, fill: white, stroke: 0.5pt + p.muted)
    draw.line((cx - s / 2, cy - s * 0.12), (cx - s * 0.1, cy - s * 0.28), (cx + s * 0.14, cy + s * 0.02),
      (cx + s / 2, cy - s * 0.22), stroke: 0.5pt + p.muted)
  }
  // an encoder tower drawn as a tapering CNN trapezoid stack (draw-only)
  let tower(cx, cy) = {
    let slabs = ((1.18, 0.05), (0.92, 0.30), (0.66, 0.54))
    for s in slabs {
      let hh = s.at(0) / 2
      let ox = s.at(1)
      draw.rect((cx - 0.16 + ox, cy - hh), (cx + 0.16 + ox, cy + hh),
        fill: p.hair, stroke: 0.8pt + p.edge)
    }
  }
  let tower-geo(cx, cy) = geo(cx + 0.28, cy, 1.18, 1.18)
  // a dense projection column vector of n cells (draw-only)
  let dense-cw = 0.36
  let dense-ch = 0.24
  let dense(cx, cy, n, fill: p.embi) = {
    let H = n * dense-ch
    let top = cy + H / 2
    for i in range(n) {
      let yt = top - i * dense-ch
      draw.rect((cx - dense-cw / 2, yt - dense-ch), (cx + dense-cw / 2, yt),
        fill: fill, stroke: 0.5pt + p.edge)
    }
  }
  let dense-geo(cx, cy, n) = geo(cx, cy, dense-cw, n * dense-ch)

  // =====================================================================================
  //  TITLE
  // =====================================================================================
  draw.content((3.4, 5.55), anchor: "west",
    text(size: 13pt, weight: "bold", fill: p.accent)[SimCLR — contrastive pretraining])
  draw.content((3.4, 5.02), anchor: "west",
    text(size: 8pt, fill: p.muted)[two augmented views · shared encoder + projection head · NT-Xent in-batch contrast])

  // =====================================================================================
  //  LEFT PANEL — the two-stream augment → f → g → z pipeline
  // =====================================================================================
  let yi =  1.95   // view i  (focal, garnet)
  let yj = -1.95   // view j  (blue)
  let ym = (yi + yj) / 2

  let x-img  = 0.0     // source image x
  let x-aug  = 2.05    // augmentation op t / t'
  let x-view = 3.55    // augmented view x̃
  let x-enc  = 5.55    // encoder tower f
  let x-rep  = 7.55    // representation h
  let x-proj = 9.35    // projection head g
  let x-z    = 11.05   // projection z

  // -- source image x (centred, one image) --
  let img = geo(x-img, ym, 1.25, 1.25)
  thumb(x-img, ym, 1.25, tint: p.hair)
  draw.content((x-img, img.bot - 0.22), text(size: 9pt, fill: p.ink)[image $bold(x)$])

  // stream metadata
  let streams = (
    (y: yi, col: p.accent, embf: p.embi, aug: [$t  tilde.op cal(T)$],  view: [$tilde(bold(x))_i$],
      h: [$bold(h)_i$], z: [$bold(z)_i$], note: [view $i$]),
    (y: yj, col: p.blue,   embf: p.embj, aug: [$t' tilde.op cal(T)$], view: [$tilde(bold(x))_j$],
      h: [$bold(h)_j$], z: [$bold(z)_j$], note: [view $j$]),
  )

  let tow-geos = ()
  let z-geos = ()
  for s in streams {
    // split from source image to the augmentation op
    arr(img.e, (x-aug - 0.42, s.y), color: p.edge, w: 1.2pt)

    // augmentation op — a circular operator labelled t / t'
    draw.circle((x-aug, s.y), radius: 0.42, fill: p.beige, stroke: 1.0pt + s.col)
    draw.content((x-aug, s.y), text(size: 9pt, fill: s.col)[#s.aug])
    draw.content((x-aug, s.y + 0.66), text(size: 6.3pt, fill: p.muted)[augment])

    // augmented view thumbnail
    thumb(x-view, s.y, 1.05, tint: p.hair)
    let vw = geo(x-view, s.y, 1.05, 1.05)
    arr((x-aug + 0.42, s.y), vw.w, color: s.col, w: 1.2pt)
    draw.content((x-view, vw.bot - 0.20), text(size: 8.5pt, fill: s.col)[#s.view])

    // encoder tower f
    tower(x-enc, s.y)
    let tw = tower-geo(x-enc, s.y)
    arr(vw.e, (tw.c.at(0) - 0.58, s.y), color: p.edge, w: 1.2pt)
    draw.content((x-enc + 0.28, tw.bot - 0.20), text(size: 9pt, fill: p.ink)[$f(dot)$])
    tow-geos.push(tw)

    // representation h (a few cells)
    dense(x-rep, s.y, 4, fill: p.hair)
    let hg = dense-geo(x-rep, s.y, 4)
    arr(tw.e, hg.w, color: s.col, w: 1.3pt)
    draw.content((x-rep, hg.bot - 0.20), text(size: 8.5pt, fill: p.ink)[#s.h])

    // projection head g — a small 2-layer MLP block
    node(x-proj, s.y, 0.74, 1.20, fill: p.hair, sw: 0.9pt)
    let gg = geo(x-proj, s.y, 0.74, 1.20)
    arr(hg.e, gg.w, color: p.edge, w: 1.2pt)
    // two stacked rungs to read as MLP head
    for dy in (0.30, 0.0, -0.30) {
      draw.line((x-proj - 0.26, s.y + dy), (x-proj + 0.26, s.y + dy), stroke: 0.5pt + p.muted)
    }
    draw.content((x-proj, gg.bot - 0.20), text(size: 9pt, fill: p.ink)[$g(dot)$])

    // projection z (normalised)
    dense(x-z, s.y, 4, fill: s.embf)
    let zg = dense-geo(x-z, s.y, 4)
    arr(gg.e, zg.w, color: s.col, w: 1.3pt)
    draw.content((x-z, zg.bot - 0.20), text(size: 8.5pt, fill: s.col)[#s.z])
    z-geos.push(zg)
  }

  // -- dashed WEIGHT-SHARING ties (encoder f AND head g are shared across views) --
  let twi = tow-geos.at(0)
  let twj = tow-geos.at(1)
  // tie between encoders, drawn just left of the towers
  let tie-x = twi.c.at(0) - 0.78
  draw.line((tie-x, twi.c.at(1)), (tie-x, twj.c.at(1)),
    stroke: (paint: p.accent, thickness: 1.0pt, dash: "dashed"))
  for tw in tow-geos {
    draw.line((tie-x, tw.c.at(1)), (tw.c.at(0) - 0.58, tw.c.at(1)),
      stroke: (paint: p.accent, thickness: 1.0pt, dash: "dashed"))
  }
  // tie between projection heads
  let gtie-x = x-proj - 0.55
  draw.line((gtie-x, yi), (gtie-x, yj),
    stroke: (paint: p.accent, thickness: 1.0pt, dash: "dashed"))
  for s in streams {
    draw.line((gtie-x, s.y), (x-proj - 0.37, s.y),
      stroke: (paint: p.accent, thickness: 1.0pt, dash: "dashed"))
  }
  // shared-weights annotation, centred between the two encoder towers
  draw.content((tie-x - 0.12, ym + 0.20), anchor: "east",
    text(size: 7.2pt, weight: "bold", fill: p.accent)[shared])
  draw.content((tie-x - 0.12, ym - 0.18), anchor: "east",
    text(size: 7.2pt, weight: "bold", fill: p.accent)[weights])
  draw.content((tie-x - 0.12, ym - 0.56), anchor: "east",
    text(size: 6.2pt, fill: p.muted)[$f, g$ tied])

  // stage captions under the pipeline
  draw.content((x-enc + 0.28, yj - 0.95), text(size: 6.6pt, fill: p.muted)[encoder])
  draw.content((x-proj, yj - 0.95), text(size: 6.6pt, fill: p.muted)[proj. head])

  // =====================================================================================
  //  RIGHT PANEL — the NT-Xent in-batch cosine-similarity matrix
  // =====================================================================================
  let gx = 13.4
  draw.line((gx - 0.95, -4.0), (gx - 0.95, 5.0),
    stroke: (paint: p.faint, thickness: 0.6pt, dash: "dashed"))

  draw.content((gx + 1.6, 5.05), anchor: "north-west",
    text(size: 11pt, weight: "bold", fill: p.blue)[NT-Xent loss])
  draw.content((gx + 1.6, 4.52), anchor: "north-west",
    text(size: 8pt, fill: p.muted)[in-batch similarity $S_(a b)=bold(z)_a^top bold(z)_b slash (norm(bold(z)_a) norm(bold(z)_b))$])

  // similarity matrix S over a tiny batch of N=2 images -> 2N=4 views.
  // index order: (1i, 1j, 2i, 2j). Positive pairs are the (k_i, k_j) of the SAME image.
  let n = 4
  let cell = 0.78
  let mx = gx + 0.55           // matrix left edge
  let my = -1.30               // matrix bottom edge
  // labels for the 4 views (two augmented views of each of 2 images)
  let labs = ($tilde(bold(x))_1^i$, $tilde(bold(x))_1^j$, $tilde(bold(x))_2^i$, $tilde(bold(x))_2^j$)
  // positive partner of each index (image 1: 0↔1, image 2: 2↔3)
  let partner = (1, 0, 3, 2)

  // draw the 4×4 grid. row a = anchor (top), col b = candidate.
  for a in range(n) {
    for b in range(n) {
      let xx = mx + b * cell
      // row 0 sits at the TOP: flip
      let yy = my + (n - 1 - a) * cell
      let fil = p.hair
      let txt = p.muted
      let lbl = []
      let sw = 0.6pt
      let st = p.faint
      if a == b {
        // self-similarity, masked out of the denominator
        fil = white
        lbl = text(size: 7pt, fill: p.faint)[—]
      } else if partner.at(a) == b {
        // the single POSITIVE for anchor a
        fil = p.accent
        lbl = text(size: 7.5pt, fill: white, weight: "bold")[$+$]
        sw = 1.4pt
        st = p.accent
      } else {
        // an in-batch NEGATIVE
        fil = p.hair
        lbl = text(size: 7.5pt, fill: p.muted)[$-$]
      }
      draw.rect((xx, yy), (xx + cell, yy + cell), fill: fil, stroke: sw + st, radius: 0pt)
      draw.content((xx + cell / 2, yy + cell / 2), lbl)
    }
  }
  let W = n * cell
  let H = n * cell
  draw.rect((mx, my), (mx + W, my + H), fill: none, stroke: 1.1pt + p.edge, radius: 0pt)

  // column labels (candidate b) across the top
  for b in range(n) {
    draw.content((mx + b * cell + cell / 2, my + H + 0.16), anchor: "south",
      text(size: 7pt, fill: p.ink)[#labs.at(b)])
  }
  // row labels (anchor a) down the left
  for a in range(n) {
    draw.content((mx - 0.14, my + (n - 1 - a) * cell + cell / 2), anchor: "east",
      text(size: 7pt, fill: p.ink)[#labs.at(a)])
  }
  draw.content((mx + W / 2, my + H + 0.66), text(size: 8.5pt, weight: "bold", fill: p.ink)[candidate $b$])
  draw.content((mx - 1.02, my + H / 2), angle: 90deg,
    text(size: 8.5pt, weight: "bold", fill: p.ink)[anchor $a$])

  // legend for the matrix — placed to the RIGHT of the grid so the loss tie can drop
  // straight down the matrix without crossing any text.
  let lgx = mx + W + 0.45
  let lgy = my + H - 0.30
  draw.rect((lgx, lgy), (lgx + 0.28, lgy + 0.28), fill: p.accent, stroke: 1.0pt + p.accent, radius: 0pt)
  draw.content((lgx + 0.40, lgy + 0.14), anchor: "west",
    text(size: 7pt, fill: p.ink)[positive])
  draw.content((lgx + 0.40, lgy - 0.16), anchor: "west",
    text(size: 6.3pt, fill: p.muted)[same image])
  draw.rect((lgx, lgy - 0.84), (lgx + 0.28, lgy - 0.56), fill: p.hair, stroke: 0.8pt + p.faint, radius: 0pt)
  draw.content((lgx + 0.40, lgy - 0.70), anchor: "west",
    text(size: 7pt, fill: p.ink)[negative])
  draw.content((lgx + 0.40, lgy - 1.00), anchor: "west",
    text(size: 6.3pt, fill: p.muted)[in-batch])
  draw.rect((lgx, lgy - 1.68), (lgx + 0.28, lgy - 1.40), fill: white, stroke: 0.8pt + p.faint, radius: 0pt)
  draw.content((lgx + 0.14, lgy - 1.54), text(size: 7pt, fill: p.faint)[—])
  draw.content((lgx + 0.40, lgy - 1.54), anchor: "west",
    text(size: 7pt, fill: p.ink)[self (masked)])

  // the NT-Xent objective written out, under the matrix block
  let fx = gx + 2.2
  let fy = my - 2.05
  draw.rect((gx - 0.55, fy - 0.78), (gx + 5.4, fy + 0.92),
    fill: p.beige, stroke: 1.0pt + p.accent, radius: 0pt)
  draw.content((fx, fy + 0.52), text(size: 9pt, weight: "bold", fill: p.accent)[NT-Xent (per positive pair $i,j$)])
  draw.content((fx, fy - 0.05), text(size: 10pt, fill: p.ink)[
    $cal(L)_(i,j) = - log (exp(S_(i j) slash tau)) / (sum_(k eq.not i) exp(S_(i k) slash tau))$])
  draw.content((fx, fy - 0.62), text(size: 6.8pt, fill: p.muted)[
    numerator = positive · denominator sums the $2N-1$ in-batch candidates · temperature $tau$])

  // an arrow tying the positive cell to the objective
  arr((mx + 1 * cell + cell / 2, my - 0.02), (mx + 1 * cell + cell / 2, fy + 0.94),
    color: p.accent, w: 1.0pt, dash: "dashed", scale: 0.6)
})
