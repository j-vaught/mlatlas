// mlatlas · render/render.typ
// Orchestrator: fragment -> styled fletcher diagram. Calls only the adapters (firewall)
// and layout/theme helpers. Resolution order per node: theme role -> render-time
// role-map -> explicit node fields -> n.style -> emphasis -> auto text via pick-text.
// Edges get the parallel chain (so per-edge style is honoured — fixing the old bug).

#import "../theme/themes.typ": mono, style-of, edge-style-of
#import "../theme/contrast.typ": pick-text, deep-merge
#import "../ir/ir.typ": *
#import "../ir/validate.typ": validate
#import "../adapters/fletcher.typ" as fl
#import "../adapters/cetz.typ": cuboid
#import "../layout/layout.typ": resolve-route, gutter-axis, assign-lanes
#import "collide.typ": check-collisions

#let _resolve-node-style(n, th, role-map) = {
  let role = if n.role in role-map { role-map.at(n.role) } else { n.role }
  let base = style-of(role, th)
  let s = (
    fill: if n.fill != auto { n.fill } else { base.at("fill", default: none) },
    stroke: if n.stroke != auto { n.stroke } else { base.at("stroke", default: th.node-stroke) },
    text-fill: if n.text-fill != auto { n.text-fill } else { base.at("text-fill", default: auto) },
    corner-radius: if n.corner-radius != auto { n.corner-radius } else { th.corner-radius },
    inset: if n.inset != auto { n.inset } else { th.node-inset },
  )
  s = deep-merge(s, n.style)
  if n.emphasis { s.stroke = th.roles.at("focal").stroke }
  if s.text-fill == auto { s.text-fill = pick-text(if s.fill == none { th.paper } else { s.fill }) }
  s
}

