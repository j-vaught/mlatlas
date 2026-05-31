// Autoencoder family (undercomplete / denoising / sparse / masked) — Goodfellow et al.;
// Bishop; Fleuret.  A single generative-pyramid hourglass: an encoder f_phi contracts the
// input x to a low-dimensional bottleneck CODE z, and a decoder g_theta expands z back to a
// reconstruction x-hat.  Training minimizes a reconstruction loss ||x - x-hat||.  The four
// family members differ only in what they add on top of this shared scaffold:
//   • undercomplete — bottleneck dim < input dim forces compression (the base case shown).
//   • denoising     — corrupt x -> x~ before the encoder; reconstruct the clean x.
//   • sparse        — penalize code activations (Omega(z)) so few units fire per input.
//   • masked        — hide a subset of input tokens/patches; reconstruct the missing ones.
// Built from architectural knowledge in mlatlas's print-first style. Reuses the vae3d /
// feature-volume scaffolding (volume + vol-anchors on the 3-D block engine).
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#import "../../src/renderers/cnn3d.typ": volume, vol-anchors, cnn3d-palette
#import "../../src/adapters/3d.typ": cam-cabinet

#let garnet = rgb("#73000A")
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let blue   = rgb("#466A9F")
#let green  = rgb("#65780B")
#let pinkr  = rgb("#CC2E40")
#let pal    = cnn3d-palette

// ── the hourglass: input shrinks to a bottleneck CODE, then grows back ─────────────
//    spatial drives the on-screen HEIGHT; channels the depth.  Encoder volumes contract,
//    the bottleneck is the narrow garnet-tinted code, decoder volumes mirror back out.
#let stages = (
  (spatial: 56, channels: 3,   base: pal.input,                       label: [$bold(x)$], sub: [input]),
  (spatial: 40, channels: 16,  base: pal.conv, relu: true,            label: [enc₁]),
  (spatial: 24, channels: 32,  base: pal.conv, relu: true,            label: [enc₂]),
  (spatial: 10, channels: 64,  base: pal.bottleneck, width: 0.34,     label: [$bold(z)$], sub: [code]),
  (spatial: 24, channels: 32,  base: pal.up,                          label: [dec₁]),
  (spatial: 40, channels: 16,  base: pal.up,                          label: [dec₂]),
  (spatial: 56, channels: 3,   base: pal.input,                       label: [$hat(bold(x))$], sub: [recon]),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw
  import cetz.draw: *

  let gap = 0.78
  let cam = cam-cabinet

  // lay out the row left-to-right, capturing anchors -------------------------------
  let cursor = 0.0
  let prev = none
  let A = ()
  for L in stages {
    let sp = L.spatial
    let ch = L.channels
    let w-ov = L.at("width", default: auto)
    let a0 = vol-anchors((0, 0), sp, ch, width: w-ov, cam: cam)
    let sw = a0.umax - a0.umin
    if prev != none { cursor = cursor + gap }
    let ox = cursor + (-a0.umin)
    let av = vol-anchors((ox, 0), sp, ch, width: w-ov, cam: cam)
    if prev != none {
      line(
        (prev.at(0) + 0.04, 0), ((av.anchor)("west").at(0) - 0.04, 0),
        stroke: 1.5pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
      )
    }
    volume(
      draw, (ox, 0), sp, ch, base: L.at("base", default: pal.conv), palette: pal, cam: cam,
      relu: L.at("relu", default: false), label: L.at("label", default: none),
      sub: L.at("sub", default: none), width: w-ov,
    )
    A.push((ox: ox, a: av))
    cursor = cursor + sw
    prev = (av.anchor)("east")
  }

  let x-a   = A.at(0).a
  let z-a   = A.at(3).a
  let xh-a  = A.at(6).a

  // ── span brackets: Encoder f_phi  |  Decoder g_theta ────────────────────────────
  let top = (z-a.anchor)("top-screen").at(1) + 2.1
  let span(x0, x1, y, label, accent) = {
    let drop = 0.20
    line((x0, y - drop), (x0, y), (x1, y), (x1, y - drop), stroke: 1.1pt + accent)
    content(((x0 + x1) / 2, y + 0.30), text(weight: "bold", size: 9.5pt, fill: accent)[#label])
  }
  let zc  = (z-a.anchor)("center").at(0)
  let ex0 = (x-a.anchor)("west").at(0)
  let ex1 = (z-a.anchor)("west").at(0) - 0.08
  let dx0 = (z-a.anchor)("east").at(0) + 0.08
  let dx1 = (xh-a.anchor)("east").at(0)
  span(ex0, ex1, top, [Encoder $f_phi$], garnet)
  span(dx0, dx1, top, [Decoder $g_theta$], blue)

  // arrows on the bracket arms hinting compression / expansion direction
  content(((ex0 + ex1) / 2, top - 0.62), text(size: 6.5pt, fill: muted)[compress $arrow.r$])
  content(((dx0 + dx1) / 2, top - 0.62), text(size: 6.5pt, fill: muted)[$arrow.r$ expand])

  // ── highlight the bottleneck CODE z ─────────────────────────────────────────────
  let zb = (z-a.anchor)("bottom-screen")
  content(
    (zc, zb.at(1) - 1.05),
    text(size: 7.5pt, fill: garnet, weight: "bold")[$bold(z) = f_phi (bold(x))$],
  )
  content((zc, zb.at(1) - 1.45), text(size: 6.5pt, fill: muted)[$dim(bold(z)) < dim(bold(x))$])

  // ── reconstruction-loss tie between x and x-hat (the shared objective) ───────────
  let lx0 = (x-a.anchor)("center").at(0)
  let lx1 = (xh-a.anchor)("center").at(0)
  let lyt = top + 1.25
  line(
    (lx0, (x-a.anchor)("top-screen").at(1) + 0.10), (lx0, lyt), (lx1, lyt), (lx1, (xh-a.anchor)("top-screen").at(1) + 0.10),
    stroke: (paint: ink, thickness: 0.9pt, dash: "densely-dotted"),
    mark: (start: "stealth", end: "stealth", scale: 0.55),
  )
  content(
    ((lx0 + lx1) / 2, lyt + 0.34),
    text(size: 8pt, fill: ink)[reconstruction loss $cal(L) = norm(bold(x) - hat(bold(x)))^2$],
  )

  // ── DENOISING branch: corrupt x -> x~ before it enters the encoder ───────────────
  let xw = (x-a.anchor)("west")
  let corr-x = xw.at(0) - 2.05
  let bw = 1.55
  let bh = 0.64
  rect(
    (corr-x - bw / 2, -bh / 2), (corr-x + bw / 2, bh / 2),
    fill: rgb("#ECECEC"), stroke: 0.9pt + ink, radius: 0pt,
  )
  content((corr-x, 0.10), text(size: 7.5pt, weight: "bold", fill: ink)[corrupt])
  content((corr-x, -0.16), text(size: 6.5pt, fill: muted)[$bold(x) arrow.r tilde(bold(x))$])
  line(
    (corr-x + bw / 2 + 0.04, 0), (xw.at(0) - 0.06, 0),
    stroke: 1.5pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
  )
  content((corr-x - bw / 2 - 0.46, 0), anchor: "east", text(size: 6.5pt, fill: muted)[$bold(x)$])
  line(
    (corr-x - bw / 2 - 0.40, 0), (corr-x - bw / 2 - 0.06, 0),
    stroke: 1.3pt + muted, mark: (end: "stealth", scale: 0.65),
  )
  content(
    (corr-x, bh / 2 + 0.40),
    text(size: 6.5pt, fill: pinkr, style: "italic")[denoising only],
  )
  // the sparse / masked add-ons are summarized in the variants strip below.
})

