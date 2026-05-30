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
  let dx = dp * 0.42
  let dy = dp * 0.42
  let light = lum(front) >= 0.5
  let top = if light { front.darken(10%) } else { front.lighten(16%) }
  let side = if light { front.darken(20%) } else { front.lighten(8%) }
  cetz.canvas(length: 1pt, {
    import cetz.draw: line, rect
    line((0, hp), (wp, hp), (wp + dx, hp + dy), (dx, hp + dy), close: true, fill: top, stroke: stroke)
    line((wp, 0), (wp, hp), (wp + dx, hp + dy), (wp + dx, dy), close: true, fill: side, stroke: stroke)
    rect((0, 0), (wp, hp), fill: front, stroke: stroke)
  })
}
