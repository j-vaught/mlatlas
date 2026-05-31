// DeepSeekMoE — shared-expert isolation: one always-on shared expert (S) plus a pool of
// fine-grained routed experts (E1..EN), of which the router activates the top-K. Output is the
// sum of the shared expert and the K selected routed experts. Composed from 3-D slabs.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 8pt)

// ---- brand palette ----------------------------------------------------------
#let garnet = rgb("#73000A")
#let blue = rgb("#466A9F")
#let green = rgb("#65780B")
#let ink = rgb("#243038")
#let muted = rgb("#5C5C5C")
#let routed-fill = rgb("#466A9F").lighten(62%) // soft blue routed experts
#let routed-on = rgb("#466A9F").lighten(30%) // selected (active) routed expert
#let shared-fill = rgb("#65780B").lighten(58%) // green shared expert
#let off = rgb("#ECECEC")

#cetz.canvas(length: 1cm, {
  import cetz.draw
  let cam = cam-cabinet // upright front faces — best for a labeled row

  // geometry ------------------------------------------------------------------
  let ew = 1.05 // expert slab width
  let eh = 1.55 // expert slab height
  let edp = 0.9 // depth
  let gap = 1.55 // x spacing between expert centers
  let row-y = 0.0 // y of the expert row

  // x positions: shared expert first, then routed experts (with a "…" elision)
  let xs = 0.0 // shared expert
  let x1 = xs + 1.85 // gap after shared (visual separation)
  let routed-x = (x1, x1 + gap, x1 + 2 * gap, x1 + 3 * gap) // E1 E2 E3 E4
  let xN1 = routed-x.last() + gap + 0.55 // E(N-1)
  let xN = xN1 + gap // E(N)
  let selected = (routed-x.at(0), routed-x.at(2)) // which routed experts the router picked

  // helper: projected anchor on a slab at row-y -------------------------------
  let A(x, ax) = {
    let a = block3d-anchors(origin: (x, row-y), w: ew, h: eh, dep: edp, cam: cam)
    (a.anchor)(ax)
  }
  let topc(x) = A(x, "top")
  let botc(x) = A(x, "bottom")

  // router + hidden nodes geometry --------------------------------------------
  let router-y = -2.7
  let router-c = ((xs + x1) / 2 + 0.4, router-y)
  let rw = 1.7
  let rh = 0.62
  let in-y = -4.35 // input hidden
  let out-y = 3.2 // output hidden
  let hub-x = router-c.at(0)

  // === (1) expert slabs ======================================================
  // shared expert (always on) — green
  tensor3d(
    draw, origin: (xs, row-y), w: ew, h: eh, dep: edp,
    base: shared-fill, edge: ink, cam: cam, seams: (0.5,),
    title: text(fill: green, weight: "bold")[Shared],
  )
  // routed experts — selected ones are saturated blue, others soft/greyed
  let routed = (
    (routed-x.at(0), [E#sub[1]], true),
    (routed-x.at(1), [E#sub[2]], false),
    (routed-x.at(2), [E#sub[3]], true),
    (routed-x.at(3), [E#sub[4]], false),
    (xN1, [E#sub[N-1]], false),
    (xN, [E#sub[N]], false),
  )
  for (x, lbl, on) in routed {
    tensor3d(
      draw, origin: (x, row-y), w: ew, h: eh, dep: edp,
      base: if on { routed-on } else { routed-fill }, edge: ink, cam: cam,
      title: text(fill: if on { blue } else { muted })[#lbl],
    )
  }
  // elision "…" between E4 and E(N-1)
  draw.content(((routed-x.at(3) + xN1) / 2, row-y), text(fill: muted, size: 13pt)[$dots.c$])

  // === (2) input hidden ======================================================
  let cell-w = 0.42
  let draw-hidden(cx, cy, lbl, anchor) = {
    for (i, dx) in (-cell-w / 2, cell-w / 2).enumerate() {
      draw.rect(
        (cx + dx - cell-w / 2 + 0.02, cy - 0.26), (cx + dx + cell-w / 2 - 0.02, cy + 0.26),
        fill: white, stroke: 0.8pt + ink,
      )
    }
    draw.content((cx, cy + (if anchor == "below" { -0.62 } else { 0.62 })), text(fill: muted)[#lbl])
  }
  draw-hidden(hub-x, in-y, [Input hidden $bold(u)_t$], "below")
  draw-hidden(hub-x, out-y, [Output hidden $bold(h)_t$], "above")

  // === (3) router block ======================================================
  draw.rect(
    (router-c.at(0) - rw / 2, router-c.at(1) - rh / 2),
    (router-c.at(0) + rw / 2, router-c.at(1) + rh / 2),
    fill: rgb("#FFF2E3"), stroke: 1pt + garnet,
  )
  draw.content(router-c, text(fill: garnet, weight: "bold")[Router])
  // top-K bars next to the router
  let bar-x0 = router-c.at(0) + rw / 2 + 0.28
  let bars = (0.30, 0.55, 0.22, 0.42)
  for (i, bh) in bars.enumerate() {
    let bx = bar-x0 + i * 0.18
    let sel = (i == 1 or i == 3)
    draw.rect(
      (bx, router-c.at(1) - rh / 2), (bx + 0.13, router-c.at(1) - rh / 2 + bh),
      fill: if sel { garnet } else { rgb("#C7C7C7") }, stroke: none,
    )
  }
  draw.content(
    (bar-x0 + 4 * 0.18 + 0.34, router-c.at(1)),
    anchor: "west", text(fill: muted)[$K=2$ routed],
  )

  // === (4) arrows ============================================================
  let stealth = (end: (symbol: "stealth", fill: ink, scale: 0.55))
  let stealth-g = (end: (symbol: "stealth", fill: garnet, scale: 0.55))

  // input hidden -> router (gating signal), garnet dashed
  draw.line(
    (hub-x, in-y + 0.3), (router-c.at(0), router-c.at(1) - rh / 2),
    stroke: 0.9pt + garnet, mark: stealth-g,
  )
  // input hidden -> shared expert (always-on), green solid
  draw.line(
    (hub-x, in-y + 0.3), botc(xs),
    stroke: 1pt + green, mark: (end: (symbol: "stealth", fill: green, scale: 0.55)),
  )
  // router -> each routed expert (gating arrows). Selected = solid garnet; others = thin grey dashed
  for (x, lbl, on) in routed {
    let target = botc(x)
    if on {
      draw.line(
        (router-c.at(0), router-c.at(1) + rh / 2), target,
        stroke: 0.95pt + garnet, mark: stealth-g,
      )
    } else {
      draw.line(
        (router-c.at(0), router-c.at(1) + rh / 2), target,
        stroke: (paint: muted, thickness: 0.5pt, dash: "densely-dotted"),
      )
    }
  }

  // experts -> output hidden (sum). Shared + selected routed contribute (solid); others none.
  let out-anchor = (hub-x, out-y - 0.32)
  // shared
  draw.line(
    topc(xs), out-anchor,
    stroke: 1pt + green, mark: (end: (symbol: "stealth", fill: green, scale: 0.55)),
  )
  for (x, lbl, on) in routed {
    if on {
      draw.line(topc(x), out-anchor, stroke: 0.95pt + blue, mark: (end: (symbol: "stealth", fill: blue, scale: 0.55)))
    }
  }

  // === (5) legend ============================================================
  let lg-x = xN + 1.35
  let lg-y = row-y + 0.55
  let legend(cy, col, lbl) = {
    draw.rect((lg-x, cy - 0.16), (lg-x + 0.36, cy + 0.16), fill: col, stroke: 0.7pt + ink)
    draw.content((lg-x + 0.5, cy), anchor: "west", text(fill: muted, size: 7.5pt)[#lbl])
  }
  legend(lg-y, shared-fill, [Shared expert\ (always active)])
  legend(lg-y - 0.95, routed-on, [Routed expert\ (selected, top-K)])
  legend(lg-y - 1.9, routed-fill, [Routed expert\ (inactive)])

  // === (6) title / subtitle ==================================================
  draw.content(
    (hub-x, out-y + 1.95),
    text(weight: "bold", size: 11pt, fill: ink)[DeepSeekMoE — Shared-Expert Isolation],
  )
  draw.content(
    (hub-x, out-y + 1.35),
    text(size: 8.5pt, fill: muted)[$ bold(h)_t = bold(u)_t + "FFN"^"(s)" (bold(u)_t) + sum_(i in cal(T)) g_i dot "FFN"^"(r)"_i (bold(u)_t) $],
  )
})
