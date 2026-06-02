// mlatlas · Fast Fourier Convolution (FFC) layer — the core unit of LaMa
// (Suvorov et al., "Resolution-robust Large Mask Inpainting with Fourier
// Convolutions", WACV 2022; FFC from Chi et al., NeurIPS 2020).
//
// An FFC layer splits its channels into a LOCAL part X_l (ordinary spatial
// conv, small receptive field) and a GLOBAL part X_g (a Spectral Transform
// that reaches the WHOLE image in one layer).  Four learned paths route
// information within and ACROSS the two domains:
//     Y_l = f_{l→l}(X_l) + f_{g→l}(X_g)        (local output)
//     Y_g = f_{g→g}(X_g) + f_{l→g}(X_l)        (global output)
// f_{g→g} is the Spectral Transform: real 2-D FFT → concat(Re,Im) →
// 1×1 conv+BN+ReLU in frequency space → inverse FFT.  Operating on a Fourier
// coefficient touches every spatial location, so the receptive field is image-wide.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ──────────────────────────────────────────────────────────────
#let ink     = rgb("#1A1A1A")
#let muted   = rgb("#5C5C5C")
#let faint   = rgb("#C7C7C7")
#let garnet  = rgb("#73000A")
#let beige   = rgb("#FFF2E3")
#let blue    = rgb("#466A9F")
#let c-local = rgb("#FFF2E3")            // local channels — beige
#let c-glob  = rgb("#466A9F").lighten(72%)  // global channels — pale blue
#let edge    = rgb("#243038")

// sequential ramp beige→garnet (for the little frequency-domain tile)
#let ramp(t) = {
  let t = calc.max(0.0, calc.min(1.0, t))
  beige.mix((garnet, t * 100%), space: oklab)
}

