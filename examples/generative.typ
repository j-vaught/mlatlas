// Generative models: GAN, VAE, diffusion chain.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 8pt, fill: white)

#stack(
  dir: ltr,
  spacing: 18pt,
  align(top, render(gan(), theme: paper)),
  align(top, render(vae(), theme: paper)),
)
#v(16pt)
#diffusion-chain(steps: 6)
