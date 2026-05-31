// Tanner graph for an LDPC (low-density parity-check) code.
// Built from first principles in mlatlas print-first style (not traced).
//
// A Tanner graph is the bipartite factor graph of a linear block code, driven by
// the parity-check matrix H (size m x n). Two node classes:
//   - n BIT / VARIABLE nodes  v_1..v_n  (round)   — one per codeword bit / column of H
//   - m CHECK / PARITY nodes  c_1..c_m  (square, '+' glyph) — one per row of H
// An undirected edge joins v_j to c_i  iff  H_{i,j} = 1. There are no bit-bit or
// check-check edges. Each check node enforces one parity equation over GF(2):
//   c_i :  sum_{j : H_{i,j}=1}  v_j  =  0  (mod 2)
// "Low-density" means H is sparse, so the graph is sparse: this is what makes
// belief-propagation / sum-product decoding cheap. Here H is the (7,4) Hamming
// parity-check matrix — a regular code with check degree 4. One satisfied parity
// equation (c_1) is highlighted in garnet as the focal annotation.
// Sources confirm conventions only (Tanner 1981; MacKay; Gallager).
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ---- brand palette -----------------------------------------------------------
#let c-garnet = rgb("#73000A")
#let ink = rgb("#1A1A1A")
#let muted = rgb("#5C5C5C")
#let c-bit = rgb("#ECECEC") // 10% black — bit-node fill
#let c-chk = rgb("#C7C7C7") // 30% black — check-node fill
#let edge = rgb("#5C5C5C")
#let faint = rgb("#A2A2A2")