#cetz.canvas(length: 1cm, {
  import cetz.draw

  let am = (end: "stealth", fill: ink, scale: 0.62)          // neutral arrow
  let ax = (end: "stealth", fill: garnet, scale: 0.62)       // cross-talk arrow

  // op box: (cx,cy) centre, returns nothing; focal → garnet frame + beige fill
  let opbox(cx, cy, w, h, title, sub, focal: false) = {
    let stk = if focal { 1.6pt + garnet } else { 1.0pt + edge }
    let fil = if focal { beige } else { white }
    draw.rect((cx - w/2, cy - h/2), (cx + w/2, cy + h/2), fill: fil, stroke: stk, radius: 0pt)
    draw.content((cx, cy + h*0.16), text(size: 8.5pt, weight: "bold", fill: ink)[#title])
    if sub != none { draw.content((cx, cy - h*0.22), text(size: 6.8pt, fill: muted)[#sub]) }
  }
  // ⊕ node
  let plus(cx, cy, r) = {
    draw.circle((cx, cy), radius: r, fill: white, stroke: 1.1pt + garnet)
    draw.line((cx - r*0.6, cy), (cx + r*0.6, cy), stroke: 1.1pt + garnet)
    draw.line((cx, cy - r*0.6), (cx, cy + r*0.6), stroke: 1.1pt + garnet)
  }

  // ════════════════════════════════════════════════════════════════════════
  // lane geometry
  // ════════════════════════════════════════════════════════════════════════
  let xIn0 = 0.0
  let xIn1 = 1.05
  let xConv = 3.7         // centre of the four conv boxes
  let bw = 2.0            // conv box width
  let xSum = 6.5          // ⊕ centres
  let rS = 0.30
  let xOut0 = 7.65
  let xOut1 = 8.75

  // input split: top = local ((1−α)C, small), bottom = global (αC, large)
  let inTop = 8.05
  let inBot = 3.95
  let inDiv = 7.05        // divider — local above, global below (α≈0.75)
  let yLocOut = (inTop + inDiv) / 2   // local feed point
  let yGloOut = (inDiv + inBot) / 2   // global feed point

  // conv box centres (top→bottom): f_ll, f_gl  feed local ⊕;  f_lg, f_gg feed global ⊕
  let yFll = 8.05
  let yFgl = 7.00
  let yFlg = 5.55
  let yFgg = 4.35
  let ySumL = (yFll + yFgl) / 2        // local ⊕
  let ySumG = (yFlg + yFgg) / 2        // global ⊕

  // ── input feature map, channel-split ───────────────────────────────────────
  draw.rect((xIn0, inDiv), (xIn1, inTop), fill: c-local, stroke: 1.0pt + edge, radius: 0pt)
  draw.rect((xIn0, inBot), (xIn1, inDiv), fill: c-glob,  stroke: 1.0pt + edge, radius: 0pt)
  draw.line((xIn0, inDiv), (xIn1, inDiv), stroke: 1.0pt + edge)   // the split
  draw.content(((xIn0+xIn1)/2, inTop + 0.30), text(size: 8pt, weight: "bold", fill: ink)[input])
  draw.content(((xIn0+xIn1)/2, inTop + 0.04), text(size: 6.5pt, fill: muted)[$H times W times C$])
  draw.content((xIn1 + 0.12, yLocOut), anchor: "west", text(size: 7pt, fill: ink)[$X_l$ #text(fill: muted, size: 6pt)[$(1-alpha)C$]])
  draw.content((xIn1 + 0.12, yGloOut), anchor: "west", text(size: 7pt, fill: blue)[$X_g$ #text(fill: muted, size: 6pt)[$alpha C$]])

  // ── routing arrows from the split into the four paths ──────────────────────
  // straight (same-domain) = ink ; cross (local↔global) = garnet
  draw.line((xIn1 + 0.62, yLocOut), (xConv - bw/2, yFll), stroke: 0.95pt + ink,    mark: am)  // l→l
  draw.line((xIn1 + 0.62, yGloOut), (xConv - bw/2, yFgg), stroke: 0.95pt + ink,    mark: am)  // g→g
  draw.line((xIn1 + 0.62, yLocOut), (xConv - bw/2, yFlg), stroke: 0.95pt + garnet, mark: ax)  // l→g
  draw.line((xIn1 + 0.62, yGloOut), (xConv - bw/2, yFgl), stroke: 0.95pt + garnet, mark: ax)  // g→l

  // ── the four conv paths ────────────────────────────────────────────────────
  opbox(xConv, yFll, bw, 0.82, $f_(l arrow.r l)$, [local conv])
  opbox(xConv, yFgl, bw, 0.82, $f_(g arrow.r l)$, [conv (g→l)])
  opbox(xConv, yFlg, bw, 0.82, $f_(l arrow.r g)$, [conv (l→g)])
  opbox(xConv, yFgg, bw, 0.98, [Spectral Transform], [$f_(g arrow.r g)$ · FFT-domain], focal: true)

  // ── conv boxes → ⊕ sums ────────────────────────────────────────────────────
  draw.line((xConv + bw/2, yFll), (xSum - rS, ySumL), stroke: 0.95pt + ink, mark: am)
  draw.line((xConv + bw/2, yFgl), (xSum - rS, ySumL), stroke: 0.95pt + ink, mark: am)
  draw.line((xConv + bw/2, yFlg), (xSum - rS, ySumG), stroke: 0.95pt + ink, mark: am)
  draw.line((xConv + bw/2, yFgg), (xSum - rS, ySumG), stroke: 0.95pt + ink, mark: am)
  plus(xSum, ySumL, rS)
  plus(xSum, ySumG, rS)

  // ── ⊕ → output concat ──────────────────────────────────────────────────────
  draw.rect((xOut0, inBot + 0.10), (xOut1, inTop), fill: white, stroke: 1.0pt + edge, radius: 0pt)
  // split the output tile to echo local(top)/global(bottom)
  let outDiv = (inBot + 0.10 + inTop) / 2 + 0.55
  draw.rect((xOut0, outDiv), (xOut1, inTop), fill: c-local, stroke: 1.0pt + edge, radius: 0pt)
  draw.rect((xOut0, inBot + 0.10), (xOut1, outDiv), fill: c-glob, stroke: 1.0pt + edge, radius: 0pt)
  draw.line((xSum + rS, ySumL), (xOut0, ySumL), stroke: 0.95pt + ink, mark: am)
  draw.line((xSum + rS, ySumG), (xOut0, ySumG), stroke: 0.95pt + ink, mark: am)
  draw.content(((xOut0+xOut1)/2, inTop + 0.30), text(size: 8pt, weight: "bold", fill: ink)[concat])
  draw.line((xOut1, (inTop + inBot + 0.10)/2), (xOut1 + 1.0, (inTop + inBot + 0.10)/2),
    stroke: 1.0pt + ink, mark: am)
  draw.content((xOut1 + 1.12, (inTop + inBot + 0.10)/2), anchor: "west",
    text(size: 8pt, weight: "bold", fill: ink)[$Y$])

  // ── the two defining equations (placed in the open band above the inset) ────
  draw.content((2.45, 3.45),
    text(size: 7.5pt, fill: ink)[$Y_l = f_(l arrow.r l)(X_l) + f_(g arrow.r l)(X_g)$])
  draw.content((8.35, 3.45),
    text(size: 7.5pt, fill: blue)[$Y_g = f_(g arrow.r g)(X_g) + f_(l arrow.r g)(X_l)$])

  // ════════════════════════════════════════════════════════════════════════
  // INSET — expand the Spectral Transform f_{g→g}
  // ════════════════════════════════════════════════════════════════════════
  let insTop = 2.65
  let insBot = -0.55
  draw.rect((0.0, insBot), (12.4, insTop), fill: none, stroke: (paint: faint, thickness: 0.7pt, dash: "dashed"), radius: 0pt)
  // dashed link from the Spectral Transform box down into the inset
  draw.line((xConv, yFgg - 0.49), (xConv, insTop + 0.02),
    stroke: (paint: garnet, thickness: 0.7pt, dash: "dashed"))
  draw.content((0.18, insTop - 0.05), anchor: "north-west",
    text(size: 8pt, weight: "bold", fill: garnet)[Spectral Transform $f_(g arrow.r g)$ — the image-wide receptive field])

  let yi = 0.85                                   // inset row baseline (box centres)
  let ibw = 1.85
  // input feed
  draw.content((0.30, yi), anchor: "east", text(size: 7pt, fill: blue)[$X_g$])
  draw.line((0.36, yi), (1.15, yi), stroke: 0.95pt + ink, mark: am)
  let sx = (1.15 + ibw/2)                         // first box centre
  opbox(sx, yi, ibw, 0.78, [FFT$#h(0.1em)_(2"d")$], [real 2-D FFT])
  let sx2 = sx + ibw + 0.95
  opbox(sx2, yi, ibw, 0.78, [concat], [$"Re" parallel "Im"$])
  let sx3 = sx2 + ibw + 0.95
  opbox(sx3, yi, ibw + 0.25, 0.78, [Conv $1 times 1$], [BN + ReLU], focal: true)
  let sx4 = sx3 + ibw + 1.2
  opbox(sx4, yi, ibw + 0.25, 0.78, [FFT$#h(0.1em)_(2"d")^(-1)$], [inverse FFT])
  // arrows between inset boxes
  draw.line((sx + ibw/2, yi),        (sx2 - ibw/2, yi),         stroke: 0.95pt + ink, mark: am)
  draw.line((sx2 + ibw/2, yi),       (sx3 - (ibw+0.25)/2, yi),  stroke: 0.95pt + ink, mark: am)
  draw.line((sx3 + (ibw+0.25)/2, yi),(sx4 - (ibw+0.25)/2, yi),  stroke: 0.95pt + ink, mark: am)
  draw.line((sx4 + (ibw+0.25)/2, yi),(sx4 + (ibw+0.25)/2 + 0.9, yi), stroke: 0.95pt + ink, mark: am)
  draw.content((sx4 + (ibw+0.25)/2 + 1.02, yi), anchor: "west", text(size: 7pt, fill: ink)[spatial])

  // tiny frequency-domain tile floating over the conv box (the spectrum being mixed)
  let nf = 6
  let cs = 0.135
  let tx = sx3 - nf*cs/2
  let ty = insTop - 0.18 - nf*cs
  for ri in range(nf) {
    for ci in range(nf) {
      // a centred low-frequency-heavy spectrum
      let dr = (ri - (nf - 1)/2) / nf
      let dc = (ci - (nf - 1)/2) / nf
      let v = calc.exp(-((dr*dr + dc*dc) * 7.0))
      draw.rect((tx + ci*cs, ty + ri*cs), (tx + (ci+1)*cs, ty + (ri+1)*cs),
        fill: ramp(v), stroke: 0.25pt + faint, radius: 0pt)
    }
  }
  draw.rect((tx, ty), (tx + nf*cs, ty + nf*cs), fill: none, stroke: 0.7pt + garnet, radius: 0pt)
  draw.content((tx + nf*cs/2, ty - 0.16), text(size: 6pt, fill: muted, style: "italic")[spectrum (Re, Im)])
  draw.line((tx + nf*cs/2, ty - 0.30), (sx3, yi + 0.40),
    stroke: (paint: faint, thickness: 0.6pt, dash: "dashed"))

  // ════════════════════════════════════════════════════════════════════════
  // title + legend
  // ════════════════════════════════════════════════════════════════════════
  draw.content((6.0, inTop + 0.95),
    text(size: 12.5pt, weight: "bold", fill: ink)[Fast Fourier Convolution layer])
  draw.content((6.0, inTop + 0.55),
    text(size: 8.5pt, fill: muted)[local + global channels; a Fourier global branch gives an image-wide receptive field in one layer])

  // legend (bottom-right, inside inset band)
  let lx = 9.4
  let ly = 1.55
  draw.line((lx, ly), (lx + 0.6, ly), stroke: 0.95pt + ink, mark: am)
  draw.content((lx + 0.72, ly), anchor: "west", text(size: 6.8pt, fill: muted)[same-domain])
  draw.line((lx, ly - 0.34), (lx + 0.6, ly - 0.34), stroke: 0.95pt + garnet, mark: ax)
  draw.content((lx + 0.72, ly - 0.34), anchor: "west", text(size: 6.8pt, fill: muted)[local ↔ global cross-talk])
})
