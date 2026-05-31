// mlatlas · renderers/pgm.typ
// Probabilistic graphical models with the standard conventions: latent variable =
// open circle, observed variable = shaded circle, plate = sharp rectangle with the
// replication count in the bottom-right corner, directed edges = stealth arrows.

#import "@preview/cetz:0.5.2"

#let pgm-palette = (
  latent: white, observed: rgb("#B6B6B6"),
  stroke: rgb("#363636"), text: rgb("#1A1A1A"), plate: rgb("#5C5C5C"),
)

// Canonical Latent Dirichlet Allocation plate diagram.
#let lda-plate(palette: pgm-palette) = {
  let p = palette
  cetz.canvas(length: 1cm, {
    import cetz.draw: circle, line, content, rect
    let r = 0.52
    let node(x, y, lbl, observed: false) = {
      circle((x, y), radius: r, fill: if observed { p.observed } else { p.latent }, stroke: 1.1pt + p.stroke)
      content((x, y), text(size: 10pt, fill: p.text)[#lbl])
    }
    let plate(x0, y0, x1, y1, lbl) = {
      rect((x0, y0), (x1, y1), stroke: 1pt + p.plate, radius: 0pt)
      content((x1 - 0.4, y0 + 0.32), text(size: 8.5pt, fill: p.plate)[#lbl])
    }
    let arr(a, b) = line(a, b, stroke: 1pt + p.stroke, mark: (end: "stealth", scale: 0.5))
    // plates behind
    plate(1.25, -1.4, 7.05, 1.4, [M])
    plate(3.3, -0.95, 6.9, 0.95, [N])
    plate(7.7, -0.95, 9.55, 0.95, [K])
    // nodes
    node(0, 0, [$alpha$])
    node(2, 0, [$theta$])
    node(4, 0, [$z$])
    node(6, 0, [$w$], observed: true)
    node(8.6, 0, [$phi.alt$])
    node(10.7, 0, [$beta$])
    // directed edges (generative order)
    arr((0 + r, 0), (2 - r, 0))
    arr((2 + r, 0), (4 - r, 0))
    arr((4 + r, 0), (6 - r, 0))
    arr((8.6 - r, 0), (6 + r, 0))
    arr((10.7 - r, 0), (8.6 + r, 0))
  })
}

// A Hidden Markov Model as a Bayesian-net chain: latent states z_t (open) emitting
// observations x_t (shaded) below.
#let hmm-chain(steps: 4, palette: pgm-palette) = {
  let p = palette
  cetz.canvas(length: 1cm, {
    import cetz.draw: circle, line, content
    let r = 0.5
    let sp = 2.2
    let arr(a, b) = line(a, b, stroke: 1pt + p.stroke, mark: (end: "stealth", scale: 0.5))
    for t in range(steps) {
      let x = t * sp
      circle((x, 1.4), radius: r, fill: p.latent, stroke: 1.1pt + p.stroke)
      content((x, 1.4), text(size: 9pt)[$z_(#(t + 1))$])
      circle((x, -1.0), radius: r, fill: p.observed, stroke: 1.1pt + p.stroke)
      content((x, -1.0), text(size: 9pt)[$x_(#(t + 1))$])
      arr((x, 1.4 - r), (x, -1.0 + r)) // emission z_t -> x_t
      if t > 0 { arr((x - sp + r, 1.4), (x - r, 1.4)) } // transition z_{t-1} -> z_t
    }
  })
}
