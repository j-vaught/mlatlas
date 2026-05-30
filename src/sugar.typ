// mlatlas · sugar.typ
// The two composition sugars over the IR — `seq` (sequential, the ~70% case) and
// `graph` (explicit nodes/edges) — plus `residual`, which makes skip connections
// first-class so an author never hand-routes a bypass.

#import "ir.typ": *
#import "primitives.typ": op-node

// Stack child fragments along the flow axis (top-to-bottom in canonical space),
// auto-connecting each child's `out` port to the next child's `in` port.
#let seq(..children, gap: 0, connect: true, edge-kind: "data") = {
  let kids = children.pos()
  let nodes = ()
  let edges = ()
  let groups = ()
  let cursor = 0
  let prev-out = none
  let first-in = none
  let i = 0
  for child in kids {
    let c = namespace(child, str(i))
    let ext = extent(c.nodes)
    let h = ext.vmax - ext.vmin + 1
    let c2 = shift(c, 0, cursor - ext.vmin)
    nodes += c2.nodes
    edges += c2.edges
    groups += c2.groups
    let cur-in = frag-in(c2)
    let cur-out = frag-out(c2)
    if first-in == none { first-in = cur-in }
    if connect and prev-out != none and cur-in != none {
      edges.push(ir-edge(prev-out, cur-in, kind: edge-kind))
    }
    prev-out = cur-out
    cursor = cursor + h + gap
    i += 1
  }
  frag(nodes: nodes, edges: edges, groups: groups, meta: ("in": first-in, "out": prev-out, w: 1, h: cursor))
}

// Explicit graph form. `nodes` is an array of fragments or ir-nodes; `edges` is an
// array of `(from, to)` / `(from, to, opts)` tuples or ir-edges.
#let graph(nodes: (), edges: (), groups: ()) = {
  let nlist = ()
  for x in nodes {
    if is-frag(x) { nlist += x.nodes } else { nlist.push(x) }
  }
  let elist = edges.map(e => {
    if type(e) == dictionary and "from" in e { e }
    else if e.len() > 2 { ir-edge(e.at(0), e.at(1), ..e.at(2)) }
    else { ir-edge(e.at(0), e.at(1)) }
  })
  frag(nodes: nlist, edges: elist, groups: groups, meta: (:))
}

// Wrap a fragment in a residual connection: add an ⊕ node after it and a skip edge
// from the block input to the ⊕. The skip routes through a gutter lane automatically.
#let residual(body, gutter: auto, sym: sym.plus.o, label: none, edge-kind: "residual") = {
  let b = namespace(body, "f")
  let ext = extent(b.nodes)
  let h = ext.vmax - ext.vmin + 1
  let add = op-node(id: "add", sym: sym)
  let add2 = shift(add, 0, ext.vmax + 1)
  let b-in = frag-in(b)
  let b-out = frag-out(b)
  let edges = b.edges
  edges.push(ir-edge(b-out, "add", kind: "data"))
  edges.push(ir-edge(b-in, "add", kind: edge-kind, route: "gutter", gutter: gutter, label: label))
  frag(
    nodes: b.nodes + add2.nodes,
    edges: edges,
    groups: b.groups,
    meta: ("in": b-in, "out": "add", w: 1, h: h + 1),
  )
}

// Group a fragment's nodes inside a labelled plate (dashed enclosure with a "xN" tag).
#let plate(body, label: none, count: none) = {
  let b = namespace(body, "p")
  let lbl = if count != none { [#label #h(3pt) $times #count$] } else { label }
  let g = ir-group("plate", b.nodes.map(n => n.id), label: lbl, kind: "plate")
  frag(nodes: b.nodes, edges: b.edges, groups: b.groups + (g,), meta: b.meta)
}
