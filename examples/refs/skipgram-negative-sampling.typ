// Skip-gram with Negative Sampling (SGNS) — the training-objective view.
//   (Mikolov et al. 2013; Jurafsky & Martin, SLP3 ch. 6.)
//
// Instead of a full softmax over the whole vocabulary, SGNS turns word2vec into a
// BINARY LOGISTIC classifier over (center, context) word-PAIRS. For a center word w
// with embedding v_w and a context word c with "output" embedding u_c, the model scores
// the pair by a DOT PRODUCT and squashes it through a sigmoid:
//        P(+ | w, c) = sigma(v_w · u_c).
// Training takes ONE observed (w, c+) pair as a POSITIVE example (label 1, push the
// sigmoid toward 1) and draws k random NOISE words c1..ck from the unigram^(3/4)
// distribution as NEGATIVE examples (label 0, push the sigmoid toward 0):
//        L = -log sigma(v_w · u_{c+})  -  sum_{i=1..k} log sigma(-v_w · u_{c_i}).
// This figure draws that objective as a set of parallel arms sharing the SAME center
// embedding: the positive arm (solid garnet, sigmoid -> 1) over k negative arms
// (dashed, sigmoid -> 0). Each arm = two embedding blocks joined by a dot-product
// op-node, then a sigmoid, then a target. Built from textbook knowledge, print-first;
// no image was traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let pal = (
  edge:   rgb("#363636"),     // 90% black — default edges
  ink:    rgb("#1A1A1A"),
  muted:  rgb("#5C5C5C"),
  faint:  rgb("#A2A2A2"),
  accent: rgb("#73000A"),     // garnet — the POSITIVE pair / focal arm
  hair:   rgb("#ECECEC"),     // light fills
  beige:  rgb("#FFF2E3"),     // op / sigmoid fills
  vpos:   rgb("#E7B7BB"),     // garnet-tinted context cells (true context)
  vneg:   rgb("#D9D9D9"),     // neutral cells (noise words)
  vcen:   rgb("#C7C7C7"),     // 30% black — center embedding cells
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let p = pal

  // ---------------------------------------------------------------- helpers ----
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
  // a small dense embedding-row of n cells (draw-only), drawn as a 1xN vector
  let cw = 0.30
  let ch = 0.30
  let embed(cx, cy, n, fill: p.vneg, stroke: p.edge) = {
    let W = n * cw
    let left = cx - W / 2
    for i in range(n) {
      draw.rect((left + i * cw, cy - ch / 2), (left + (i + 1) * cw, cy + ch / 2),
        fill: fill, stroke: 0.5pt + stroke)
    }
  }
  let embed-geo(cx, cy, n) = geo(cx, cy, n * cw, ch)
  // straight stealth edge
  let arr(a, b, color: p.edge, w: 1.2pt, dash: none, scale: 0.6) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: scale),
  )
  // an op-node glyph (a small circle holding a symbol) — reuses the op-node look
  let opnode(cx, cy, sym, color: p.edge, fill: p.beige, r: 0.30, fs: 8pt) = {
    draw.circle((cx, cy), radius: r, fill: fill, stroke: 1.0pt + color)
    draw.content((cx, cy), text(size: fs, fill: color)[#sym])
  }

  // ============================================================================
  //  TITLE
  // ============================================================================
  draw.content((0.6, 5.55), anchor: "west",
    text(size: 13pt, weight: "bold", fill: p.accent)[Skip-gram with negative sampling])
  draw.content((0.6, 5.05), anchor: "west",
    text(size: 8.5pt, fill: p.muted)[
      binary logistic classifier over word-pairs — not a full softmax])

  // ============================================================================
  //  SHARED CENTER WORD EMBEDDING  v_w
  // ============================================================================
  let n-dim = 5
  let x-cen = 0.0
  let y-cen = 1.0
  // center embedding drawn as a column-ish vector (rotate read: a tall stack)
  let cen-cw = 0.42
  let cen-ch = 0.30
  let cen-n = n-dim
  let cenH = cen-n * cen-ch
  let cen-top = y-cen + cenH / 2
  for i in range(cen-n) {
    let yt = cen-top - i * cen-ch
    draw.rect((x-cen - cen-cw / 2, yt - cen-ch), (x-cen + cen-cw / 2, yt),
      fill: p.vcen, stroke: 0.6pt + p.edge)
  }
  let cen = geo(x-cen, y-cen, cen-cw, cenH)
  draw.content((x-cen, cen.top + 0.55),
    text(size: 9.5pt, weight: "bold", fill: p.ink)[$bold(v)_w$])
  draw.content((x-cen, cen.top + 0.95),
    text(size: 7pt, fill: p.muted)[center word $w$])
  draw.content((x-cen, cen.bot - 0.30),
    text(size: 6.5pt, fill: p.muted)[shared])
  draw.content((x-cen, cen.bot - 0.62),
    text(size: 6.5pt, fill: p.muted)[embedding])

  // ============================================================================
  //  ARMS — one positive (top), k negatives (below). Each arm:
  //     v_w  -->  ( · )  <--  u_c     ->  sigma  ->  target {1 | 0}
  //  The dot-product op-node sits at a shared x; sigmoid + target to its right.
  // ============================================================================
  let x-ctx   = 3.5     // context embedding column (u_c) — left input to the dot
  let x-dot   = 5.6     // dot-product op-node column
  let x-sig   = 7.7     // sigmoid op-node column
  let x-tgt   = 9.6     // target / label column

  // arm vertical positions (positive on top, four negatives below)
  let arms = (
    (y:  2.7, kind: "pos", col: p.accent, cell: p.vpos, ulab: [$bold(u)_(c^+)$],
       wlab: [true context $c^+$], tgt: [1]),
    (y:  0.9, kind: "neg", col: p.edge,   cell: p.vneg, ulab: [$bold(u)_(c_1)$],
       wlab: [noise $c_1$], tgt: [0]),
    (y: -0.6, kind: "neg", col: p.edge,   cell: p.vneg, ulab: [$bold(u)_(c_2)$],
       wlab: [noise $c_2$], tgt: [0]),
    (y: -2.1, kind: "neg", col: p.edge,   cell: p.vneg, ulab: [$bold(u)_(c_3)$],
       wlab: [noise $c_3$], tgt: [0]),
    (y: -3.6, kind: "neg", col: p.edge,   cell: p.vneg, ulab: [$bold(u)_(c_k)$],
       wlab: [noise $c_k$], tgt: [0]),
  )

  // a vertical ellipsis between the 3rd and 4th negative to imply "k of them"
  // (placed between c_3 and c_k arms)
  let y-ell = (-2.1 + -3.6) / 2

  // ---- shared v_w BROADCAST BUS ------------------------------------------------
  // the single center embedding v_w is broadcast to every arm. a horizontal feeder
  // leaves v_w and a vertical trunk (the "bus") at bus-x carries it to all arms;
  // each arm taps the trunk just before its dot node.
  let bus-x = x-ctx + n-dim * cw / 2 + 0.60
  let y-top = 2.7 + 0.62        // positive arm tap height
  let y-bot = -3.6              // lowest negative arm
  // feeder from v_w east into the trunk
  draw.line(cen.e, (bus-x, y-cen), stroke: (paint: p.accent, thickness: 1.6pt))
  // the vertical trunk
  draw.line((bus-x, y-top), (bus-x, y-bot), stroke: (paint: p.edge, thickness: 1.4pt))
  // a little hub dot where the feeder meets the trunk
  draw.circle((bus-x, y-cen), radius: 0.05, fill: p.accent, stroke: none)
  draw.content((bus-x - 0.10, y-cen + 0.34), anchor: "east",
    text(size: 6.2pt, fill: p.muted)[broadcast $bold(v)_w$])

  for a in arms {
    let y = a.y
    let solid = a.kind == "pos"
    let dash = if solid { none } else { "dashed" }
    let eW = if solid { 1.7pt } else { 1.2pt }

    // ---- context embedding u_c (left input to the dot) --------------------
    embed(x-ctx, y, n-dim, fill: a.cell, stroke: a.col)
    let ue = embed-geo(x-ctx, y, n-dim)
    draw.content((ue.w.at(0) - 0.18, y), anchor: "east",
      text(size: 8.5pt, weight: if solid { "bold" } else { "regular" }, fill: a.col)[#a.ulab])
    draw.content((x-ctx, ue.bot - 0.26), text(size: 6.3pt, fill: p.muted)[#a.wlab])

    // ---- edge: u_c -> dot-product op-node (enters from the left) ----------
    arr(ue.e, (x-dot - 0.34, y), color: a.col, w: eW, dash: dash, scale: 0.55)

    // ---- edge: shared center v_w -> dot (taps the broadcast bus, drops in top) -
    // each arm taps the vertical bus at bus-x, rises a little, elbows across to
    // the dot's x, then drops DOWN into the dot's NORTH boundary. this keeps the
    // v_w operand visually distinct from the u_c operand (which enters the west).
    let rise = 0.62
    draw.line(
      (bus-x, y), (bus-x, y + rise),
      (x-dot, y + rise),
      (x-dot, y + 0.34),
      stroke: (paint: a.col, thickness: eW, dash: dash),
      mark: (end: "stealth", scale: 0.55),
    )

    // ---- the DOT-PRODUCT op-node ------------------------------------------
    opnode(x-dot, y, sym.dot, color: a.col,
      fill: if solid { p.beige } else { p.hair }, r: 0.32, fs: 11pt)

    // ---- edge: dot -> sigmoid (clear run) ---------------------------------
    arr((x-dot + 0.34, y), (x-sig - 0.40, y), color: a.col, w: eW, dash: dash, scale: 0.55)
    // score label v_w · u_c riding the clear edge
    draw.content(((x-dot + x-sig) / 2, y + 0.28),
      text(size: 6.2pt, fill: a.col)[$bold(v)_w dot.op bold(u)_c$])

    // ---- the SIGMOID op-node ----------------------------------------------
    opnode(x-sig, y, $sigma$, color: a.col,
      fill: if solid { p.beige } else { p.hair }, r: 0.40, fs: 10pt)

    // ---- edge: sigmoid -> target ------------------------------------------
    arr((x-sig + 0.40, y), (x-tgt - 0.40, y), color: a.col, w: eW, dash: dash, scale: 0.55)

    // ---- target label box (the desired sigmoid value) ---------------------
    let tw = 0.62
    let th = 0.62
    node(x-tgt, y, tw, th,
      fill: if solid { p.accent } else { p.hair },
      stroke: a.col, sw: if solid { 1.2pt } else { 0.9pt })
    draw.content((x-tgt, y),
      text(size: 10pt, weight: "bold", fill: if solid { white } else { a.col })[#a.tgt])
  }

  // vertical ellipsis implying the k negatives
  for j in range(3) {
    draw.circle((x-dot, y-ell + 0.18 - j * 0.18), radius: 0.022, fill: p.muted, stroke: none)
    draw.circle((x-ctx, y-ell + 0.18 - j * 0.18), radius: 0.022, fill: p.muted, stroke: none)
  }

  // ============================================================================
  //  COLUMN HEADERS
  // ============================================================================
  let hy = 4.1
  draw.content((x-ctx, hy), text(size: 7.5pt, weight: "bold", fill: p.ink)[context vector])
  draw.content((x-ctx, hy - 0.34), text(size: 6.3pt, fill: p.muted)[$bold(u)_c$ — output emb.])
  draw.content((x-dot, hy), text(size: 7.5pt, weight: "bold", fill: p.ink)[dot product])
  draw.content((x-dot, hy - 0.34), text(size: 6.3pt, fill: p.muted)[$bold(v)_w dot.op bold(u)_c$])
  draw.content((x-sig, hy), text(size: 7.5pt, weight: "bold", fill: p.ink)[sigmoid])
  draw.content((x-sig, hy - 0.34), text(size: 6.3pt, fill: p.muted)[$sigma(dot) in (0,1)$])
  draw.content((x-tgt, hy), text(size: 7.5pt, weight: "bold", fill: p.ink)[label])
  draw.content((x-tgt, hy - 0.34), text(size: 6.3pt, fill: p.muted)[$y in {0, 1}$])

  // ============================================================================
  //  ARM-GROUP BRACKETS (positive vs. k negatives) — sharp square brackets
  // ============================================================================
  let brk(y0, y1, x, label, color) = {
    let out = 0.20
    draw.line((x + out, y0), (x, y0), (x, y1), (x + out, y1),
      stroke: 1.1pt + color)
    draw.content((x - 0.14, (y0 + y1) / 2), anchor: "east",
      text(size: 7.5pt, weight: "bold", fill: color)[#label])
  }
  let bx = x-tgt + 1.95
  // positive bracket (single arm)
  brk(2.7 - 0.45, 2.7 + 0.45, bx, [positive], p.accent)
  // negatives bracket (the four-plus-ellipsis stack)
  brk(-3.6 - 0.45, 0.9 + 0.45, bx, [$k$ negatives], p.edge)
  draw.content((bx + 0.30, 2.7), anchor: "west",
    text(size: 6.3pt, style: "italic", fill: p.muted)[$y = 1$, push $sigma -> 1$])
  draw.content((bx + 0.30, (0.9 + -3.6) / 2), anchor: "west",
    text(size: 6.3pt, style: "italic", fill: p.muted)[$y = 0$, push $sigma -> 0$])
  draw.content((bx + 0.30, (0.9 + -3.6) / 2 - 0.40), anchor: "west",
    text(size: 6.3pt, fill: p.muted)[$c_i tilde P_n (w) prop "count"(w)^(3 slash 4)$])

  // ============================================================================
  //  OBJECTIVE (caption strip, bottom)
  // ============================================================================
  let cap-y = -5.15
  draw.line((-0.6, cap-y + 0.55), (12.0, cap-y + 0.55),
    stroke: (paint: p.faint, thickness: 0.5pt, dash: "dotted"))
  draw.content((-0.4, cap-y), anchor: "west", text(size: 9pt, fill: p.ink)[
    $cal(L) = -log sigma(bold(v)_w dot.op bold(u)_(c^+))
       - sum_(i=1)^(k) log sigma(-bold(v)_w dot.op bold(u)_(c_i))$])
  draw.content((-0.4, cap-y - 0.62), anchor: "west", text(size: 7pt, fill: p.muted)[
    maximise the score of the true (center, context) pair; minimise it for $k$ sampled noise pairs])
})
