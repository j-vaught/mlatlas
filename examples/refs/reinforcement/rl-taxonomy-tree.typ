// mlatlas · Taxonomy of reinforcement-learning algorithms (after Spinning Up).
// A top-down tree that classifies RL methods. The first split is the central
// question of whether the agent has (or learns) a model of the environment:
//
//   RL algorithms
//   ├─ Model-Free RL
//   │    ├─ Policy Optimization   (optimize π_θ directly, on-policy)
//   │    └─ Q-Learning            (learn Q*, act greedily, off-policy)
//   │      · DDPG / TD3 / SAC interpolate between the two families
//   └─ Model-Based RL
//        ├─ Learn the Model       (fit a dynamics model from data)
//        └─ Given the Model       (planner over a known/simulated model)
//
// Leaves carry representative algorithm names. Orthogonal (elbow) connectors;
// the garnet accent marks the root question. Print-first: light fills, dark
// text, sharp corners, no rounded nodes.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── palette ───────────────────────────────────────────────────────────────
  let p = (
    edge:   rgb("#363636"),
    text:   rgb("#1A1A1A"),
    muted:  rgb("#5C5C5C"),
    grid:   rgb("#C7C7C7"),
    garnet: rgb("#73000A"),     // sparse accent: root + its connectors
  )
  // branch tints — model-free family vs model-based family
  let tint = (
    free:  rgb("#D9E2EE"),      // light blue   → model-free subtree
    based: rgb("#E7ECCF"),      // light green  → model-based subtree
    mid:   rgb("#FFF2E3"),      // beige        → category nodes
    leaf:  rgb("#FFFFFF"),      // white        → leaf (algorithm) chips
  )
  let txc = (
    free:  rgb("#466A9F"),
    based: rgb("#65780B"),
  )

  // ── helpers ────────────────────────────────────────────────────────────────
  // a rounded-OFF rectangular node centred at `pos`
  let node(pos, w, h, body, fill: rgb("#FFFFFF"), stroke-col: p.edge,
           tcol: p.text, sz: 9pt, wt: "regular") = {
    draw.rect(
      (pos.at(0) - w / 2, pos.at(1) - h / 2),
      (pos.at(0) + w / 2, pos.at(1) + h / 2),
      fill: fill, stroke: 1.1pt + stroke-col, radius: 0pt,
    )
    draw.content(pos, text(size: sz, fill: tcol, weight: wt)[#body])
  }

  // node anchor helpers (centre coords are stored; derive edge midpoints)
  let top(pos, h) = (pos.at(0), pos.at(1) + h / 2)
  let bot(pos, h) = (pos.at(0), pos.at(1) - h / 2)

  // orthogonal elbow connector from bottom-of-parent to top-of-child:
  // straight down to the child's row mid-gap, across, then down into the child.
  let elbow(a, b, color: p.edge, w: 1pt) = {
    let my = (a.at(1) + b.at(1)) / 2
    draw.line(
      a, (a.at(0), my), (b.at(0), my), b,
      stroke: w + color,
    )
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  Geometry — four rows top→down
  // ══════════════════════════════════════════════════════════════════════════
  let yRoot = 9.4               // root
  let yFam  = 7.2               // model-free / model-based
  let yCat  = 4.8               // category nodes
  let yLeaf = 1.6               // leaf algorithm chips (stacked text blocks)

  // node sizes
  let rW = 3.0;  let rH = 0.9   // root
  let fW = 3.1;  let fH = 0.82  // family
  let cW = 3.0;  let cH = 0.78  // category
  let lW = 2.7                  // leaf block width (height varies per content)

  // x-positions (canvas units). Two families split the width.
  let xFree = -4.6             // model-free family centre
  let xBased =  5.0            // model-based family centre
  let xRoot = (xFree + xBased) / 2

  // category x-positions under each family
  let xPO  = -7.2              // policy optimization
  let xQL  = -2.0              // q-learning
  let xLM  =  2.7              // learn the model
  let xGM  =  7.3              // given the model

  // ── root node position ─────────────────────────────────────────────────────
  let nRoot = (xRoot, yRoot)
  let nFree = (xFree, yFam)
  let nBased = (xBased, yFam)
  let nPO  = (xPO, yCat)
  let nQL  = (xQL, yCat)
  let nLM  = (xLM, yCat)
  let nGM  = (xGM, yCat)

  // ══════════════════════════════════════════════════════════════════════════
  //  Connectors (drawn first, so nodes sit on top)
  // ══════════════════════════════════════════════════════════════════════════
  // root → families  (garnet accent on the central split)
  elbow(bot(nRoot, rH), top(nFree, fH), color: p.garnet, w: 1.5pt)
  elbow(bot(nRoot, rH), top(nBased, fH), color: p.garnet, w: 1.5pt)
  // model-free → its two categories
  elbow(bot(nFree, fH), top(nPO, cH), color: txc.free, w: 1.2pt)
  elbow(bot(nFree, fH), top(nQL, cH), color: txc.free, w: 1.2pt)
  // model-based → its two categories
  elbow(bot(nBased, fH), top(nLM, cH), color: txc.based, w: 1.2pt)
  elbow(bot(nBased, fH), top(nGM, cH), color: txc.based, w: 1.2pt)
  // category → leaf chip (short straight stem)
  let stem(npos, color) = draw.line(
    bot(npos, cH), (npos.at(0), yLeaf + 1.55), stroke: 1pt + color,
  )
  stem(nPO, txc.free)
  stem(nQL, txc.free)
  stem(nLM, txc.based)
  stem(nGM, txc.based)

  // ══════════════════════════════════════════════════════════════════════════
  //  Leaf chips — stacked algorithm names beneath each category
  // ══════════════════════════════════════════════════════════════════════════
  // a leaf block: centred title-less list of algorithm names, framed.
  let leaf-block(xc, items, accent) = {
    let n = items.len()
    let rowh = 0.46
    let pad = 0.22
    let h = n * rowh + 2 * pad
    let top-y = yLeaf + 1.55
    let bot-y = top-y - h
    draw.rect(
      (xc - lW / 2, bot-y), (xc + lW / 2, top-y),
      fill: tint.leaf, stroke: 1pt + p.grid, radius: 0pt,
    )
    // a thin colored bar at the left edge keys the chip to its family
    draw.rect(
      (xc - lW / 2, bot-y), (xc - lW / 2 + 0.12, top-y),
      fill: accent, stroke: none,
    )
    for (i, it) in items.enumerate() {
      let yy = top-y - pad - rowh / 2 - i * rowh
      draw.content(
        (xc, yy),
        text(size: 8.5pt, fill: p.text)[#it],
      )
    }
  }

  leaf-block(xPO, ([Policy Gradient], [A2C / A3C], [PPO], [TRPO]), txc.free)
  leaf-block(xQL, ([DQN], [C51], [QR-DQN], [HER]), txc.free)
  leaf-block(xLM, ([World Models], [I2A], [MBMF], [MBVE]), txc.based)
  leaf-block(xGM, ([AlphaZero], [MuZero]), txc.based)

  // ══════════════════════════════════════════════════════════════════════════
  //  Nodes
  // ══════════════════════════════════════════════════════════════════════════
  node(nRoot, rW, rH, [RL algorithms], fill: p.garnet,
       stroke-col: p.garnet, tcol: rgb("#FFFFFF"), sz: 11pt, wt: "bold")

  node(nFree, fW, fH, [Model-Free RL], fill: tint.free,
       stroke-col: txc.free, tcol: txc.free, sz: 10pt, wt: "bold")
  node(nBased, fW, fH, [Model-Based RL], fill: tint.based,
       stroke-col: txc.based, tcol: txc.based, sz: 10pt, wt: "bold")

  node(nPO, cW, cH, [Policy Optimization], fill: tint.mid,
       stroke-col: p.edge, sz: 9pt, wt: "bold")
  node(nQL, cW, cH, [Q-Learning], fill: tint.mid,
       stroke-col: p.edge, sz: 9pt, wt: "bold")
  node(nLM, cW, cH, [Learn the Model], fill: tint.mid,
       stroke-col: p.edge, sz: 9pt, wt: "bold")
  node(nGM, cW, cH, [Given the Model], fill: tint.mid,
       stroke-col: p.edge, sz: 9pt, wt: "bold")

  // ── the bridge: DDPG / TD3 / SAC interpolate PO ↔ Q-learning ────────────────
  // a dashed double-headed link between the two model-free categories with a
  // floating chip naming the hybrid (deterministic policy-gradient) algorithms.
  let bridgeY = yCat
  let aPO = (xPO + cW / 2, bridgeY)
  let aQL = (xQL - cW / 2, bridgeY)
  draw.line(
    aPO, aQL,
    stroke: (paint: p.muted, thickness: 1pt, dash: "dashed"),
    mark: (start: "stealth", end: "stealth", scale: 0.5),
  )
  let xMid = (xPO + xQL) / 2
  // chip sits in the gap between the family node and the category row
  node((xMid, bridgeY + 1.06), 2.55, 0.66, text(size: 8pt)[DDPG · TD3 · SAC],
       fill: rgb("#FFFFFF"), stroke-col: p.muted, tcol: p.muted)
  draw.line(
    (xMid, bridgeY + 0.73), (xMid, bridgeY),
    stroke: (paint: p.muted, thickness: 0.8pt, dash: "dashed"),
  )
  draw.content(
    (xMid, bridgeY + 1.62),
    text(size: 6.6pt, fill: p.muted, style: "italic")[interpolating methods],
  )

  // ══════════════════════════════════════════════════════════════════════════
  //  Title + the splitting-question annotations
  // ══════════════════════════════════════════════════════════════════════════
  draw.content(
    (xRoot, yRoot + 1.05),
    text(size: 12pt, fill: p.text, weight: "bold")[A taxonomy of RL algorithms],
  )
  // the root question, sitting just above the central horizontal connector
  draw.content(
    (xRoot, (yRoot + yFam) / 2 + 0.30),
    anchor: "south",
    text(size: 8pt, fill: p.garnet, style: "italic")[do we have / learn a model?],
  )

  // sub-question chips beside each family→category split
  // (offset left of the model-free fork so it clears the bridge chip)
  draw.content(
    (xFree - 1.9, (yFam + yCat) / 2 + 0.18),
    anchor: "east",
    text(size: 7.5pt, fill: p.muted, style: "italic")[what to learn],
  )
  draw.content(
    (xBased, (yFam + yCat) / 2 + 0.18),
    text(size: 7.5pt, fill: p.muted, style: "italic")[where is the model from],
  )

  // policy- vs value-based reminder under the model-free categories
  draw.content(
    (xPO, yCat - 0.66),
    anchor: "north",
    text(size: 6.8pt, fill: txc.free, style: "italic")[on-policy · optimize $pi_theta$],
  )
  draw.content(
    (xQL, yCat - 0.66),
    anchor: "north",
    text(size: 6.8pt, fill: txc.free, style: "italic")[off-policy · learn $Q^*$],
  )
  draw.content(
    (xLM, yCat - 0.66),
    anchor: "north",
    text(size: 6.8pt, fill: txc.based, style: "italic")[fit dynamics $hat(P)$],
  )
  draw.content(
    (xGM, yCat - 0.66),
    anchor: "north",
    text(size: 6.8pt, fill: txc.based, style: "italic")[plan / search],
  )
})
