// A U-Net: encoder (down), bottleneck, decoder (up), with horizontal skip connections.
#import "../lib.typ": *

#standalone(unet(depth: 3, base: 32), theme: colorful)
