// A feature-map stack: spatial -> height, channels -> depth (log), ReLU bands; one shared camera.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#feature-stack-fig((
  (spatial: 224, channels: 3, base: cnn3d-palette.input, label: [input]),
  (spatial: 224, channels: 64, n: 2, relu: true, label: [conv1]),
  (spatial: 112, channels: 128, n: 2, relu: true, label: [conv2]),
  (spatial: 56, channels: 256, n: 3, relu: true, label: [conv3]),
), cam: cam-iso)
