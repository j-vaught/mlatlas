// mlatlas · render/collide.typ
// bbox-aware, scale-independent edge/block collision check. Treats each non-endpoint
// node as an axis-aligned box in grid units and tests it against each edge segment.

#import "../layout/layout.typ": resolve-route, gutter-axis, edge-segments
#import "../layout/bbox.typ": node-half

#let _seg-hits(a, b, n) = {
  let (hu, hv) = node-half(n)
  let nu = n.pos.at(0)
  let nv = n.pos.at(1)
  if calc.abs(a.at(0) - b.at(0)) < 1e-6 {
    // vertical segment at u = a.u
    ((calc.abs(a.at(0) - nu) < hu) and (calc.min(a.at(1), b.at(1)) < nv + hv) and (nv - hv < calc.max(a.at(1), b.at(1))))
  } else if calc.abs(a.at(1) - b.at(1)) < 1e-6 {
    // horizontal segment at v = a.v
    ((calc.abs(a.at(1) - nv) < hv) and (calc.min(a.at(0), b.at(0)) < nu + hu) and (nu - hu < calc.max(a.at(0), b.at(0))))
  } else { false }
}

#let check-collisions(nodes, edges, posmap) = {
  let issues = ()
  for e in edges {
    if (e.from in posmap) and (e.to in posmap) {
      let pf = posmap.at(e.from)
      let pt = posmap.at(e.to)
      let route = resolve-route(e, pf, pt)
      let goff = if e.gutter != auto { e.gutter } else { -0.5 }
      let axis = gutter-axis(pf, pt)
      for seg in edge-segments(pf, pt, route, goff, axis) {
        for n in nodes {
          if (n.id != e.from) and (n.id != e.to) and (n.pos != none) {
            if _seg-hits(seg.at(0), seg.at(1), n) {
              issues.push(repr(e.from) + " -> " + repr(e.to) + " crosses " + repr(n.id))
            }
          }
        }
      }
    }
  }
  issues.dedup()
}
