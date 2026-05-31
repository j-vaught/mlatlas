// GAN — Generative Adversarial Network (Goodfellow et al. 2014; d2l-style schematic).
// Two networks trained adversarially:
//   Generator  G: noise z ~ p(z)  ->  fake sample G(z)   (volumes EXPAND, channels shrink)
//   Discriminator D: x -> scalar prob "real / fake"      (volumes CONTRACT to a 1-d decision)
// Real data x and fake data G(z) both flow into D, which is trained to tell them apart
// while G is trained to fool D. Built from architectural knowledge in mlatlas's print-first
// style; the reference is used only to confirm the noise -> G -> fake -> D -> real/fake flow.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// pull the 3-D feature-volume engine + cnn palette out of the library
#import "../../src/renderers/cnn3d.typ": volume, vol-anchors, cnn3d-palette
#import "../../src/adapters/3d.typ": cam-cabinet

#let garnet = rgb("#73000A")
#let ink    = rgb("#222222")
#let muted  = rgb("#5C5C5C")
#let pal     = cnn3d-palette

// the GAN tower: generator expands z into a fake image, discriminator contracts it to a decision.
#let stages = (
  (spatial: 8,  channels: 128, base: pal.bottleneck, width: 0.30, label: [z],    sub: [noise]),
  (spatial: 16, channels: 64,  base: pal.up,                       label: [G₁]),
  (spatial: 32, channels: 32,  base: pal.up,                       label: [G₂]),
  (spatial: 64, channels: 3,   base: pal.input,                    label: [G(z)], sub: [fake]),
  (spatial: 32, channels: 32,  base: pal.conv, relu: true,         label: [D₁]),
  (spatial: 16, channels: 64,  base: pal.conv, relu: true,         label: [D₂]),
  (spatial: 8,  channels: 1,   base: pal.pool, width: 0.28,        label: [D(·)], sub: [real / fake]),
)

