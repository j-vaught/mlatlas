// TD / n-step / Monte Carlo backup spectrum (Sutton & Barto, ch. 7 & 12) —
// a STANDARD reinforcement-learning concept.
//
// A horizontal continuum of backup diagrams of INCREASING depth, all updating the
// SAME root state value V(s_t). Each fragment follows ONE sampled trajectory
// (state — action — reward — state …) and bootstraps off the value at its deepest
// state node:
//
//   • 1-step TD, TD(0):  V(s_t) ← R_{t+1} + γ V(s_{t+1})              (shallow bootstrap)
//   • 2-step:            V(s_t) ← R_{t+1} + γ R_{t+2} + γ² V(s_{t+2})
//   • n-step:            … n sampled rewards, then γⁿ V(s_{t+n})       (partial bootstrap)
//   • Monte Carlo (∞):   V(s_t) ← G_t = Σ γ^{k} R_{t+1+k}            (full return, NO bootstrap)
//
// Moving right deepens the backup: MORE sampled rewards (↑ variance) and LESS
// reliance on the bootstrapped estimate (↓ bias). This is the bias–variance
// spectrum of temporal-difference learning. The TD(λ) view averages all n-step
// returns with weight (1−λ)λ^{n−1}; the inset shows that geometric decay.
//
// Original mlatlas figure built from knowledge in the print-first house style:
// light fills, dark text, sharp orthogonal corners, stealth arrowheads. One thin
// mini-renderer draws each sampled-trajectory fragment; geometry computed in Typst.
#import "../../../lib.typ": *
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
#let blue   = rgb("#466A9F")

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ────────────────────────── node glyphs ──────────────────────────
  let sr = 0.165   // state-node (open circle) radius
  let ar = 0.095   // action-node (filled circle) radius
  let step = 0.78  // vertical gap between consecutive state nodes

  // STATE node: open circle. `focal` -> garnet ring (the node being backed up).
  let state-node(p, focal: false) = {
    let s = if focal { 1.5pt + garnet } else { 1.05pt + ink }
    circle(p, radius: sr, fill: white, stroke: s)
  }
  // ACTION node: small filled circle on the sampled path.
  let action-node(p) = { circle(p, radius: ar, fill: ink, stroke: 0.8pt + ink) }
  // bootstrap node: dashed garnet ring (value estimate plugged in here).
  let boot-node(p) = {
    circle(p, radius: sr, fill: beige, stroke: (paint: garnet, thickness: 1.3pt, dash: "dashed"))
  }
  // terminal state symbol: a small filled square (end of episode).
  let terminal(p) = {
    rect((p.at(0) - sr, p.at(1) - sr), (p.at(0) + sr, p.at(1) + sr), fill: ink, stroke: 1.0pt + ink)
  }

  // PURE helper: y of the deepest (bootstrap / terminal) node for a chain of
  // `depth` transitions starting at ytop. (no truncation case handled by caller)
  let chain-bottom(ytop, depth) = ytop - depth * step

  // ──────────────── thin sampled-trajectory backup mini-renderer ────────────────
  // Draws ONE vertical chain (called as a statement). Root state at (x, ytop),
  // going DOWN through `depth` transitions: state →(action)→ state … The deepest
  // state is a bootstrap node (open dashed) unless `terminate` (terminal square).
  let chain(x, ytop, depth: 1, terminate: false) = {
    state-node((x, ytop), focal: true)
    for k in range(depth) {
      let y0   = ytop - k * step
      let yact  = y0 - step / 2
      let ystat = y0 - step
      line((x, y0 - sr), (x, yact + ar), stroke: 1.1pt + ink)
      action-node((x, yact))
      line((x, yact - ar), (x, ystat + sr), stroke: 1.1pt + ink)
      let last = (k == depth - 1)
      if last and terminate { terminal((x, ystat)) }
      else if last { boot-node((x, ystat)) }
      else { state-node((x, ystat)) }
    }
  }

  // ════════════════════════ layout ════════════════════════
  let ytop = 8.2
  let cols = (0, 2.6, 5.4, 8.6)        // x of each fragment column
  let depths = (1, 2, 4, 5)            // shown transitions per column (MC truncates)
  let titles = ([TD(0)], [2-step], [$n$-step], [Monte Carlo])
  let subt = (
    [1 sampled reward], [2 sampled rewards], [$n$ sampled rewards], [full return $G_t$],
  )

  // ── draw the four fragments ──
  // MC column: draw 4 transitions then a dotted ellipsis down to a terminal square.
  chain(cols.at(0), ytop, depth: depths.at(0))
  chain(cols.at(1), ytop, depth: depths.at(1))
  chain(cols.at(2), ytop, depth: depths.at(2))

  // Monte Carlo: explicit truncated chain (4 transitions, ellipsis, terminal)
  {
    let x = cols.at(3)
    state-node((x, ytop), focal: true)
    for k in range(4) {
      let y0   = ytop - k * step
      let yact  = y0 - step / 2
      let ystat = y0 - step
      line((x, y0 - sr), (x, yact + ar), stroke: 1.1pt + ink)
      action-node((x, yact))
      line((x, yact - ar), (x, ystat + sr), stroke: 1.1pt + ink)
      state-node((x, ystat))
    }
    // ellipsis gap then terminal
    let ybase = ytop - 4 * step
    for d in range(3) { circle((x, ybase - 0.22 - d * 0.18), radius: 0.026, fill: muted, stroke: none) }
    let yterm = ybase - 0.22 - 2 * 0.18 - 0.50
    line((x, ybase - 0.22 - 2 * 0.18 - 0.12), (x, yterm + sr + 0.12 + 0.10), stroke: 1.1pt + ink)
    action-node((x, yterm + sr + 0.12 + 0.10 - 0.06))
    terminal((x, yterm))
  }

  // ── reward labels (right of each action→state edge) ──
  let reward-lbl(x, k, txt) = {
    content((x + sr + 0.05, ytop - k * step - step / 2), anchor: "west",
            text(size: 6.6pt, fill: muted)[#txt])
  }
  reward-lbl(cols.at(0), 0, $R_(t+1)$)
  reward-lbl(cols.at(1), 0, $R_(t+1)$); reward-lbl(cols.at(1), 1, $R_(t+2)$)
  reward-lbl(cols.at(2), 0, $R_(t+1)$); reward-lbl(cols.at(2), 3, $R_(t+n)$)
  reward-lbl(cols.at(3), 0, $R_(t+1)$)

  // ── bootstrap callouts (left side) ──
  content((cols.at(0) - sr - 0.10, chain-bottom(ytop, 1)), anchor: "east",
          box(width: 1.5cm)[#align(right)[#text(size: 6.2pt, fill: garnet)[bootstrap\ $gamma V(s_(t+1))$]]])
  content((cols.at(2) - sr - 0.10, chain-bottom(ytop, 4)), anchor: "east",
          box(width: 1.4cm)[#align(right)[#text(size: 6.2pt, fill: garnet)[$gamma^n V(s_(t+n))$]]])
  // terminal callout (right of MC terminal)
  let mc-term-y = (ytop - 4 * step) - 0.22 - 2 * 0.18 - 0.50
  content((cols.at(3) + sr + 0.10, mc-term-y), anchor: "west",
          text(size: 6.4pt, fill: ink)[terminal\ (no bootstrap)])

  // ── column titles + subtitles (subtitle stacked clearly ABOVE the title) ──
  for (i, x) in cols.enumerate() {
    content((x, ytop + 0.95), anchor: "south",
            box(width: 2.2cm)[#align(center)[#text(size: 6.4pt, fill: muted)[#subt.at(i)]]])
    content((x, ytop + 0.46), anchor: "south",
            text(size: 9.5pt,
                 fill: (if i == 0 or i == cols.len() - 1 { garnet } else { ink }),
                 weight: "bold")[#titles.at(i)])
  }
  // root state label
  content((cols.at(0) - sr - 0.10, ytop), anchor: "east", text(size: 8pt, fill: ink)[$s_t$])

  // ════════════════════════ spectrum axis (TD → MC) ════════════════════════
  let ay = 2.95
  let axl = cols.at(0) - 0.55
  let axr = cols.at(3) + 0.55
  line((axl, ay), (axr, ay), stroke: 1.4pt + ink, mark: (end: "stealth", scale: 0.9))
  content((axl - 0.10, ay), anchor: "east", text(size: 8.5pt, fill: garnet, weight: "bold")[TD(0)])
  content((axr + 0.12, ay), anchor: "west", text(size: 8.5pt, fill: garnet, weight: "bold")[Monte Carlo])
  for x in cols { line((x, ay + 0.10), (x, ay - 0.10), stroke: 1.0pt + muted) }
  content(((axl + axr) / 2, ay + 0.26), anchor: "south",
          text(size: 8pt, fill: ink)[depth of backup #h(0.3em) #text(fill: faint, size: 6.8pt)[(shallow #sym.arrow.r deep, bootstrap-free)]])

  // ── bias / variance wedges beneath the axis ──
  let by = ay - 0.62                       // variance wedge centre
  content((axl - 0.10, by), anchor: "east", text(size: 7.5pt, fill: blue)[variance])
  line((cols.at(0) - 0.20, by - 0.02), (cols.at(3) + 0.20, by + 0.14),
       (cols.at(3) + 0.20, by - 0.14), close: true, fill: blue.lighten(58%), stroke: 0.6pt + blue)
  content((axr + 0.12, by), anchor: "west", text(size: 6.8pt, fill: blue)[high])

  let by2 = by - 0.52                      // bias wedge centre
  content((axl - 0.10, by2), anchor: "east", text(size: 7.5pt, fill: garnet)[bias])
  line((cols.at(0) - 0.20, by2 + 0.14), (cols.at(0) - 0.20, by2 - 0.14),
       (cols.at(3) + 0.20, by2 - 0.02), close: true, fill: garnet.lighten(74%), stroke: 0.6pt + garnet)
  content((axr + 0.12, by2), anchor: "west", text(size: 6.8pt, fill: garnet)[low])

  // ════════════════════════ TD(λ) inset: n-step weighting decay ════════════════════════
  // The λ-return weights the n-step return by (1−λ)λ^{n−1}; a geometric decay.
  let lam = 0.7
  let pw = 4.0
  let ph = 2.2
  let px = cols.at(0) - 0.55
  let py = -0.25
  let nbars = 7
  let maxw = (1 - lam)
  rect((px, py), (px + pw, py + ph), fill: white, stroke: 0.7pt + gline)
  let bl = px + 0.55                     // baseline left
  let bb = py + 0.45                     // baseline bottom
  line((bl, bb), (px + pw - 0.20, bb), stroke: 0.9pt + muted)
  line((bl, bb), (bl, py + ph - 0.42), stroke: 0.9pt + muted)
  let plot-h = ph - 1.05
  let bw = (pw - 0.95) / nbars
  for n in range(nbars) {
    let w = (1 - lam) * calc.pow(lam, n)
    let h = w / maxw * plot-h
    let bx = bl + 0.06 + n * bw
    rect((bx, bb), (bx + bw * 0.64, bb + h),
         fill: (if n == 0 { garnet } else { garnet.lighten(34% + n * 8%) }),
         stroke: 0.5pt + garnet.darken(8%))
    content((bx + bw * 0.32, bb - 0.04), anchor: "north", text(size: 6pt, fill: muted)[#(n + 1)])
  }
  content((px + pw / 2 + 0.2, py + ph - 0.20), anchor: "north",
          text(size: 7.2pt, fill: ink)[TD($lambda$) weight  $(1 - lambda) lambda^(n-1)$])
  content(((bl + px + pw - 0.20) / 2 + 0.05, bb - 0.30), anchor: "north",
          text(size: 6.2pt, fill: muted)[$n$-step return index #h(0.3em) ($lambda = 0.7$)])
  content((bl - 0.22, (bb + py + ph - 0.42) / 2), anchor: "south", angle: 90deg,
          text(size: 6.2pt, fill: muted)[weight])

  // ════════════════════════ update-target equations ════════════════════════
  // placed to the RIGHT of the inset, clear of the bias/variance wedges above.
  let ex = px + pw + 0.45
  let ey = 1.40
  content((ex, ey), anchor: "west",
          text(size: 8.5pt, fill: ink)[$n$#h(0.12em)-step target:  $G_(t:t+n) = sum_(k=0)^(n-1) gamma^k R_(t+k+1) + gamma^n V(s_(t+n))$])
  content((ex, ey - 0.66), anchor: "west",
          text(size: 8.5pt, fill: ink)[$lambda$#h(0.05em)-return:  $G_t^lambda = (1 - lambda) sum_(n=1)^infinity lambda^(n-1) G_(t:t+n)$])
  content((ex, ey - 1.24), anchor: "west",
          text(size: 7.2pt, fill: muted)[$n = 1 ==>$ TD(0); #h(0.5em) $n -> infinity ==>$ Monte Carlo $G_t$])

  // ─────────────────────────── legend (single full-width row at the bottom) ───────────────────────────
  let ly = -0.62
  let lx0 = px + pw + 0.40
  state-node((lx0 + 0.13, ly))
  content((lx0 + 0.36, ly), anchor: "west", text(size: 7.4pt, fill: ink)[state $s$])
  action-node((lx0 + 1.55, ly))
  content((lx0 + 1.76, ly), anchor: "west", text(size: 7.4pt, fill: ink)[action $a$])
  boot-node((lx0 + 2.85, ly))
  content((lx0 + 3.10, ly), anchor: "west", text(size: 7.4pt, fill: garnet)[bootstrap $V(s')$])
  terminal((lx0 + 5.30, ly))
  content((lx0 + 5.55, ly), anchor: "west", text(size: 7.4pt, fill: ink)[terminal])
})
