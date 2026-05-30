// mlatlas · layout/layout.typ
// Route resolution + the gutter lane allocator. Routing is sharp/orthogonal by default:
// straight where aligned, right-angle gutter lanes for skips, L-corners otherwise.

#let resolve-route(e, pf, pt) = {
  if e.route != "auto" { e.route }
  else if e.kind in ("skip", "residual") { "gutter" }
  else if pf.at(0) == pt.at(0) and calc.abs(pf.at(1) - pt.at(1)) <= 1 { "straight" }
  else if pf.at(1) == pt.at(1) and calc.abs(pf.at(0) - pt.at(0)) <= 1 { "straight" }
  else if pf.at(0) == pt.at(0) or pf.at(1) == pt.at(1) { "gutter" }
  else { "corner" }
}

// Gutter runs perpendicular to the collinear axis: vertical pair -> sideways (u); else (v).
#let gutter-axis(pf, pt) = if pf.at(0) == pt.at(0) { "u" } else { "v" }

// Grid-coord segments an edge will draw (for the collision checker).
#let edge-segments(pf, pt, route, goff, axis) = {
  if route == "corner" {
    let c = (pf.at(0), pt.at(1))
    ((pf, c), (c, pt))
  } else if route == "gutter" {
    if axis == "u" {
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

// Greedy interval-graph colouring: overlapping skip spans on the same lane axis get
// distinct lanes, so dense/U-Net skips fan out instead of overlapping. Returns
// edge-index(str) -> lane(int).
#let assign-lanes(edges, posmap) = {
  let items = ()
  for (i, e) in edges.enumerate() {
    if (e.from in posmap) and (e.to in posmap) {
      let pf = posmap.at(e.from)
      let pt = posmap.at(e.to)
      if resolve-route(e, pf, pt) == "gutter" {
        if pf.at(0) == pt.at(0) {
          items.push((i: i, key: "u" + repr(pf.at(0)), lo: calc.min(pf.at(1), pt.at(1)), hi: calc.max(pf.at(1), pt.at(1))))
        } else if pf.at(1) == pt.at(1) {
          items.push((i: i, key: "v" + repr(pf.at(1)), lo: calc.min(pf.at(0), pt.at(0)), hi: calc.max(pf.at(0), pt.at(0))))
        }
      }
    }
  }
  let sorted = items.sorted(key: it => it.lo)
  let lanes = (:)
  let active = ()
  for it in sorted {
    let used = active.filter(a => a.key == it.key and a.hi > it.lo).map(a => a.lane)
    let lane = 0
    while lane in used { lane = lane + 1 }
    lanes.insert(str(it.i), lane)
    active.push((key: it.key, hi: it.hi, lane: lane))
  }
  lanes
}
