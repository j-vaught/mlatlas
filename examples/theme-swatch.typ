// A swatch sheet: every role under each theme — the one-glance contrast audit.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 10pt, fill: rgb("#DDDDDD"))

#stack(
  dir: ttb,
  spacing: 8pt,
  theme-swatch(mono),
  theme-swatch(colorful),
  theme-swatch(grayscale),
  theme-swatch(slides),
)
