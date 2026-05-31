// Dynamic routing between capsules — vector-valued capsules that route to
// higher-level capsules BY AGREEMENT through iterative coupling coefficients.
//
// A capsule is a VECTOR (not a scalar neuron): its length encodes the probability
// that an entity is present, its orientation encodes the entity's instantiation /
// pose parameters. Routing connects a layer of lower capsules u_i to a layer of
// higher capsules v_j:
//   (1) predict:   u-hat_{j|i} = W_ij u_i          (per-pair pose transform)
//   (2) couple:    c_ij = softmax_j(b_ij)          (coupling coeffs, sum_j c_ij = 1)
//   (3) combine:   s_j = sum_i c_ij u-hat_{j|i}     (weighted vote)
//   (4) squash:    v_j = squash(s_j)               (length -> [0,1), keep direction)
//   (5) agree:     b_ij <- b_ij + u-hat_{j|i} . v_j  (votes that agree get reinforced)
// Steps (2)-(5) iterate a few times ("routing by agreement"); a prediction that
// AGREES with the emerging output v_j (large dot product) has its coupling coeff
// grown, so agreeing votes dominate the parent capsule.
//
// Built from the standard convention (Sabour, Frosst & Hinton 2017, "Dynamic Routing
// Between Capsules"; Foundations of Computer Vision) in mlatlas's print-first house
// style. Original bipartite layout — not traced from any figure.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let edgecol = rgb("#A2A2A2")
#let lowfill = rgb("#ECECEC")  // 10% black — lower capsule
#let highfill = rgb("#FFF2E3") // beige — higher capsule
#let blue    = rgb("#466A9F")
#let barbg   = rgb("#C7C7C7")  // capsule vector-bar track

