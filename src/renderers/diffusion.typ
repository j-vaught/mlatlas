// mlatlas · renderers/diffusion.typ
// A dedicated DDPM Markov-chain renderer (Lil'Log / DDPM style): states x_T … x_0 as
// circles with a noise-level grey ramp (x_T darkest → x_0 white), the reverse/denoising
// process p_θ as solid arrows on top (noise → data), the forward/noising process q as
// dashed garnet arrows on the bottom (data → noise). Sharp orthogonal U-routing.

#import "@preview/cetz:0.5.2"

#let diffusion-chain(steps: 5, palette: auto) = {
  let ink = rgb("#363636")
  let garnet = rgb("#73000A")
  cetz.canvas(length: 1cm, {
    import cetz.draw: circle, line, content
    let r = 0.72
    let sp = 2.3
    let n = steps
    for i in range(n + 1) {
      let x = i * sp
      let t = i / n
      let v = int(95 + 160 * t) // x_T dark (95), x_0 white (255)
      circle((x, 0), radius: r, fill: luma(v), stroke: 1pt + ink)
      let lbl = if i == 0 { [$bold(x)_T$] } else if i == n { [$bold(x)_0$] } else { [$bold(x)_(T - #i)$] }
      content((x, 0), text(size: 9pt, fill: if v < 150 { white } else { rgb("#1A1A1A") })[#lbl])
    }
    // per-gap arrows as distinct peaks/valleys (so they don't merge into a single rail)
    for i in range(n) {
      let x0 = i * sp
      let x1 = (i + 1) * sp
      let mid = (x0 + x1) / 2
      // reverse (denoise) p_theta: solid peak on top, into x_{i+1} (toward data)
      line((x0 + r * 0.6, r * 0.8), (mid, r + 0.62), (x1 - r * 0.6, r * 0.8), stroke: 1.3pt + ink, mark: (end: "stealth", scale: 0.95))
      // forward (noising) q: dashed garnet valley on bottom, into x_i (toward noise)
      line((x1 - r * 0.6, -r * 0.8), (mid, -r - 0.62), (x0 + r * 0.6, -r * 0.8), stroke: (paint: garnet, thickness: 1.2pt, dash: "dashed"), mark: (end: "stealth", scale: 0.95))
    }
    // process labels above the first peak / below the first valley
    content((sp / 2, r + 1.25), text(size: 9.5pt, fill: ink)[$p_(theta) (bold(x)_(t-1) | bold(x)_t)$])
    content((sp / 2, -r - 1.28), text(size: 9.5pt, fill: garnet)[$q(bold(x)_t | bold(x)_(t-1))$])
  })
}
