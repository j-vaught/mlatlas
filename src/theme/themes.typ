// mlatlas · theme/themes.typ
// TIER 3 — the shipped themes + the `theme()` / `palette-theme()` constructors and the
// `style-of` / `edge-style-of` lookups. Default is `mono` (the user's restrained brand).
// Switch with one setting: `render(ir, theme: colorful)`.

#import "tokens.typ": neutral, okabe, colorful-hues
#import "contrast.typ": deep-merge
#import "roles.typ": (
  mono-roles, colorful-roles, colorblind-roles, grayscale-roles, paper-roles, color-roles,
  mono-edges, color-edges,
)

#let base-geometry = (
  corner-radius: 0pt,
  edge-corner-radius: 0pt,
  node-inset: 7pt,
  node-width: 26mm, // uniform block width -> tidy columns (overridable per node)
  spacing: (11mm, 6mm),
  mark: "stealth", // the ONLY arrowhead style
  mark-scale: 85%, // crisp arrowheads sized to stroke (not faint nubs)
  font: "New Computer Modern",
  font-size: 9pt,
  label-size: 7.5pt,
  gutter: 0.72, // skip-lane offset (grid units) — clear of the wide blocks
)

#let _theme(name, paper, ink, roles, edges) = base-geometry + (
  name: name,
  palette: neutral,
  paper: paper,
  ink: ink,
  node-stroke: 1pt + ink,
  roles: roles,
  edges: edges,
)

#let mono = _theme("mono", neutral.paper, neutral.ink, mono-roles, mono-edges)
#let colorful = _theme("colorful", neutral.paper, neutral.ink, colorful-roles, color-edges)
#let colorblind = _theme("colorblind", neutral.paper, neutral.ink, colorblind-roles, color-edges)
#let grayscale = _theme("grayscale", neutral.paper, neutral.ink, grayscale-roles, mono-edges)
#let bw = grayscale
// Canonical ML-paper pastels (the recognizable Transformer-paper look).
#let paper = {
  let t = _theme("paper", neutral.paper, rgb("#1A1A1A"), paper-roles, color-edges)
  t.node-stroke = 1.1pt + rgb("#5A5A5A")
  t
}

// Slides: opt-in dark theme (saturated fills, dark paper, light text via pick-text).
#let _slides-aux = (
  control: (fill: rgb("#2A2E35"), stroke: (paint: rgb("#8A93A0"), thickness: 1pt, dash: "dashed"), text-fill: rgb("#E8E8E8")),
  container: (fill: none, stroke: (paint: rgb("#8A93A0"), thickness: 0.8pt, dash: "dashed"), text-fill: rgb("#C8C8C8")),
  focal: (fill: rgb("#1B1E24"), stroke: 2.5pt + rgb("#E0A0A6"), text-fill: white),
)
#let slides = {
  let t = _theme("slides", rgb("#15181C"), rgb("#F2F2F2"), color-roles(colorful-hues, kind: "solid", aux: _slides-aux), color-edges)
  t.node-stroke = 1pt + rgb("#C8C8C8")
  t
}

// Custom theme: deep-merge overrides onto a base (default mono).
//   #let t = theme(spacing: (18mm, 12mm), roles: (norm: (stroke: 2pt + blue)))
#let theme(base: mono, ..overrides) = deep-merge(base, overrides.named())

// One-call custom colour scheme from a role->hue map (auto light fill + border + text).
//   #let t = palette-theme((data: rgb("#114B5F"), op: rgb("#9A2617"), norm: rgb("#1B998B")))
#let palette-theme(hues, base: mono, ..overrides) = {
  deep-merge(deep-merge(base, (name: "custom", roles: color-roles(hues))), overrides.named())
}

#let style-of(role, th) = {
  if role in th.roles {
    th.roles.at(role)
  } else {
    th.roles.at("op", default: (fill: th.palette.white, stroke: th.node-stroke, text-fill: auto))
  }
}
#let edge-style-of(kind, th) = {
  if kind in th.edges { th.edges.at(kind) } else { th.edges.at("data") }
}
