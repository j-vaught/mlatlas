// Bahdanau (additive) / Luong (multiplicative) cross-attention — rebuilt in
// mlatlas's print-first style from the standard seq2seq-with-attention concept
// (D2L; Jurafsky & Martin SLP3; Eisenstein; Bishop). No image traced.
//
// Left panel: the attention mechanism. A decoder query s_{t-1} scores every
// encoder hidden state h_1..h_T (additive MLP, Bahdanau; or dot / general,
// Luong); softmax turns the scores into alignment weights a_{t,i}; a
// weighted-sum op-node forms the context vector c_t. Each fan-in edge's stroke
// width is proportional to its weight a_{t,i}.
// Right panel: a source × target alignment heatmap (luma-filled rect cells).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ────────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#000000")
#let blue   = rgb("#466A9F")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let ec-fill = rgb("#ECECEC")          // encoder state box fill
#let dc-fill = rgb("#FFF2E3")          // decoder query box fill (beige)

// ════════════════════════════════════════════════════════════════════════════
// PANEL A — the attention mechanism (fan-in with weight-proportional strokes)
// ════════════════════════════════════════════════════════════════════════════

// alignment weights a_{t,1..T} for the illustrated decoder step (sum ≈ 1).
#let weights = (0.07, 0.11, 0.46, 0.24, 0.12)
#let src-tok = ("le", "chat", "noir", "dort", "·")   // source words (encoder)
#let T = weights.len()

#let panel-a = cetz.canvas(length: 1cm, {
  import cetz.draw: *

  let bx = 0.92                 // encoder box half-width
  let by = 0.34                 // encoder box half-height
  let dx = 0.92                 // column pitch
  let ey = 3.0                  // encoder row y
  let sumy = 1.35               // weighted-sum op-node y
  let cy = 0.05                 // context vector y
  let qx = -2.2                 // decoder query x
  let qy = 2.05                 // decoder query y

  let cx-of(i) = i * dx         // x-center of encoder column i
  let mid-x = (T - 1) * dx / 2

  // ── encoder hidden states h_1 .. h_T (a row of light boxes) ───────────────
  for i in range(T) {
    let x = cx-of(i)
    rect((x - bx/2, ey - by), (x + bx/2, ey + by),
      fill: ec-fill, stroke: 0.7pt + muted)
    content((x, ey), text(size: 9pt)[$h_#(i+1)$])
    // source token under each state, italic
    content((x, ey + by + 0.30),
      text(size: 8pt, fill: muted, style: "italic", src-tok.at(i)))
  }
  // encoder bracket label
  content((mid-x, ey + by + 0.78),
    text(size: 8.5pt, fill: ink, weight: "bold")[encoder hidden states])

  // ── decoder query s_{t-1} ─────────────────────────────────────────────────
  rect((qx - bx/2, qy - by), (qx + bx/2, qy + by),
    fill: dc-fill, stroke: 0.8pt + garnet)
  content((qx, qy), text(size: 9pt, fill: garnet)[$s_(t-1)$])
  content((qx, qy + by + 0.30),
    text(size: 8.5pt, fill: garnet, weight: "bold")[decoder query])

  // ── fan-in edges:  h_i ─(weight)→ Σ ; stroke width ∝ a_{t,i} ─────────────
  for i in range(T) {
    let x = cx-of(i)
    let w = weights.at(i)
    let sw = 0.4pt + (3.6 * w) * 1pt          // weight → thickness
    let is-top = w == calc.max(..weights)
    let col = if is-top { garnet } else { blue.transparentize(18%) }
    line((x, ey - by), (mid-x, sumy + 0.30),
      stroke: sw + col)
    // weight tag near the encoder end of the heaviest two edges, staggered in y
    if w >= 0.20 {
      let ty = if is-top { ey - by - 0.30 } else { ey - by - 0.70 }
      content((x + 0.46, ty),
        text(size: 7.5pt, fill: if is-top { garnet } else { blue })[
          $a_(t #h(1pt) #(i+1)) = #w$
        ])
    }
  }

  // the query also feeds the scorer (dashed, it is the thing being scored against)
  line((qx, qy - by), (mid-x, sumy + 0.30),
    stroke: (paint: garnet, thickness: 0.8pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.7))

  // ── weighted-sum op node  Σ  →  context c_t ───────────────────────────────
  circle((mid-x, sumy), radius: 0.40, fill: white, stroke: 1.0pt + ink)
  content((mid-x, sumy), text(size: 13pt)[$sum$])
  content((mid-x + 0.92, sumy + 0.04), anchor: "west",
    text(size: 7.5pt, fill: muted)[$c_t = sum_i a_(t i) h_i$])

  // Σ → context vector box
  line((mid-x, sumy - 0.40), (mid-x, cy + 0.30),
    stroke: 1.0pt + ink, mark: (end: "stealth", scale: 0.8))
  rect((mid-x - 1.05, cy - 0.34), (mid-x + 1.05, cy + 0.30),
    fill: white, stroke: 1.1pt + garnet)
  content((mid-x, cy - 0.02),
    text(size: 9pt, fill: garnet, weight: "bold")[context $c_t$])

  // ── scoring formulae (Bahdanau additive vs Luong multiplicative) ──────────
  let fy = -1.25
  content((mid-x, fy),
    text(size: 8.5pt, fill: ink)[
      align weights: $a_(t i) = "softmax"_i (e_(t i))$
    ])
  content((mid-x, fy - 0.62),
    text(size: 8pt, fill: muted)[
      #text(fill: garnet, weight: "bold")[Bahdanau]
      (additive): $e_(t i) = v^top tanh(W_s s_(t-1) + W_h h_i)$
    ])
  content((mid-x, fy - 1.18),
    text(size: 8pt, fill: muted)[
      #text(fill: blue, weight: "bold")[Luong]
      (mult.): $e_(t i) = s_(t-1)^top h_i$
      #h(6pt) or #h(6pt) $s_(t-1)^top W h_i$
    ])
})

// ════════════════════════════════════════════════════════════════════════════
// PANEL B — source × target alignment heatmap (luma-filled rect grid)
// ════════════════════════════════════════════════════════════════════════════

#let tgt-tok = ("the", "black", "cat", "sleeps", "<eos>")   // target rows
// alignment matrix A[t][i]:  rows = target steps, cols = source words.
// Roughly monotone (a clean MT alignment), with the illustrated step (row "cat")
// matching the weight vector used in panel A.
#let A = (
  (0.62, 0.18, 0.08, 0.06, 0.06),   // the   ← le
  (0.10, 0.20, 0.58, 0.07, 0.05),   // black ← noir  (adjective swap)
  (0.07, 0.11, 0.46, 0.24, 0.12),   // cat   ← chat/noir  (= panel-A weights)
  (0.05, 0.07, 0.12, 0.70, 0.06),   // sleeps← dort
  (0.06, 0.06, 0.06, 0.14, 0.68),   // <eos> ← ·
)

