// mlatlas · ir.typ
// The Semantic IR — the L3 contract. Everything in the library is built from these
// plain dictionaries. A *fragment* is `(nodes, edges, groups, meta)`; presets and
// sugars all produce and consume fragments, so they splice together freely.
//
// Positions are in elastic grid units (u, v). The renderer (and fletcher) turn those
// into metric coordinates; the library never computes absolute lengths for layout.

// ---- node ----------------------------------------------------------------------
// `auto` fields fall back to the theme at render time; explicit values override it.
#let ir-node(
  id,
  label: none,
  kind: "rect", // geometry: rect | circle | ellipse | diamond | pill
  role: "op", // semantics -> drives styling via the theme
  pos: none, // (u, v) grid coords; filled by a primitive or the renderer
  fill: auto,
  stroke: auto,
  text-fill: auto,
  corner-radius: auto,
  width: auto,
  height: auto,
  inset: auto,
  ports: ("in", "out"),
  style: (:), // arbitrary per-node style patch, merged last
  data: (:), // primitive-specific payload (e.g. slab geometry)
) = (
  id: id,
  label: label,
  kind: kind,
  role: role,
  pos: pos,
  fill: fill,
  stroke: stroke,
  text-fill: text-fill,
  corner-radius: corner-radius,
  width: width,
  height: height,
  inset: inset,
  ports: ports,
  style: style,
  data: data,
)

// ---- edge ----------------------------------------------------------------------
#let ir-edge(
  from,
  to,
  kind: "data", // data | skip | residual | grad | control | attention | sample
  marks: auto, // fletcher marks string, e.g. "->"; auto -> theme arrow
  label: none,
  stroke: auto,
  dash: auto,
  route: "auto", // auto | straight | corner | gutter
  gutter: auto, // perpendicular lane offset (grid units, signed)
  style: (:),
) = (
  from: from,
  to: to,
  kind: kind,
  marks: marks,
  label: label,
  stroke: stroke,
  dash: dash,
  route: route,
  gutter: gutter,
  style: style,
)

// ---- group (plate / enclosure) -------------------------------------------------
#let ir-group(id, members, label: none, kind: "plate", style: (:)) = (
  id: id,
  members: members, // array of node ids
  label: label,
  kind: kind,
  style: style,
)

// ---- fragment ------------------------------------------------------------------
// meta carries `in`/`out` node ids (entry/exit ports) plus extent `w`/`h`.
#let frag(nodes: (), edges: (), groups: (), meta: (:)) = (
  nodes: nodes,
  edges: edges,
  groups: groups,
  meta: meta,
)

#let is-frag(x) = type(x) == dictionary and "nodes" in x and "edges" in x

// ---- helpers -------------------------------------------------------------------
#let extent(nodes) = {
  let us = nodes.map(n => n.pos).filter(p => p != none).map(p => p.at(0))
  let vs = nodes.map(n => n.pos).filter(p => p != none).map(p => p.at(1))
  (
    umin: if us.len() > 0 { calc.min(..us) } else { 0 },
    umax: if us.len() > 0 { calc.max(..us) } else { 0 },
    vmin: if vs.len() > 0 { calc.min(..vs) } else { 0 },
    vmax: if vs.len() > 0 { calc.max(..vs) } else { 0 },
  )
}

// Shift every node position by (du, dv).
#let shift(f, du, dv) = {
  let nodes = f.nodes.map(n => {
    if n.pos != none { n.pos = (n.pos.at(0) + du, n.pos.at(1) + dv) }
    n
  })
  (..f, nodes: nodes)
}

// Prefix every id in `f` with `ns/` so nested presets never collide.
#let namespace(f, ns) = {
  let pre(id) = ns + "/" + id
  let nodes = f.nodes.map(n => { n.id = pre(n.id); n })
  let edges = f.edges.map(e => { e.from = pre(e.from); e.to = pre(e.to); e })
  let groups = f.groups.map(g => {
    g.members = g.members.map(pre)
    g.id = pre(g.id)
    g
  })
  let meta = f.meta
  if "in" in meta { meta.in = pre(meta.in) }
  if "out" in meta { meta.out = pre(meta.out) }
  frag(nodes: nodes, edges: edges, groups: groups, meta: meta)
}

#let frag-in(f) = f.meta.at("in", default: if f.nodes.len() > 0 { f.nodes.first().id } else { none })
#let frag-out(f) = f.meta.at("out", default: if f.nodes.len() > 0 { f.nodes.last().id } else { none })
