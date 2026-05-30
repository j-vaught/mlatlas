// The "simple is easy" case: three blocks, auto-wired, brand-themed — one line.
#import "../lib.typ": *

#standalone(seq(
  block(label: [Input], role: "data"),
  block(label: [Hidden Layer]),
  block(label: [Output], role: "io"),
))
