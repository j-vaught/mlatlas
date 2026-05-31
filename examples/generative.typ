// Generative models: GAN and VAE (the diffusion chain has its own example).
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 12pt, fill: white)

#stack(
  dir: ltr,
  spacing: 26pt,
  align(top)[
    #align(center, text(weight: "bold")[(a) GAN]) #v(4pt)
    #render(gan(), theme: paper)
  ],
  align(top)[
    #align(center, text(weight: "bold")[(b) VAE]) #v(4pt)
    #render(vae(), theme: paper)
  ],
)
