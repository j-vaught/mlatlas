// Computational graph — forward pass + reverse-mode autodiff (backprop).
// A scalar expression is decomposed into primitive ops as nodes of a DAG. Solid
// black "data" edges carry values forward; dashed garnet "grad" edges overlay the
// SAME wires in reverse, each carrying the local Jacobian factor of the chain rule.
//
// Worked example (the canonical logistic-loss circuit taught in Goodfellow et al.,
// Bishop DL/PRML, UDL, Nielsen, Fleuret):
//     u = w · x        z = u + b        a = σ(z)        L = (a − y)²
// Forward:  inputs → · → + → σ → loss.
// Backward: seed ∂L/∂L = 1 at the loss, then multiply local derivatives back along
// each wire:  ∂L/∂a = 2(a−y),  ∂a/∂z = a(1−a),  ∂z/∂u = 1,  ∂u/∂w = x, …
// Hand-built in cetz so every wire (and its overlaid reverse-mode gradient) is placed
// exactly — print-first house style, not traced.

#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let garnet = rgb("#73000A")
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let beige  = rgb("#FFF2E3")
#let b10    = rgb("#ECECEC")

#align(center)[
  #text(size: 13pt, weight: "bold", fill: ink)[Computational graph: forward pass and backpropagation]

  #v(2pt)
  #text(size: 9.5pt, fill: muted)[
    $u = w dot x$, #h(7pt) $z = u + b$, #h(7pt) $a = sigma(z)$, #h(7pt) $L = (a - y)^2$
  ]

  #v(14pt)

  #cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // ── geometry ───────────────────────────────────────────────────────────
    let R   = 0.42          // op-node radius
    let rr  = 0.40          // leaf radius
    let spy = 0             // spine y (ops live here)
    let leafy = 1.7         // leaf-input row, above the spine
    let gy  = -1.45         // gradient-tape y, below the spine

    // op spine x-positions
    let x-mul  = 0
    let x-add  = 3
    let x-sig  = 6
    let x-loss = 9.4

    // leaf-input x-positions (each sits above-left of the op it feeds).
    // w (parameter) and x (data) are split into two columns so the reverse
    // gradient wire that climbs back into w never crosses the x node.
    let x-w = -3.0
    let x-x = -1.9
    let x-b = x-add - 1.15
    let x-y = x-loss - 1.25

    // ── styling helpers ──────────────────────────────────────────────────────
    let fwd  = (stroke: 1pt + ink, mark: (end: "stealth", scale: 0.7))
    let grad = (stroke: (paint: garnet, thickness: 1pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))

    // op node: light circle, dark glyph
    let op(x, glyph, r: R, fill: white, sz: 11pt) = {
      circle((x, spy), radius: r, fill: fill, stroke: 1.1pt + ink)
      content((x, spy), text(size: sz, fill: ink)[#glyph])
    }
    // leaf node: small tinted circle (param = garnet ring, data = ink ring)
    let leaf(x, y, glyph, accent) = {
      circle((x, y), radius: rr, fill: beige, stroke: 1.4pt + accent)
      content((x, y), text(size: 9.5pt, fill: ink)[#glyph])
    }

    // ── forward data edges (solid) ───────────────────────────────────────────
    // leaves w,x → ·
    line((x-w + rr - 0.02, leafy), (x-mul - 0.25, spy + R - 0.12), ..fwd)
    line((x-x + rr - 0.02, -leafy + 0.0), (x-mul - 0.25, spy - R + 0.12), ..fwd)
    // · → +  ;  b → +
    line((x-mul + R + 0.02, spy), (x-add - R - 0.02, spy), ..fwd)
    line((x-b, leafy - rr + 0.02), (x-add - 0.18, spy + R + 0.02), ..fwd)
    // + → σ
    line((x-add + R + 0.02, spy), (x-sig - R - 0.02, spy), ..fwd)
    // σ → loss  ;  y → loss
    line((x-sig + R + 0.02, spy), (x-loss - 1.05, spy), ..fwd)
    line((x-y, leafy - rr + 0.02), (x-loss - 0.65, spy + 0.42 + 0.02), ..fwd)

    // ── nodes ────────────────────────────────────────────────────────────────
    leaf(x-w, leafy,  text(size: 9.5pt)[$w$], garnet)   // parameter
    leaf(x-x, -leafy, text(size: 9.5pt)[$x$], ink)      // data input
    leaf(x-b, leafy,  text(size: 9.5pt)[$b$], garnet)   // parameter
    leaf(x-y, leafy,  text(size: 9.5pt)[$y$], ink)      // target

    op(x-mul, $times$, sz: 12pt)
    op(x-add, $+$, sz: 13pt)
    op(x-sig, $sigma$, r: 0.46, sz: 12pt)
    // loss as a rectangle (the scalar output)
    rect((x-loss - 1.05, spy - 0.46), (x-loss + 1.05, spy + 0.46), fill: b10, stroke: 1.5pt + ink)
    content((x-loss, spy), text(size: 9pt, fill: ink)[$L=(a-y)^2$])

    // forward intermediate-value tags above the spine wires
    let tag(x, y, s) = content((x, y), text(size: 7.5pt, fill: muted)[#s])
    tag((x-mul + x-add) / 2, spy + 0.30, [$u$])
    tag((x-add + x-sig) / 2, spy + 0.30, [$z$])
    tag((x-sig + x-loss - 1.05) / 2, spy + 0.30, [$a$])

    // ── reverse gradient edges (dashed garnet), routed BELOW the spine ────────
    // each runs right→left and is labelled with the op's LOCAL derivative.
    let back(xr, xl, lbl) = {
      // drop from the right op, run left along the tape, rise into the left op
      line((xr, spy - R - 0.02), (xr, gy), (xl, gy), (xl, spy - R - 0.02), ..grad)
      content(((xr + xl) / 2, gy - 0.30), text(size: 7.5pt, fill: garnet)[#lbl])
    }
    back(x-loss - 0.55, x-sig + 0.10, [$2(a - y)$])           // ∂L/∂a
    back(x-sig - 0.10, x-add + 0.10,  [$a(1 - a)$])           // ∂a/∂z
    back(x-add - 0.10, x-mul + 0.10,  [$1$])                  // ∂z/∂u
    // local factor ∂u/∂w = x on the × op, then the gradient lands on parameter w
    content((x-mul - 0.62, gy - 0.30), text(size: 7.5pt, fill: garnet)[$x$])
    // route from × down to a lower tape, left, then up into w (avoids the forward x→× wire)
    let wtape = gy - 0.62
    line((x-mul - 0.10, spy - R - 0.02), (x-mul - 0.10, wtape),
         (x-w, wtape), (x-w, leafy - rr - 0.02), ..grad)
    // the accumulated parameter gradient, annotated to the left of w
    content((x-w - rr - 0.18, leafy), anchor: "east",
            text(size: 7.5pt, fill: garnet)[$(partial L)/(partial w)$])

    // seed of backprop at the loss: ∂L/∂L = 1 drops onto the gradient tape
    line((x-loss, spy - 0.46), (x-loss, gy), (x-loss - 0.55, gy), ..grad)
    content((x-loss + 0.12, (spy - 0.46 + gy) / 2 + 0.05), anchor: "west",
            text(size: 7.5pt, fill: garnet)[$(partial L)/(partial L) = 1$])
  })

  #v(12pt)
  // legend ----------------------------------------------------------------------
  #cetz.canvas(length: 1cm, {
    import cetz.draw: *
    line((0, 0), (1.1, 0), stroke: 1pt + ink, mark: (end: "stealth", scale: 0.7))
    content((1.3, 0), anchor: "west", text(size: 8.5pt, fill: ink)[forward (data / activations)])
    line((6.4, 0), (7.5, 0), stroke: (paint: garnet, thickness: 1pt, dash: "dashed"), mark: (end: "stealth", scale: 0.7))
    content((7.7, 0), anchor: "west", text(size: 8.5pt, fill: garnet)[backward (gradients, chain rule)])
  })

  #v(4pt)
  #box(width: 15.5cm, [
    #set par(justify: false)
    #set align(center)
    #text(size: 8.5pt, fill: muted)[
      Each op caches its inputs on the forward pass. Backprop seeds $partial L \/ partial L = 1$ at
      the loss and walks the DAG in reverse: every dashed edge multiplies by the *local* derivative
      of its op, so the global gradient at each parameter (e.g. #text(fill: garnet)[$partial L \/ partial w$])
      is the product of the local factors along its path — the chain rule.
    ]
  ])
]
