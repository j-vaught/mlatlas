// Byte-Pair Encoding (BPE) merges — subword tokenization learned bottom-up.
//
// Starting from characters (plus an end-of-word marker), BPE repeatedly merges
// the MOST FREQUENT adjacent pair in the corpus into a single new token. Each
// merge appends a rule to the learned merge table and rewrites the segmentation,
// producing successively shorter rows. Here the trace is shown for the word
// "lowest"; the garnet bracket marks the pair being merged at each step, and the
// arrow steps down to the next (shorter) row. The merge table on the right is the
// learned, ordered output that drives tokenization of unseen text.
//
// Original mlatlas figure of a standard NLP concept (Jurafsky & Martin SLP3).
// Built from knowledge, not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9.5pt)

// ── palette ───────────────────────────────────────────────────────────────
#let garnet  = rgb("#73000A")
#let ink     = rgb("#000000")
#let charfil = rgb("#FFF2E3")     // beige — base characters
#let charstr = rgb("#5C5C5C")
#let subfil  = white              // already-merged subwords
#let substr  = rgb("#363636")
#let newfil  = garnet.transparentize(90%)  // freshly created token
#let dimcol  = rgb("#A2A2A2")
#let labcol  = rgb("#5C5C5C")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── geometry ───────────────────────────────────────────────────────────
  let cw   = 1.18          // cell width
  let ch   = 0.66          // cell half-height
  let gap  = 0.22          // gap between cells
  let pitch = cw + gap     // horizontal pitch
  let rowsp = 1.62         // vertical spacing between rows
  let x0    = 0.0          // left edge of first cell

  // draw one token cell centred at (x, y); returns nothing
  let cell(x, y, body, fil, strk, w: 1.0) = {
    let hw = cw / 2 * w
    rect((x - hw, y - ch), (x + hw, y + ch), fill: fil, stroke: 1.1pt + strk, radius: 0pt)
    content((x, y), text(fill: ink)[#body])
  }

  // PURE layout: compute per-cell (centre, left, right) for a row of tokens.
  // tokens: array of (label, kind, span) where kind in "char"/"sub"/"new"
  // span = cell width in base-cell units (1 normal, >1 wide).
  let layout-row(tokens) = {
    let cx = x0 + cw / 2
    let centres = ()
    for tk in tokens {
      let (lab, kind, span) = tk
      let half = cw / 2 * span
      let sx = cx - cw/2 + half        // recentre wide cells
      centres.push((sx, sx - half, sx + half, lab, kind, span))
      cx = sx + half + gap + cw/2
    }
    centres
  }

  // DRAW a laid-out row at vertical position y.
  let draw-row(y, centres) = {
    for c in centres {
      let (sx, l, r, lab, kind, span) = c
      let (fil, strk) = if kind == "char" { (charfil, charstr) }
        else if kind == "new" { (newfil, garnet) }
        else { (subfil, substr) }
      cell(sx, y, lab, fil, strk, w: span)
    }
  }

  // ── merge trace data ─────────────────────────────────────────────────────
  // each row: (tokens, merge-pair-indices-or-none, rule-label)
  //   tokens: (label, kind, span)
  //   pair: (i, j) indices of the two adjacent cells being merged (in THIS row)
  let C(l) = (l, "char", 1.0)
  let S(l, s) = (l, "sub", s)
  let N(l, s) = (l, "new", s)

  let rows = (
    (( C(`l`), C(`o`), C(`w`), C(`e`), C(`s`), C(`t`), S(`·`, 1.0) ), (3, 4)),  // merge e s
    (( C(`l`), C(`o`), C(`w`), N(`es`, 1.4), C(`t`), S(`·`, 1.0) ),   (3, 4)),  // merge es t
    (( C(`l`), C(`o`), C(`w`), N(`est`, 1.6), S(`·`, 1.0) ),          (3, 4)),  // merge est ·
    (( C(`l`), C(`o`), C(`w`), N(`est·`, 1.9) ),                      (0, 1)),  // merge l o
    (( N(`lo`, 1.4), C(`w`), S(`est·`, 1.9) ),                        (0, 1)),  // merge lo w
    (( N(`low`, 1.7), S(`est·`, 1.9) ),                               none),    // final
  )

  // freshly-created token per row (string) for the merge-rule list
  let rules = (
    (`e`, `s`, `es`),
    (`es`, `t`, `est`),
    (`est`, `·`, `est·`),
    (`l`, `o`, `lo`),
    (`lo`, `w`, `low`),
  )

  // ── draw rows top-to-bottom ──────────────────────────────────────────────
  let ytop = 0.0
  let row_centres = ()
  for (ri, r) in rows.enumerate() {
    let y = ytop - ri * rowsp
    let (tokens, pair) = r
    let cs = layout-row(tokens)
    draw-row(y, cs)
    row_centres.push((y, cs, pair))
  }

  // step label on far left of each row
  for (ri, rc) in row_centres.enumerate() {
    let (y, cs, pair) = rc
    let stepy = y
    if ri == 0 {
      content((x0 - 1.35, y), text(fill: labcol, size: 8.5pt)[start])
    } else {
      content((x0 - 1.35, y), text(fill: labcol, size: 8.5pt)[merge #ri])
    }
  }

  // ── garnet bracket under merged pair + arrow to next row ─────────────────
  for (ri, rc) in row_centres.enumerate() {
    let (y, cs, pair) = rc
    if pair != none {
      let (i, j) = pair
      let left  = cs.at(i).at(1)
      let right = cs.at(j).at(2)
      let by    = y - ch - 0.14      // bracket sits just below the row
      // bracket: up-ticks at both ends, spanning the merged pair
      line(
        (left,  by - 0.16),
        (left,  by),
        (right, by),
        (right, by - 0.16),
        stroke: 1.6pt + garnet,
      )
    }
  }

  // arrows stepping down between rows, anchored under the merged pair
  for ri in range(rows.len() - 1) {
    let (y, cs, pair) = row_centres.at(ri)
    let (ny, ncs, npair) = row_centres.at(ri + 1)
    // offset to the right edge of the merged pair so the arrow clears the bracket
    let ax = if pair != none {
      let (i, j) = pair
      cs.at(j).at(2) + 0.28
    } else { cs.at(0).at(2) + 0.28 }
    line(
      (ax, y - ch - 0.05),
      (ax, ny + ch + 0.05),
      stroke: 1.1pt + rgb("#363636"),
      mark: (end: "stealth", fill: rgb("#363636"), scale: 0.7),
    )
  }

  // ── merge table (learned, ordered output) on the right ───────────────────
  let tx = x0 + 10.7       // table left (inner content origin)
  let tytop = ytop - 0.15
  let trsp = 0.84
  let tboxL = tx - 0.45
  let tboxR = tx + 3.55
  content(((tboxL + tboxR)/2, tytop + 0.62), text(fill: ink, weight: "bold", size: 10pt)[Merge table])
  content(((tboxL + tboxR)/2, tytop + 0.22), text(fill: labcol, size: 7.5pt)[learned rules, applied in order])

  // header rule
  line((tboxL, tytop - 0.12), (tboxR, tytop - 0.12), stroke: 0.9pt + rgb("#363636"))
  for (k, rule) in rules.enumerate() {
    let (a, b, c) = rule
    let ry = tytop - 0.58 - k * trsp
    content((tx, ry), text(fill: labcol, size: 8pt)[#(k + 1).])
    // ( a , b )  ->  c
    content((tx + 0.95, ry), text(fill: ink)[( #a , #b )])
    content((tx + 2.2, ry), text(fill: garnet)[$arrow.r$])
    let hw = cw/2 * 1.4
    rect((tx + 2.75 - hw, ry - ch*0.7), (tx + 2.75 + hw, ry + ch*0.7),
      fill: newfil, stroke: 1.1pt + garnet, radius: 0pt)
    content((tx + 2.75, ry), text(fill: ink)[#c])
  }
  // table outer box (sharp corners)
  let tboxB = tytop - 0.58 - (rules.len() - 1) * trsp - 0.5
  rect((tboxL, tytop + 0.92), (tboxR, tboxB), stroke: 0.7pt + dimcol, radius: 0pt)

  // ── legend ───────────────────────────────────────────────────────────────
  let ly = ytop - rows.len() * rowsp + 0.55
  let lx = x0
  let leg(x, fil, strk, lab) = {
    rect((x, ly - 0.2), (x + 0.42, ly + 0.2), fill: fil, stroke: 1pt + strk, radius: 0pt)
    content((x + 0.42 + 0.12, ly), anchor: "west", text(fill: labcol, size: 8pt)[#lab])
  }
  leg(lx, charfil, charstr, [base character])
  leg(lx + 3.05, subfil, substr, [existing subword])
  leg(lx + 6.4, newfil, garnet, [new token (this step)])

  // bracket glyph + meaning, on the second legend line
  let ly2 = ly - 0.7
  line((lx + 0.04, ly2 - 0.14), (lx + 0.04, ly2 + 0.1), (lx + 0.5, ly2 + 0.1), (lx + 0.5, ly2 - 0.14),
    stroke: 1.6pt + garnet)
  content((lx + 0.66, ly2), anchor: "west",
    text(fill: labcol, size: 8pt)[garnet bracket marks the most-frequent adjacent pair selected to merge])
  content((lx, ly2 - 0.62), anchor: "west",
    text(fill: labcol, size: 8pt)[#text(fill: garnet)[·] = end-of-word marker `</w>`#h(0.6cm) arrow steps to the next (shorter) segmentation])
})
