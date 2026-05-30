// mlatlas · sugar/sugar.typ
// Composition over the IR. `seq` (sequential) and `graph` (explicit) plus the 2-D
// builders that make CUSTOM TOPOLOGIES trivial — `parallel` (side-by-side arms),
// `branch` (one -> many), `merge`/`concat` (many -> one). These cover dual-backbone,
// dual-head, two-stream / multi-modal fusion without any manual coordinate maths.

#import "../ir/ir.typ": *
#import "../prim/op.typ": op-node
#import "../prim/block.typ": block

// ---- sequential (flow axis = v) ----
#let seq(..children, gap: 0, connect: true, edge-kind: "data") = {
  let kids = children.pos()
  let nodes = ()
  let edges = ()
  let groups = ()
  let cursor = 0
  let prev-out = none
  let first-in = none
  for (i, child) in kids.enumerate() {
    let c = namespace(child, str(i))
    let e = extent(c.nodes)
    let h = e.vmax - e.vmin + 1
    let uc = (e.umin + e.umax) / 2
    let c2 = shift(c, -uc, cursor - e.vmin)
    nodes += c2.nodes
    edges += c2.edges
    groups += c2.groups
    let ci = frag-in(c2)
    let co = frag-out(c2)
    if first-in == none { first-in = ci }
    if connect and prev-out != none and ci != none and type(prev-out) != array and type(ci) != array {
      edges.push(ir-edge(prev-out, ci, kind: edge-kind))
    }
    prev-out = co
    cursor = cursor + h + gap
  }
  frag(nodes: nodes, edges: edges, groups: groups, meta: ("in": first-in, "out": prev-out))
}

// ---- parallel arms (cross axis = u), aligned at the top ----
#let parallel(..arms, gap: 1) = {
  let kids = arms.pos()
  let nodes = ()
  let edges = ()
  let groups = ()
  let ucursor = 0
  let ins = ()
  let outs = ()
  for (i, arm) in kids.enumerate() {
    let c = namespace(arm, "p" + str(i))
    let e = extent(c.nodes)
    let w = e.umax - e.umin + 1
    let c2 = shift(c, ucursor - e.umin, -e.vmin)
    nodes += c2.nodes
    edges += c2.edges
    groups += c2.groups
    ins.push(frag-in(c2))
    outs.push(frag-out(c2))
    ucursor = ucursor + w + gap
  }
  frag(nodes: nodes, edges: edges, groups: groups, meta: ("in": ins, "out": outs))
}

// ---- one trunk fanning out to many arms ----
#let branch(trunk, ..arms, gap: 1, edge-kind: "data") = {
  let t = namespace(trunk, "t")
  let te = extent(t.nodes)
  let par = parallel(..arms.pos(), gap: gap)
  let pe = extent(par.nodes)
  let tuc = (te.umin + te.umax) / 2
  let puc = (pe.umin + pe.umax) / 2
  let par2 = shift(par, tuc - puc, te.vmax + 1 - pe.vmin)
  let edges = t.edges + par2.edges
  let tout = frag-out(t)
  for ai in as-list(par2.meta.at("in")) {
    if ai != none { edges.push(ir-edge(tout, ai, kind: edge-kind)) }
  }
  frag(
    nodes: t.nodes + par2.nodes, edges: edges, groups: t.groups + par2.groups,
    meta: ("in": frag-in(t), "out": par2.meta.at("out")),
  )
}

// ---- many arms fanning in to a join node ----
#let merge(..arms, into: none, gap: 1, edge-kind: "data") = {
  let par = parallel(..arms.pos(), gap: gap)
  let pe = extent(par.nodes)
  let join = if into != none { into } else { op-node(sym: sym.plus.o) }
  let j = namespace(join, "j")
  let je = extent(j.nodes)
  let juc = (je.umin + je.umax) / 2
  let puc = (pe.umin + pe.umax) / 2
  let j2 = shift(j, puc - juc, pe.vmax + 1 - je.vmin)
  let edges = par.edges + j2.edges
  let jin = frag-in(j2)
  for ao in as-list(par.meta.at("out")) {
    if ao != none { edges.push(ir-edge(ao, jin, kind: edge-kind)) }
  }
  frag(
    nodes: par.nodes + j2.nodes, edges: edges, groups: par.groups + j2.groups,
    meta: ("in": par.meta.at("in"), "out": frag-out(j2)),
  )
}

#let concat(..arms, label: [concat], gap: 1) = merge(..arms.pos(), into: block(id: "cat", label: label, role: "op"), gap: gap)

// ---- residual: body + auto skip-to-⊕ ----
#let residual(body, gutter: auto, sym: sym.plus.o, label: none, edge-kind: "residual") = {
  let b = namespace(body, "f")
  let e = extent(b.nodes)
  let uc = (e.umin + e.umax) / 2
  let addn = ir-node("add", label: [#sym], kind: "circle", role: "add", pos: (uc, e.vmax + 1), width: 6mm, height: 6mm, inset: 1pt)
  let bi = frag-in(b)
  let bo = frag-out(b)
  let edges = b.edges
  edges.push(ir-edge(bo, "add", kind: "data"))
  edges.push(ir-edge(bi, "add", kind: edge-kind, route: "gutter", gutter: gutter, label: label))
  frag(nodes: b.nodes + (addn,), edges: edges, groups: b.groups, meta: ("in": bi, "out": "add"))
}

// ---- dashed plate (×N) around a body ----
#let plate(body, label: none, count: none) = {
  let b = namespace(body, "pl")
  let lbl = if count != none { [#label #h(3pt) $times #count$] } else { label }
  let g = ir-group("plate", b.nodes.map(n => n.id), label: lbl, kind: "plate")
  frag(nodes: b.nodes, edges: b.edges, groups: b.groups + (g,), meta: b.meta)
}

// ---- explicit graph ----
#let graph(nodes: (), edges: (), groups: ()) = {
  let nlist = ()
  for x in nodes {
    if is-frag(x) { nlist += x.nodes } else { nlist.push(x) }
  }
  let elist = edges.map(e => {
    if type(e) == dictionary and "from" in e { e } else if e.len() > 2 { ir-edge(e.at(0), e.at(1), ..e.at(2)) } else { ir-edge(e.at(0), e.at(1)) }
  })
  frag(nodes: nlist, edges: elist, groups: groups, meta: (:))
}
