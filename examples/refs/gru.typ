// mlatlas · GRU cell (Cho et al. 2014) — reset gate, update gate, candidate
// hidden state, and the convex-combination hidden-state update. Composed in the
// lstm-cell3d idiom: block3d gate blocks threaded by a garnet hidden-state conveyor.
//
//   R_t = σ(W_r·[H_{t-1}, X_t])              reset gate
//   Z_t = σ(W_z·[H_{t-1}, X_t])              update gate
//   H̃_t = tanh(W·[(R_t ⊙ H_{t-1}), X_t])    candidate hidden state
//   H_t = (1 − Z_t) ⊙ H_{t-1} + Z_t ⊙ H̃_t   new hidden state
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // palette — print-first, garnet accent
  let p = (
    gate: rgb("#F2A6C9"),       // sigmoid gates (reset / update)
    cand: rgb("#FFF2E3"),       // candidate (tanh) — beige
    state: rgb("#73000A"),      // hidden-state conveyor (garnet)
    input: rgb("#E9EDF0"),      // x_t slab
    edge: rgb("#243038"),
    text: rgb("#222222"),
    muted: rgb("#5C5C5C"),
    op: rgb("#FFFFFF"),
  )
  let cam = cam-cabinet

  // ---- geometry --------------------------------------------------------------
  let conv-y = 2.55            // hidden-state conveyor (top)
  let bus-y = -2.5             // shared [H_{t-1}, X_t] input bus (bottom)
  let gw = 1.2
  let gh = 1.4
  let gd = 0.75
  // a clean left-to-right row of the three processing blocks
  let rx = 0.0                 // reset gate
  let zx = 2.4                 // update gate
  let cx = 4.8                 // candidate H̃_t (tanh)
  let xL = -2.4                // left edge / H_{t-1} entry
  let xR = 8.2                 // right edge / H_t exit
  let mix-y = 1.05             // op-disc mixing band, between blocks and conveyor

  let arr(a, b, color: p.edge, w: 1.3pt, s: 0.6) = draw.line(a, b, stroke: w + color, mark: (end: "stealth", scale: s))
  let wire(a, b, color: p.edge, w: 1.1pt) = draw.line(a, b, stroke: w + color)

  // small operator disc (⊙ Hadamard, + add, 1− complement)
  let op(pos, sym, r: 0.3, fill: p.op, sz: 8pt) = {
    draw.circle(pos, radius: r, fill: fill, stroke: 1.0pt + p.edge)
    draw.content(pos, text(size: sz, fill: p.text)[#sym])
  }

  // draw a labelled block; anchors fetched separately (drawables must not join a dict)
  let block(origin, base, body) = {
    block3d(draw, origin: origin, w: gw, h: gh, dep: gd, base: base, edge: p.edge, cam: cam)
    draw.content(origin, text(size: 7.5pt, fill: p.text)[#body])
  }
  let anch(origin) = block3d-anchors(origin: origin, w: gw, h: gh, dep: gd, cam: cam)

  // ---- the shared [H_{t-1}, X_t] input bus along the bottom -----------------
  wire((xL, bus-y), (cx, bus-y), color: p.muted, w: 1.6pt)
  block3d(draw, origin: (xL - 0.6, bus-y), w: 0.7, h: 0.55, dep: 0.35, base: p.input, edge: p.edge, cam: cam)
  draw.content((xL - 0.6, bus-y), text(size: 8pt, fill: p.text)[$x_t$])
  // the previous hidden state also feeds the bus (drop-down from the conveyor at far left)
  wire((xL, conv-y - 0.05), (xL, bus-y), color: p.state, w: 1.4pt)

  // ---- hidden-state conveyor (garnet) across the top ------------------------
  wire((xL, conv-y), (xR - 0.4, conv-y), color: p.state, w: 2.4pt)
  draw.content((xL - 0.25, conv-y), anchor: "east", text(size: 9pt, fill: p.state)[$H_(t-1)$])
  draw.content((xR - 0.2, conv-y), anchor: "west", text(size: 9pt, fill: p.state)[$H_t$])

  // ===========================================================================
  // gate / candidate blocks
  // ===========================================================================
  block((rx, 0), p.gate, [Reset\ gate · $sigma$])
  let R = anch((rx, 0))
  block((zx, 0), p.gate, [Update\ gate · $sigma$])
  let Z = anch((zx, 0))
  block((cx, 0), p.cand, [Candidate\ $tilde(H)_t$ · tanh])
  let H = anch((cx, 0))

  // input bus -> each block (bottom faces)
  for (a, name) in ((R, "R"), (Z, "Z"), (H, "H")) {
    let bx = (a.anchor)("bottom-screen").at(0)
    arr((bx, bus-y + 0.16), (bx, (a.anchor)("bottom-screen").at(1)))
  }

  // ===========================================================================
  // (1) reset-Hadamard:  R_t ⊙ H_{t-1}
  //     reset gate output × (a tap of the previous hidden state)
  // ===========================================================================
  let rhad = (rx + 0.65, mix-y)
  op(rhad, $dot.o$)
  // reset gate -> rhad
  arr(((R.anchor)("top-screen").at(0), (R.anchor)("top-screen").at(1)), (rhad.at(0) - 0.18, rhad.at(1) - 0.24))
  // conveyor tap (garnet) -> rhad
  wire((rx - 0.35, conv-y), (rx - 0.35, mix-y), color: p.state, w: 1.4pt)
  arr((rx - 0.35, mix-y), (rhad.at(0) - 0.3, rhad.at(1)), color: p.state, w: 1.4pt)

  // ===========================================================================
  // (2) reset-gated state -> candidate H̃_t
  //     routed on its own lane just below the mixing band so it stays clear of
  //     the update-gate complement / Hadamard column
  // ===========================================================================
  // ribbon runs along the mixing band (above the block tops, so it clears the
  // update gate) and drops into the candidate from the top
  let reset-lane = mix-y - 0.28
  let cand-top = (H.anchor)("top-screen")
  wire((rhad.at(0), mix-y - 0.27), (rhad.at(0), reset-lane), color: p.state, w: 1.4pt)
  wire((rhad.at(0), reset-lane), (cand-top.at(0), reset-lane), color: p.state, w: 1.4pt)
  arr((cand-top.at(0), reset-lane), (cand-top.at(0), cand-top.at(1) + 0.02), color: p.state, w: 1.4pt)

  // ===========================================================================
  // (3) update-gate mixing:
  //     left  Hadamard  (1 − Z_t) ⊙ H_{t-1}     — on the conveyor
  //     right Hadamard      Z_t   ⊙ H̃_t          — candidate × update gate
  //     add  combines both onto the conveyor -> H_t
  // ===========================================================================
  // complement node (1 − Z_t), sitting just below the conveyor over the update gate
  let comp = (zx, mix-y)
  op(comp, [$1-$], r: 0.32, sz: 7.5pt)
  arr(((Z.anchor)("top-screen").at(0), (Z.anchor)("top-screen").at(1)), (comp.at(0), comp.at(1) - 0.32))

  // left Hadamard on the conveyor, fed by (1−Z) and the garnet ribbon
  let lhad = (zx, conv-y)
  op(lhad, $dot.o$, r: 0.27)
  arr((comp.at(0), comp.at(1) + 0.32), (lhad.at(0), lhad.at(1) - 0.27), w: 1.1pt)

  // update gate also feeds the right Hadamard (raw Z_t branch)
  let rhad2 = (cx + 1.55, mix-y)
  op(rhad2, $dot.o$, r: 0.27)
  // candidate H̃_t -> right Hadamard (garnet)
  arr(((H.anchor)("east").at(0) + 0.02, (H.anchor)("east").at(1)), (rhad2.at(0) - 0.27, rhad2.at(1) - 0.02), color: p.state, w: 1.4pt)
  // Z_t branch tapped from the update-gate top (BEFORE the complement), routed
  // along a high lane and dropped into the right Hadamard from its RIGHT side,
  // leaving the Hadamard's top free for the output wire to the conveyor
  let z-lane = mix-y + 0.55
  let z-tap-x = (Z.anchor)("top-screen").at(0) + 0.4
  let z-drop-x = rhad2.at(0) + 0.85
  wire((z-tap-x, (Z.anchor)("top-screen").at(1) + 0.1), (z-tap-x, z-lane), w: 1.0pt)
  wire((z-tap-x, z-lane), (z-drop-x, z-lane), w: 1.0pt)
  wire((z-drop-x, z-lane), (z-drop-x, rhad2.at(1)), w: 1.0pt)
  arr((z-drop-x, rhad2.at(1)), (rhad2.at(0) + 0.27, rhad2.at(1)), w: 1.0pt)
  draw.content((z-tap-x - 0.02, z-lane + 0.2), text(size: 6.5pt, fill: p.muted)[$Z_t$])

  // add node merges right Hadamard back onto the conveyor (output via the top)
  let add = (xR - 1.4, conv-y)
  op(add, $+$, r: 0.3)
  arr((rhad2.at(0), rhad2.at(1) + 0.27), (rhad2.at(0), conv-y - 0.05), color: p.state, w: 1.4pt)
  wire((rhad2.at(0), conv-y), (add.at(0) - 0.3, conv-y), color: p.state, w: 1.4pt)

  // ---- title + legend --------------------------------------------------------
  draw.content(((xL + xR) / 2, conv-y + 1.05), text(size: 11pt, weight: "bold", fill: p.text)[GRU cell])
  draw.content(((xL + xR) / 2, bus-y - 1.0), text(size: 8pt, fill: p.muted)[
    $H_t = (1 - Z_t) dot.o H_(t-1) + Z_t dot.o tilde(H)_t$ #h(0.6em) (reset $R_t$, update $Z_t$, candidate $tilde(H)_t$)
  ])
})
