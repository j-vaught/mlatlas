// mlatlas · render.typ
// L0 emitter: turns the Semantic IR into a fletcher diagram. This is the only file
// that knows about fletcher/cetz, so a breaking package release touches one place.
//
// Brand-enforced drawing defaults: rectangular nodes, STEALTH arrowheads only, and
// SHARP orthogonal edges (no curves) — straight where nodes are aligned, deterministic
// right-angle gutter lanes for skips, L-corners otherwise. A `check` pass warns when an
// edge crosses an unrelated block.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node as fnode, edge as fedge
#import "@preview/cetz:0.5.2"
#import "theme.typ": garnet-theme, style-of, edge-style-of, deep-merge
#import "ir.typ": *

// ---- node styling --------------------------------------------------------------
#let _shape-of(kind) = {
  if kind == "circle" { fletcher.shapes.circle }
  else if kind == "ellipse" { fletcher.shapes.ellipse }
  else if kind == "diamond" { fletcher.shapes.diamond }
  else if kind == "pill" or kind == "stadium" { fletcher.shapes.pill }
  else { fletcher.shapes.rect } // force a real rectangle — never fletcher's auto shape
}

#let _resolve-node-style(n, th) = {
  let base = style-of(n.role, th)
  let s = (
    fill: if n.fill != auto { n.fill } else { base.at("fill", default: none) },
    stroke: if n.stroke != auto { n.stroke } else { base.at("stroke", default: th.node-stroke) },
    text-fill: if n.text-fill != auto { n.text-fill } else { base.at("text-fill", default: th.palette.black) },
    corner-radius: if n.corner-radius != auto { n.corner-radius } else { th.corner-radius },
    inset: if n.inset != auto { n.inset } else { th.node-inset },
  )
  deep-merge(s, n.style)
}

// An oblique 3-D cuboid (feature-map prism) drawn with cetz. Numbers are in pt.
#let _cuboid(d, front, top, side, strk, lbl, lblfill) = {
  let w = d.w.pt()
  let h = d.h.pt()
  let dep = d.depth.pt()
  let dx = dep * 0.5
  let dy = dep * 0.5
  cetz.canvas(length: 1pt, {
    import cetz.draw: line, rect, content
    line((0, h), (w, h), (w + dx, h + dy), (dx, h + dy), close: true, fill: top, stroke: strk)
    line((w, 0), (w, h), (w + dx, h + dy), (w + dx, dy), close: true, fill: side, stroke: strk)
    rect((0, 0), (w, h), fill: front, stroke: strk)
    if lbl != none and lbl != [] {
      content((w / 2, h / 2), text(fill: lblfill, size: 7pt, lbl))
    }
  })
}

