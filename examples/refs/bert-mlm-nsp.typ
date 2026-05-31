// BERT pretraining objectives — Masked-LM (MLM) + Next-Sentence Prediction (NSP).
// Rebuilt in mlatlas's print-first style from the standard concept (Devlin et al.;
// Jurafsky & Martin SLP3). No image traced.
//
// A packed two-sentence input  [CLS] A.. [SEP] B.. [SEP]  has ~15% of its tokens
// corrupted: most are replaced by a special [MASK] symbol (garnet). Token +
// segment + position embeddings feed a deep bidirectional Transformer encoder,
// which emits one CONTEXTUAL vector per position. Two pretraining heads read out
// of it:
//   · MLM head — runs ONLY the masked positions through a softmax over the whole
//     vocabulary V to reconstruct the original tokens.
//   · NSP head — runs the pooled [CLS] vector C through a 2-way softmax to predict
//     whether sentence B truly follows sentence A (IsNext / NotNext).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── palette ──────────────────────────────────────────────────────────────────
#let garnet = rgb("#73000A")
#let ink    = rgb("#000000")
#let blue   = rgb("#466A9F")
#let green  = rgb("#65780B")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let tok-fill  = rgb("#ECECEC")     // ordinary input-token box
#let mask-fill = rgb("#FFF2E3")     // [MASK] box (beige, garnet stroke)
#let out-fill  = white              // contextual-output box

// ── the packed input sequence ───────────────────────────────────────────────
// label, segment (A/B), and whether this position was masked / is special.
#let seqtok = (
  ("[CLS]", "A", "cls"),
  ("the",   "A", "tok"),
  ("[MASK]","A", "mask"),   // was "cat"
  ("sat",   "A", "tok"),
  ("[SEP]", "A", "sep"),
  ("it",    "B", "tok"),
  ("[MASK]","B", "mask"),   // was "purred"
  ("[SEP]", "B", "sep"),
)
#let N = seqtok.len()
#let orig = ("—", "the", "cat", "sat", "—", "it", "purred", "—")  // gold targets

// ── geometry ─────────────────────────────────────────────────────────────────
#let pitch = 1.62        // column pitch
#let bw = 0.66           // box half-width
#let bh = 0.30           // box half-height
#let cx(i) = i * pitch   // x-center of column i
#let midx = (N - 1) * pitch / 2

#let y-tok  = 0.0        // input-token row
#let y-encB = 1.55       // encoder bottom edge
#let y-encT = 3.25       // encoder top edge
#let y-out  = 4.80       // contextual-output row
#let y-head = 7.20       // softmax-head row