#cetz.canvas(length: 1cm, {
  import cetz.draw
  import cetz.draw: *

  let gap = 0.95
  let cam = cam-cabinet

  // ── lay out the row, capturing each volume's anchors ────────────────────
  let cursor = 0.0
  let prev = none
  let A = ()                 // per-stage anchor records
  for L in stages {
    let sp = L.spatial
    let ch = L.channels
    let w-ov = L.at("width", default: auto)
    let a0 = vol-anchors((0, 0), sp, ch, width: w-ov, cam: cam)
    let sw = a0.umax - a0.umin
    if prev != none { cursor = cursor + gap }
    let ox = cursor + (-a0.umin)
    let av = vol-anchors((ox, 0), sp, ch, width: w-ov, cam: cam)
    // flow arrow between consecutive volumes
    if prev != none {
      line(
        (prev.at(0) + 0.04, 0), ((av.anchor)("west").at(0) - 0.04, 0),
        stroke: 1.6pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
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

  // convenient handles
  let z-a    = A.at(0).a       // noise z
  let fake-a = A.at(3).a       // G(z) fake image (the network "waist")
  let dec-a  = A.at(6).a       // D(·) decision
  let g1-a   = A.at(1).a
  let g2-a   = A.at(2).a
  let d1-a   = A.at(4).a
  let d2-a   = A.at(5).a

  // top y for brackets, just above the tallest volume (the fake image)
  let top = (fake-a.anchor)("top-screen").at(1) + 0.55

  // ── span bracket helper (square corners, garnet) ────────────────────────
  let span(x0, x1, y, label, accent) = {
    let drop = 0.20
    line(
      (x0, y - drop), (x0, y), (x1, y), (x1, y - drop),
      stroke: 1.1pt + accent,
    )
    content(((x0 + x1) / 2, y + 0.30), text(weight: "bold", size: 9.5pt, fill: accent)[#label])
  }

  // Generator spans z .. G(z); Discriminator spans G(z) .. D(.)
  let gx0 = (z-a.anchor)("west").at(0)
  let gx1 = (fake-a.anchor)("east").at(0)
  let dx0 = (fake-a.anchor)("west").at(0)
  let dx1 = (dec-a.anchor)("east").at(0)
  span(gx0, (fake-a.anchor)("west").at(0) - 0.05, top, [Generator $G$], garnet)
  span((fake-a.anchor)("east").at(0) + 0.05, dx1, top, [Discriminator $D$], rgb("#466A9F"))

  // ── noise source label, to the left of z ────────────────────────────────
  let zin = (z-a.anchor)("west")
  content(
    (zin.at(0) - 1.5, 0),
    text(size: 9pt, fill: ink)[$bold(z) tilde p(bold(z))$],
  )
  line(
    (zin.at(0) - 0.92, 0), (zin.at(0) - 0.06, 0),
    stroke: 1.6pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
  )
  content((zin.at(0) - 1.5, -0.42), text(size: 6.5pt, fill: muted)[prior noise])

  // ── REAL-DATA path: real sample x feeds into the discriminator too ──────
  // entry point is the front-west of the first discriminator volume (D₁).
  let d-in = (fake-a.anchor)("east")           // same junction G(z) hands to D
  let real-y = -2.5
  let real-x = (fake-a.anchor)("center").at(0)
  // real-data source box (sharp corners)
  let bw = 1.7
  let bh = 0.72
  rect(
    (real-x - bw / 2, real-y - bh / 2), (real-x + bw / 2, real-y + bh / 2),
    fill: rgb("#ECECEC"), stroke: 0.9pt + ink,
  )
  content((real-x, real-y + 0.06), text(size: 8.5pt, weight: "bold", fill: ink)[real data $bold(x)$])
  content((real-x, real-y - 0.22), text(size: 6.5pt, fill: muted)[$bold(x) tilde p_"data"$])
  // route up-and-into the D₁ volume (orthogonal, garnet dashed = the "real" branch).
  // arrive a touch below center so it doesn't collide with the solid fake-flow arrow.
  let d1-w = (d1-a.anchor)("west")
  let real-into = d1-w.at(1) - 0.55
  line(
    (real-x, real-y + bh / 2),
    (real-x, real-into),
    (d1-w.at(0) - 0.04, real-into),
    stroke: (paint: garnet, thickness: 1.3pt, dash: "dashed"),
    mark: (end: "stealth", scale: 0.7),
  )
  // also tag the two branches handed to D: the generated "fake" (solid) and "real" (dashed)
  content(
    ((fake-a.anchor)("east").at(0) + 0.46, 0.34),
    text(size: 6.5pt, fill: muted)[fake],
  )
  content(
    (d1-w.at(0) - 0.30, -0.95),
    anchor: "east",
    text(size: 6.5pt, fill: garnet)[real],
  )

  // ── decision output: real vs fake ───────────────────────────────────────
  let dout = (dec-a.anchor)("east")
  line(
    (dout.at(0) + 0.06, 0), (dout.at(0) + 0.92, 0),
    stroke: 1.6pt + pal.edge.transparentize(10%), mark: (end: "stealth", scale: 0.8),
  )
  content(
    (dout.at(0) + 2.05, 0),
    text(size: 9pt, fill: ink)[$D(dot) in [0, 1]$],
  )
  content((dout.at(0) + 2.05, -0.42), text(size: 6.5pt, fill: muted)[P(real)])

  // ── adversarial objective (caption) ─────────────────────────────────────
  let cap-y = real-y - 1.25
  content(
    (real-x, cap-y),
    text(size: 8.5pt, fill: rgb("#363636"))[
      $G$ maximizes the chance $D$ mislabels $G(bold(z))$ as real;
      $D$ minimizes its error on real vs. fake.
    ],
  )
  content(
    (real-x, cap-y - 0.72),
    text(size: 8.5pt, fill: garnet, style: "italic")[
      $min_G max_D thick EE_(bold(x)) [log D(bold(x))] + EE_(bold(z)) [log(1 - D(G(bold(z))))]$
    ],
  )
})