#let panel-b = cetz.canvas(length: 1cm, {
  import cetz.draw: *

  let cell = 0.78
  let nC = src-tok.len()        // columns = source
  let nR = tgt-tok.len()        // rows = target

  // title bar
  rect((0 - 0.05, nR * cell + 0.30), (nC * cell + 0.05, nR * cell + 0.94),
    fill: garnet, stroke: none)
  content((nC * cell / 2, nR * cell + 0.62),
    text(fill: white, weight: "bold", size: 9.5pt)[alignment $A_(t i)$])

  // column (source) labels across the top
  for j in range(nC) {
    content((j * cell + cell/2, nR * cell + 0.13),
      text(size: 8pt, fill: ink, style: "italic", src-tok.at(j)))
  }
  // row (target) labels down the left; row 0 is the TOP row.
  for i in range(nR) {
    content((-0.18, (nR - 1 - i) * cell + cell/2), anchor: "east",
      text(size: 8pt, fill: ink, tgt-tok.at(i)))
  }

  // heatmap cells: darker = higher weight (luma fill). Garnet tint on the
  // argmax cell of each row to read the alignment path.
  for i in range(nR) {
    let row = A.at(i)
    let amax = calc.max(..row)
    for j in range(nC) {
      let w = row.at(j)
      let yy = (nR - 1 - i) * cell        // flip so row 0 is on top
      let xx = j * cell
      let peak = w == amax
      // luma fill: high w → dark; map to garnet ramp for peaks, neutral else
      let fil = if peak {
        garnet.transparentize(100% - (35% + 60% * w))
      } else {
        rgb("#363636").transparentize(100% - (12% + 78% * w))
      }
      rect((xx, yy), (xx + cell, yy + cell),
        fill: fil, stroke: 0.5pt + rgb("#A2A2A2"))
      // print the weight value as a decimal (e.g. 0.46), contrast-aware.
      // pad single digits so 0.07 stays "0.07" rather than "0.7".
      let pct = calc.round(w * 100)
      let wtxt = "0." + (if pct < 10 { "0" } else { "" }) + str(pct)
      content((xx + cell/2, yy + cell/2),
        text(size: 7.5pt,
          fill: if w > 0.30 { white } else { muted },
          weight: if peak { "bold" } else { "regular" },
          wtxt))
    }
  }

  // axis captions
  content((nC * cell / 2, -0.52),
    text(size: 8.5pt, fill: muted)[source positions $i$ (French)])
  content((-1.35, nR * cell / 2), angle: 90deg,
    text(size: 8.5pt, fill: muted)[target steps $t$ (English)])
})

// ════════════════════════════════════════════════════════════════════════════
// LAYOUT
// ════════════════════════════════════════════════════════════════════════════
#align(center)[
  #text(size: 13pt, weight: "bold")[Bahdanau / Luong cross-attention]
  #v(2pt)
  #text(size: 9pt, fill: muted)[
    decoder query scores every encoder state · softmax → alignment weights ·
    weighted-sum context vector
  ]
  #v(14pt)
  #grid(
    columns: (auto, auto),
    column-gutter: 34pt,
    align: (center + horizon, center + horizon),
    panel-a,
    panel-b,
  )
  #v(8pt)
  #text(size: 8pt, fill: faint, style: "italic")[
    The "cat" row of the heatmap (highlighted in panel A) shows the
    alignment weights for one decoder step; edge thickness #box($prop$) weight.
  ]
]