// ── variants strip: what each family member ADDS to the shared scaffold ───────────
#v(10pt)
#cetz.canvas(length: 1cm, {
  import cetz.draw
  import cetz.draw: *

  let cellw = 4.35
  let names = (
    (t: [Undercomplete], c: garnet),
    (t: [Denoising],     c: pinkr),
    (t: [Sparse],        c: green),
    (t: [Masked],        c: blue),
  )
  let bodies = (
    [bottleneck dim $<$ input dim;\ compression is the only regularizer],
    [corrupt input $bold(x) arrow.r tilde(bold(x))$,\ reconstruct the clean $bold(x)$],
    [penalize code activations $Omega(bold(z))$\ so few units fire per input],
    [hide a subset of input\ tokens / patches, predict them],
  )
  let losses = (
    [$norm(bold(x) - hat(bold(x)))^2$],
    [$norm(bold(x) - g_theta (f_phi (tilde(bold(x)))))^2$],
    [$norm(bold(x) - hat(bold(x)))^2 + lambda Omega(bold(z))$],
    [$sum_(i in cal(M)) norm(bold(x)_i - hat(bold(x))_i)^2$],
  )

  let n = names.len()
  let totw = n * cellw
  // header rule
  line((0, 1.30), (totw, 1.30), stroke: 0.8pt + ink)
  content((totw / 2, 1.62), text(size: 8.5pt, weight: "bold", fill: ink)[The four family members share one scaffold — encoder $arrow.r$ code $arrow.r$ decoder — and differ in the colored add-on])

  for i in range(n) {
    let x0 = i * cellw
    let cx = x0 + cellw / 2
    // accent chip + name
    rect((x0 + 0.16, 0.92), (x0 + 0.46, 1.14), fill: names.at(i).c, stroke: none, radius: 0pt)
    content((x0 + 0.58, 1.03), anchor: "west", text(size: 9pt, weight: "bold", fill: names.at(i).c)[#names.at(i).t])
    // body
    content((cx, 0.34), text(size: 7pt, fill: ink)[#align(center)[#bodies.at(i)]])
    // objective
    content((cx, -0.60), text(size: 7pt, fill: muted)[objective:])
    content((cx, -0.92), text(size: 7.5pt, fill: names.at(i).c)[#losses.at(i)])
    // vertical separators
    if i > 0 { line((x0, -1.30), (x0, 1.20), stroke: 0.4pt + rgb("#C7C7C7")) }
  }
  line((0, -1.30), (totw, -1.30), stroke: 0.4pt + rgb("#C7C7C7"))
})
