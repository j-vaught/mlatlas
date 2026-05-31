// Generic 3-D feature-map stack (cm-scale) via feature-stack: a VGG-ish pipeline.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#feature-stack-fig((
  (spatial: 224, channels: 3, base: cnn3d-palette.input, label: [input], sub: [224²×3]),
  (spatial: 224, channels: 64, n: 2, relu: true, label: [conv1]),
  (spatial: 112, channels: 128, n: 2, relu: true, label: [conv2]),
  (spatial: 56, channels: 256, n: 3, relu: true, label: [conv3]),
  (spatial: 28, channels: 512, n: 3, relu: true, label: [conv4]),
  (spatial: 14, channels: 512, base: cnn3d-palette.pool, label: [pool]),
))
