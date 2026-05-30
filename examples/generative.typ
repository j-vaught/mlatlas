// Generative models: GAN, VAE, diffusion chain.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 8pt, fill: white)

#stack(
  dir: ltr,
  spacing: 16pt,
  align(top, render(gan())),
  align(top, render(vae())),
  align(top, render(diffusion-chain(steps: 4), dir: "ttb")),
)
