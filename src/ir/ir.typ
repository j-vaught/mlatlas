// mlatlas · ir/ir.typ
// The Semantic IR — the contract. Everything is built from these plain dicts. A
// *fragment* is `(nodes, edges, groups, meta)`; `meta.in`/`meta.out` are entry/exit
// ports (a single id, or a LIST of ids for multi-stream fragments from parallel/branch).
// Positions are elastic grid units (u = cross/lane axis, v = flow/depth axis).

#let ir-node(
  id,
  label: none,
  kind: "rect", // rect | circle | ellipse | diamond | pill | slab
  role: "op", // semantic role -> theme style
  emphasis: false, // sparse garnet focal accent
  pos: none, // (u, v)
  fill: auto,
  stroke: auto,
  text-fill: auto,
  corner-radius: auto,
  width: auto,
  height: auto,
  inset: auto,
  font: auto,
  text-size: auto,
  ports: ("in", "out"),
  style: (:), // per-node style patch (highest precedence)
  data: (:), // primitive payload (e.g. slab geometry)
) = (
  id: id,
  label: label,
  kind: kind,
  role: role,
  emphasis: emphasis,
  pos: pos,
  fill: fill,
  stroke: stroke,
  text-fill: text-fill,
  corner-radius: corner-radius,
  width: width,
  height: height,
  inset: inset,
  font: font,
  text-size: text-size,
  ports: ports,
  style: style,
  data: data,
)

#let ir-edge(
  from,
  to,
  kind: "data", // data | skip | residual | grad | control | attention | sample
  marks: auto,
  label: none,
  stroke: auto,
  dash: auto,
  route: "auto", // auto | straight | corner | gutter
  gutter: auto,
  from-port: auto,
  to-port: auto,
  style: (:), // per-edge style patch (now honoured by the renderer)
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
  from-port: from-port,
  to-port: to-port,
  style: style,
)

#let ir-group(id, members, label: none, kind: "plate", style: (:)) = (
  id: id,
  members: members,
  label: label,
  kind: kind,
  style: style,
)

#let frag(nodes: (), edges: (), groups: (), meta: (:)) = (
  nodes: nodes,
  edges: edges,
  groups: groups,
  meta: meta,
)

#let is-frag(x) = type(x) == dictionary and "nodes" in x and "edges" in x

// ---- helpers -------------------------------------------------------------------
#let extent(nodes) = {
  let ps = nodes.map(n => n.pos).filter(p => p != none)
  let us = ps.map(p => p.at(0))
  let vs = ps.map(p => p.at(1))
  (
    umin: if us.len() > 0 { calc.min(..us) } else { 0 },
    umax: if us.len() > 0 { calc.max(..us) } else { 0 },
    vmin: if vs.len() > 0 { calc.min(..vs) } else { 0 },
    vmax: if vs.len() > 0 { calc.max(..vs) } else { 0 },
  )
}

#let frag-w(f) = { let e = extent(f.nodes); e.umax - e.umin + 1 }
#let frag-h(f) = { let e = extent(f.nodes); e.vmax - e.vmin + 1 }

#let shift(f, du, dv) = {
  let nodes = f.nodes.map(n => {
    if n.pos != none { n.pos = (n.pos.at(0) + du, n.pos.at(1) + dv) }
    n
  })
  (..f, nodes: nodes)
}

#let namespace(f, ns) = {
  let pre(id) = ns + "/" + id
  let prelist(x) = if type(x) == array { x.map(pre) } else { pre(x) }
  let nodes = f.nodes.map(n => { n.id = pre(n.id); n })
  let edges = f.edges.map(e => { e.from = pre(e.from); e.to = pre(e.to); e })
  let groups = f.groups.map(g => {
    g.members = g.members.map(pre)
    g.id = pre(g.id)
    g
  })
  let meta = f.meta
  if "in" in meta { meta.in = prelist(meta.in) }
  if "out" in meta { meta.out = prelist(meta.out) }
  frag(nodes: nodes, edges: edges, groups: groups, meta: meta)
}

// first/last node id fallback when meta is absent
#let frag-in(f) = f.meta.at("in", default: if f.nodes.len() > 0 { f.nodes.first().id } else { none })
#let frag-out(f) = f.meta.at("out", default: if f.nodes.len() > 0 { f.nodes.last().id } else { none })

// normalize a port (id or list) to a list
#let as-list(x) = if type(x) == array { x } else if x == none { () } else { (x,) }

// Structural checks run by the renderer (gated by `check`): duplicate ids and dangling
// edges are errors; unknown roles fall back gracefully so they are not fatal.
#let validate(f) = {
  let errors = ()
  let seen = (:)
  for n in f.nodes {
    if n.id in seen { errors.push("duplicate node id: " + repr(n.id)) } else { seen.insert(n.id, true) }
  }
  for e in f.edges {
    if not (e.from in seen) { errors.push("edge references missing node (from): " + repr(e.from)) }
    if not (e.to in seen) { errors.push("edge references missing node (to): " + repr(e.to)) }
  }
  (errors: errors.dedup(), warnings: ())
}
