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
    let r = 0.64
    let sp = 2.5
    let n = steps
    for i in range(n + 1) {
      let x = i * sp
      let t = i / n
      let v = int(95 + 160 * t) // x_T dark (95), x_0 white (255)
      circle((x, 0), radius: r, fill: luma(v), stroke: 1pt + ink)
      let lbl = if i == 0 { [$bold(x)_T$] } else if i == n { [$bold(x)_0$] } else { [$bold(x)_(T - #i)$] }
      content((x, 0), text(size: 8.5pt, fill: if v < 150 { white } else { rgb("#1A1A1A") })[#lbl])
    }
    for i in range(n) {
      let x0 = i * sp
      let x1 = (i + 1) * sp
      // reverse (denoise) p_theta: top U, into x_{i+1} (toward data)
      line((x0, r), (x0, r + 0.72), (x1, r + 0.72), (x1, r), stroke: 1.3pt + ink, mark: (end: "stealth", scale: 0.9))
      // forward (noising) q: bottom U, dashed garnet, into x_i (toward noise)
      line((x1, -r), (x1, -r - 0.72), (x0, -r - 0.72), (x0, -r), stroke: (paint: garnet, thickness: 1.2pt, dash: "dashed"), mark: (end: "stealth", scale: 0.9))
    }
    // process labels on the first transition
    content((sp / 2, r + 1.02), text(size: 8.5pt, fill: ink)[$p_theta(bold(x)_(t-1) | bold(x)_t)$])
    content((sp / 2, -r - 1.05), text(size: 8.5pt, fill: garnet)[$q(bold(x)_t | bold(x)_(t-1))$])
  })
}
