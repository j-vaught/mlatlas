// mlatlas · layout/bbox.typ
// Node footprint in GRID units (scale-independent). Used by the collision checker so it
// reasons about real block extents, not points.

#let node-half(n) = {
  // default half-extents ~0.46 cell each; could later scale by explicit width/height
  (0.46, 0.46)
}
