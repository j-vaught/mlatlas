// mlatlas · LaMa — Resolution-robust Large Mask Inpainting with Fourier
// Convolutions (Suvorov et al., WACV 2022).  The generator is a ResNet-style
// encoder→bottleneck→decoder whose bottleneck residual blocks are Fast Fourier
// Convolutions (see ffc-block.typ), giving an image-wide receptive field.  It
// takes a 4-channel input (masked RGB ⊕ binary mask) and predicts the inpainted
// image.  Training combines: a High-Receptive-Field Perceptual Loss (HRFPL,
// computed with a dilated segmentation-pretrained ResNet), a PatchGAN
// adversarial loss with discriminator feature-matching and an R1 penalty, and an
// L1 term on the visible (known) pixels only.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 18pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let faint  = rgb("#C7C7C7")
#let garnet = rgb("#73000A")
#let beige  = rgb("#FFF2E3")
#let blue   = rgb("#466A9F")
#let c-enc  = rgb("#FFF2E3")                 // encoder — beige
#let c-ffc  = rgb("#73000A").lighten(84%)    // bottleneck FFC blocks — garnet tint
#let c-dec  = rgb("#1F414D").lighten(76%)    // decoder — teal tint
#let edge   = rgb("#243038")

#let CAM = cam-cabinet

// match the feature-map engine's spatial→height / channels→depth mapping
#let fm-h(sp) = calc.max(0.8, calc.min(3.4, 0.7 + sp * 0.009))
#let fm-dep(ch) = calc.max(0.4, calc.min(2.4, 0.3 + calc.log(calc.max(ch, 1), base: 2) * 0.19))

