// Transposed (fractionally-strided) convolution — learnable upsampling.
// A small input feature map is expanded into a larger output: every input cell is
// multiplied by the shared kernel and the resulting kernel-sized "stamp" is added into
// the output, sliding by the stride. With stride s the spatial size grows ~s×. The 3-D
// row shows the volume growing (small slab -> "transp. conv /2 up" -> larger slab); the
// inset shows the stamping mechanic for a 2x2 input / 2x2 kernel / stride 1 example.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#let pal = cnn3d-palette
#let cam = cam-cabinet

// brand colors
#let garnet = rgb("#73000A")
#let blue = rgb("#466A9F")
#let dgreen = rgb("#65780B")
#let ink = rgb("#222222")
#let muted = rgb("#5C5C5C")
#let line10 = rgb("#ECECEC")
#let line30 = rgb("#C7C7C7")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ============================================================ TOP: 3-D volume row
  let y = 0.0
  // input volume (small spatial) -> op-node -> output volume (large spatial), same channels
  let inA = vol-anchors((0, y), 14, 21, cam: cam)
  let inOx = -inA.umin
  let inAa = vol-anchors((inOx, y), 14, 21, cam: cam)

  // op-node sits between
  let opx = (inAa.anchor)("east").at(0) + 1.6
  let outOx = opx + 1.7 - (vol-anchors((0, y), 112, 21, cam: cam)).umin
  let outA = vol-anchors((outOx, y), 112, 21, cam: cam)

  // draw input volume
  volume(
    draw, (inOx, y), 14, 21, base: pal.input, palette: pal, cam: cam,
    label: [input feature map], sub: [14#sym.times 14#sym.times K],
  )
  // op-node: a sharp square (no rounded corners) with garnet outline
  let opr = 0.62
  draw.rect(
    (opx - opr, y - opr), (opx + opr, y + opr),
    radius: 0pt, fill: garnet.lighten(86%), stroke: 1.4pt + garnet,
  )
  draw.content((opx, y + 0.16), text(size: 8.5pt, weight: "bold", fill: garnet)[transp.])
  draw.content((opx, y - 0.18), text(size: 8.5pt, weight: "bold", fill: garnet)[conv #sym.arrow.t 2])
  // draw output volume
  volume(
    draw, (outOx, y), 112, 21, base: pal.up, palette: pal, cam: cam,
    label: [output feature map], sub: [28#sym.times 28#sym.times K],
  )

  // flow arrows in/out of the op-node
  draw.line(
    ((inAa.anchor)("east").at(0) + 0.05, y), (opx - opr - 0.05, y),
    stroke: 1.6pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
  )
  draw.line(
    (opx + opr + 0.05, y), ((outA.anchor)("west").at(0) - 0.05, y),
    stroke: 1.6pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
  )

  // stride / learnable-kernel note above the op
  draw.content(
    (opx, y + opr + 0.62),
    text(size: 7.5pt, fill: muted)[learnable kernel \u{2113}×\u{2113}, stride #sym.times 2],
  )

  // upsampling bracket over the whole row
  let topY = calc.max((inAa.anchor)("top-screen").at(1), (outA.anchor)("top-screen").at(1))
  let bY = topY + 1.35
  let x1 = (inAa.anchor)("west").at(0)
  let x2 = (outA.anchor)("east").at(0)
  draw.line((x1, bY - 0.18), (x1, bY), (x2, bY), (x2, bY - 0.18), stroke: 0.9pt + blue)
  draw.content((( x1 + x2) / 2, bY + 0.3), text(size: 8.5pt, weight: "bold", fill: blue)[spatial size grows #sym.times 2 (s = 2)])

  // title
  draw.content(
    (x1, bY + 1.0), anchor: "west",
    text(size: 12pt, weight: "bold", fill: garnet)[Transposed convolution — learnable upsampling],
  )

  // ============================================================ BOTTOM: stamping mechanic inset
  // a 2x2 input, 2x2 kernel, stride 1 -> 3x3 output. Each input cell scales the kernel and the
  // 2x2 stamp is ADDED into the output at the cell's stride-shifted position; overlaps sum.
  let cell = 0.62
  let baseY = -5.7

  // ---- helper: draw a labeled grid of values -------------------------------------------
  let grid(ox, oy, nx, ny, fillfn, txtfn, edge: ink, lw: 1.0pt) = {
    for iy in range(ny) {
      for ix in range(nx) {
        // row 0 at top
        let cx = ox + ix * cell
        let cy = oy - iy * cell
        draw.rect(
          (cx, cy - cell), (cx + cell, cy),
          radius: 0pt, fill: fillfn(ix, iy), stroke: lw + edge,
        )
        let t = txtfn(ix, iy)
        if t != none { draw.content((cx + cell / 2, cy - cell / 2), t) }
      }
    }
  }

  // ---------- INPUT 2x2 ----------
  let inX = -4.6
  let inTop = baseY + 0.6
  // highlight the (0,0) input cell (value a) as the focal element in garnet
  grid(
    inX, inTop, 2, 2,
    (ix, iy) => if (ix, iy) == (0, 0) { garnet.lighten(78%) } else { line10 },
    (ix, iy) => {
      let names = (((0, 0), "a"), ((1, 0), "b"), ((0, 1), "c"), ((1, 1), "d"))
      let nm = names.find(p => p.at(0) == (ix, iy)).at(1)
      let col = if (ix, iy) == (0, 0) { garnet } else { ink }
      text(size: 9pt, weight: "bold", fill: col)[#nm]
    },
    edge: ink,
  )
  draw.content((inX + cell, inTop + 0.42), text(size: 8.5pt, weight: "bold", fill: ink)[input 2#sym.times 2])

  // ---------- KERNEL 2x2 ----------
  let kX = inX + 3.1
  let kTop = inTop
  grid(
    kX, kTop, 2, 2,
    (ix, iy) => blue.lighten(80%),
    (ix, iy) => {
      let names = (((0, 0), "w\u{2080}"), ((1, 0), "w\u{2081}"), ((0, 1), "w\u{2082}"), ((1, 1), "w\u{2083}"))
      text(size: 8.5pt, weight: "bold", fill: blue)[#names.find(p => p.at(0) == (ix, iy)).at(1)]
    },
    edge: blue,
  )
  draw.content((kX + cell, kTop + 0.42), text(size: 8.5pt, weight: "bold", fill: blue)[kernel \u{2113}×\u{2113}])

  // operator between input and kernel
  draw.content(
    (inX + 2.55, inTop - cell),
    text(size: 11pt, weight: "bold", fill: muted)[#sym.times],
  )

  // arrow from (input * kernel) into the output region
  let arrFromX = kX + 2 * cell + 0.25
  let arrToX = arrFromX + 1.05
  let midY = inTop - cell
  draw.line(
    (arrFromX, midY), (arrToX, midY),
    stroke: 1.6pt + garnet, mark: (end: "stealth", scale: 0.8),
  )
  draw.content((( arrFromX + arrToX) / 2, midY + 0.36), text(size: 7.5pt, fill: garnet)[stamp \u{0026} add])

  // ---------- OUTPUT 3x3 (with the a·kernel stamp shown) ----------
  let oX = arrToX + 0.35
  let oTop = inTop + 0.32
  // ghost full output grid
  grid(
    oX, oTop, 3, 3,
    (ix, iy) => white,
    (ix, iy) => none,
    edge: line30, lw: 0.8pt,
  )
  // overlay: the stamp for input cell a lands at output rows/cols 0..1 (stride 1, position 0)
  grid(
    oX, oTop, 2, 2,
    (ix, iy) => garnet.lighten(80%),
    (ix, iy) => {
      let names = (
        ((0, 0), "a w\u{2080}"), ((1, 0), "a w\u{2081}"),
        ((0, 1), "a w\u{2082}"), ((1, 1), "a w\u{2083}"),
      )
      text(size: 7pt, weight: "bold", fill: garnet)[#names.find(p => p.at(0) == (ix, iy)).at(1)]
    },
    edge: garnet, lw: 1.1pt,
  )
  draw.content((oX + 1.5 * cell, oTop + 0.42), text(size: 8.5pt, weight: "bold", fill: ink)[output 3#sym.times 3])

  // dashed ghost stamps for the other input cells, showing stride-shifted overlap (summed)
  let ghost(gx, gy) = {
    draw.rect(
      (gx, gy - 2 * cell), (gx + 2 * cell, gy),
      radius: 0pt, fill: none, stroke: (paint: dgreen, thickness: 0.9pt, dash: "dashed"),
    )
  }
  ghost(oX + cell, oTop) // input b -> shifted right by stride
  ghost(oX, oTop - cell) // input c -> shifted down
  draw.content(
    (oX + 1.5 * cell, oTop - 3 * cell - 0.4),
    text(size: 7pt, fill: dgreen)[other cells stamp at stride-shifted spots; overlaps summed],
  )

  // section label for the inset
  draw.content(
    (inX, inTop + 1.15), anchor: "west",
    text(size: 9.5pt, weight: "bold", fill: ink)[How one input cell upsamples: multiply the shared kernel, stamp into the output],
  )

  // thin divider between the two panels
  draw.line(
    (inX - 0.2, -3.2), (oX + 3 * cell + 0.6, -3.2),
    stroke: 0.6pt + line30,
  )
})
