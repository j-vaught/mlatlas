// mlatlas · Constituency (phrase-structure) parse tree + CKY span chart.
//
// LEFT: a context-free grammar (CFG) derivation drawn as a phrase-structure
// tree. Words sit at the leaves on a baseline; pre-terminal POS tags (Det, N,
// V) and phrasal non-terminals (NP, VP, S) label internal nodes placed above
// the midpoint of the span they dominate. Branches are PLAIN lines (a CFG
// derivation, not a flow) — no arrowheads. The root is S.
//
//   S  -> NP VP
//   NP -> Det N
//   VP -> V  NP
//
// RIGHT: the CKY / CYK recognition table for the same sentence. The cell at
// (i, j) holds the set of non-terminals that can derive the span of words
// w[i..j]. Only the upper triangle is used; the diagonal holds pre-terminals
// (single words) and the top-right corner holds S iff the sentence is in the
// language. The garnet diagonal of the parse and the garnet S-cell tie the two
// views together.
//
// Original mlatlas figure of a standard NLP concept (Jurafsky & Martin SLP3;
// Eisenstein). Built from knowledge, not traced. Sentence: "the chef cooks
// the soup".
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── palette ────────────────────────────────────────────────────────────────
  let p = (
    edge:   rgb("#363636"),     // branch lines
    text:   rgb("#1A1A1A"),
    muted:  rgb("#5C5C5C"),
    grid:   rgb("#C7C7C7"),
    garnet: rgb("#73000A"),     // sparse accent: root S + S-cell
    leaf:   rgb("#ECECEC"),     // leaf word chips
    ntfil:  white,              // non-terminal node fill
    cell:   rgb("#FFF2E3"),     // filled CKY cells (beige)
    cellgr: rgb("#C7C7C7"),     // empty CKY cell border
  )

  // ════════════════════════════════════════════════════════════════════════════
  //  GRAMMAR / SENTENCE DATA
  // ════════════════════════════════════════════════════════════════════════════
  // words on the baseline (left → right), with their column index 0..4
  let words = ("the", "chef", "cooks", "the", "soup")
  let dx = 1.55                 // horizontal spacing between leaf words (cm)
  let wx = (i) => i * dx        // x of leaf column i

  // ── tree node placement ──────────────────────────────────────────────────────
  // baseline (leaf words) at y = 0; tree grows UP. Levels by tree DEPTH:
  //   words < POS tags < NP (lower phrasal) < VP (dominates NP2) < S (root)
  let yLeaf = 0.0               // word chips
  let yPos  = 1.10             // pre-terminal POS tags  (Det, N, V)
  let yNP   = 2.30             // phrasal NP nodes (both NP1 and NP2)
  let yVP   = 3.45             // VP  (dominates NP2 → must be above yNP)
  let yRoot = 4.60             // S

  // pre-terminal POS over each word
  let pos = ("Det", "N", "V", "Det", "N")
  // x of each pre-terminal = its word column
  let posx = (i) => wx(i)

  // phrasal nodes: NP1 over (the chef) cols 0-1; NP2 over (the soup) cols 3-4;
  // VP over (cooks the soup) cols 2-4; S over all.
  let np1x = (wx(0) + wx(1)) / 2
  let np2x = (wx(3) + wx(4)) / 2
  let vpx  = (posx(2) + np2x) / 2
  let sx   = (np1x + vpx) / 2

  // a non-terminal label chip (rounded? no — sharp). returns nothing.
  let ntchip(x, y, label, accent: false) = {
    let w = 0.46
    let h = 0.30
    let fil = if accent { p.garnet.transparentize(86%) } else { p.ntfil }
    let str = if accent { 1.6pt + p.garnet } else { 1.1pt + p.edge }
    let tc  = if accent { p.garnet } else { p.text }
    draw.rect((x - w, y - h), (x + w, y + h), fill: fil, stroke: str, radius: 0pt)
    draw.content((x, y), text(size: 9pt, weight: "bold", fill: tc)[#label])
  }

  // plain branch line between a parent anchor and a child anchor (no arrowhead)
  let branch(px, py, cx, cy) = {
    draw.line((px, py), (cx, cy), stroke: 1.1pt + p.edge)
  }

  // ── draw branches first (under the chips) ────────────────────────────────────
  // S → NP1, VP
  branch(sx, yRoot - 0.30, np1x, yNP + 0.30)
  branch(sx, yRoot - 0.30, vpx,  yVP + 0.30)
  // NP1 → Det(0), N(1)
  branch(np1x, yNP - 0.30, posx(0), yPos + 0.30)
  branch(np1x, yNP - 0.30, posx(1), yPos + 0.30)
  // VP → V(2), NP2
  branch(vpx, yVP - 0.30, posx(2), yPos + 0.30)
  branch(vpx, yVP - 0.30, np2x,    yNP + 0.30)
  // NP2 → Det(3), N(4)
  branch(np2x, yNP - 0.30, posx(3), yPos + 0.30)
  branch(np2x, yNP - 0.30, posx(4), yPos + 0.30)
  // pre-terminal → word
  for i in range(5) {
    branch(posx(i), yPos - 0.30, wx(i), yLeaf + 0.34)
  }

  // ── draw phrasal + root + POS chips ──────────────────────────────────────────
  ntchip(sx,   yRoot, [S], accent: true)
  ntchip(np1x, yNP,   [NP])
  ntchip(vpx,  yVP,   [VP])
  ntchip(np2x, yNP,   [NP])
  for i in range(5) {
    ntchip(posx(i), yPos, pos.at(i))
  }

  // ── leaf word chips ──────────────────────────────────────────────────────────
  let lw = 0.55
  let lh = 0.30
  for i in range(5) {
    let cx = wx(i)
    draw.rect((cx - lw, yLeaf - lh), (cx + lw, yLeaf + lh),
      fill: p.leaf, stroke: 1.0pt + p.edge, radius: 0pt)
    draw.content((cx, yLeaf), text(size: 9pt, fill: p.text, style: "italic")[#words.at(i)])
  }

  // ── tree title + grammar key ─────────────────────────────────────────────────
  draw.content((vpx, yRoot + 1.05),
    text(size: 11pt, weight: "bold", fill: p.text)[Constituency parse tree])
  draw.content((wx(2), yLeaf - 0.92),
    text(size: 8pt, fill: p.muted, style: "italic")[
      phrase-structure derivation under a CFG])

  // ════════════════════════════════════════════════════════════════════════════
  //  CKY / CYK SPAN CHART  (right of the tree)
  // ════════════════════════════════════════════════════════════════════════════
  // Upper-triangular table over spans [i, j].  We index by:
  //   row r = span length - 1   (r = 0 bottom: single words / diagonal)
  //   col c = start position i   (0..4)
  // A cell exists when c + r <= 4 (i.e. span fits in the 5-word sentence).
  let n = 5
  let cs = 1.05                 // CKY cell size (cm)
  let ox = wx(4) + 2.7          // chart origin x (left edge of column 0)
  let oy = 0.0                  // chart origin y (bottom row baseline)

  // cell lower-left corner for (row r, col c)
  let cellx = (c) => ox + c * cs
  let celly = (r) => oy + r * cs

  // contents of each populated cell, keyed "r-c".  Diagonal r=0 = pre-terminals.
  // span [i, i+r].  Values are the non-terminals derivable for that span.
  let chart = (
    "0-0": ("Det",), "0-1": ("N",),  "0-2": ("V",), "0-3": ("Det",), "0-4": ("N",),
    "1-0": ("NP",),                                   "1-3": ("NP",),
                                       "2-2": ("VP",),
                          "3-2": (),
    "4-0": ("S",),
  )
  // (the empty-but-relevant cells "3-2" etc. left blank illustrate combination)

  // draw all upper-triangle cells (border grid), then fill populated ones
  for r in range(n) {
    for c in range(n) {
      if c + r <= n - 1 {
        let x0 = cellx(c)
        let y0 = celly(r)
        let key = str(r) + "-" + str(c)
        let has = chart.keys().contains(key) and chart.at(key).len() > 0
        let isS = key == "4-0"
        let fil = if isS { p.garnet.transparentize(84%) }
                  else if has { p.cell }
                  else { white }
        let strc = if isS { 1.6pt + p.garnet }
                   else if r == 0 { 1.1pt + p.edge }
                   else { 0.8pt + p.cellgr }
        draw.rect((x0, y0), (x0 + cs, y0 + cs), fill: fil, stroke: strc, radius: 0pt)
        // cell label
        if chart.keys().contains(key) and chart.at(key).len() > 0 {
          let lbl = chart.at(key).join(", ")
          let tc = if isS { p.garnet } else { p.text }
          let wt = if isS { "bold" } else { "regular" }
          draw.content((x0 + cs / 2, y0 + cs / 2),
            text(size: 8.5pt, weight: wt, fill: tc)[#lbl])
        }
      }
    }
  }

  // word labels under each column (the diagonal words), and start-index ticks
  for c in range(n) {
    let x0 = cellx(c) + cs / 2
    draw.content((x0, oy - 0.34),
      text(size: 7.5pt, fill: p.muted, style: "italic")[#words.at(c)])
  }
  // column start-index i along the bottom; row = span length along the left
  for c in range(n) {
    draw.content((cellx(c) + cs / 2, oy - 0.72),
      text(size: 7pt, fill: p.muted)[$i = #c$])
  }
  for r in range(n) {
    // only show length tick where a cell exists in that row (col 0 always does)
    draw.content((ox - 0.32, celly(r) + cs / 2),
      anchor: "east", text(size: 7pt, fill: p.muted)[#(r + 1)])
  }
  draw.content((ox - 0.32, celly(n - 1) + cs + 0.30),
    anchor: "east", text(size: 7.5pt, fill: p.muted)[span\ len])

  // arrow hint: cell (r,c) combines a left sub-span and a lower sub-span
  // (the CKY recurrence). Illustrate on the VP cell "2-2": V[2] + NP[3..4].
  // draw a thin guide from the two contributing cells into the VP cell.
  let vpcx = cellx(2) + cs / 2
  let vpcy = celly(2) + cs / 2
  let vcx  = cellx(2) + cs / 2
  let vcy  = celly(0) + cs / 2          // V on diagonal at col 2
  let npcx = cellx(3) + cs / 2
  let npcy = celly(1) + cs / 2          // NP for [3..4]
  draw.line((vcx, vcy + cs / 2 - 0.04), (vpcx - 0.04, vpcy - cs / 2 + 0.10),
    stroke: (paint: p.muted, thickness: 0.7pt, dash: "dotted"),
    mark: (end: "stealth", scale: 0.45))
  draw.line((npcx - cs / 2 + 0.04, npcy), (vpcx + cs / 2 - 0.10, vpcy),
    stroke: (paint: p.muted, thickness: 0.7pt, dash: "dotted"),
    mark: (end: "stealth", scale: 0.45))

  // CKY title + caption
  let chartw = n * cs
  draw.content((ox + chartw / 2, celly(n - 1) + cs + 1.05),
    text(size: 11pt, weight: "bold", fill: p.text)[CKY span chart])
  draw.content((ox + chartw / 2, celly(n - 1) + cs + 0.52),
    text(size: 8pt, fill: p.muted, style: "italic")[
      cell$(i, j)$ $=$ non-terminals deriving $w_i dots w_j$])

  // recurrence note under the chart
  draw.content((ox + chartw / 2, oy - 1.18),
    text(size: 8pt, fill: p.muted)[
      $"VP" -> "V" "NP"$ #h(0.5em) fills $["cooks"]$ $times$ $["the soup"]$])
  draw.content((ox + chartw / 2, oy - 1.62),
    text(size: 8pt, fill: p.garnet, weight: "bold")[
      top-right $=$ S #sym.arrow.r sentence is in the language])
})