#let _emit-node(n, th, role-map) = {
  let s = _resolve-node-style(n, th, role-map)
  if n.kind == "slab" {
    let front = if s.fill == none { th.palette.b10 } else { s.fill }
    let strk = if n.stroke != auto { n.stroke } else { 0.8pt + th.ink } // thin neutral border on prisms
    let cub = cuboid(n.data.at("w", default: 26pt), n.data.at("h", default: 26pt), n.data.at("depth", default: 14pt), front, strk)
    let cap = n.data.at("caption", default: none)
    let body = if cap != none {
      stack(dir: ttb, spacing: 3pt, align(center, cub), align(center, text(size: 7pt, fill: th.ink)[#cap]))
    } else { align(center, cub) }
    fl.fl-borderless(n.pos, body, name: n.id)
  } else {
    let lbl = if n.label == none { [] } else {
      let t = text(fill: s.text-fill)[#n.label]
      if n.text-size != auto { t = text(size: n.text-size)[#t] }
      if n.font != auto { t = text(font: n.font)[#t] }
      t
    }
    // uniform default width for rectangles -> tidy columns; circles/others stay auto
    let w = if n.width != auto { n.width } else if n.kind == "rect" { th.at("node-width", default: auto) } else { auto }
    fl.fl-node(
      n.pos, lbl, name: n.id, shape: fl.shape-of(n.kind),
      fill: s.fill, stroke: s.stroke, inset: s.inset, corner-radius: s.corner-radius,
      width: w, height: n.height,
    )
  }
}

#let _stroke-with-dash(stroke, dash) = {
  if dash == none or dash == auto { stroke } else { (paint: stroke.paint, thickness: stroke.thickness, dash: dash) }
}

#let _emit-edge(e, th, posmap, lane) = {
  let es = edge-style-of(e.kind, th)
  let st = deep-merge(
    (stroke: es.at("stroke", default: 0.9pt + th.ink), dash: es.at("dash", default: none), marks: auto, label: e.label),
    e.style,
  )
  let stroke = if e.stroke != auto { e.stroke } else { st.stroke }
  let dash = if e.dash != auto { e.dash } else { st.dash }
  let strk = _stroke-with-dash(stroke, dash)
  let marks = if e.marks != auto { e.marks } else if st.marks != auto { st.marks } else { (none, th.mark) }
  let ecr = th.at("edge-corner-radius", default: 0pt)
  let lblc = if st.label == none { none } else { text(size: th.label-size, fill: th.palette.b70)[#st.label] }

  let pf = posmap.at(e.from)
  let pt = posmap.at(e.to)
  let route = resolve-route(e, pf, pt)
  if route == "gutter" {
    let base = if e.gutter != auto { e.gutter } else { -(th.at("gutter", default: 0.5)) }
    let goff = base * (lane + 1)
    fl.fl-gutter(e.from, e.to, goff, gutter-axis(pf, pt), marks, strk, lblc, ecr)
  } else if route == "corner" {
    fl.fl-corner(e.from, e.to, marks, strk, lblc, ecr)
  } else {
    fl.fl-straight(e.from, e.to, marks, strk, lblc)
  }
}

// Returns an array: the enclosure box + (optionally) a label node placed just OUTSIDE
// the top-right of the plate (so it never overlaps the data path).
#let _emit-group(g, th, posmap) = {
  let cs = style-of("container", th)
  let box = fl.fl-enclose(g.members, none, cs.at("stroke", default: 0.8pt + th.palette.b70), cs.at("fill", default: none), 8pt, th.corner-radius)
  if g.label == none {
    (box,)
  } else {
    let ms = g.members.map(m => posmap.at(m, default: none)).filter(p => p != none)
    if ms.len() == 0 {
      (box,)
    } else {
      let umax = calc.max(..ms.map(p => p.at(0)))
      let vmin = calc.min(..ms.map(p => p.at(1)))
      let lbl = fl.fl-borderless((umax + 0.6, vmin - 0.4), text(size: th.label-size, fill: cs.at("text-fill", default: th.palette.b70))[#g.label], name: g.id + "/__lbl")
      (box, lbl)
    }
  }
}

#let render(f, theme: mono, dir: "ttb", spacing: auto, check: "warn", role-map: (:), ..diagram-args) = {
  let th = theme
  let v = validate(f)
  if v.errors.len() > 0 { panic("mlatlas: " + v.errors.join("; ")) }

  let nodes = f.nodes.enumerate().map(((i, n)) => {
    if n.pos == none { n.pos = (0, i) }
    n
  })
  if dir == "ltr" { nodes = nodes.map(n => { n.pos = (n.pos.at(1), n.pos.at(0)); n }) }
  let posmap = (:)
  for n in nodes { posmap.insert(n.id, n.pos) }

  let issues = if check != "off" { check-collisions(nodes, f.edges, posmap) } else { () }
  if check == "error" and issues.len() > 0 {
    panic("mlatlas: " + str(issues.len()) + " edge/block collision(s): " + issues.join("; "))
  }

  let lanes = assign-lanes(f.edges, posmap)
  let elements = ()
  for n in nodes { elements.push(_emit-node(n, th, role-map)) }
  for (i, e) in f.edges.enumerate() { elements.push(_emit-edge(e, th, posmap, lanes.at(str(i), default: 0))) }
  for g in f.groups { elements += _emit-group(g, th, posmap) }

  let sp = if spacing != auto { spacing } else { th.spacing }
  let dia = fl.fl-diagram(sp, th.node-stroke, elements, mark-scale: th.at("mark-scale", default: 70%))
  let themed = {
    set text(font: th.at("font", default: "New Computer Modern"), size: th.at("font-size", default: 9pt), fill: pick-text(th.paper))
    dia
  }

  if check == "warn" and issues.len() > 0 {
    block[
      #themed
      #v(3pt)
      #block(inset: 4pt, stroke: 1pt + th.palette.garnet, fill: th.palette.beige)[
        #text(size: 7.5pt, fill: th.palette.garnet)[*mlatlas warning* — #str(issues.len()) edge/block collision(s): #issues.join("; ")]
      ]
    ]
  } else { themed }
}

// Standalone figure: auto-sized page tinted to the theme paper, then render.
#let standalone(f, theme: mono, margin: 8mm, ..args) = {
  set page(width: auto, height: auto, margin: margin, fill: theme.paper)
  render(f, theme: theme, ..args.named())
}
