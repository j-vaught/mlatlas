// mlatlas · theme/tokens.typ
// TIER 1 — base palettes (raw colour literals). Neutrals (the user's restrained
// "broody" brand: garnet + blacks + beige) are shared by every theme; `okabe` is the
// colourblind-safe categorical hue set used by the `colorful` / `colorblind` themes.

#let neutral = (
  ink: rgb("#111111"),
  paper: rgb("#FFFFFF"),
  white: rgb("#FFFFFF"),
  beige: rgb("#FFF2E3"),
  garnet: rgb("#73000A"), // sparse accent ONLY (focal / emphasis / key edges)
  b90: rgb("#363636"),
  b70: rgb("#5C5C5C"),
  b50: rgb("#A2A2A2"),
  b30: rgb("#C7C7C7"),
  b10: rgb("#ECECEC"),
)

// Okabe–Ito: distinguishable under all common colour-vision deficiencies.
#let okabe = (
  blue: rgb("#0072B2"),
  sky: rgb("#56B4E9"),
  orange: rgb("#E69F00"),
  vermillion: rgb("#D55E00"),
  green: rgb("#009E73"),
  yellow: rgb("#F0E442"),
  yellow-border: rgb("#C9A400"), // darker yellow for borders/text (#F0E442 fails contrast as a line)
  magenta: rgb("#CC79A7"),
  violet: rgb("#7E57C2"),
  black: rgb("#000000"),
)

// Hue assignment per semantic role for the colourful / slides themes.
#let colorful-hues = (
  input: okabe.sky,
  data: okabe.sky,
  io: okabe.sky,
  op: okabe.orange,
  compute: okabe.orange,
  norm: okabe.green,
  activation: okabe.yellow-border,
  attention: okabe.blue,
  param: okabe.magenta,
  loss: okabe.vermillion,
  memory: okabe.violet,
  output: okabe.black,
  add: okabe.black,
)

// Reduced, maximally-distinct set for the colourblind theme (5 hues + dash redundancy).
#let colorblind-hues = (
  input: okabe.blue,
  data: okabe.blue,
  io: okabe.blue,
  op: okabe.orange,
  compute: okabe.orange,
  norm: okabe.green,
  activation: okabe.green,
  attention: okabe.blue,
  param: okabe.magenta,
  loss: okabe.vermillion,
  memory: okabe.magenta,
  output: okabe.black,
  add: okabe.black,
)
