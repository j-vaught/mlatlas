// mlatlas · Gridworld value function V(s) + greedy policy field — the canonical
// reinforcement-learning toy-domain visualization (Sutton & Barto; Kochenderfer).
//
// A 6×5 grid of states. Each cell is shaded by its state-value V(s) on a
// garnet→beige ramp (low value = deep garnet, high value = beige), and carries
// the greedy action arg max_a Σ P(s'|s,a)[r + γ V(s')] as a stealth arrow.
// Two absorbing terminals — a +1 goal and a −1 trap — and four wall cells (no
// state). The value field and the policy below are the EXACT fixed point of
// value iteration on this MDP (γ = 0.9, step cost −0.04, deterministic moves),
// so the heatmap and the arrows are mutually consistent.
#import "../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern")

#cetz.canvas(length: 1cm, {
  import cetz.draw

  // ── palette ─────────────────────────────────────────────────────────────
  let p = (
    edge:  rgb("#363636"),
    text:  rgb("#1A1A1A"),
    muted: rgb("#5C5C5C"),
    grid:  rgb("#5C5C5C"),
    wall:  rgb("#363636"),     // obstacle fill
    goal:  rgb("#65780B"),     // dark-green terminal accent (+1)
    trap:  rgb("#CC2E40"),     // pink-red terminal accent (−1)
    garnet: rgb("#73000A"),
  )

  // garnet → beige value ramp.  t in [0,1]: 0 = lowest value, 1 = highest.
  // interpolate garnet (115,0,10) → ugly-brown-ish mid → beige (255,242,227).
  let lerp(a, b, t) = a + (b - a) * t
  let ramp(t) = {
    // two-segment ramp through a warm mid-tone for readable contrast
    let mid = (199, 96, 58)              // warm clay
    let lo = (115, 0, 10)                // garnet
    let hi = (255, 242, 227)             // beige
    let c = if t < 0.5 {
      let u = t / 0.5
      (lerp(lo.at(0), mid.at(0), u), lerp(lo.at(1), mid.at(1), u), lerp(lo.at(2), mid.at(2), u))
    } else {
      let u = (t - 0.5) / 0.5
      (lerp(mid.at(0), hi.at(0), u), lerp(mid.at(1), hi.at(1), u), lerp(mid.at(2), hi.at(2), u))
    }
    rgb(int(c.at(0)), int(c.at(1)), int(c.at(2)))
  }
  // luminance-aware text color for a cell fill: white on the darker (lower-value)
  // end of the ramp, dark ink on the light beige (high-value) end.
  let on(fill-rgb-t) = if fill-rgb-t < 0.66 { rgb("#FFFFFF") } else { rgb("#1A1A1A") }

  // ── grid geometry ───────────────────────────────────────────────────────
  let W = 6
  let H = 5
  let S = 1.55                  // cell size (cm)
  let ox = 0                    // left edge
  let oy = 0                    // bottom edge
  // cell center for column c (0..W-1), row r (0..H-1), row 0 at bottom
  let cx(c) = ox + (c + 0.5) * S
  let cy(r) = oy + (r + 0.5) * S

  // ── the MDP solution (value iteration fixed point) ─────────────────────
  // each entry: "c,r" -> (V, action | none).  terminals carry their reward.
  let walls = ((2, 1), (2, 2), (2, 3), (4, 3))
  let goal = (5, 4)
  let trap = (5, 1)
  let V = (
    "0,0": (0.142, "N"), "1,0": (0.203, "N"), "2,0": (0.270, "E"), "3,0": (0.344, "N"), "4,0": (0.427, "N"), "5,0": (0.344, "W"),
    "0,1": (0.203, "N"), "1,1": (0.270, "N"),                       "3,1": (0.427, "N"), "4,1": (0.519, "N"), "5,1": (-1.000, none),
    "0,2": (0.270, "N"), "1,2": (0.344, "N"),                       "3,2": (0.519, "N"), "4,2": (0.621, "E"), "5,2": (0.734, "N"),
    "0,3": (0.344, "N"), "1,3": (0.427, "N"),                       "3,3": (0.621, "N"),                       "5,3": (0.860, "N"),
    "0,4": (0.427, "E"), "1,4": (0.519, "E"), "2,4": (0.621, "E"), "3,4": (0.734, "E"), "4,4": (0.860, "E"), "5,4": (1.000, none),
  )
  // value range used for the color ramp (non-terminal span)
  let vmin = 0.142
  let vmax = 1.000
  let tnorm(v) = (v - vmin) / (vmax - vmin)

  // action unit vectors (grid up = +y)
  let dirs = ("N": (0, 1), "S": (0, -1), "E": (1, 0), "W": (-1, 0))

  let is-wall(c, r) = walls.contains((c, r))

  // ── draw cells ──────────────────────────────────────────────────────────
  for r in range(H) {
    for c in range(W) {
      let x0 = ox + c * S
      let y0 = oy + r * S
      let x1 = x0 + S
      let y1 = y0 + S
      let mid = (cx(c), cy(r))
      if is-wall(c, r) {
        // obstacle: solid dark block, hatched feel via fill + label
        draw.rect((x0, y0), (x1, y1), fill: p.wall, stroke: 1pt + p.grid, radius: 0pt)
        draw.content(mid, text(size: 8pt, fill: rgb("#C7C7C7"), style: "italic")[wall])
        continue
      }
      let key = str(c) + "," + str(r)
      let cell = V.at(key)
      let v = cell.at(0)
      let act = cell.at(1)
      let is-goal = (c, r) == goal
      let is-trap = (c, r) == trap

      // fill colour
      let t = tnorm(v)
      let fill-c = if is-trap { p.trap } else { ramp(t) }
      draw.rect((x0, y0), (x1, y1), fill: fill-c, stroke: 1pt + p.grid, radius: 0pt)

      // terminal accents: thick coloured border + symbol; non-terminals: arrow
      if is-goal {
        draw.rect((x0, y0), (x1, y1), fill: none, stroke: 2.6pt + p.goal, radius: 0pt)
        draw.content((cx(c), cy(r) + 0.30 * S), text(size: 15pt, weight: "bold", fill: p.goal)[$+1$])
        draw.content((cx(c), cy(r) - 0.26 * S), text(size: 8.5pt, fill: p.goal, style: "italic")[goal])
      } else if is-trap {
        draw.rect((x0, y0), (x1, y1), fill: none, stroke: 2.6pt + rgb("#7A0010"), radius: 0pt)
        draw.content((cx(c), cy(r) + 0.30 * S), text(size: 15pt, weight: "bold", fill: rgb("#FFFFFF"))[$-1$])
        draw.content((cx(c), cy(r) - 0.26 * S), text(size: 8.5pt, fill: rgb("#FFE3E6"), style: "italic")[trap])
      } else {
        // greedy policy arrow, centred in the cell
        let d = dirs.at(act)
        let L = 0.30 * S
        let a0 = (cx(c) - d.at(0) * L, cy(r) - d.at(1) * L)
        let a1 = (cx(c) + d.at(0) * L, cy(r) + d.at(1) * L)
        let acol = on(t)
        draw.line(a0, a1, stroke: 2.2pt + acol, mark: (end: "stealth", scale: 0.7))
        // value label in the cell corner
        draw.content(
          (x0 + 0.18, y0 + 0.18),
          anchor: "south-west",
          text(size: 7.5pt, fill: on(t))[#{ let s = str(calc.round(v, digits: 2)); s }],
        )
      }
    }
  }

  // grid frame (over the fills)
  draw.rect((ox, oy), (ox + W * S, oy + H * S), fill: none, stroke: 1.4pt + p.edge, radius: 0pt)

  // ── axis-style row / column indices ──────────────────────────────────────
  for c in range(W) {
    draw.content((cx(c), oy - 0.42), text(size: 8pt, fill: p.muted)[#c])
  }
  for r in range(H) {
    draw.content((ox - 0.42, cy(r)), anchor: "east", text(size: 8pt, fill: p.muted)[#r])
  }
  draw.content((ox + W * S / 2, oy - 0.95), text(size: 9pt, fill: p.text)[column])
  draw.content((ox - 1.15, oy + H * S / 2), anchor: "south", text(size: 9pt, fill: p.text)[#rotate(-90deg, reflow: true)[row]])

  // ── title ─────────────────────────────────────────────────────────────
  draw.content(
    (ox + W * S / 2, oy + H * S + 0.95),
    text(size: 12pt, weight: "bold", fill: p.text)[Gridworld: state-value $V(s)$ and greedy policy $pi(s)$],
  )
  draw.content(
    (ox + W * S / 2, oy + H * S + 0.42),
    text(size: 8.5pt, fill: p.muted, style: "italic")[value iteration fixed point · $gamma = 0.9$ · step cost $-0.04$],
  )

  // ══════════════════════════════════════════════════════════════════════
  //  COLORBAR — value ramp legend, to the right of the grid
  // ══════════════════════════════════════════════════════════════════════
  let bx = ox + W * S + 0.8     // left of bar
  let bw = 0.55                 // bar width
  let by = oy + 0.4             // bottom of bar
  let bh = H * S - 0.8          // bar height
  let NB = 48
  for i in range(NB) {
    let t0 = i / NB
    let t1 = (i + 1) / NB
    let yy0 = by + t0 * bh
    let yy1 = by + t1 * bh
    draw.rect((bx, yy0), (bx + bw, yy1), fill: ramp((t0 + t1) / 2), stroke: none)
  }
  draw.rect((bx, by), (bx + bw, by + bh), fill: none, stroke: 1pt + p.edge, radius: 0pt)
  // ticks: map value -> bar position
  let ticks = (0.142, 0.4, 0.6, 0.8, 1.0)
  for tv in ticks {
    let yy = by + tnorm(tv) * bh
    draw.line((bx + bw, yy), (bx + bw + 0.12, yy), stroke: 0.9pt + p.edge)
    draw.content((bx + bw + 0.20, yy), anchor: "west", text(size: 7.5pt, fill: p.muted)[#calc.round(tv, digits: 2)])
  }
  draw.content(
    (bx + bw / 2, by + bh + 0.40),
    text(size: 8.5pt, fill: p.text)[$V(s)$],
  )
  // end labels placed inside the bar with luminance-matched text
  draw.content((bx + bw / 2, by + bh - 0.22), text(size: 6.5pt, fill: rgb("#5C5C5C"))[high])
  draw.content((bx + bw / 2, by + 0.22), text(size: 6.5pt, fill: rgb("#FFE3DA"))[low])
})
