// mlatlas · presets/nn.typ — standard neural networks.

#import "../prim/neuron-graph.typ": neuron-graph
#import "../prim/block.typ": block
#import "../sugar/sugar.typ": seq

#let _roles-for(n) = ("data",) + ("op",) * (n - 2) + ("output",)

// A single perceptron / logistic unit (n inputs -> 1 output).
#let perceptron(inputs: 3) = neuron-graph((inputs, 1), layer-roles: ("data", "output"))

// A multilayer perceptron from a list of layer sizes, e.g. mlp((4, 8, 8, 3)).
#let mlp(layers: (4, 6, 6, 2), ..args) = neuron-graph(layers, layer-roles: _roles-for(layers.len()), ..args.named())

// A block-style feedforward stack (labelled rectangles instead of neurons).
#let feedforward(units: (784, 256, 64, 10)) = seq(
  ..units.enumerate().map(((i, u)) => {
    let r = if i == 0 { "data" } else if i == units.len() - 1 { "output" } else { "op" }
    block(id: "fc" + str(i), label: [Dense\ #u], role: r)
  }),
)
