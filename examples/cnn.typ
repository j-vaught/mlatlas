// Publication-grade CNN figures via the dedicated cetz prism renderer (PlotNeuralNet
// recipe): VGG-16 and LeNet-5.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 14pt, fill: white)

#align(center, vgg16())
#v(22pt)
#align(center, scale(150%, reflow: true, lenet5()))
