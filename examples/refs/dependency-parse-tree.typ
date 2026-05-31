// Dependency parse tree — directed labeled arcs over a single row of words.
//
// In a (projective) dependency grammar every word except the sentence ROOT has
// exactly ONE head: a directed, labeled arc runs head -> dependent, named with a
// grammatical relation (nsubj = nominal subject, dobj = direct object, det =
// determiner, amod = adjectival modifier). A single distinguished ROOT arc points
// into the main predicate (the finite verb). The arcs are drawn as smooth curves
// ABOVE the words, with the relation label at each arc's apex and a stealth
// arrowhead at the DEPENDENT end. A well-formed projective parse has no crossing
// arcs and forms a tree rooted at ROOT.
//
//   ROOT --root--> chased
//   chased --nsubj--> cat ,  chased --dobj--> mouse
//   cat --det--> The ,  mouse --det--> the ,  mouse --amod--> small
//
// Curved arcs over a baseline are not expressible via the orthogonal edge router,
// so this is a dedicated cetz renderer that computes arc geometry in Typst.
// Built from the standard NLP convention (Jurafsky & Martin SLP3 ch. on
// dependency parsing; Eisenstein) in mlatlas print-first style — not traced.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette: print-first, garnet a sparse focal accent ----------------
#let garnet = rgb("#73000A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let arccol = rgb("#363636") // ordinary dependency arc (90% black)
#let rootcol = rgb("#5C5C5C") // root marker text

