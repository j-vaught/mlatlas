// mlatlas · adapters/cetz.typ
// FIREWALL: the only file that imports cetz. Exposes the drawing helpers the library
// needs (currently the 3-D cuboid for feature-map slabs).

#import "@preview/cetz:0.5.2"
#import "../theme/contrast.typ": lum

#let _pt(x) = if type(x) == length { x.pt() } else { x }

// Oblique 3-D cuboid (feature-map prism). Front face = spatial extent, depth = channels.
// Face shading is LUMINANCE-ADAPTIVE so the three faces stay distinct on light fills
// (print/mono) AND dark fills (slides).
#let cuboid(w, h, depth, front, stroke) = {
  let wp = _pt(w)
  let hp = _pt(h)
  let dp = _pt(depth)
  // cabinet oblique: front face stays an upright rectangle; depth shears up-right ×0.38
  let dx = dp * 0.38
  let dy = dp * 0.38
  // directional lighting: top brightest, front mid, side darkest (top > front > side)
  let light = lum(front) >= 0.5
  let top = if light { front.lighten(13%).saturate(18%) } else { front.lighten(26%) }
  let side = if light { front.darken(15%) } else { front.lighten(7%) }
  cetz.canvas(length: 1pt, {
    import cetz.draw: line, rect
    line((0, hp), (wp, hp), (wp + dx, hp + dy), (dx, hp + dy), close: true, fill: top, stroke: stroke)
    line((wp, 0), (wp, hp), (wp + dx, hp + dy), (wp + dx, dy), close: true, fill: side, stroke: stroke)
    rect((0, 0), (wp, hp), fill: front, stroke: stroke)
  })
}
