// mlatlas · theme/contrast.typ
// Colour + dictionary utilities shared by the theme system and the renderer.
// The luminance-based `pick-text` is the safety net: any fill (a role default, a
// theme, or a user override) gets readable text automatically — so we never end up
// with dark-block/dark-text or light-block/light-text by accident.

// Relative luminance (sRGB, 0..1). Convert to rgb first: some colours are `luma`.
#let lum(c) = {
  let p = rgb(c).components(alpha: false).map(x => x / 100%)
  0.2126 * p.at(0) + 0.7152 * p.at(1) + 0.0722 * p.at(2)
}

// Pick a readable text colour for a given fill.
#let pick-text(fill, dark: rgb("#111111"), light: rgb("#FFFFFF"), thresh: 0.52) = {
  if fill == none { dark } else if lum(fill) >= thresh { dark } else { light }
}

// A light, print-safe fill derived from a saturated hue (mix toward white).
#let tint(hue, amount: 16%) = white.mix((hue, amount))

// Recursively merge dict `patch` onto `base` (patch wins on leaves).
#let deep-merge(base, patch) = {
  if type(base) != dictionary or type(patch) != dictionary {
    patch
  } else {
    let out = base
    for (k, v) in patch {
      if k in out and type(out.at(k)) == dictionary and type(v) == dictionary {
        out.insert(k, deep-merge(out.at(k), v))
      } else {
        out.insert(k, v)
      }
    }
    out
  }
}