// draw a capsule as a small framed box holding a horizontal "pose vector" bar
// whose filled length encodes activation. p = center, w/h = box size.
#let capsule(draw, p, w, h, act, lab, focal: false, fill: lowfill) = {
  let x0 = p.at(0) - w / 2
  let y0 = p.at(1) - h / 2
  let strk = if focal { garnet } else { ink }
  let sw = if focal { 1.6pt } else { 1.0pt }
  draw.rect((x0, y0), (x0 + w, y0 + h), fill: fill, stroke: (paint: strk, thickness: sw), radius: 0pt)
  // the pose vector drawn as a row of segment bars whose height ~ component
  let n = 4
  let pad = 0.085
  let bw = (w - 2 * pad) / n
  let comps = if focal { (0.95, 0.55, 0.80, 0.35) } else { (0.5, 0.78, 0.32, 0.62) }
  for k in range(n) {
    let bx = x0 + pad + k * bw
    let bh = (h - 2 * pad) * comps.at(k) * act
    draw.rect((bx + 0.012, y0 + pad), (bx + bw - 0.012, y0 + pad + bh),
      fill: if focal { garnet } else { rgb("#5C5C5C") }, stroke: none, radius: 0pt)
  }
  // label below the capsule
  draw.content((p.at(0), y0 - 0.26), text(size: 8pt, fill: ink)[#lab])
}

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // =====================================================================
  // PANEL A — bipartite routing mesh: lower capsules -> higher capsules
  // =====================================================================
  draw.content((1.0, 5.05), anchor: "center",
    text(size: 10.5pt, weight: "bold", fill: ink)[(a) routing between capsule layers])

  let cw = 0.74   // capsule box width
  let ch = 0.62   // capsule box height
  // lower capsule layer (left column) — primary capsules u_i
  let lowX = -3.0
  let lowYs = (3.3, 1.7, 0.1, -1.5)
  let lowLabs = ([$u_1$], [$u_2$], [$u_3$], [$u_4$])
  let lowActs = (0.85, 0.95, 0.5, 0.7)
  // higher capsule layer (right column) — digit / object capsules v_j
  let highX = 4.6
  let highYs = (2.5, 0.3)
  let highLabs = ([$v_1$], [$v_2$])
  let highActs = (0.95, 0.4)

  // coupling coefficients c_ij for the focal lower capsule u_2 (row index 1):
  // softmax over j -> sums to 1. u_2 routes mostly to v_1 (it agrees).
  // matrix rows = lower i, cols = higher j.
  let C = (
    (0.55, 0.45),   // u_1
    (0.88, 0.12),   // u_2  <- focal: strongly to v_1
    (0.40, 0.60),   // u_3
    (0.30, 0.70),   // u_4
  )

  // ---- all-pairs routing edges (behind nodes) ------------------------------
  // each lower capsule predicts INTO each higher capsule; edge width ∝ c_ij.
  // the focal route (u_2 -> v_1) is garnet; the rest grey.
  for (i, ly) in lowYs.enumerate() {
    for (j, hy) in highYs.enumerate() {
      let c = C.at(i).at(j)
      let focal = (i == 1 and j == 0)
      let col = if focal { garnet } else { edgecol }
      let th = 0.4pt + c * 6.5pt
      draw.line((lowX + cw / 2, ly), (highX - cw / 2, hy),
        stroke: (paint: col, thickness: th),
        mark: (end: "stealth", fill: col, scale: 0.7))
    }
  }
  // c_ij label on the focal edge (nudged just above the garnet route)
  draw.content((0.7, 2.42), anchor: "center",
    text(size: 8.5pt, fill: garnet, weight: "bold")[$c_(2 1)$])
  draw.content((-0.2, 0.55), anchor: "center",
    text(size: 7pt, fill: muted)[edge width $prop c_(i j)$])

  // ---- lower capsules ------------------------------------------------------
  for (i, ly) in lowYs.enumerate() {
    capsule(draw, (lowX, ly), cw, ch, lowActs.at(i), lowLabs.at(i), focal: (i == 1))
  }
  draw.content((lowX, 4.25), anchor: "center",
    text(size: 8.5pt, fill: muted)[lower caps $u_i$])
  draw.content((lowX, 3.92), anchor: "center",
    text(size: 7pt, fill: muted)[(parts / pose)])

  // ---- higher capsules -----------------------------------------------------
  for (j, hy) in highYs.enumerate() {
    capsule(draw, (highX, hy), cw + 0.12, ch + 0.12, highActs.at(j), highLabs.at(j),
      focal: (j == 0), fill: highfill)
  }
  draw.content((highX, 4.25), anchor: "center",
    text(size: 8.5pt, fill: muted)[higher caps $v_j$])
  draw.content((highX, 3.92), anchor: "center",
    text(size: 7pt, fill: muted)[(whole / object)])

  // prediction-vector annotation on a non-focal edge
  draw.content((1.0, 3.55), anchor: "center",
    text(size: 7.5pt, fill: ink)[$hat(u)_(j|i) = W_(i j) thin u_i$])
  draw.content((1.0, 3.18), anchor: "center",
    text(size: 6.8pt, fill: muted)[pose transform per pair])

  // softmax note for coupling coefficients
  draw.content((-3.0, -2.45), anchor: "center",
    text(size: 7.5pt, fill: muted)[each $u_i$: $sum_j c_(i j) = 1$])

  // =====================================================================
  // PANEL B — how one higher capsule v_j is formed (squash of weighted votes)
  // =====================================================================
  let bx = 8.7
  let by = 1.6
  draw.rect((bx - 0.7, by - 3.55), (bx + 5.0, by + 1.45),
    stroke: (paint: rgb("#A2A2A2"), thickness: 0.8pt), radius: 0pt)
  draw.content((bx + 2.15, by + 1.95), anchor: "center",
    text(size: 10.5pt, weight: "bold", fill: ink)[(b) forming a parent capsule $v_j$])

  // mini stack of votes c_ij·u-hat feeding a sum op, then squash, then v_j
  let lx = bx - 0.4
  draw.content((lx, by + 0.9), anchor: "west",
    text(size: 8.5pt, fill: ink)[vote: $#h(0.15em) hat(u)_(j|i) = W_(i j) u_i$])
  draw.content((lx, by + 0.25), anchor: "west",
    text(size: 8.5pt, fill: ink)[combine: $#h(0.15em) s_j = sum_i c_(i j) thin hat(u)_(j|i)$])
  // the squash equation, highlighted as the capsule essence (garnet)
  draw.content((lx, by - 0.5), anchor: "west",
    text(size: 8.5pt, fill: garnet, weight: "bold")[squash (length $-> [0,1)$, keep direction):])
  draw.content((lx + 0.2, by - 1.35), anchor: "west",
    text(size: 9.5pt, fill: ink)[$v_j = (norm(s_j)^2) / (1 + norm(s_j)^2) dot s_j / norm(s_j)$])

  // small op-node row: sum -> squash
  let oy = by - 2.65
  draw.circle((bx + 0.45, oy), radius: 0.30, fill: rgb("#ECECEC"),
    stroke: (paint: ink, thickness: 1.0pt))
  draw.content((bx + 0.45, oy), text(size: 10pt, fill: ink)[$sum$])
  draw.content((bx + 0.45, oy - 0.55), text(size: 7pt, fill: muted)[$s_j$])
  draw.line((bx + 0.75, oy), (bx + 1.55, oy),
    stroke: (paint: muted, thickness: 1.0pt), mark: (end: "stealth", scale: 0.7))
  draw.rect((bx + 1.55, oy - 0.32), (bx + 2.85, oy + 0.32),
    fill: highfill, stroke: (paint: garnet, thickness: 1.4pt), radius: 0pt)
  draw.content((bx + 2.2, oy), text(size: 8.5pt, fill: ink)[squash])
  draw.line((bx + 2.85, oy), (bx + 3.7, oy),
    stroke: (paint: garnet, thickness: 1.3pt), mark: (end: "stealth", fill: garnet, scale: 0.85))
  // v_j output capsule
  capsule(draw, (bx + 4.3, oy), 0.8, 0.66, 0.95, [$v_j$], focal: true, fill: highfill)

  // =====================================================================
  // PANEL C — routing by agreement (iterative update of b_ij)
  // =====================================================================
  let cy = -5.35
  draw.content((1.4, cy + 1.95), anchor: "center",
    text(size: 10.5pt, weight: "bold", fill: ink)[(c) routing by agreement (iterate $r$ times)])

  // a prediction u-hat and current output v_j; their dot product (agreement)
  // updates the routing logit b_ij, which re-softmaxes into c_ij.
  let pu = (-2.6, cy)        // prediction vector tail
  let pv = (1.2, cy)         // output capsule center
  // draw the prediction vote as an arrow
  draw.line((pu.at(0), cy), (pu.at(0) + 1.4, cy + 0.55),
    stroke: (paint: blue, thickness: 1.6pt), mark: (end: "stealth", fill: blue, scale: 0.9))
  draw.content((pu.at(0) + 0.05, cy - 0.45), anchor: "west",
    text(size: 8pt, fill: blue)[$hat(u)_(j|i)$ (vote)])
  // output capsule v_j
  capsule(draw, pv, 0.82, 0.66, 0.95, [$v_j$], focal: true, fill: highfill)
  // agreement = dot product
  draw.content((-0.55, cy + 0.95), anchor: "center",
    text(size: 8pt, fill: garnet, weight: "bold")[agreement $= hat(u)_(j|i) dot v_j$])

  // update arrows: logit b_ij -> softmax -> c_ij -> back into the combine
  let ux = 3.6
  draw.rect((ux, cy - 0.32), (ux + 1.15, cy + 0.32),
    fill: rgb("#ECECEC"), stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content((ux + 0.575, cy), text(size: 8pt, fill: ink)[$b_(i j) +$])
  draw.content((ux + 0.575, cy + 0.58), anchor: "center",
    text(size: 7pt, fill: muted)[logit])
  draw.line((pv.at(0) + 0.5, cy), (ux, cy),
    stroke: (paint: garnet, thickness: 1.2pt), mark: (end: "stealth", fill: garnet, scale: 0.8))

  draw.line((ux + 1.15, cy), (ux + 2.05, cy),
    stroke: (paint: muted, thickness: 1.0pt), mark: (end: "stealth", scale: 0.7))
  draw.rect((ux + 2.05, cy - 0.32), (ux + 3.45, cy + 0.32),
    fill: highfill, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content((ux + 2.75, cy), text(size: 8pt, fill: ink)[$"softmax"_j$])
  draw.content((ux + 2.75, cy - 0.62), anchor: "center",
    text(size: 7pt, fill: muted)[$-> c_(i j)$])

  // feedback loop arrow back to the combine (left), drawn as an elbow
  draw.line((ux + 2.75, cy + 0.32), (ux + 2.75, cy + 1.25),
    stroke: (paint: muted, thickness: 1.0pt))
  draw.line((ux + 2.75, cy + 1.25), (pv.at(0), cy + 1.25),
    stroke: (paint: muted, thickness: 1.0pt))
  draw.line((pv.at(0), cy + 1.25), (pv.at(0), cy + 0.45),
    stroke: (paint: muted, thickness: 1.0pt), mark: (end: "stealth", scale: 0.7))
  draw.content((2.4, cy + 1.46), anchor: "center",
    text(size: 7pt, fill: muted)[re-weight votes, recompute $v_j$])

  // bottom caption
  draw.content((1.4, cy - 1.35), anchor: "center",
    text(size: 7.5pt, fill: muted)[votes that AGREE with $v_j$ grow $c_(i j)$; disagreeing votes shrink])
})
