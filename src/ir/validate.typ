// mlatlas · ir/validate.typ
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