#let _emit-node(n, th) = {
  if n.kind == "slab" {
    let rs = style-of(n.role, th)
    let front = if n.fill != auto { n.fill } else { rs.at("fill", default: th.palette.b10) }
    if front == none { front = th.palette.b10 }
    let top = front.lighten(20%)
    let side = front.darken(15%)
    let strk = rs.at("stroke", default: th.node-stroke)
    let lblfill = rs.at("text-fill", default: th.palette.black)
    let cub = _cuboid(n.data, front, top, side, strk, n.label, lblfill)
    let body = if n.data.at("dims", default: none) != none {
      align(center, stack(dir: ttb, spacing: 3pt, cub, text(size: 6.5pt, fill: th.palette.b70)[#n.data.dims]))
    } else { cub }
    fnode(n.pos, body, name: label(n.id), stroke: none, fill: none, inset: 1pt)
  } else {
    let s = _resolve-node-style(n, th)
    let body = if n.label == none { [] } else { text(fill: s.text-fill)[#n.label] }
    let args = (
      name: label(n.id),
      corner-radius: s.corner-radius,
      fill: s.fill,
      stroke: s.stroke,
      inset: s.inset,
    )
    if n.width != auto { args.insert("width", n.width) }
    if n.height != auto { args.insert("height", n.height) }
    args.insert("shape", _shape-of(n.kind))
    fnode(n.pos, body, ..args)
  }
}

// ---- edge routing --------------------------------------------------------------
// Resolve the routing regime for an edge given its endpoints (grid coords).
#let _resolve-route(e, pf, pt) = {
  if e.route != "auto" { e.route }
  else if e.kind in ("skip", "residual") { "gutter" }
  else if pf.at(0) == pt.at(0) and calc.abs(pf.at(1) - pt.at(1)) <= 1 { "straight" }
  else if pf.at(1) == pt.at(1) and calc.abs(pf.at(0) - pt.at(0)) <= 1 { "straight" }
  else if pf.at(0) == pt.at(0) or pf.at(1) == pt.at(1) { "gutter" }
  else { "corner" }
}

// The polyline (list of grid-coord segments) an edge will draw — used by the checker.
#let _edge-segments(pf, pt, route, goff) = {
  if route == "corner" {
    let c = (pf.at(0), pt.at(1))
    ((pf, c), (c, pt))
  } else if route == "gutter" {
    if pf.at(0) == pt.at(0) {
      let g0 = (pf.at(0) + goff, pf.at(1))
      let g1 = (pf.at(0) + goff, pt.at(1))
      ((pf, g0), (g0, g1), (g1, pt))
    } else {
      let g0 = (pf.at(0), pf.at(1) + goff)
      let g1 = (pt.at(0), pt.at(1) + goff)
      ((pf, g0), (g0, g1), (g1, pt))
    }
  } else { ((pf, pt),) }
}

#let _stroke-with-dash(stroke, dash) = {
  if dash == none or dash == auto { stroke } else { (paint: stroke.paint, thickness: stroke.thickness, dash: dash) }
}

#let _emit-edge(e, th, posmap) = {
  let es = edge-style-of(e.kind, th)
  let stroke = if e.stroke != auto { e.stroke } else { es.at("stroke", default: 0.9pt + th.palette.black) }
  let dash = if e.dash != auto { e.dash } else { es.at("dash", default: none) }
  let strk = _stroke-with-dash(stroke, dash)
  let marks = if e.marks != auto { e.marks } else { (none, th.mark) }
  let ecr = th.at("edge-corner-radius", default: 0pt)
  let lbl = if e.label == none { none } else { text(size: th.label-size, fill: th.palette.b70)[#e.label] }

  let pf = posmap.at(e.from)
  let pt = posmap.at(e.to)
  let route = _resolve-route(e, pf, pt)
  let fl = label(e.from)
  let tl = label(e.to)

  if route == "gutter" {
    let goff = if e.gutter != auto { e.gutter } else { -0.5 }
    if pf.at(0) == pt.at(0) {
      fedge(fl, (rel: (goff, 0), to: fl), (rel: (goff, 0), to: tl), tl, marks: marks, stroke: strk, corner-radius: ecr, label: lbl)
    } else {
      fedge(fl, (rel: (0, goff), to: fl), (rel: (0, goff), to: tl), tl, marks: marks, stroke: strk, corner-radius: ecr, label: lbl)
    }
  } else if route == "corner" {
    fedge(fl, tl, marks: marks, corner: left, corner-radius: ecr, stroke: strk, label: lbl)
  } else {
    fedge(fl, tl, marks: marks, stroke: strk, label: lbl)
  }
}

#let _emit-group(g, th) = {
  let s = deep-merge((stroke: (paint: th.palette.b70, thickness: 0.8pt, dash: "dashed"), fill: none, inset: 5pt), g.style)
  let lbl = if g.label == none { none } else { text(size: th.label-size, fill: th.palette.b70)[#g.label] }
  fnode(enclose: g.members.map(label), lbl, corner-radius: th.corner-radius, stroke: s.stroke, fill: s.fill, inset: s.inset, snap: -1)
}

// ---- collision checker ---------------------------------------------------------
// Flag edges whose routed polyline passes straight through an unrelated block.
#let check-collisions(nodes, edges, posmap) = {
  let issues = ()
  for e in edges {
    if (e.from in posmap) and (e.to in posmap) {
      let pf = posmap.at(e.from)
      let pt = posmap.at(e.to)
      let route = _resolve-route(e, pf, pt)
      let goff = if e.gutter != auto { e.gutter } else { -0.5 }
      for seg in _edge-segments(pf, pt, route, goff) {
        let a = seg.at(0)
        let b = seg.at(1)
        for n in nodes {
          if (n.id != e.from) and (n.id != e.to) and (n.pos != none) {
            let nu = n.pos.at(0)
            let nv = n.pos.at(1)
            let hit = false
            if calc.abs(a.at(0) - b.at(0)) < 0.001 {
              if calc.abs(nu - a.at(0)) < 0.001 and calc.min(a.at(1), b.at(1)) < nv and nv < calc.max(a.at(1), b.at(1)) { hit = true }
            } else if calc.abs(a.at(1) - b.at(1)) < 0.001 {
              if calc.abs(nv - a.at(1)) < 0.001 and calc.min(a.at(0), b.at(0)) < nu and nu < calc.max(a.at(0), b.at(0)) { hit = true }
            }
            if hit { issues.push(repr(e.from) + " -> " + repr(e.to) + " crosses " + repr(n.id)) }
          }
        }
      }
    }
  }
  issues.dedup()
}

// ---- public render -------------------------------------------------------------
#let render(f, theme: garnet-theme, dir: "ttb", spacing: auto, check: "warn", ..diagram-args) = {
  let th = theme
  let nodes = f.nodes.enumerate().map(((i, n)) => {
    if n.pos == none { n.pos = (0, i) }
    n
  })
  if dir == "ltr" {
    nodes = nodes.map(n => { n.pos = (n.pos.at(1), n.pos.at(0)); n })
  }
  let posmap = (:)
  for n in nodes { posmap.insert(n.id, n.pos) }

  // layout validation
  let issues = if check != "off" { check-collisions(nodes, f.edges, posmap) } else { () }
  if check == "error" and issues.len() > 0 {
    panic("mlatlas: " + str(issues.len()) + " edge/block collision(s): " + issues.join("; "))
  }

  let elements = ()
  for n in nodes { elements.push(_emit-node(n, th)) }
  for e in f.edges { elements.push(_emit-edge(e, th, posmap)) }
  for g in f.groups { elements.push(_emit-group(g, th)) }

  let sp = if spacing != auto { spacing } else { th.spacing }
  let dia = diagram(spacing: sp, node-stroke: th.node-stroke, ..diagram-args.named(), ..elements)

  let fnt = th.at("font", default: auto)
  let themed = if fnt == auto or fnt == none { dia } else {
    set text(font: fnt, size: th.at("font-size", default: 9pt))
    dia
  }

  if check == "warn" and issues.len() > 0 {
    block[
      #themed
      #v(3pt)
      #block(inset: 4pt, stroke: 1pt + th.palette.pink-red, fill: th.palette.pink-red.lighten(82%))[
        #text(size: 7.5pt, fill: th.palette.pink-red)[*mlatlas warning* — #str(issues.len()) edge/block collision(s): #issues.join("; ")]
      ]
    ]
  } else { themed }
}

// Convenience for a standalone figure file: auto-sized white page, then render.
#let standalone(f, margin: 8mm, ..args) = {
  set page(width: auto, height: auto, margin: margin, fill: white)
  render(f, ..args)
}
