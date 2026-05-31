// Multi-head Latent Attention (MLA) vs regular Multi-head Attention (MHA).
// Built from architectural knowledge (DeepSeek-V2/V3): MLA compresses K,V into one
// low-rank latent c^{KV} = W_dkv x_t, then up-projects it back to per-head K and V
// (W_uk, W_uv) at inference. The cache holds only the small latent -> KV-cache savings.
// MHA materialises full K and V directly via W_k, W_v.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

#let garnet = rgb("#73000A")
#let ink = rgb("#243038")
#let muted = rgb("#5C5C5C")
#let slabfill = rgb("#ECECEC")   // generic K/Q/V slab (10% black)
#let inputfill = rgb("#000000")  // input x_t (black, white text)
#let latentfill = rgb("#FFF2E3") // compressed latent — garnet-edged beige, the key object

#let cam = cam-cabinet

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ---- helpers -------------------------------------------------------------
  // a labeled upright slab; returns nothing, label centered on the front face
  let slab(o, w, h, dep, fill, label, edge: ink, lblfill: ink, lblsize: 8.5pt) = {
    block3d(draw, origin: o, w: w, h: h, dep: dep, base: fill, edge: edge, cam: cam)
    let c = project((0, 0, -dep / 2), cam: cam, origin: o)
    draw.content(c, text(size: lblsize, fill: lblfill, weight: "bold")[#label])
  }
  // stealth arrow between two slab face-docks (world space), with optional weight label
  let conn(o1, s1, f1, o2, s2, f2, lbl: none, lblpos: "mid", dx: 0pt, dy: 0pt) = {
    let a = dock((o1.at(0), o1.at(1), 0), s1.at(0), s1.at(1), s1.at(2), f1)
    let b = dock((o2.at(0), o2.at(1), 0), s2.at(0), s2.at(1), s2.at(2), f2)
    arrow3d(draw, a, b, cam: cam, color: ink, w: 1.0pt, scale: 0.7)
    if lbl != none {
      let pa = project(a, cam: cam)
      let pb = project(b, cam: cam)
      let m = ((pa.at(0) + pb.at(0)) / 2, (pa.at(1) + pb.at(1)) / 2)
      draw.content((m.at(0) + dx / 1cm * 1, m.at(1) + dy / 1cm * 1),
        text(size: 8pt, fill: garnet, style: "italic")[#lbl])
    }
  }

  // common slab geometry
  let SW = 1.9    // slab width
  let SH = 0.62   // slab height
  let SD = 1.0    // slab depth
  let IN = (1.7, 0.62, 1.0)  // input box (w,h,dep)

  // ====================================================================== MLA
  // column x-centres
  let q-x = -1.3
  let kv-x = 1.55
  let in-x = (q-x + kv-x) / 2
  let row-top = 2.4     // input row y
  let row-mid = 0.7     // query / latent row y
  let row-bot = -1.1    // key / value row y

  // panel title
  draw.content((in-x, 4.35),
    text(size: 13pt, weight: "bold", fill: garnet)[Multi-head Latent Attention (MLA)])
  draw.content((in-x, 3.75),
    text(size: 9pt, fill: muted, style: "italic")[Inference step $t$ — caches only the latent])

  // input x_t
  let o-in = (in-x, row-top)
  slab(o-in, IN.at(0), IN.at(1), IN.at(2), inputfill, text(fill: white)[Input $x_t$], edge: ink, lblfill: white)

  // Query (direct) + Compressed latent
  let o-q = (q-x, row-mid)
  let o-c = (kv-x, row-mid)
  slab(o-q, SW, SH, SD, slabfill, [Query])
  slab(o-c, SW, SH + 0.18, SD, latentfill,
    align(center, text(fill: garnet)[Compressed\ #text(size: 7.5pt)[latent $c_t^(K V)$]]),
    edge: garnet, lblfill: garnet, lblsize: 8pt)

  // Key + Value (up-projected from latent)
  let kx = kv-x - 1.15
  let vx = kv-x + 1.15
  let o-k = (kx, row-bot)
  let o-v = (vx, row-bot)
  slab(o-k, 1.55, SH, SD, slabfill, [Key])
  slab(o-v, 1.55, SH, SD, slabfill, [Value])

  // wiring: x_t -> Query (W_q),  x_t -> latent (W_dkv)
  conn(o-in, IN, "bottom", o-q, (SW, SH, SD), "top", lbl: [$W_q$], dx: -26pt, dy: 6pt)
  conn(o-in, IN, "bottom", o-c, (SW, SH + 0.18, SD), "top", lbl: [$W_(d k v)$], dx: 18pt, dy: 6pt)
  // latent -> Key (W_uk),  latent -> Value (W_uv)
  conn(o-c, (SW, SH + 0.18, SD), "bottom", o-k, (1.55, SH, SD), "top", lbl: [$W_(u k)$], dx: -20pt, dy: 4pt)
  conn(o-c, (SW, SH + 0.18, SD), "bottom", o-v, (1.55, SH, SD), "top", lbl: [$W_(u v)$], dx: 18pt, dy: 4pt)

  // dashed frame around the MLA panel
  draw.rect((-3.0, -2.05), (3.55, 3.35), stroke: (paint: garnet, thickness: 1.1pt, dash: "densely-dotted"))

  // key-idea callout
  draw.content((1.55, -2.55), anchor: "north",
    box(width: 5.6cm)[#align(center, text(size: 8pt, fill: garnet)[
      *Key idea:* only $c_t^(K V)$ is cached; $K$ and $V$ are reconstructed on the fly,
      cutting KV-cache memory.])])

  // ====================================================================== MHA
  let DX = 9.6   // horizontal offset for the MHA panel
  let m-q = -2.0 + DX
  let m-k = 0.0 + DX
  let m-v = 2.0 + DX
  let m-in = m-k

  draw.content((m-in, 4.35),
    text(size: 13pt, weight: "bold", fill: ink)[Regular Multi-head Attention (MHA)])
  draw.content((m-in, 3.75),
    text(size: 9pt, fill: muted, style: "italic")[Inference step $t$ — caches full $K$ and $V$])

  let mo-in = (m-in, row-top)
  slab(mo-in, IN.at(0), IN.at(1), IN.at(2), inputfill, text(fill: white)[Input $x_t$], edge: ink, lblfill: white)

  let mo-q = (m-q, row-mid)
  let mo-k = (m-k, row-mid)
  let mo-v = (m-v, row-mid)
  slab(mo-q, SW, SH, SD, slabfill, [Query])
  slab(mo-k, SW, SH, SD, slabfill, [Key])
  slab(mo-v, SW, SH, SD, slabfill, [Value])

  conn(mo-in, IN, "bottom", mo-q, (SW, SH, SD), "top", lbl: [$W_q$], dx: -22pt, dy: 8pt)
  conn(mo-in, IN, "bottom", mo-k, (SW, SH, SD), "top", lbl: [$W_k$], dx: -14pt, dy: -2pt)
  conn(mo-in, IN, "bottom", mo-v, (SW, SH, SD), "top", lbl: [$W_v$], dx: 22pt, dy: 8pt)

  draw.rect((-3.0 + DX, -0.25), (3.0 + DX, 3.35),
    stroke: (paint: ink, thickness: 1.0pt, dash: "densely-dotted"))
})
