// mlatlas · renderers/gnn.typ
// A dedicated radial message-passing diagram (Veličković/Distill style): a central
// target node receives messages from neighbours fanned around it; multi-head attention
// is shown as parallel coloured strands; an "aggregate" arrow exits to the updated node.

#import "@preview/cetz:0.5.2"

#let gnn-palette = (
  node: rgb("#ECECEC"), node-stroke: rgb("#3A3A3A"),
  target: rgb("#FBE1E3"), target-stroke: rgb("#73000A"),
  out: rgb("#E7EFD9"), out-stroke: rgb("#65780B"),
  heads: (rgb("#466A9F"), rgb("#CC2E40"), rgb("#1F414D")),
  line: rgb("#262626"), muted: rgb("#5C5C5C"), text: rgb("#1E1E1E"),
)

#let message-passing(neighbors: 5, heads: 3, palette: gnn-palette) = {
  let p = palette
  cetz.canvas(length: 1cm, {
    import cetz.draw: circle, line, content
    let R = 3.2
    let nr = 0.52
    let a0 = 52deg
    let a1 = 308deg
    let positions = ()
    for i in range(neighbors) {
      let t = if neighbors <= 1 { 0.5 } else { i / (neighbors - 1) }
      let ang = a0 + (a1 - a0) * t
      positions.push((R * calc.cos(ang), R * calc.sin(ang)))
    }
    // multi-head message strands (neighbour -> centre)
    for pos in positions {
      let (nx, ny) = pos
      let dx = 0 - nx
      let dy = 0 - ny
      let len = calc.sqrt(dx * dx + dy * dy)
      let ux = dx / len
      let uy = dy / len
      let px = -uy
      let py = ux
      let sx = nx + ux * nr
      let sy = ny + uy * nr
      let ex = 0 - ux * (nr + 0.18)
      let ey = 0 - uy * (nr + 0.18)
      for k in range(heads) {
        let off = (k - (heads - 1) / 2) * 0.14
        let col = p.heads.at(calc.rem(k, p.heads.len()))
        // one centred arrowhead on the middle strand so the bundle has a single clean head
        let mk = if k == calc.floor(heads / 2) { (end: "stealth", scale: 0.8) } else { (:) }
        line((sx + px * off, sy + py * off), (ex + px * off, ey + py * off), stroke: 1.2pt + col, mark: mk)
      }
    }
    // neighbour nodes
    for (i, pos) in positions.enumerate() {
      circle(pos, radius: nr, fill: p.node, stroke: 1pt + p.node-stroke)
      content(pos, text(size: 8pt, fill: p.text)[$h_(#i)$])
    }
    // alpha label on the first strand
    let f = positions.at(0)
    content((f.at(0) * 0.55, f.at(1) * 0.55 + 0.42), text(size: 7.5pt, fill: p.muted)[$alpha_(v 0)$])
    // central target node
    circle((0, 0), radius: nr + 0.06, fill: p.target, stroke: 1.7pt + p.target-stroke)
    content((0, 0), text(size: 8pt, fill: p.text)[$h_v$])
    // aggregate -> updated node
    line((nr + 0.1, 0), (R - nr - 0.15, 0), stroke: 2.2pt + p.line, mark: (end: "stealth", scale: 0.85))
    content(((nr + R) / 2, 0.34), text(size: 7.5pt, fill: p.muted)[aggregate])
    circle((R, 0), radius: nr, fill: p.out, stroke: 1.6pt + p.out-stroke)
    content((R, 0), text(size: 8pt, fill: p.text)[$h'_v$])
  })
}