#let diagram = cetz.canvas(length: 1cm, {
  import cetz.draw: *

  // ── a labelled box helper ──────────────────────────────────────────────────
  let tokbox(i, lbl, fil, strk, txtcol, weight: "regular") = {
    let x = cx(i)
    rect((x - bw, y-tok - bh), (x + bw, y-tok + bh), fill: fil, stroke: strk)
    content((x, y-tok), text(size: 8.5pt, fill: txtcol, weight: weight, raw(lbl)))
  }

  // ── INPUT TOKEN ROW ─────────────────────────────────────────────────────────
  for (i, t) in seqtok.enumerate() {
    let (lbl, seg, kind) = t
    if kind == "mask" {
      tokbox(i, lbl, mask-fill, 1.0pt + garnet, garnet, weight: "bold")
    } else if kind == "cls" {
      tokbox(i, lbl, tok-fill, 1.0pt + blue, blue, weight: "bold")
    } else if kind == "sep" {
      tokbox(i, lbl, tok-fill, 0.8pt + muted, muted)
    } else {
      tokbox(i, lbl, tok-fill, 0.8pt + ink, ink)
    }
    // segment / position annotation under each box
    content((cx(i), y-tok - bh - 0.32),
      text(size: 6.5pt, fill: faint)[$E_seg^#seg + E_"pos"^#i$])
    // input arrow into the encoder
    line((cx(i), y-tok + bh), (cx(i), y-encB),
      stroke: 0.6pt + muted, mark: (end: "stealth", scale: 0.55))
  }

  // segment brackets (sentence A / sentence B) under the row
  let braky = y-tok - bh - 0.78
  line((cx(0) - bw, braky), (cx(4) + bw, braky), stroke: 0.8pt + blue)
  content(((cx(0) + cx(4)) / 2, braky - 0.26),
    text(size: 7.5pt, fill: blue, weight: "bold")[sentence A])
  line((cx(5) - bw, braky), (cx(7) + bw, braky), stroke: 0.8pt + green)
  content(((cx(5) + cx(7)) / 2, braky - 0.26),
    text(size: 7.5pt, fill: green, weight: "bold")[sentence B])

  content((-2.05, y-tok), anchor: "east",
    text(size: 8pt, fill: ink, weight: "bold")[input\ tokens])

  // ── THE BIDIRECTIONAL TRANSFORMER ENCODER ───────────────────────────────────
  let eL = -bw - 0.55
  let eR = cx(N - 1) + bw + 0.55
  rect((eL, y-encB), (eR, y-encT), fill: rgb("#363636"), stroke: 1.1pt + ink)
  content((midx, (y-encB + y-encT) / 2 + 0.22),
    text(size: 12pt, fill: white, weight: "bold")[BERT encoder])
  content((midx, (y-encB + y-encT) / 2 - 0.30),
    text(size: 8pt, fill: rgb("#C7C7C7"))[deep bidirectional Transformer ($times L$ blocks)])

  // ── CONTEXTUAL OUTPUT ROW  C / T_1 .. T_n ──────────────────────────────────
  for i in range(N) {
    let kind = seqtok.at(i).at(2)
    line((cx(i), y-encT), (cx(i), y-out - bh),
      stroke: 0.6pt + muted, mark: (end: "stealth", scale: 0.55))
    let emph = kind == "mask" or kind == "cls"
    let strk = if kind == "mask" { 1.0pt + garnet }
      else if kind == "cls" { 1.0pt + blue }
      else { 0.7pt + faint }
    rect((cx(i) - bw, y-out - bh), (cx(i) + bw, y-out + bh),
      fill: out-fill, stroke: strk)
    let lab = if kind == "cls" { $C$ } else { $T_#i$ }
    let tc = if kind == "mask" { garnet } else if kind == "cls" { blue } else { ink }
    content((cx(i), y-out),
      text(size: 8.5pt, fill: tc, weight: if emph { "bold" } else { "regular" }, lab))
  }
  content((-2.05, y-out), anchor: "east",
    text(size: 8pt, fill: ink, weight: "bold")[contextual\ vectors])

  // ════════ HEADS ════════
  // helper: a small softmax-head stack at column x, ending in a class strip.
  let head(hx, title, tcol, src-i, src-strk, rows, total: none) = {
    let hw = 1.55
    let hy = y-head
    // routing edge from the source output vector up to the head input
    line((cx(src-i), y-out + bh), (cx(src-i), hy - 0.95),
      stroke: 1.1pt + tcol, mark: (end: "stealth", scale: 0.8))
    line((cx(src-i), hy - 0.95), (hx, hy - 0.95), stroke: 1.1pt + tcol)
    line((hx, hy - 0.95), (hx, hy - 0.60),
      stroke: 1.1pt + tcol, mark: (end: "stealth", scale: 0.8))
    // softmax bar
    rect((hx - hw, hy - 0.60), (hx + hw, hy - 0.18), fill: tcol, stroke: none)
    content((hx, hy - 0.39), text(size: 8pt, fill: white, weight: "bold", title))
    // class rows (a tiny bar chart of probabilities)
    let ry = hy - 0.05
    for (j, r) in rows.enumerate() {
      let (name, p, hit) = r
      let y = ry + j * 0.46
      // probability bar
      rect((hx - hw, y), (hx - hw + 2 * hw * p, y + 0.34),
        fill: if hit { tcol.transparentize(35%) } else { rgb("#C7C7C7") },
        stroke: 0.4pt + faint)
      // outline of full width
      rect((hx - hw, y), (hx + hw, y + 0.34), fill: none, stroke: 0.4pt + faint)
      content((hx - hw + 0.08, y + 0.17), anchor: "west",
        text(size: 7pt, fill: if hit { ink } else { muted },
          weight: if hit { "bold" } else { "regular" }, raw(name)))
      content((hx + hw - 0.08, y + 0.17), anchor: "east",
        text(size: 6.5pt, fill: muted)[#p])
    }
    if total != none {
      content((hx, ry + rows.len() * 0.46 + 0.14),
        text(size: 6.5pt, fill: faint, style: "italic", total))
    }
  }

  // ── MLM head (over vocabulary V) — fed by a MASKED position ─────────────────
  let mlm-x = cx(2) - 2.7
  head(mlm-x, [MLM softmax], garnet, 2, 1.0pt + garnet,
    (("cat", 0.81, true), ("dog", 0.07, false), ("mat", 0.05, false), ("⋯", 0.02, false)),
    total: [over vocabulary $|V|$])
  // the SAME MLM head is shared across every masked position — show T_6 feeding it
  // too (dashed), so the diagram matches "only the masked positions are scored".
  line((cx(6), y-out + bh), (cx(6), y-head - 0.95),
    stroke: (paint: garnet, thickness: 0.9pt, dash: "dashed"))
  line((cx(6), y-head - 0.95), (mlm-x, y-head - 0.95),
    stroke: (paint: garnet, thickness: 0.9pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.7))
  content((mlm-x, y-head + 0.05 + 4 * 0.46 + 0.42),
    text(size: 7.5pt, fill: garnet, weight: "bold")[Masked LM])
  content((mlm-x, y-head + 0.05 + 4 * 0.46 + 0.74),
    text(size: 6.5pt, fill: muted)[predict $T_2 -> $ gold "cat"])

  // ── NSP head (binary) — fed by the [CLS] position ───────────────────────────
  let nsp-x = cx(N - 1) + 2.7
  head(nsp-x, [NSP softmax], blue, 0, 1.0pt + blue,
    (("IsNext", 0.90, true), ("NotNext", 0.10, false)),
    total: [binary])
  content((nsp-x, y-head + 0.05 + 2 * 0.46 + 0.42),
    text(size: 7.5pt, fill: blue, weight: "bold")[Next-Sentence Pred.])
  content((nsp-x, y-head + 0.05 + 2 * 0.46 + 0.74),
    text(size: 6.5pt, fill: muted)[pooled $C ->$ A,B adjacent?])
})

// ════════════════════════════════════════════════════════════════════════════
// LAYOUT
// ════════════════════════════════════════════════════════════════════════════
#align(center)[
  #text(size: 13pt, weight: "bold")[BERT pretraining: Masked-LM + Next-Sentence Prediction]
  #v(2pt)
  #text(size: 9pt, fill: muted)[
    corrupt #box[$~$]15% of tokens with #text(fill: garnet, weight: "bold")[\[MASK\]] ·
    one bidirectional encoder · two read-out heads
  ]
  #v(12pt)
  #diagram
  #v(6pt)
  #text(size: 8pt, fill: faint, style: "italic")[
    Only the masked positions ($T_2, T_6$) are scored by the MLM softmax; only the
    \[CLS\] vector $C$ feeds the NSP softmax. Loss $=$ MLM cross-entropy $+$ NSP cross-entropy.
  ]
]