#cetz.canvas(length: 1cm, {
  import cetz.draw: line, content, bezier, rect

  // ---- the sentence: one row of word tokens --------------------------------
  // index 0 is the abstract ROOT slot; 1..6 are the words.
  let words = (
    [ROOT], [The], [cat], [chased], [the], [small], [mouse],
  )
  // x-centre of each token (uneven spacing tuned to label widths)
  let cx = (-0.2, 1.7, 3.1, 4.9, 6.9, 8.3, 9.9)
  let baseY = 0.0 // text baseline row
  let topGap = 0.32 // gap between word top and where an arc starts

  // word-token top anchor (where arcs attach)
  let topOf(i) = (cx.at(i), baseY + topGap)

  // ---- arc drawer ----------------------------------------------------------
  // head -> dependent arc: a symmetric bezier rising to an apex whose height
  // grows with the horizontal span (so wider arcs nest cleanly above shorter
  // ones, giving the classic non-crossing "rainbow" look). Arrowhead (stealth)
  // sits at the DEPENDENT end; the relation label rides at the apex.
  let dep-arc(h, d, lbl, focal: false, hscale: 1.0, hoff: 0.0, doff: 0.0) = {
    let ph0 = topOf(h)
    let pd0 = topOf(d)
    let ph = (ph0.at(0) + hoff, ph0.at(1))
    let pd = (pd0.at(0) + doff, pd0.at(1))
    let span = calc.abs(cx.at(d) - cx.at(h))
    // apex height: base + proportion of span, scaled per-arc to avoid collisions
    let apex = (0.55 + 0.30 * span) * hscale
    let st = if focal {
      (paint: garnet, thickness: 1.5pt)
    } else {
      (paint: arccol, thickness: 1.0pt)
    }
    // control points pull straight up from each endpoint -> smooth shoulders
    let c1 = (ph.at(0), ph.at(1) + apex)
    let c2 = (pd.at(0), pd.at(1) + apex)
    bezier(
      ph, pd, c1, c2,
      stroke: st,
      mark: (end: "stealth", fill: if focal { garnet } else { arccol }, scale: 0.7),
    )
    // relation label at the apex (midpoint of the two control points)
    let mx = (ph.at(0) + pd.at(0)) / 2
    let my = baseY + topGap + apex + 0.16
    // small white pad behind label so the arc does not strike through it
    let lw = 0.30 + 0.11 * lbl.len()
    rect(
      (mx - lw, my - 0.17), (mx + lw, my + 0.17),
      fill: white, stroke: none,
    )
    content(
      (mx, my),
      text(
        size: 8pt,
        fill: if focal { garnet } else { muted },
        weight: if focal { "bold" } else { "regular" },
      )[#lbl],
    )
  }

  // ---- arcs (drawn shortest-span first so the white label pads layer well) --
  // det:  cat -> The
  dep-arc(2, 1, "det", hscale: 1.0)
  // amod: mouse -> small   (shortest on the right — sits lowest)
  dep-arc(6, 5, "amod", hscale: 0.95, hoff: -0.30)
  // det:  mouse -> the     (nests just above amod)
  dep-arc(6, 4, "det", hscale: 1.0, hoff: -0.15)
  // nsubj: chased -> cat   (focal — the subject relation, in garnet)
  dep-arc(3, 2, "nsubj", focal: true, hscale: 0.92, hoff: -0.22)
  // dobj:  chased -> mouse (wide span — arcs HIGH over det/amod, no crossing)
  dep-arc(3, 6, "dobj", hscale: 1.0, hoff: 0.22, doff: 0.30)

  // ---- ROOT arc into the main verb -----------------------------------------
  // distinguished arc ROOT -> chased, labeled "root", drawn from the ROOT slot.
  dep-arc(0, 3, "root", hscale: 0.92, doff: -0.22)

  // ---- the word row --------------------------------------------------------
  // ROOT slot drawn as a small boxed marker; words as plain content.
  for (i, w) in words.enumerate() {
    if i == 0 {
      // ROOT marker — boxed, sharp corners
      rect(
        (cx.at(i) - 0.62, baseY - 0.24), (cx.at(i) + 0.62, baseY + 0.24),
        fill: rgb("#ECECEC"), stroke: (paint: ink, thickness: 1.0pt), radius: 0pt,
      )
      content((cx.at(i), baseY), text(size: 8.5pt, fill: ink, weight: "bold")[ROOT])
    } else {
      content((cx.at(i), baseY), text(size: 11pt, fill: ink)[#w])
    }
  }

  // ---- part-of-speech tags under each word (the usual second annotation row)
  let pos = ("", "DET", "NOUN", "VERB", "DET", "ADJ", "NOUN")
  for (i, p) in pos.enumerate() {
    if p != "" {
      content(
        (cx.at(i), baseY - 0.52),
        text(size: 7pt, fill: rgb("#A2A2A2"), style: "italic")[#p],
      )
    }
  }

  // ---- title + caption -----------------------------------------------------
  content(
    ((cx.at(0) + cx.at(6)) / 2, 3.65),
    text(size: 12pt, weight: "bold", fill: ink)[Dependency parse tree],
  )
  content(
    ((cx.at(0) + cx.at(6)) / 2, 3.18),
    text(size: 8.5pt, fill: muted)[directed labeled arcs head $arrow.r$ dependent; one ROOT arc into the main verb; projective (no crossings)],
  )

  // ---- legend (bottom) -----------------------------------------------------
  let lx = cx.at(0) - 0.0
  let ly = -1.55
  // ordinary arc glyph
  line(
    (lx, ly), (lx + 0.7, ly),
    stroke: (paint: arccol, thickness: 1.0pt),
    mark: (end: "stealth", fill: arccol, scale: 0.7),
  )
  content((lx + 0.86, ly), anchor: "west", text(size: 8pt, fill: muted)[dependency arc (head $arrow.r$ dependent)])
  // focal arc glyph
  line(
    (lx + 6.0, ly), (lx + 6.7, ly),
    stroke: (paint: garnet, thickness: 1.5pt),
    mark: (end: "stealth", fill: garnet, scale: 0.7),
  )
  content((lx + 6.86, ly), anchor: "west", text(size: 8pt, fill: garnet)[focal relation (nsubj)])

  let ly2 = ly - 0.62
  // relation abbreviations gloss
  content(
    (lx, ly2), anchor: "west",
    text(size: 7.5pt, fill: rgb("#A2A2A2"))[nsubj = nominal subject · dobj = direct object · det = determiner · amod = adjectival modifier],
  )
})
