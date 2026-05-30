// mlatlas · theme.typ
// Brand palette, role -> style mapping, the default garnet theme, and a custom-theme
// constructor. Brand rules are encoded ONCE here and inherited by every figure:
// rectangular nodes (corner-radius: 0pt), garnet accent, high contrast, sharp
// orthogonal edges. An author overrides by passing a patched theme — never by
// editing a preset.

#let brand = (
  garnet: rgb("#73000A"),
  black: rgb("#000000"),
  white: rgb("#FFFFFF"),
  beige: rgb("#FFF2E3"),
  b90: rgb("#363636"), b70: rgb("#5C5C5C"), b50: rgb("#A2A2A2"),
  b30: rgb("#C7C7C7"), b10: rgb("#ECECEC"),
  blue: rgb("#466A9F"), dark-blue: rgb("#1F414D"),
  pink-red: rgb("#CC2E40"), dark-green: rgb("#65780B"),
  lime: rgb("#CED318"), brown: rgb("#A49137"),
)

// Recursively merge dictionary `patch` onto `base` (patch wins on leaves).
#let deep-merge(base, patch) = {
  if type(base) != dictionary or type(patch) != dictionary { return patch }
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

// The default, brand-compliant theme.
#let garnet-theme = (
  palette: brand,
  // global geometry / hard brand rules
  corner-radius: 0pt, // nodes are NEVER rounded unless explicitly overridden
  edge-corner-radius: 0pt, // edge bends are NEVER rounded — sharp orthogonal only
  node-inset: 7pt,
  node-stroke: 1pt + brand.black,
  spacing: (13mm, 10mm),
  mark: "stealth", // the ONLY arrowhead style used anywhere
  font: "New Computer Modern", // formal default; swap to a mono for a "code" look
  font-size: 9pt,
  label-size: 7pt,
  // role -> node style. The author sets `role:`; the theme decides the look.
  roles: (
    op: (fill: brand.b10, stroke: 1pt + brand.black, text-fill: brand.black),
    param: (fill: brand.garnet, stroke: 1pt + brand.black, text-fill: brand.white),
    data: (fill: brand.beige, stroke: 1pt + brand.black, text-fill: brand.black),
    loss: (fill: brand.pink-red, stroke: 1pt + brand.black, text-fill: brand.white),
    io: (fill: brand.white, stroke: 1pt + brand.black, text-fill: brand.black),
    ctrl: (fill: brand.white, stroke: (paint: brand.b50, thickness: 1pt, dash: "dashed"), text-fill: brand.b70),
    add: (fill: brand.white, stroke: 1pt + brand.black, text-fill: brand.black),
    norm: (fill: brand.b30, stroke: 1pt + brand.black, text-fill: brand.black),
    attn: (fill: brand.blue, stroke: 1pt + brand.black, text-fill: brand.white),
  ),
  // edge kind -> style
  edges: (
    data: (stroke: 0.9pt + brand.black, dash: none),
    skip: (stroke: 1pt + brand.blue, dash: none),
    residual: (stroke: 1pt + brand.blue, dash: none),
    grad: (stroke: 0.9pt + brand.pink-red, dash: "dashed"),
    control: (stroke: 0.9pt + brand.b50, dash: "dashed"),
    attention: (stroke: 0.7pt + brand.b50, dash: none),
    sample: (stroke: 0.9pt + brand.dark-green, dash: "dashed"),
  ),
)

// Build a custom theme by deep-merging overrides onto the default.
//   #let mine = theme(spacing: (20mm, 12mm), roles: (op: (fill: rgb("#eee"))))
#let theme(..overrides) = deep-merge(garnet-theme, overrides.named())

// The two sanctioned font styles: formal (New Computer Modern, the default) and a
// "code"/computery monospace. Use `code-theme` or `theme(font: "...")` to switch.
#let code-theme = deep-merge(garnet-theme, (font: "DejaVu Sans Mono", font-size: 8.5pt, label-size: 7pt))

#let style-of(role, th) = {
  if role in th.roles { th.roles.at(role) } else { th.roles.op }
}
#let edge-style-of(kind, th) = {
  if kind in th.edges { th.edges.at(kind) } else { th.edges.data }
}
