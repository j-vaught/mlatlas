// mlatlas · adapters/cetz.typ
// FIREWALL: the only file that imports cetz. Exposes the drawing helpers the library
// needs (currently the 3-D cuboid for feature-map slabs).

#import "@preview/cetz:0.5.2"
#import "../theme/contrast.typ": lum

#let _pt(x) = if type(x) == length { x.pt() } else { x }

// Oblique 3-D cuboid. Face shading is LUMINANCE-ADAPTIVE so the three faces stay
// distinct on light fills (print/mono) AND dark fills (slides).
#let cuboid(w, h, depth, front, stroke, label, lblfill) = {
  let wp = _pt(w)
  let hp = _pt(h)
  let dp = _pt(depth)
  let dx = dp * 0.5
  let dy = dp * 0.5
  let light = lum(front) >= 0.5
  let top = if light { front.darken(8%) } else { front.lighten(15%) }
  let side = if light { front.darken(18%) } else { front.lighten(7%) }
  cetz.canvas(length: 1pt, {
    import cetz.draw: line, rect, content
    line((0, hp), (wp, hp), (wp + dx, hp + dy), (dx, hp + dy), close: true, fill: top, stroke: stroke)
    line((wp, 0), (wp, hp), (wp + dx, hp + dy), (wp + dx, dy), close: true, fill: side, stroke: stroke)
    rect((0, 0), (wp, hp), fill: front, stroke: stroke)
    if label != none and label != [] {
      content((wp / 2, hp / 2), text(fill: lblfill, size: 7pt, label))
    }
  })
}
