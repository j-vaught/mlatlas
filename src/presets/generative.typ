// mlatlas · presets/generative.typ — generative models.

#import "../ir/ir.typ": ir-node, ir-edge, frag
#import "../prim/block.typ": block
#import "../sugar/sugar.typ": seq

// GAN: z -> Generator -> x_fake ; {x_real, x_fake} -> Discriminator -> real/fake.
#let gan() = frag(
  nodes: (
    ir-node("z", label: [$bold(z)$], role: "data", pos: (0, 0)),
    ir-node("g", label: [Generator], role: "attention", pos: (0, 1)),
    ir-node("xf", label: [$x_"fake"$], role: "op", pos: (0, 2)),
    ir-node("xr", label: [$x_"real"$], role: "data", pos: (2, 2)),
    ir-node("d", label: [Discriminator], role: "attention", pos: (1, 3)),
    ir-node("loss", label: [real / fake], role: "loss", pos: (1, 4)),
  ),
  edges: (
    ir-edge("z", "g"), ir-edge("g", "xf"),
    ir-edge("xf", "d"), ir-edge("xr", "d"),
    ir-edge("d", "loss"),
  ),
  meta: ("in": "z", "out": "loss"),
)

// VAE with the reparameterization step.
#let vae() = seq(
  block(id: "x", label: [Input $x$], role: "data"),
  block(label: [Encoder $q_phi$], role: "attention"),
  block(label: [$mu, sigma$], role: "param"),
  block(label: [$z = mu + sigma dot.c epsilon$\ #text(size: 0.8em)[(reparam.)]], role: "op"),
  block(label: [Decoder $p_theta$], role: "attention"),
  block(id: "xh", label: [Reconstruction $hat(x)$], role: "output"),
)

// Diffusion: reverse (denoising) chain x_T -> ... -> x_0.
#let diffusion-chain(steps: 4) = {
  let nodes = ()
  let edges = ()
  for i in range(steps + 1) {
    let lbl = if i == 0 { [$x_T$] } else if i == steps { [$x_0$] } else { [$x_(T - #i)$] }
    let r = if i == 0 { "data" } else if i == steps { "output" } else { "op" }
    nodes.push(ir-node("x" + str(i), label: lbl, role: r, pos: (i, 0)))
  }
  for i in range(steps) {
    edges.push(ir-edge("x" + str(i), "x" + str(i + 1), kind: "data", label: if i == 0 { [denoise $p_theta$] } else { none }))
  }
  frag(nodes: nodes, edges: edges, meta: ("in": "x0", "out": "x" + str(steps)))
}
