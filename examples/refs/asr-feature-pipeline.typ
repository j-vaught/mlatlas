// mlatlas · ASR front-end feature pipeline (spectrogram + MFCC).
// The classic speech-recognition front end (Jurafsky & Martin, SLP3):
//   waveform → STFT → spectrogram (time×frequency heatmap) → mel filterbank
//   → log → DCT → MFCC vectors fed to the acoustic model.
// A box-and-arrow flow names every stage; under it three real panels show the
// signal actually transforming: a raw waveform, the time×frequency spectrogram
// heatmap (beige→garnet luma ramp, the new grid-heatmap primitive), the
// triangular mel filterbank, and the resulting stack of MFCC feature vectors.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

// ── palette ───────────────────────────────────────────────────────────────────
#let p = (
  ink:    rgb("#1A1A1A"),
  text:   rgb("#222222"),
  muted:  rgb("#5C5C5C"),
  edge:   rgb("#363636"),
  grid:   rgb("#A2A2A2"),
  faint:  rgb("#C7C7C7"),
  beige:  rgb("#FFF2E3"),
  blue:   rgb("#466A9F"),
  garnet: rgb("#73000A"),
)

// sequential ramp: beige (t=0) → garnet (t=1), interpolated in oklab.
#let ramp(t) = {
  let t = calc.max(0.0, calc.min(1.0, t))
  p.beige.mix((p.garnet, t * 100%), space: oklab)
}
#let on-fill(t) = if t > 0.55 { white } else { p.ink }

// ── synthetic-but-plausible spectrogram field ──────────────────────────────────
// A formant-like energy field: a few horizontal voiced bands (formants) that
// drift over time, plus a broadband burst (a plosive) near one time frame.
#let nT = 28          // time frames (columns)
#let nF = 20          // frequency bins (rows, low freq at bottom)
#let spec = ()
#for fi in range(nF) {
  let row = ()
  for ti in range(nT) {
    let tt = ti / (nT - 1)
    let ff = fi / (nF - 1)
    // three formants whose centre frequency wobbles with time
    let f1 = 0.16 + 0.05 * calc.sin(tt * 6.0)
    let f2 = 0.42 + 0.07 * calc.sin(tt * 4.0 + 1.0)
    let f3 = 0.68 + 0.05 * calc.sin(tt * 5.0 + 2.0)
    let band(c, w, a) = a * calc.exp(-(calc.pow((ff - c) / w, 2)))
    let v = band(f1, 0.05, 1.0) + band(f2, 0.055, 0.82) + band(f3, 0.06, 0.6)
    // a broadband plosive burst around frame 18
    v = v + 0.95 * calc.exp(-(calc.pow((tt - 0.66) / 0.03, 2))) * (0.35 + 0.65 * ff)
    // gentle overall low-frequency emphasis + a quiet onset
    v = v * (0.35 + 0.65 * calc.min(1.0, tt * 5.0))
    v = v + 0.03
    // contrast boost (gamma < 1 darkens the strong bands)
    v = calc.pow(calc.min(1.0, v), 0.7)
    row.push(calc.min(1.0, v))
  }
  spec.push(row)
}

