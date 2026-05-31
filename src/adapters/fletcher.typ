// mlatlas · adapters/fletcher.typ
// FIREWALL: the only file that imports fletcher. A breaking fletcher release is
// absorbed here. Exposes a small, stable internal drawing API.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, node, edge

#let shape-of(kind) = {
  if kind == "circle" { fletcher.shapes.circle }
  else if kind == "ellipse" { fletcher.shapes.ellipse }
  else if kind == "diamond" { fletcher.shapes.diamond }
  else if kind == "pill" or kind == "stadium" { fletcher.shapes.pill }
  else { fletcher.shapes.rect } // never fletcher's auto shape -> always a real rectangle
}

#let fl-node(pos, body, name: none, shape: auto, fill: none, stroke: 1pt + black, inset: 7pt, corner-radius: 0pt, width: auto, height: auto) = {
  let args = (name: label(name), corner-radius: corner-radius, fill: fill, stroke: stroke, inset: inset)
  if shape != auto { args.insert("shape", shape) }
  if width != auto { args.insert("width", width) }
  if height != auto { args.insert("height", height) }
  node(pos, body, ..args)
}

// borderless node — for slab cuboids (only the cetz body shows)
#let fl-borderless(pos, body, name: none) = node(pos, body, name: label(name), stroke: none, fill: none, inset: 1pt)

#let fl-straight(from, to, marks, stroke, lbl) = edge(label(from), label(to), marks: marks, stroke: stroke, label: lbl)

#let fl-corner(from, to, marks, stroke, lbl, ecr) = edge(label(from), label(to), marks: marks, corner: left, corner-radius: ecr, stroke: stroke, label: lbl)

// gutter route via node-relative waypoints (deterministic side, sharp corners)
#let fl-gutter(from, to, goff, axis, marks, stroke, lbl, ecr) = {
  let fl = label(from)
  let tl = label(to)
  if axis == "u" {
    edge(fl, (rel: (goff, 0), to: fl), (rel: (goff, 0), to: tl), tl, marks: marks, stroke: stroke, corner-radius: ecr, label: lbl)
  } else {
    edge(fl, (rel: (0, goff), to: fl), (rel: (0, goff), to: tl), tl, marks: marks, stroke: stroke, corner-radius: ecr, label: lbl)
  }
}

#let fl-enclose(members, lbl, stroke, fill, inset, corner-radius) = node(
  enclose: members.map(label),
  lbl,
  stroke: stroke,
  fill: fill,
  inset: inset,
  corner-radius: corner-radius,
  snap: -1,
)

#let fl-diagram(spacing, node-stroke, elements, mark-scale: 70%) = diagram(spacing: spacing, node-stroke: node-stroke, mark-scale: mark-scale, ..elements)