#cetz.canvas(length: 1cm, {
  import cetz.draw
  let y = 0.0
  let am = (end: "stealth", fill: ink, scale: 0.6)

  let fm-anchors(x, sp, ch) = block3d-anchors(
    origin: (x, y), w: 0.34, h: fm-h(sp), dep: fm-dep(ch), cam: CAM,
  )
  let east(a) = (a.anchor)("east")
  let west(a) = (a.anchor)("west")
  let topS(a) = (a.anchor)("top-screen")
  let botS(a) = (a.anchor)("bottom-screen")

  // ════════════════════════════════════════════════════════════════════════
  // GENERATOR — encoder · FFC bottleneck · decoder
  // (x, spatial, channels, fill, label, sub)
  // ════════════════════════════════════════════════════════════════════════
  let G = (
    (0.0,  256, 4,   c-enc, [masked input], [$256^2 times 4$]),
    (1.75, 128, 64,  c-enc, [down ↓2],      [$128^2 times 64$]),
    (3.15, 64,  128, c-enc, [down ↓2],      [$64^2 times 128$]),
    (4.45, 32,  256, c-enc, [down ↓2],      [$32^2 times 256$]),
    (5.55, 32,  256, c-ffc, none, none),
    (5.95, 32,  256, c-ffc, none, none),
    (6.35, 32,  256, c-ffc, none, none),
    (7.65, 64,  128, c-dec, [up ↑2],        [$64^2 times 128$]),
    (9.05, 128, 64,  c-dec, [up ↑2],        [$128^2 times 64$]),
    (10.55,256, 3,   c-dec, [inpainted],    [$256^2 times 3$]),
  )
  let anc = G.map(s => fm-anchors(s.at(0), s.at(1), s.at(2)))

  // forward arrows between consecutive stages
  for i in range(G.len() - 1) {
    draw.line(east(anc.at(i)), west(anc.at(i + 1)), stroke: 0.9pt + ink, mark: am)
  }

  // slabs (encoder/decoder solid; FFC stack with a trailing band to read as conv)
  for (i, s) in G.enumerate() {
    let isffc = i >= 4 and i <= 6
    feature-map(
      draw, (s.at(0), y), spatial: s.at(1), channels: s.at(2),
      base: s.at(3), edge: edge, cam: CAM, relu: isffc,
    )
  }

  // brace + label over the FFC bottleneck stack
  let bl = topS(anc.at(4)).at(0) - 0.18
  let br = topS(anc.at(6)).at(0) + 0.30
  let by = calc.max(topS(anc.at(4)).at(1), topS(anc.at(6)).at(1)) + 0.32
  draw.line((bl, by - 0.16), (bl, by), (br, by), (br, by - 0.16), stroke: 0.9pt + garnet)
  draw.content(((bl + br)/2, by + 0.42),
    text(size: 8pt, weight: "bold", fill: garnet)[$times$ 9–18  FFC residual blocks])
  draw.content(((bl + br)/2, by + 0.13),
    text(size: 6.5pt, fill: muted)[image-wide receptive field])

  // per-stage labels (skip the inner FFC prisms)
  for (i, s) in G.enumerate() {
    if s.at(4) == none { continue }
    let p = botS(anc.at(i))
    draw.content((p.at(0), p.at(1) - 0.30), text(size: 7.5pt, weight: "bold", fill: ink)[#s.at(4)])
    draw.content((p.at(0), p.at(1) - 0.62), text(size: 6.5pt, fill: muted)[#s.at(5)])
  }
  // small "image with a hole" glyph in front of the input, to read as a mask
  {
    let gx = -1.35
    let gy = y + fm-h(256) * 0.45
    draw.rect((gx, gy - 0.45), (gx + 0.9, gy + 0.45), fill: beige, stroke: 0.8pt + edge, radius: 0pt)
    draw.rect((gx + 0.28, gy - 0.12), (gx + 0.66, gy + 0.26), fill: white, stroke: (paint: garnet, thickness: 0.9pt, dash: "dashed"), radius: 0pt)
    draw.content((gx + 0.45, gy - 0.66), text(size: 6.5pt, fill: muted)[image ⊙ mask])
    draw.line((gx + 0.9, gy), (west(anc.at(0)).at(0) - 0.05, west(anc.at(0)).at(1)), stroke: 0.9pt + ink, mark: am)
  }

  // title
  draw.content((5.0, by + 1.25),
    text(size: 13pt, weight: "bold", fill: ink)[LaMa — large-mask inpainting generator])

  // ════════════════════════════════════════════════════════════════════════
  // LOSS PANEL
  // ════════════════════════════════════════════════════════════════════════
  let opbox(cx, cy, w, h, title, sub, focal: false) = {
    let stk = if focal { 1.6pt + garnet } else { 1.0pt + edge }
    let fil = if focal { beige } else { white }
    draw.rect((cx - w/2, cy - h/2), (cx + w/2, cy + h/2), fill: fil, stroke: stk, radius: 0pt)
    draw.content((cx, cy + h*0.17), text(size: 8pt, weight: "bold", fill: ink)[#title])
    if sub != none { draw.content((cx, cy - h*0.23), text(size: 6.5pt, fill: muted)[#sub]) }
  }

  let fTop = -2.55
  let fBot = -7.05
  draw.rect((-1.55, fBot), (12.7, fTop), fill: none, stroke: (paint: faint, thickness: 0.7pt, dash: "dashed"), radius: 0pt)
  draw.content((-1.4, fTop - 0.05), anchor: "north-west", text(size: 8.5pt, weight: "bold", fill: garnet)[Training objective])

  // route the prediction from the generator output down-and-left into the panel
  let op = botS(anc.at(9))
  draw.line(
    (op.at(0), op.at(1) - 0.05), (op.at(0), -2.1), (-0.55, -2.1), (-0.55, -3.43),
    stroke: (paint: ink, thickness: 0.8pt, dash: "dashed"), mark: am,
  )
  draw.content((op.at(0) + 0.12, -1.95), anchor: "west", text(size: 7pt, fill: ink, style: "italic")[$hat(x)$])

  // x̂ (prediction) and x (target) tiles
  draw.rect((-0.97, -4.27), (-0.13, -3.43), fill: c-dec, stroke: 0.8pt + edge, radius: 0pt)
  draw.content((-0.55, -3.85), text(size: 8pt, weight: "bold", fill: ink)[$hat(x)$])
  draw.content((-0.55, -4.5), text(size: 6.3pt, fill: muted)[prediction])
  draw.rect((-0.97, -5.77), (-0.13, -4.93), fill: beige, stroke: 0.8pt + edge, radius: 0pt)
  draw.content((-0.55, -5.35), text(size: 8pt, weight: "bold", fill: ink)[$x$])
  draw.content((-0.55, -6.0), text(size: 6.3pt, fill: muted)[target])

  // fan-out point
  let fk = (0.5, -4.6)
  draw.line((-0.13, -3.85), fk, stroke: 0.85pt + ink)
  draw.line((-0.13, -5.35), fk, stroke: 0.85pt + ink)

  // three loss branches
  let xB = 4.0
  // (A) HRF perceptual loss — dilated, segmentation-pretrained ResNet
  draw.line(fk, (xB - 1.55, -3.25), stroke: 0.85pt + ink, mark: am)
  opbox(xB, -3.25, 3.0, 0.92, [$phi_"HRF"$: dilated ResNet], [segmentation-pretrained], focal: true)
  draw.line((xB + 1.5, -3.25), (8.7, -3.25), stroke: 0.85pt + ink, mark: am)
  draw.content((8.85, -3.25), anchor: "west", text(size: 8pt, fill: garnet, weight: "bold")[$alpha dot cal(L)_"HRFPL"$])
  draw.content((8.85, -3.57), anchor: "west", text(size: 6.2pt, fill: muted)[wide-RF perceptual])

  // (B) PatchGAN discriminator — adversarial + feature-matching + R1
  draw.line(fk, (xB - 1.55, -4.6), stroke: 0.85pt + ink, mark: am)
  opbox(xB, -4.6, 3.0, 0.92, [$D$: PatchGAN], [per-patch real / fake])
  draw.line((xB + 1.5, -4.6), (8.7, -4.6), stroke: 0.85pt + ink, mark: am)
  draw.content((8.85, -4.6), anchor: "west", text(size: 8pt, fill: ink, weight: "bold")[$kappa cal(L)_"Adv" + beta cal(L)_"DiscFM" + gamma R_1$])
  draw.content((8.85, -4.92), anchor: "west", text(size: 6.2pt, fill: muted)[adversarial · feature-match · grad. penalty])

  // (C) L1 on known pixels
  draw.line(fk, (xB - 1.55, -5.95), stroke: 0.85pt + ink, mark: am)
  opbox(xB, -5.95, 3.0, 0.92, [known-region mask], [visible pixels only])
  draw.line((xB + 1.5, -5.95), (8.7, -5.95), stroke: 0.85pt + ink, mark: am)
  draw.content((8.85, -5.95), anchor: "west", text(size: 8pt, fill: ink, weight: "bold")[$cal(L)_1^"known"$])
  draw.content((8.85, -6.27), anchor: "west", text(size: 6.2pt, fill: muted)[reconstruct what is seen])

  // final objective line
  draw.content((5.5, fBot + 0.30),
    text(size: 8pt, fill: ink)[$cal(L)_"final" = kappa cal(L)_"Adv" + alpha cal(L)_"HRFPL" + beta cal(L)_"DiscFM" + gamma R_1 + cal(L)_1^"known"$])
})
