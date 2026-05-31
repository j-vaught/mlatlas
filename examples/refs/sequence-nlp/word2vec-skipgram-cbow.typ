// word2vec — Skip-gram vs CBOW (Mikolov et al. 2013; D2L / Jurafsky-Martin SLP3 schematic).
// Both are shallow "predict-the-context" networks with NO hidden non-linearity:
//   one-hot word(s) --[W: V×d projection]--> d-dim embedding --[W': d×V]--> softmax over vocab.
//   The projection matrix W IS the learned word-embedding table (row per word).
// LEFT  — Skip-gram: center word w_t -> its embedding v_{w_t} -> shared softmax predicts EACH
//          surrounding context word independently (branch to many outputs).
// RIGHT — CBOW: the surrounding context one-hots are AVERAGED into one vector -> embedding ->
//          softmax predicts the center word (merge of many inputs to one output).
// Built from textbook knowledge in mlatlas's print-first style; no image traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let pal = (
  edge: rgb("#243038"),
  ink: rgb("#222222"),
  muted: rgb("#5C5C5C"),
  faint: rgb("#A2A2A2"),
  accent: rgb("#73000A"), // garnet — the learned embedding / focal path
  blue: rgb("#466A9F"),
  onehot: rgb("#ECECEC"), // one-hot input slab (neutral)
  proj: rgb("#FFF2E3"), // projection / output matrix (beige)
  emb: rgb("#E7B7BB"), // embedding (garnet-tinted, the heart of word2vec)
  smax: rgb("#C7C7C7"), // softmax block
  hot: rgb("#73000A"), // the single hot cell in a one-hot vector
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let p = pal

  // ----- helpers ---------------------------------------------------------------
  let arr(a, b, color: p.edge, w: 1.3pt, dash: none) = draw.line(
    a, b, stroke: (paint: color, thickness: w, dash: dash), mark: (end: "stealth", scale: 0.7),
  )

  // ---- PURE geometry helpers (return only an anchor dict — no drawing) ----
  let geo(cx, cy, w, h) = (
    w: (cx - w / 2, cy), e: (cx + w / 2, cy),
    n: (cx, cy + h / 2), s: (cx, cy - h / 2), c: (cx, cy),
    top: cy + h / 2, bot: cy - h / 2, H: h,
  )

  // ---- drawing helpers (return only drawables) ----
  // sharp rectangle node centred on (cx,cy)
  let node(cx, cy, w, h, fill: p.proj, stroke: p.edge, sw: 0.9pt) = {
    draw.rect((cx - w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), fill: fill, stroke: sw + stroke)
  }

  // a one-hot column vector of `n` cells with the `hot`-th cell filled garnet
  let onehot(cx, cy, n, hot, cw: 0.42, ch: 0.30, fill: p.onehot) = {
    let H = n * ch
    let top = cy + H / 2
    for i in range(n) {
      let yt = top - i * ch
      let f = if i == hot { p.hot } else { fill }
      draw.rect((cx - cw / 2, yt - ch), (cx + cw / 2, yt), fill: f, stroke: 0.6pt + p.edge)
    }
  }

  // a dense (continuous) column vector of `n` grey-graded cells -> the embedding
  let dense(cx, cy, n, cw: 0.42, ch: 0.30, shades: ()) = {
    let H = n * ch
    let top = cy + H / 2
    for i in range(n) {
      let yt = top - i * ch
      let f = if shades.len() > i { shades.at(i) } else { p.emb }
      draw.rect((cx - cw / 2, yt - ch), (cx + cw / 2, yt), fill: f, stroke: 0.6pt + p.edge)
    }
  }

  // softmax bar chart (a probability distribution over the vocab) drawn vertically
  let probbar(cx, cy, n, peak, cw: 0.42, ch: 0.30, peakcol: p.accent) = {
    let H = n * ch
    let top = cy + H / 2
    // a little bell of probability mass around `peak`
    for i in range(n) {
      let yt = top - i * ch
      let d = calc.abs(i - peak)
      let m = calc.max(0.07, 1.0 - 0.42 * d) // bar length fraction
      let bw = cw * m
      let f = if i == peak { peakcol } else { p.smax }
      draw.rect((cx - cw / 2, yt - ch + 0.03), (cx - cw / 2 + bw, yt - 0.03), fill: f, stroke: 0.4pt + p.edge)
    }
    // frame
    draw.rect((cx - cw / 2, cy - H / 2), (cx + cw / 2, cy + H / 2), fill: none, stroke: 0.7pt + p.edge)
  }

  // column-vector height (n cells of ch)
  let colH(n, ch: 0.30) = n * ch

  let emb-shades = (rgb("#E7B7BB"), rgb("#D99AA1"), rgb("#E7B7BB"), rgb("#C97D86"), rgb("#E7B7BB"))

  // =====================================================================================
  //  LEFT PANEL — SKIP-GRAM : center -> context (branch to many softmax outputs)
  // =====================================================================================
  let lx = 0

  draw.content((lx + 4.4, 6.05), text(size: 12pt, weight: "bold", fill: p.accent)[Skip-gram])
  draw.content((lx + 4.4, 5.5), text(size: 8pt, fill: p.muted)[predict each context word from the center word])

  // -- input: center word one-hot --
  let in1 = geo(lx, 0, 0.42, colH(5))
  onehot(lx, 0, 5, 1)
  draw.content((lx, in1.bot - 0.55), text(size: 8pt, fill: p.ink)[$bold(x)_(w_t)$])
  draw.content((lx, in1.bot - 1.0), text(size: 6.5pt, fill: p.muted)[one-hot, $|V|$])
  draw.content((lx, in1.top + 0.55), text(size: 7.5pt, weight: "bold", fill: p.ink)[center])

  // -- projection matrix W (V x d) --
  let W1 = geo(lx + 1.8, 0, 1.1, 1.9)
  node(lx + 1.8, 0, 1.1, 1.9, fill: p.proj)
  draw.content(W1.c, text(size: 9pt, fill: p.ink)[$W$])
  draw.content((W1.c.at(0), W1.bot - 0.45), text(size: 6.5pt, fill: p.muted)[$|V| times d$])
  arr(in1.e, W1.w)

  // -- embedding (the center-word vector v_{w_t}) --
  let emb1 = geo(lx + 3.3, 0, 0.42, colH(5))
  dense(lx + 3.3, 0, 5, shades: emb-shades)
  draw.content((emb1.c.at(0), emb1.bot - 0.55), text(size: 8pt, fill: p.accent)[$bold(v)_(w_t)$])
  draw.content((emb1.c.at(0), emb1.bot - 1.0), text(size: 6.5pt, fill: p.muted)[embedding, $d$])
  arr(W1.e, emb1.w, color: p.accent, w: 1.5pt)

  // -- output matrix W' (d x V), shared across all context positions --
  let Wo1 = geo(lx + 5.1, 0, 1.1, 1.9)
  node(lx + 5.1, 0, 1.1, 1.9, fill: p.proj)
  draw.content(Wo1.c, text(size: 9pt, fill: p.ink)[$W'$])
  draw.content((Wo1.c.at(0), Wo1.bot - 0.45), text(size: 6.5pt, fill: p.muted)[$d times |V|$])
  arr(emb1.e, Wo1.w)

  // -- branch: ONE shared softmax produces a prediction for EACH context slot --
  // three context positions: w_{t-1}, w_{t+1}, w_{t+2} (window). Garnet = focal.
  let ctx = (
    (y: 2.5, lab: $w_(t-2)$, peak: 1),
    (y: 0.0, lab: $w_(t-1)$, peak: 3),
    (y: -2.5, lab: $w_(t+1)$, peak: 0),
  )
  let smx = lx + 6.9
  for c in ctx {
    let pb = geo(smx, c.y, 0.42, colH(5))
    probbar(smx, c.y, 5, c.peak)
    // shared-softmax fan-out from W'
    arr(Wo1.e, pb.w)
    draw.content((pb.e.at(0) + 0.75, c.y), text(size: 8pt, fill: p.ink)[$hat(y)_(#c.lab)$])
  }
  // group label for the softmax column (shared softmax -> context window)
  draw.content((smx + 0.65, 4.35), text(size: 7.5pt, weight: "bold", fill: p.ink)[softmax over $V$])
  draw.content((smx + 0.65, 3.95), text(size: 6.5pt, fill: p.muted)[shared weights · context window])

  // =====================================================================================
  //  DIVIDER
  // =====================================================================================
  let mid = 9.7
  draw.line((mid, -5.7), (mid, 6.4), stroke: (paint: p.faint, thickness: 0.6pt, dash: "dashed"))

  // =====================================================================================
  //  RIGHT PANEL — CBOW : averaged context -> center  (merge many inputs into one output)
  // =====================================================================================
  let rx = 11.0

  draw.content((rx + 4.4, 6.05), text(size: 12pt, weight: "bold", fill: p.blue)[CBOW])
  draw.content((rx + 4.4, 5.5), text(size: 8pt, fill: p.muted)[predict the center word from the averaged context])

  // -- inputs: several context one-hots, sharing the SAME projection matrix W --
  let cin = (
    (y: 2.5, lab: $bold(x)_(w_(t-2))$, hot: 1),
    (y: 0.0, lab: $bold(x)_(w_(t-1))$, hot: 3),
    (y: -2.5, lab: $bold(x)_(w_(t+1))$, hot: 0),
  )
  let ix = rx
  let ins = ()
  for c in cin {
    let oh = geo(ix, c.y, 0.42, colH(5))
    onehot(ix, c.y, 5, c.hot)
    draw.content((ix, oh.bot - 0.45), text(size: 7.5pt, fill: p.ink)[#c.lab])
    ins.push(oh)
  }
  draw.content((ix, 4.35), text(size: 7.5pt, weight: "bold", fill: p.ink)[context])
  draw.content((ix, 3.95), text(size: 6.5pt, fill: p.muted)[one-hots])

  // shared projection W (drawn as one tall block the inputs fan into)
  let W2 = geo(rx + 1.8, 0, 1.1, 1.9)
  node(rx + 1.8, 0, 1.1, 1.9, fill: p.proj)
  draw.content(W2.c, text(size: 9pt, fill: p.ink)[$W$])
  draw.content((W2.c.at(0), W2.bot - 0.45), text(size: 6.5pt, fill: p.muted)[$|V| times d$, shared])
  for oh in ins { arr(oh.e, W2.w) }

  // average node (sum / |C|) — the defining CBOW step
  let avg = (rx + 3.3, 0)
  draw.circle(avg, radius: 0.34, fill: white, stroke: 1.1pt + p.blue)
  draw.content(avg, text(size: 9pt, fill: p.blue)[$\u{2300}$])
  draw.content((avg.at(0), avg.at(1) - 0.62), text(size: 6.5pt, fill: p.muted)[average])
  arr(W2.e, (avg.at(0) - 0.36, avg.at(1)))

  // averaged embedding (continuous vector)
  let emb2 = geo(rx + 4.7, 0, 0.42, colH(5))
  dense(rx + 4.7, 0, 5, shades: emb-shades)
  draw.content((emb2.c.at(0), emb2.bot - 0.55), text(size: 8pt, fill: p.accent)[$overline(bold(v))$])
  draw.content((emb2.c.at(0), emb2.bot - 1.0), text(size: 6.5pt, fill: p.muted)[mean embedding, $d$])
  arr((avg.at(0) + 0.36, avg.at(1)), emb2.w, color: p.accent, w: 1.5pt)

  // output matrix W'
  let Wo2 = geo(rx + 6.3, 0, 1.1, 1.9)
  node(rx + 6.3, 0, 1.1, 1.9, fill: p.proj)
  draw.content(Wo2.c, text(size: 9pt, fill: p.ink)[$W'$])
  draw.content((Wo2.c.at(0), Wo2.bot - 0.45), text(size: 6.5pt, fill: p.muted)[$d times |V|$])
  arr(emb2.e, Wo2.w)

  // single softmax -> center word prediction
  let pb2 = geo(rx + 7.9, 0, 0.42, colH(5))
  probbar(rx + 7.9, 0, 5, 2, peakcol: p.blue)
  arr(Wo2.e, pb2.w)
  draw.content((pb2.c.at(0), pb2.top + 0.55), text(size: 7.5pt, weight: "bold", fill: p.ink)[softmax over $V$])
  draw.content((pb2.e.at(0) + 0.85, 0), text(size: 8pt, fill: p.ink)[$hat(y)_(w_t)$])
  draw.content((pb2.e.at(0) + 0.85, -0.45), text(size: 6.5pt, fill: p.muted)[center word])

  // =====================================================================================
  //  SHARED FOOTNOTE
  // =====================================================================================
  draw.content(
    (mid, -6.55), anchor: "north",
    text(size: 8pt, fill: p.muted)[#box(width: 21cm)[
      Both models are *shallow* — no hidden non-linearity. The projection matrix $W$ ($|V| times d$)
      is itself the learned word-embedding table: row $w$ is the vector for word $w$. Skip-gram maximizes
      the probability of each surrounding word given the center; CBOW does the reverse on the averaged
      context. In practice the full softmax over $|V|$ is approximated by negative sampling or hierarchical softmax.
    ]],
  )
})
