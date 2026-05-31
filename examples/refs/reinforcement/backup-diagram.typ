// Backup diagram (Sutton & Barto) — a STANDARD reinforcement-learning concept.
//
// The open/filled-circle tree fragment depicts ONE Bellman backup: value information
// flows UP the tree (from leaves to the root) to update the root's estimate. An OPEN
// circle is a STATE node; a FILLED circle is an ACTION (state–action) node. From the
// root state s the agent can take each action a; taking a transitions to a successor
// state s′ with reward r under the dynamics p(s′,r | s,a). The diagram makes the
// expansion in the Bellman equation visible: v(s) averages over actions (policy π),
// then over outcomes (dynamics p), of  r + γ v(s′).
//
// Original mlatlas figure built from knowledge in the print-first house style: light
// fills, dark text, sharp orthogonal corners, stealth arrowheads. Three fragments
// from one thin mini-renderer show the standard spectrum — v_π (full expectation over
// actions), q_π (one fixed action then full expectation over outcomes), and a SAMPLE
// (one-step TD) backup that follows a single trajectory rather than averaging.
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

#cetz.canvas(length: 1cm, {
  import cetz.draw: *
  set-style(stroke: (cap: "round", join: "round"))

  // ────────────────────────── node glyphs ──────────────────────────
  let sr = 0.20   // state-node (open circle) radius
  let ar = 0.115  // action-node (filled circle) radius

  // STATE node: open circle. `focal` -> garnet ring (the node being backed up).
  let state-node(p, focal: false, fill-c: white) = {
    circle(p, radius: sr, fill: fill-c,
           stroke: (if focal { 1.5pt + garnet } else { 1.1pt + ink }))
  }
  // ACTION node: small filled circle.
  let action-node(p, sample: false) = {
    circle(p, radius: ar, fill: (if sample { garnet } else { ink }),
           stroke: (if sample { 0.9pt + garnet } else { 0.9pt + ink }))
  }
  // stick edge between two points (no arrowhead — convention in S&B fragments).
  let stick(a, b, sample: false) = {
    line(a, b, stroke: (if sample { 1.4pt + garnet } else { 1.0pt + ink }))
  }

  // ──────────────────── thin backup-diagram mini-renderer ────────────────────
  // Draws one fragment centred at (ox, oy):
  //   • root state at top, `branching` action nodes below it (the policy choice),
  //   • `succ` successor states below EACH action node (the dynamics outcomes),
  //   • `sample` = number of action branches actually followed (garnet). The rest
  //     are drawn faint (the expectation / averaged branches).
  // Returns nothing; pure drawing. Geometry computed in Typst.
  // `accent: true` -> on-path branches drawn garnet (the SAMPLE / TD fragment).
  //                   false -> on-path branches drawn neutral dark (full backups).
  let backup-diagram(ox, oy, branching: 2, succ: 2, sample: 0,
                      fix-action: none, leaf-state: true, accent: false) = {
    let y-root = oy
    let y-act  = oy - 1.05
    let y-leaf = oy - 2.10
    let aspan  = 1.55                                   // half-width of action fan
    let lspan  = 0.42                                   // half-spread of leaves per action

    // action-node x positions
    let axs = if branching == 1 { (ox,) } else {
      range(branching).map(i => ox - aspan + 2 * aspan * i / (branching - 1))
    }

    // root state
    state-node((ox, y-root), focal: true)

    for (i, ax) in axs.enumerate() {
      // is this action branch on the sampled trajectory / the fixed action?
      let on-path = if fix-action != none { i == fix-action } else { i < sample }
      let acc = on-path and accent          // garnet styling only for the sample fragment
      // edge root -> action
      if on-path { stick((ox, y-root - sr), (ax, y-act + ar), sample: acc) } else {
        line((ox, y-root - sr), (ax, y-act + ar), stroke: 1.0pt + faint)
      }
      // action node
      if on-path { action-node((ax, y-act), sample: acc) } else {
        circle((ax, y-act), radius: ar, fill: faint, stroke: 0.9pt + faint)
      }
      // successor states below this action
      if leaf-state {
        let lxs = if succ == 1 { (ax,) } else {
          range(succ).map(j => ax - lspan + 2 * lspan * j / (succ - 1))
        }
        for lx in lxs {
          if on-path {
            stick((ax, y-act - ar), (lx, y-leaf + sr), sample: acc)
            state-node((lx, y-leaf))
          } else {
            line((ax, y-act - ar), (lx, y-leaf + sr), stroke: 1.0pt + faint)
            circle((lx, y-leaf), radius: sr, fill: white, stroke: 0.9pt + faint)
          }
        }
      }
    }
  }

  // ════════════════════════ Fragment A:  v_π(s) ════════════════════════
  let xA = 0
  backup-diagram(xA, 6.0, branching: 3, succ: 2, sample: 3)   // all actions averaged
  // labels
  content((xA + sr + 0.16, 6.0), anchor: "west", text(size: 9pt, fill: ink)[$s$])
  content((xA - 1.55 - 0.16, 6.0 - 1.05), anchor: "east", text(size: 7.5pt, fill: muted)[$pi(a|s)$])
  content((xA + 1.55 + 0.14, 6.0 - 1.05), anchor: "west", text(size: 8pt, fill: ink)[$a$])
  content((xA + 1.97, 6.0 - 2.10 + 0.02), anchor: "west", text(size: 8pt, fill: ink)[$s'$])
  content((xA, 6.0 + sr + 0.42), anchor: "south",
          text(size: 10pt, fill: garnet, weight: "bold")[$v_pi$ backup])
  content((xA, 6.0 - 2.10 - 0.55), anchor: "north",
          box(width: 4.4cm)[#align(center)[#text(size: 7.5pt, fill: muted)[average over *both* actions ($pi$)\ and outcomes ($p$)]]])

  // ════════════════════════ Fragment B:  q_π(s,a) ════════════════════════
  let xB = 5.6
  backup-diagram(xB, 6.0, branching: 1, succ: 3, sample: 1, fix-action: 0)
  content((xB + sr + 0.16, 6.0), anchor: "west", text(size: 9pt, fill: ink)[$s$])
  content((xB + ar + 0.14, 6.0 - 1.05), anchor: "west", text(size: 8pt, fill: ink)[$a$])
  // reward on the dynamics edges (one representative label)
  content((xB - 0.62, 6.0 - 1.62), anchor: "east",
          text(size: 7pt, fill: muted)[$p,r$])
  content((xB + 0.66, 6.0 - 2.10 + 0.02), anchor: "west", text(size: 8pt, fill: ink)[$s'$])
  content((xB, 6.0 + sr + 0.42), anchor: "south",
          text(size: 10pt, fill: garnet, weight: "bold")[$q_pi$ backup])
  content((xB, 6.0 - 2.10 - 0.55), anchor: "north",
          box(width: 4.0cm)[#align(center)[#text(size: 7.5pt, fill: muted)[action $a$ *fixed*; average\ over outcomes ($p$) only]]])

  // ════════════════════════ Fragment C: sample (TD) ════════════════════════
  let xC = 10.9
  backup-diagram(xC, 6.0, branching: 3, succ: 2, sample: 0, fix-action: 1, accent: true)  // one sampled branch
  content((xC + sr + 0.16, 6.0), anchor: "west", text(size: 9pt, fill: ink)[$s$])
  content((xC + ar + 0.12, 6.0 - 1.05 + 0.02), anchor: "west", text(size: 7.5pt, fill: garnet)[$a_t$])
  // reward sits beside the right-hand sampled transition edge
  content((xC + 0.60, 6.0 - 1.58), anchor: "west",
          box(fill: white, inset: 1pt, text(size: 7pt, fill: garnet)[$r_(t+1)$]))
  // successor label to the right of the sampled action's right leaf
  content((xC + 0.42 + sr + 0.16, 6.0 - 2.10 - 0.02), anchor: "west",
          box(fill: white, inset: 1pt, text(size: 7.5pt, fill: garnet)[$s_(t+1)$]))
  content((xC, 6.0 + sr + 0.42), anchor: "south",
          text(size: 10pt, fill: garnet, weight: "bold")[sample (TD) backup])
  content((xC, 6.0 - 2.10 - 0.55), anchor: "north",
          box(width: 4.2cm)[#align(center)[#text(size: 7.5pt, fill: muted)[follow *one* sampled\ transition — no averaging]]])

  // ───────────────────── Bellman expectation equation ─────────────────────
  let eqy = 2.10
  line((-1.6, eqy + 0.55), (13.0, eqy + 0.55), stroke: 0.7pt + gline)
  content((-1.6, eqy), anchor: "west",
          text(size: 9.5pt, fill: ink)[
            $v_pi (s) = sum_a pi(a|s) sum_(s',r) p(s',r | s,a) [ r + gamma v_pi (s') ]$
          ])
  content((-1.6, eqy - 0.78), anchor: "west",
          text(size: 7.5pt, fill: muted)[the backup diagram *is* this expectation drawn as a tree: outer sum = action fan, inner sum = outcome fan, leaves = $v_pi(s')$.])

  // ─────────────────────────── legend ───────────────────────────
  let ly = 0.95
  let lx = -1.6
  state-node((lx + 0.15, ly), focal: false)
  content((lx + 0.45, ly), anchor: "west", text(size: 8pt, fill: ink)[state node (open circle)])

  action-node((lx + 4.55, ly))
  content((lx + 4.78, ly), anchor: "west", text(size: 8pt, fill: ink)[action node (filled circle)])

  state-node((lx + 9.05, ly), focal: true)
  content((lx + 9.35, ly), anchor: "west", text(size: 8pt, fill: ink)[node being updated])

  line((lx + 12.6, ly - 0.18), (lx + 12.6, ly + 0.22),
       stroke: 1.1pt + garnet, mark: (end: "stealth", scale: 0.8))
  content((lx + 12.8, ly), anchor: "west", text(size: 8pt, fill: garnet)[backup direction])
})
