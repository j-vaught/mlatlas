// mlatlas · renderers/pyramid3d.typ
// Generative pyramids on the engine: a generic pyramid3d (a row of volumes whose height
// contracts/expands), plus vae3d (encoder -> latent -> decoder hourglass) and gan3d (generator
// expand -> discriminator contract). Reuses the cnn3d feature-stack.
#import "@preview/cetz:0.5.2"
#import "./cnn3d.typ": feature-stack, cnn3d-palette
#import "../adapters/3d.typ": cam-cabinet

#let pyramid3d(stages: (), palette: cnn3d-palette, cam: cam-cabinet, gap: 0.85) = cetz.canvas(length: 1cm, {
  import cetz.draw
  feature-stack(draw, stages, palette: palette, cam: cam, gap: gap)
})

#let vae3d(palette: cnn3d-palette, cam: cam-cabinet) = cetz.canvas(length: 1cm, {
  import cetz.draw
  feature-stack(draw, (
    (spatial: 224, channels: 3, base: palette.input, label: [x], sub: [input]),
    (spatial: 112, channels: 32, relu: true, label: [enc₁]),
    (spatial: 56, channels: 64, relu: true, label: [enc₂]),
    (spatial: 16, channels: 128, base: palette.bottleneck, label: [z], sub: [μ, σ]),
    (spatial: 56, channels: 64, base: palette.up, label: [dec₁]),
    (spatial: 112, channels: 32, base: palette.up, label: [dec₂]),
    (spatial: 224, channels: 3, base: palette.input, label: [x̂], sub: [recon]),
  ), palette: palette, cam: cam, gap: 0.8)
})

#let gan3d(palette: cnn3d-palette, cam: cam-cabinet) = cetz.canvas(length: 1cm, {
  import cetz.draw
  feature-stack(draw, (
    (spatial: 8, channels: 128, base: palette.bottleneck, width: 0.3, label: [z], sub: [noise]),
    (spatial: 16, channels: 64, base: palette.up, label: [G₁]),
    (spatial: 32, channels: 32, base: palette.up, label: [G₂]),
    (spatial: 64, channels: 3, base: palette.input, label: [fake], sub: [G(z)]),
    (spatial: 32, channels: 32, base: palette.conv, relu: true, label: [D₁]),
    (spatial: 16, channels: 64, base: palette.conv, relu: true, label: [D₂]),
    (spatial: 8, channels: 1, base: palette.pool, width: 0.28, label: [D(x)], sub: [real / fake]),
  ), palette: palette, cam: cam, gap: 0.8)
})
