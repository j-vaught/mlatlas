// Bootstrap resampling fan-out — a standard statistical-learning concept (ESL; ISLR/ISLP).
//
// An observed dataset of n points is RESAMPLED WITH REPLACEMENT B times. Each bootstrap
// dataset D*_b draws n points from D, so some original points are DUPLICATED and others are
// OMITTED. A statistic theta-hat*_b is computed on every bootstrap dataset; the B values form
// an empirical SAMPLING DISTRIBUTION used to estimate the standard error / confidence interval
// of theta-hat.
//
// Original mlatlas figure built from knowledge in the print-first house style: light fills,
// dark text, sharp orthogonal corners, stealth arrowheads, garnet as a sparse focal accent on
// the resulting sampling distribution. Each dataset is a small fixed grid of "data points";
// duplicated points are filled garnet, omitted ones are hollow, so with-replacement reads at a
// glance.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#A2A2A2")
#let gline  = rgb("#C7C7C7")
#let panel  = rgb("#ECECEC")
#let beige  = rgb("#FFF2E3")
#let gwash  = rgb("#73000A").transparentize(85%)

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ───────────────────────── layout constants ─────────────────────────
  let n-cells = 9                    // n = 9 data points per dataset (3×3 glyph)
  let cols = 3
  let dot-r = 0.13                   // radius of a data-point dot
  let cell = 0.42                    // spacing between dots inside a glyph
  let pad = 0.30                     // inner padding of a dataset card

  // a dataset glyph: a 3×3 grid of point markers, optionally with a per-point
  // "count" (0 = omitted/hollow, 1 = once, >1 = duplicated -> garnet + ring).
  // counts: list of n-cells integers (multiplicities).
  let glyph-w = (cols - 1) * cell + 2 * pad + 2 * dot-r
  let rows = 3
  let glyph-h = (rows - 1) * cell + 2 * pad + 2 * dot-r

  let draw-dataset(cx, cy, counts, card-fill, card-stroke) = {
    // card background
    rect((cx - glyph-w / 2, cy - glyph-h / 2), (cx + glyph-w / 2, cy + glyph-h / 2),
         fill: card-fill, stroke: card-stroke, radius: 0pt)
    // points, row-major top-to-bottom
    let x0 = cx - (cols - 1) * cell / 2
    let y0 = cy + (rows - 1) * cell / 2
    for k in range(n-cells) {
      let r = calc.quo(k, cols)
      let c = calc.rem(k, cols)
      let px = x0 + c * cell
      let py = y0 - r * cell
      let m = counts.at(k)
      if m == 0 {
        // omitted: hollow dot with faint dashed ring
        circle((px, py), radius: dot-r, fill: white, stroke: (paint: faint, dash: "densely-dotted", thickness: 0.7pt))
      } else if m == 1 {
        // sampled once: solid neutral dot
        circle((px, py), radius: dot-r, fill: muted, stroke: 0.7pt + ink)
      } else {
        // duplicated (m>=2): garnet fill + a small multiplicity badge
        circle((px, py), radius: dot-r, fill: garnet, stroke: 0.8pt + garnet)
        content((px + dot-r + 0.085, py + dot-r + 0.02), anchor: "center",
                text(size: 5.5pt, fill: garnet, weight: "bold")[#m#sym.times])
      }
    }
  }

  // ───────────────────────── original dataset D ───────────────────────
  let y-data = 5.6
  // every point present exactly once
  let orig = range(n-cells).map(_ => 1)
  draw-dataset(0, y-data, orig, beige, 0.95pt + ink)
  content((0, y-data + glyph-h / 2 + 0.40),
          text(size: 10pt, fill: ink)[*observed data* $D = {x_1, dots, x_n}$])
  content((glyph-w / 2 + 0.18, y-data), anchor: "west",
          text(size: 7.5pt, fill: muted)[$n$ points])

  // ───────────────────────── B bootstrap datasets ─────────────────────
  // Each bootstrap multiset: counts sum to n (= 9). Hand-picked so duplicates &
  // omissions read clearly; each is a valid draw-with-replacement of n points.
  let boot-counts = (
    (2, 0, 1, 1, 0, 2, 1, 1, 1),   // D*_1
    (1, 1, 0, 2, 1, 0, 1, 1, 2),   // D*_2
    (0, 2, 1, 0, 3, 1, 1, 0, 1),   // D*_3
    (1, 0, 2, 1, 1, 1, 0, 2, 1),   // D*_b
  )
  let n-boot = boot-counts.len()
  let boot-gap = 2.55
  let span = (n-boot - 1) * boot-gap
  let xs = range(n-boot).map(i => i * boot-gap - span / 2)
  let y-boot = 2.4
  let boot-labels = ($D^*_1$, $D^*_2$, $D^*_3$, $D^*_B$)

  // fan-out label
  content((span / 2 + 0.95, (y-data + y-boot) / 2 + 0.55), anchor: "west",
          box(fill: white, inset: 1.5pt,
              text(size: 8pt, fill: garnet)[sample $n$ points\ *with replacement*\ ($B$ times)]))

  for (i, x) in xs.enumerate() {
    // fan-out arrow from D down to this bootstrap dataset
    line((x * 0.16, y-data - glyph-h / 2 - 0.04), (x, y-boot + glyph-h / 2 + 0.06),
         stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.8))
    draw-dataset(x, y-boot, boot-counts.at(i), white, 0.85pt + ink)
    content((x, y-boot - glyph-h / 2 - 0.30),
            text(size: 9pt, fill: ink)[#boot-labels.at(i)])
  }
  // ellipsis between D*_3 and D*_B
  content(((xs.at(2) + xs.at(3)) / 2, y-boot),
          text(size: 12pt, fill: muted)[$dots.c$])

  // ───────────────────────── statistic per bootstrap set ──────────────
  let y-stat = -0.55
  let stat-labels = ($hat(theta)^*_1$, $hat(theta)^*_2$, $hat(theta)^*_3$, $hat(theta)^*_B$)
  for (i, x) in xs.enumerate() {
    // arrow dataset -> statistic node
    line((x, y-boot - glyph-h / 2 - 0.62), (x, y-stat + 0.34),
         stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.8))
    // statistic node (small op chip)
    let sw = 1.1
    let sh = 0.62
    rect((x - sw / 2, y-stat - sh / 2), (x + sw / 2, y-stat + sh / 2),
         fill: panel, stroke: 0.85pt + ink, radius: 0pt)
    content((x, y-stat), text(size: 9pt, fill: ink)[#stat-labels.at(i)])
  }
  content(((xs.at(2) + xs.at(3)) / 2, y-stat),
          text(size: 11pt, fill: muted)[$dots.c$])
  // what the statistic is
  content((span / 2 + 0.95, y-stat), anchor: "west",
          box(fill: white, inset: 1.5pt,
              text(size: 8pt, fill: ink)[compute statistic\ $hat(theta)^*_b = s(D^*_b)$]))

  // ───────────────────────── aggregate -> sampling distribution ───────
  // funnel all statistics into the histogram below.
  let y-hist-top = -3.55             // top of the distribution panel (title sits here)
  for x in xs {
    line((x, y-stat - 0.34), (x * 0.12, y-hist-top + 0.55),
         stroke: 0.9pt + muted, mark: (end: "stealth", scale: 0.8))
  }

  // ── bootstrap sampling distribution: a small histogram (garnet focal) ──
  let hx0 = -2.55                    // left edge of histogram baseline
  let hx1 =  2.55                    // right edge
  let base = y-hist-top - 1.95       // baseline y
  let bins = (0.18, 0.42, 0.72, 1.05, 1.30, 1.12, 0.80, 0.50, 0.26, 0.12)
  let nb = bins.len()
  let bw = (hx1 - hx0) / nb
  // backing panel
  rect((hx0 - 0.35, base - 0.30), (hx1 + 0.35, base + 1.62),
       fill: white, stroke: 0.7pt + gline, radius: 0pt)
  // bars
  for (j, h) in bins.enumerate() {
    let bx = hx0 + j * bw
    rect((bx + 0.04, base), (bx + bw - 0.04, base + h),
         fill: gwash, stroke: 0.9pt + garnet, radius: 0pt)
  }
  // baseline axis
  line((hx0 - 0.05, base), (hx1 + 0.20, base), stroke: 0.9pt + ink,
       mark: (end: "stealth", scale: 0.7))
  content((hx1 + 0.30, base - 0.02), anchor: "west",
          text(size: 8pt, fill: ink)[$hat(theta)^*$])

  // mean / standard-error markers under the curve
  let mu-x = (hx0 + hx1) / 2 + 0.04 * (hx1 - hx0)
  line((mu-x, base), (mu-x, base + 1.45), stroke: (paint: ink, dash: "dashed", thickness: 0.8pt))
  content((mu-x, base + 1.62 + 0.16), text(size: 8pt, fill: ink)[$macron(hat(theta)^*)$])
  // SE span (a double-headed segment one bar to each side of the mean)
  let se = 1.55 * bw
  line((mu-x - se, base - 0.18), (mu-x + se, base - 0.18),
       stroke: 0.9pt + muted, mark: (start: "stealth", end: "stealth", scale: 0.55))
  content((mu-x, base - 0.40),
          text(size: 7.5pt, fill: muted)[$plus.minus hat("se")_B$])

  content((0, base + 1.62 + 0.55),
          text(size: 10pt, fill: garnet, weight: "bold")[bootstrap sampling distribution of $hat(theta)$])

  // standard-error formula beside the distribution
  content((hx1 + 0.55, base + 0.95), anchor: "west",
          box(fill: white, inset: 2pt,
              text(size: 8pt, fill: ink)[
                $hat("se")_B = sqrt(1 / (B - 1) sum_(b=1)^B (hat(theta)^*_b - macron(hat(theta)^*))^2)$
              ]))

  // ───────────────────────── legend ───────────────────────────────────
  let ly = base - 0.95
  let lx = hx0 - 0.35
  // duplicated swatch
  circle((lx + 0.12, ly + 0.14), radius: dot-r, fill: garnet, stroke: 0.8pt + garnet)
  content((lx + 0.34, ly + 0.14), anchor: "west",
          text(size: 7.5pt, fill: ink)[point drawn $gt.eq 2#sym.times$ (duplicated)])
  // once swatch
  circle((lx + 4.0, ly + 0.14), radius: dot-r, fill: muted, stroke: 0.7pt + ink)
  content((lx + 4.22, ly + 0.14), anchor: "west",
          text(size: 7.5pt, fill: ink)[drawn once])
  // omitted swatch
  circle((lx + 6.05, ly + 0.14), radius: dot-r, fill: white,
         stroke: (paint: faint, dash: "densely-dotted", thickness: 0.7pt))
  content((lx + 6.27, ly + 0.14), anchor: "west",
          text(size: 7.5pt, fill: ink)[omitted ($0#sym.times$)])
})