// ---- the parity-check matrix H (m=3 rows, n=7 cols) --------------------------
// Row i = check c_i, Col j = bit v_j. H_{i,j}=1  <=>  edge (v_j, c_i).
#let H = (
  (1, 0, 1, 0, 1, 0, 1),
  (0, 1, 1, 0, 0, 1, 1),
  (0, 0, 0, 1, 1, 1, 1),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let n = 7 // bit nodes
  let m = 3 // check nodes
  let rb = 0.40 // bit circle radius
  let sc = 0.36 // check square half-side

  // ---- layout: bits on the top lane, checks on the bottom lane ---------------
  let dxb = 1.55 // bit spacing
  let x0b = -(n - 1) * dxb / 2 // center the bit lane
  let yb = 1.9 // bit-lane y
  let bit-x(j) = x0b + j * dxb // j = 0..n-1
  let BIT(j) = (bit-x(j), yb)

  let dxc = 3.55 // check spacing (3 checks span the bit lane)
  let x0c = -(m - 1) * dxc / 2
  let yc = -1.9 // check-lane y
  let chk-x(i) = x0c + i * dxc // i = 0..m-1
  let CHK(i) = (chk-x(i), yc)

  // ---- incidence edges from H — drawn first, behind nodes --------------------
  // Garnet for the edges of the highlighted check c_1 (row 0), neutral otherwise.
  for i in range(m) {
    for j in range(n) {
      if H.at(i).at(j) == 1 {
        let focal = (i == 0)
        let a = BIT(j)
        let b = CHK(i)
        draw.line(
          (a.at(0), a.at(1) - rb),
          (b.at(0), b.at(1) + sc),
          stroke: (
            paint: if focal { c-garnet } else { edge },
            thickness: if focal { 1.25pt } else { 0.9pt },
          ),
        )
      }
    }
  }

  // ---- check nodes (filled squares with '+' parity glyph) --------------------
  let check(i, focal: false) = {
    let c = CHK(i)
    draw.rect(
      (c.at(0) - sc, c.at(1) - sc), (c.at(0) + sc, c.at(1) + sc),
      fill: if focal { rgb("#F2D9DB") } else { c-chk },
      stroke: (paint: if focal { c-garnet } else { ink }, thickness: if focal { 1.5pt } else { 1.1pt }),
      radius: 0pt,
    )
    draw.content(c, text(size: 12pt, fill: if focal { c-garnet } else { ink }, weight: "bold")[$+$])
    draw.content(
      (c.at(0), c.at(1) - sc - 0.34),
      text(size: 9pt, fill: if focal { c-garnet } else { ink })[$c_#(i + 1)$],
    )
  }
  for i in range(m) { check(i, focal: i == 0) }

  // ---- bit / variable nodes (open circles) -----------------------------------
  let bit(j) = {
    let c = BIT(j)
    draw.circle(c, radius: rb, fill: c-bit, stroke: (paint: ink, thickness: 1.1pt))
    draw.content(c, text(size: 9pt, fill: ink)[$v_#(j + 1)$])
  }
  for j in range(n) { bit(j) }

  // ---- focal parity-equation annotation (garnet) -----------------------------
  // c_1 = row 0 of H = bits {1,3,5,7}; this is the GF(2) constraint it enforces.
  // Placed below c_1 in clear space so it does not collide with lane labels.
  draw.content(
    (CHK(0).at(0), CHK(0).at(1) - sc - 0.72),
    text(size: 8.5pt, fill: c-garnet, weight: "bold")[$v_1 plus.o v_3 plus.o v_5 plus.o v_7 = 0$],
  )

  // ---- lane labels -----------------------------------------------------------
  draw.content(
    (x0b - dxb - 0.15, yb), anchor: "east",
    text(size: 8.5pt, fill: muted)[bit nodes],
  )
  draw.content(
    (x0b - dxb - 0.15, yb - 0.42), anchor: "east",
    text(size: 7.5pt, fill: faint)[(variables, cols of $H$)],
  )
  draw.content(
    (x0c - dxc / 2 - 0.55, yc + 0.42), anchor: "east",
    text(size: 8.5pt, fill: muted)[check nodes],
  )
  draw.content(
    (x0c - dxc / 2 - 0.55, yc), anchor: "east",
    text(size: 7.5pt, fill: faint)[(parity, rows of $H$)],
  )

  // ---- the parity-check matrix H, drawn at right as the driver ---------------
  let Hx = (n - 1) * dxb / 2 + 1.9 // right of the bit lane
  let Hy = -0.05
  let cw = 0.40 // matrix cell width
  let rh = 0.40 // matrix cell height
  let Hx0 = Hx + cw // first column center
  let Hy0 = Hy + rh // first row center (top)
  // bracket-style title
  draw.content((Hx + (n + 1) * cw / 2, Hy0 + rh + 0.45), text(size: 9pt, fill: ink)[$H = $ parity-check matrix])
  // column headers v_j
  for j in range(n) {
    draw.content(
      (Hx0 + j * cw, Hy0 + rh - 0.04),
      text(size: 6.5pt, fill: muted)[$v_#(j + 1)$],
    )
  }
  // entries + row labels
  for i in range(m) {
    let ry = Hy0 - i * rh
    draw.content((Hx0 - cw - 0.18, ry), anchor: "east", text(size: 7pt, fill: if i == 0 { c-garnet } else { muted })[$c_#(i + 1)$])
    for j in range(n) {
      let one = H.at(i).at(j) == 1
      draw.content(
        (Hx0 + j * cw, ry),
        text(
          size: 8pt,
          fill: if one and i == 0 { c-garnet } else if one { ink } else { faint },
          weight: if one { "bold" } else { "regular" },
        )[#H.at(i).at(j)],
      )
    }
  }
  // enclosing brackets
  let bxl = Hx0 - cw / 2 - 0.2
  let bxr = Hx0 + (n - 1) * cw + cw / 2 + 0.2
  let byt = Hy0 + rh / 2 + 0.05
  let byb = Hy0 - (m - 1) * rh - rh / 2 - 0.05
  let blen = 0.16
  for (bx, dir) in ((bxl, 1), (bxr, -1)) {
    draw.line((bx, byt), (bx, byb), stroke: (paint: ink, thickness: 1.0pt))
    draw.line((bx, byt), (bx + dir * blen, byt), stroke: (paint: ink, thickness: 1.0pt))
    draw.line((bx, byb), (bx + dir * blen, byb), stroke: (paint: ink, thickness: 1.0pt))
  }
  // dims note
  draw.content(
    (Hx + (n + 1) * cw / 2, byb - 0.42),
    text(size: 7.5pt, fill: muted)[$m = 3$ checks $times$ $n = 7$ bits  ·  edge $<=>$ $H_(i j) = 1$],
  )

  // ---- legend (bottom-left) --------------------------------------------------
  let lx = x0b - dxb - 0.15
  let ly = -3.55
  draw.circle((lx + 0.18, ly), radius: 0.18, fill: c-bit, stroke: (paint: ink, thickness: 1.0pt))
  draw.content((lx + 0.5, ly), anchor: "west", text(size: 8pt, fill: muted)[bit node $v_j$])
  draw.rect((lx + 2.2, ly - 0.18), (lx + 2.56, ly + 0.18), fill: c-chk, stroke: (paint: ink, thickness: 1.0pt), radius: 0pt)
  draw.content((lx + 2.38, ly), text(size: 9pt, fill: ink, weight: "bold")[$+$])
  draw.content((lx + 2.72, ly), anchor: "west", text(size: 8pt, fill: muted)[check node $c_i$ (parity)])
  draw.line((lx + 5.4, ly), (lx + 5.9, ly), stroke: (paint: edge, thickness: 1.0pt))
  draw.content((lx + 6.04, ly), anchor: "west", text(size: 8pt, fill: muted)[incidence edge])

  // ---- title -----------------------------------------------------------------
  draw.content(
    (0, 3.5),
    text(size: 12pt, weight: "bold", fill: ink)[Tanner graph of an LDPC code],
  )
  draw.content(
    (0, 2.95),
    text(size: 8.5pt, fill: muted)[bipartite: bit nodes vs parity-check nodes; an edge wherever $H_(i j) = 1$  ·  sparse $H$ = "low-density"],
  )
})
