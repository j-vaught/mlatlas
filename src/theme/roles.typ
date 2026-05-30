// mlatlas · theme/roles.typ
// TIER 2 — semantic role -> style tables. A style is
//   (fill: colour|none, stroke: stroke, text-fill: colour|auto)
// where `text-fill: auto` defers to luminance-based `pick-text` at render time.
//
// `color-roles(hues)` derives a full print-safe table (light tint fill + 2pt coloured
// border + auto text) from a role->hue map, so a USER can define a whole scheme by
// supplying hues only. `mono-roles` / `grayscale-roles` are hand-authored.

#import "tokens.typ": neutral, okabe, colorful-hues, colorblind-hues
#import "contrast.typ": tint

// Auxiliary roles shared by the colour themes (light background).
#let _aux-light = (
  control: (fill: neutral.white, stroke: (paint: neutral.b50, thickness: 1pt, dash: "dashed"), text-fill: neutral.b70),
  container: (fill: none, stroke: (paint: neutral.b70, thickness: 0.8pt, dash: "dashed"), text-fill: neutral.b70),
  focal: (fill: neutral.white, stroke: 2.5pt + neutral.garnet, text-fill: neutral.ink),
)

// Build a full role table from a role->hue map.
//   kind: "tint" (light fill + coloured border) | "solid" (saturated fill, for dark/slides)
#let color-roles(hues, kind: "tint", weight: 2pt, amount: 16%, aux: _aux-light) = {
  let out = (:)
  for (role, hue) in hues {
    let fill = if kind == "solid" { hue } else { tint(hue, amount: amount) }
    out.insert(role, (fill: fill, stroke: weight + hue, text-fill: auto))
  }
  for (k, v) in aux { out.insert(k, v) }
  out
}

#let colorful-roles = color-roles(colorful-hues)
#let colorblind-roles = color-roles(colorblind-hues, weight: 2.2pt)

// Monochrome (DEFAULT): light fills (white/grey/beige), dark text, ink borders;
// category by value + border weight/dash; garnet reserved for the "interesting"
// roles (attention/param/loss/focal) and skip edges — the restrained brand identity.
#let mono-roles = (
  input: (fill: neutral.beige, stroke: 1.2pt + neutral.ink, text-fill: neutral.ink),
  data: (fill: neutral.beige, stroke: 1.2pt + neutral.ink, text-fill: neutral.ink),
  io: (fill: neutral.white, stroke: 1.4pt + neutral.ink, text-fill: neutral.ink),
  op: (fill: neutral.white, stroke: 1.1pt + neutral.ink, text-fill: neutral.ink),
  compute: (fill: neutral.white, stroke: 1.1pt + neutral.ink, text-fill: neutral.ink),
  norm: (fill: neutral.b10, stroke: 0.9pt + neutral.ink, text-fill: neutral.ink),
  activation: (fill: neutral.white, stroke: (paint: neutral.ink, thickness: 0.9pt, dash: "densely-dashed"), text-fill: neutral.ink),
  attention: (fill: neutral.white, stroke: 1.6pt + neutral.garnet, text-fill: neutral.ink),
  param: (fill: neutral.b10, stroke: 1.6pt + neutral.garnet, text-fill: neutral.ink),
  loss: (fill: neutral.white, stroke: 1.6pt + neutral.garnet, text-fill: neutral.ink),
  control: (fill: neutral.white, stroke: (paint: neutral.b50, thickness: 1pt, dash: "dashed"), text-fill: neutral.b70),
  memory: (fill: neutral.beige, stroke: 1pt + neutral.ink, text-fill: neutral.ink),
  output: (fill: neutral.b10, stroke: 1.6pt + neutral.ink, text-fill: neutral.ink),
  add: (fill: neutral.white, stroke: 1.1pt + neutral.ink, text-fill: neutral.ink),
  focal: (fill: neutral.white, stroke: 2.5pt + neutral.garnet, text-fill: neutral.ink),
  container: (fill: none, stroke: (paint: neutral.b70, thickness: 0.8pt, dash: "dashed"), text-fill: neutral.b70),
)

// Pure grayscale / B&W: value steps + dash differentiation (hatch is a later refinement);
// dark fills get auto (white) text via pick-text.
#let grayscale-roles = (
  input: (fill: rgb("#FFFFFF"), stroke: 1.5pt + black, text-fill: black),
  data: (fill: rgb("#FFFFFF"), stroke: 1.5pt + black, text-fill: black),
  io: (fill: rgb("#FFFFFF"), stroke: 1.6pt + black, text-fill: black),
  op: (fill: rgb("#FFFFFF"), stroke: 1pt + black, text-fill: black),
  compute: (fill: rgb("#FFFFFF"), stroke: 1pt + black, text-fill: black),
  norm: (fill: rgb("#E4E4E4"), stroke: 1pt + black, text-fill: black),
  activation: (fill: rgb("#EFEFEF"), stroke: (paint: black, thickness: 1pt, dash: "densely-dashed"), text-fill: black),
  attention: (fill: rgb("#CFCFCF"), stroke: 1.7pt + black, text-fill: black),
  param: (fill: rgb("#BDBDBD"), stroke: 1.7pt + black, text-fill: black),
  loss: (fill: rgb("#8F8F8F"), stroke: 1.7pt + black, text-fill: auto),
  control: (fill: white, stroke: (paint: rgb("#777777"), thickness: 1pt, dash: "dashed"), text-fill: rgb("#333333")),
  memory: (fill: rgb("#E4E4E4"), stroke: 1pt + black, text-fill: black),
  output: (fill: rgb("#8F8F8F"), stroke: 1.7pt + black, text-fill: auto),
  add: (fill: white, stroke: 1pt + black, text-fill: black),
  focal: (fill: white, stroke: 2.6pt + black, text-fill: black),
  container: (fill: none, stroke: (paint: rgb("#777777"), thickness: 0.8pt, dash: "dashed"), text-fill: rgb("#555555")),
)

// ---- edge styles per theme family ----
#let mono-edges = (
  data: (stroke: 0.9pt + neutral.ink, dash: none),
  skip: (stroke: 1pt + neutral.garnet, dash: none),
  residual: (stroke: 1pt + neutral.garnet, dash: none),
  grad: (stroke: 0.9pt + neutral.ink, dash: "dashed"),
  control: (stroke: 0.9pt + neutral.b50, dash: "dashed"),
  attention: (stroke: 0.7pt + neutral.b50, dash: none),
  sample: (stroke: 0.9pt + neutral.ink, dash: "densely-dashed"),
)
#let color-edges = (
  data: (stroke: 0.9pt + neutral.ink, dash: none),
  skip: (stroke: 1pt + okabe.blue, dash: none),
  residual: (stroke: 1pt + okabe.blue, dash: none),
  grad: (stroke: 0.9pt + okabe.vermillion, dash: "dashed"),
  control: (stroke: 0.9pt + neutral.b50, dash: "dashed"),
  attention: (stroke: 0.7pt + neutral.b50, dash: none),
  sample: (stroke: 0.9pt + okabe.green, dash: "densely-dashed"),
)