// ── geometry ────────────────────────────────────────────────────────────────
#let cw = 0.165               // spectrogram cell width  (cm)
#let ch = 0.165               // spectrogram cell height (cm)
#let specW = nT * cw
#let specH = nF * ch

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // small arrow between flow boxes
  let flowmark = (end: (symbol: "stealth", fill: p.edge, scale: 0.5))

  // ════════════════════════════════════════════════════════════════════════
  // ROW 1 — the box-and-arrow pipeline (named stages)
  // ════════════════════════════════════════════════════════════════════════
  let bh = 0.78                       // box height
  let by = 9.7                        // baseline y of the flow row
  // (label, sub, width, focal?)
  let stages = (
    ([Waveform],          [$s[n]$],         1.55, false),
    ([STFT],              [windowed FFT],   1.55, false),
    ([Spectrogram],       [time×freq],      2.05, true),
    ([Mel filterbank],    [$~26$ triangles],2.00, false),
    ([log],               [$log(·)$],       1.10, false),
    ([DCT],               [decorrelate],    1.55, false),
    ([MFCC],              [$c_1..c_(12)$],  1.55, true),
    ([Acoustic model],    [GMM / DNN],      2.05, false),
  )
  // place boxes left→right with uniform gaps
  let gap = 0.62
  let xs = ()                         // store (x0, x1, cx) of each box
  let cx = 0.0
  for (lbl, sub, w, focal) in stages {
    let x0 = cx
    let x1 = cx + w
    let xc = (x0 + x1) / 2
    let stk = if focal { 1.8pt + p.garnet } else { 1.1pt + p.edge }
    let fil = if focal { p.beige } else { white }
    draw.rect((x0, by), (x1, by + bh), fill: fil, stroke: stk, radius: 0pt)
    draw.content((xc, by + bh * 0.66), text(size: 9pt, fill: p.ink, weight: "bold")[#lbl])
    draw.content((xc, by + bh * 0.27), text(size: 7pt, fill: p.muted)[#sub])
    xs.push((x0, x1, xc))
    cx = x1 + gap
  }
  // arrows between consecutive boxes
  for i in range(stages.len() - 1) {
    let a = xs.at(i)
    let b = xs.at(i + 1)
    draw.line((a.at(1), by + bh / 2), (b.at(0), by + bh / 2), stroke: 1pt + p.edge, mark: flowmark)
  }
  let flowRight = xs.last().at(1)     // right edge of last flow box

  // ════════════════════════════════════════════════════════════════════════
  // The four signal PANELS sit below, linked to their pipeline stage by a
  // light dashed drop-line so the reader sees the signal transforming.
  // ════════════════════════════════════════════════════════════════════════
  let panelTop = 7.6                  // top y of the panel band
  let panelBot = 0.0
  let panelH = panelTop - panelBot

  // helper: dashed connector from a flow box down to a panel's top-centre
  let droplink(stageIdx, px) = {
    let sx = xs.at(stageIdx).at(2)
    draw.line(
      (sx, by - 0.04), (sx, by - 0.30), (px, by - 0.55), (px, panelTop + 0.18),
      stroke: (paint: p.faint, thickness: 0.7pt, dash: "dashed"),
    )
  }

  // ── PANEL A: raw waveform (under "Waveform") ───────────────────────────────
  let wfX = 0.0
  let wfW = 2.7
  let wfTop = panelTop
  let wfBot = panelTop - 1.7
  let wfMid = (wfTop + wfBot) / 2
  let wfH = (wfTop - wfBot)
  draw.rect((wfX, wfBot), (wfX + wfW, wfTop), fill: white, stroke: 0.9pt + p.edge, radius: 0pt)
  // zero axis
  draw.line((wfX, wfMid), (wfX + wfW, wfMid), stroke: 0.5pt + p.faint)
  // a little speech-like waveform: amplitude-modulated sum of tones
  let nW = 130
  let pts = range(nW + 1).map(k => {
    let u = k / nW
    let x = wfX + u * wfW
    let env = calc.exp(-(calc.pow((u - 0.5) / 0.42, 2)))
    let s = env * (calc.sin(u * 58.0) * 0.6 + calc.sin(u * 23.0 + 1.0) * 0.4)
    let y = wfMid + s * (wfH / 2 - 0.07)
    (x, y)
  })
  draw.line(..pts, stroke: 0.9pt + p.ink)
  draw.content((wfX + wfW / 2, wfBot - 0.22), text(size: 8pt, fill: p.text, weight: "bold")[waveform $s[n]$])
  draw.content((wfX + wfW / 2, wfBot - 0.50), text(size: 6.5pt, fill: p.muted)[amplitude vs. time])
  droplink(0, wfX + wfW / 2)

  // ── PANEL B: spectrogram heatmap (under "Spectrogram") ─────────────────────
  // anchored so its block sits roughly under the Spectrogram box
  let spX = 3.45
  let spY = panelTop - specH - 0.0   // place with top near panelTop
  // shift down a touch so axis labels fit; recompute bottom
  let spBot = spY
  let spTop = spY + specH
  for fi in range(nF) {
    for ti in range(nT) {
      let v = spec.at(fi).at(ti)
      let xx = spX + ti * cw
      let yy = spBot + fi * ch          // fi=0 is low freq at bottom
      draw.rect((xx, yy), (xx + cw, yy + ch), fill: ramp(v), stroke: none)
    }
  }
  draw.rect((spX, spBot), (spX + specW, spTop), fill: none, stroke: 1.0pt + p.edge, radius: 0pt)
  // axes
  draw.line((spX, spBot), (spX, spTop), stroke: 0.8pt + p.edge)
  draw.line((spX, spBot), (spX + specW, spBot), stroke: 0.8pt + p.edge)
  draw.content((spX + specW / 2, spBot - 0.30), text(size: 8pt, fill: p.text, weight: "bold")[spectrogram])
  draw.content((spX + specW / 2, spBot - 0.56), text(size: 6.5pt, fill: p.muted)[time →])
  draw.content((spX - 0.30, spBot + specH / 2), anchor: "south", angle: 90deg, text(size: 6.5pt, fill: p.muted)[frequency →])
  // formant annotation arrow
  draw.line(
    (spX + specW + 0.05, spBot + specH * 0.42),
    (spX + specW - 0.55, spBot + specH * 0.42),
    stroke: 0.7pt + p.garnet, mark: (end: (symbol: "stealth", fill: p.garnet, scale: 0.4)),
  )
  draw.content((spX + specW + 0.08, spBot + specH * 0.42), anchor: "west", text(size: 6.5pt, fill: p.garnet, style: "italic")[formants])
  droplink(2, spX + specW / 2)

  // ── PANEL C: mel filterbank (under "Mel filterbank") ───────────────────────
  let mbX = spX + specW + 1.35
  let mbW = 3.0
  let mbBot = panelTop - 1.7
  let mbTop = panelTop
  let mbH = mbTop - mbBot
  draw.rect((mbX, mbBot), (mbX + mbW, mbTop), fill: white, stroke: 0.9pt + p.edge, radius: 0pt)
  draw.line((mbX, mbBot), (mbX + mbW, mbBot), stroke: 0.7pt + p.edge)
  // overlapping triangular filters, centres mel-spaced (denser at low freq)
  let nFilt = 8
  // mel-like centres: quadratic spacing → narrow & dense at left, wide at right
  let centres = range(nFilt).map(k => {
    let u = (k + 1) / (nFilt + 1)
    calc.pow(u, 1.6)
  })
  for (k, c) in centres.enumerate() {
    // half-width = distance to neighbours (triangles meet at neighbour centres)
    let lo = if k == 0 { 0.0 } else { centres.at(k - 1) }
    let hi = if k == nFilt - 1 { 1.0 } else { centres.at(k + 1) }
    let xl = mbX + lo * mbW
    let xc = mbX + c * mbW
    let xr = mbX + hi * mbW
    let yb = mbBot
    let yt = mbBot + mbH * 0.86
    let fc = if k == 3 { p.garnet } else { p.blue }
    let lw = if k == 3 { 1.3pt } else { 0.8pt }
    draw.line((xl, yb), (xc, yt), (xr, yb), stroke: lw + fc)
  }
  draw.content((mbX + mbW / 2, mbBot - 0.30), text(size: 8pt, fill: p.text, weight: "bold")[mel filterbank])
  draw.content((mbX + mbW / 2, mbBot - 0.56), text(size: 6.5pt, fill: p.muted)[triangular, mel-spaced])
  droplink(3, mbX + mbW / 2)

  // ── PANEL D: MFCC feature vectors (under "MFCC") ───────────────────────────
  // a stack of coefficient columns over a few frames — small heatmap of c_i
  let nCoef = 13          // rows: MFCC coefficients c0..c12
  let nFr = 10            // columns: successive analysis frames
  let mc = 0.18           // cell size
  let mfX = mbX + mbW + 1.55
  let mfBot = panelTop - nCoef * mc
  let mfTop = panelTop
  // synthetic MFCC values: low-index coeffs large, decaying; sign varies by frame
  for ci in range(nCoef) {
    for fr in range(nFr) {
      let decay = calc.exp(-ci * 0.35)
      let val = decay * calc.sin(fr * 0.9 + ci * 1.3)
      let t = (val + 1) / 2      // map −1..1 → 0..1
      // emphasise magnitude for the luma ramp
      let mag = calc.abs(val)
      let xx = mfX + fr * mc
      let yy = mfBot + (nCoef - 1 - ci) * mc   // c0 at top
      draw.rect((xx, yy), (xx + mc, yy + mc), fill: ramp(mag), stroke: 0.3pt + p.faint, radius: 0pt)
    }
  }
  let mfW = nFr * mc
  let mfH = nCoef * mc
  draw.rect((mfX, mfBot), (mfX + mfW, mfTop), fill: none, stroke: 1.0pt + p.garnet, radius: 0pt)
  // highlight one frame-column = one MFCC vector
  draw.rect(
    (mfX + 3 * mc, mfBot), (mfX + 4 * mc, mfTop),
    fill: none, stroke: 1.4pt + p.garnet, radius: 0pt,
  )
  draw.line(
    (mfX + 3.5 * mc, mfTop + 0.05), (mfX + 3.5 * mc, mfTop + 0.40),
    stroke: 0.7pt + p.garnet, mark: (start: (symbol: "stealth", fill: p.garnet, scale: 0.4)),
  )
  draw.content((mfX + 3.5 * mc, mfTop + 0.44), anchor: "south", text(size: 6.5pt, fill: p.garnet, style: "italic")[one frame = 1 vector])
  // coefficient axis labels
  draw.content((mfX - 0.12, mfTop - 0.5 * mc), anchor: "east", text(size: 6pt, fill: p.muted)[$c_0$])
  draw.content((mfX - 0.12, mfBot + 0.5 * mc), anchor: "east", text(size: 6pt, fill: p.muted)[$c_(12)$])
  draw.content((mfX + mfW / 2, mfBot - 0.30), text(size: 8pt, fill: p.text, weight: "bold")[MFCC vectors])
  draw.content((mfX + mfW / 2, mfBot - 0.56), text(size: 6.5pt, fill: p.muted)[$13$ coeffs × frames])
  droplink(6, mfX + mfW / 2)

  // ── shared colourbar for the two heatmaps ─────────────────────────────────
  let cbX = mfX + mfW + 0.75
  let cbW = 0.26
  let cbBot = panelTop - 2.4
  let cbTop = panelTop
  let cbH = cbTop - cbBot
  let nseg = 32
  for s in range(nseg) {
    let t0 = s / nseg
    let t1 = (s + 1) / nseg
    draw.rect((cbX, cbBot + t0 * cbH), (cbX + cbW, cbBot + t1 * cbH), fill: ramp((t0 + t1) / 2), stroke: none)
  }
  draw.rect((cbX, cbBot), (cbX + cbW, cbTop), fill: none, stroke: 0.7pt + p.edge, radius: 0pt)
  draw.content((cbX + cbW + 0.10, cbTop), anchor: "west", text(size: 6.5pt, fill: p.muted)[high])
  draw.content((cbX + cbW + 0.10, cbBot), anchor: "west", text(size: 6.5pt, fill: p.muted)[low])
  draw.content((cbX + cbW / 2, cbTop + 0.18), anchor: "south", text(size: 6.5pt, fill: p.muted)[energy])

  // ════════════════════════════════════════════════════════════════════════
  // title
  // ════════════════════════════════════════════════════════════════════════
  draw.content(
    (flowRight / 2, by + bh + 0.95),
    text(size: 12.5pt, fill: p.ink, weight: "bold")[ASR front-end: waveform to MFCC features],
  )
})
