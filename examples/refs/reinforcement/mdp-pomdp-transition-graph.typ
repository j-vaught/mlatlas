// MDP / POMDP transition graph.
//   TOP — a Markov Decision Process as a directed graph: circular STATE nodes
//   s ∈ {s0,s1,s2}; from each state an ACTION (small filled square glyph, a ∈
//   {a0,a1}) fans out into one or more stochastic transitions. Each directed
//   edge state→action→state' carries a transition probability p = P(s'|s,a)
//   and a reward r = R(s,a,s'). The action squares make the two-stage
//   "choose action, then nature samples s'" structure explicit — the defining
//   feature of an MDP versus a plain Markov chain.
//
//   BOTTOM — the POMDP extension: the same dynamics now run over a HIDDEN
//   state layer (dashed, shaded), and the agent never sees s directly; each
//   hidden state EMITS an observation o (square obs node) through an emission
//   distribution Z(o|s') = P(o|s'). Belief over hidden states replaces the
//   state itself as the decision variable.
//
// Standard teaching figure (Sutton & Barto; Kochenderfer DMU; Prince UDL),
// built from first principles in mlatlas's print-first house style. Not traced.
#import "../../../lib.typ": *
#import "@preview/cetz:0.5.2"
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#set text(font: "New Computer Modern", size: 9pt)

// ── brand palette ─────────────────────────────────────────────────────────
#let garnet = rgb("#73000A") // sparse accent — focal action / reward edge
#let ink    = rgb("#1A1A1A")
#let muted  = rgb("#5C5C5C")
#let edge   = rgb("#363636")
#let statef = rgb("#ECECEC") // 10% black — state fill
#let hidf   = rgb("#C7C7C7") // 30% black — hidden state fill
#let actf   = rgb("#363636") // 90% black — action square fill
#let obsf   = white          // observation fill

#cetz.canvas(length: 1cm, {
  import cetz.draw: circle, line, content, rect

  let rs = 0.62 // state circle radius
  let sa = 0.20 // action square half-side
  let so = 0.34 // observation square half-side

  // ── helpers ───────────────────────────────────────────────────────────────
  // unit vector from a to b
  let uvec(a, b) = {
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let l = calc.sqrt(dx * dx + dy * dy)
    (dx / l, dy / l)
  }
  // point on a ray from p in direction u at distance d
  let along(p, u, d) = (p.at(0) + u.at(0) * d, p.at(1) + u.at(1) * d)

  // state node: open-ish circle, math label
  let state(p, lbl, focal: false) = {
    circle(p, radius: rs, fill: statef,
      stroke: (paint: if focal { garnet } else { edge }, thickness: if focal { 1.7pt } else { 1.2pt }))
    content(p, text(size: 11pt, fill: ink)[#lbl])
  }
  // hidden state node: shaded, dashed outline
  let hidden(p, lbl) = {
    circle(p, radius: rs, fill: hidf,
      stroke: (paint: edge, thickness: 1.1pt, dash: "dashed"))
    content(p, text(size: 11pt, fill: ink)[#lbl])
  }
  // action glyph: small filled square at p with a label tag
  let action(p, lbl, lpos, lanchor: "south", accent: false) = {
    rect((p.at(0) - sa, p.at(1) - sa), (p.at(0) + sa, p.at(1) + sa),
      fill: if accent { garnet } else { actf },
      stroke: (paint: ink, thickness: 0.9pt), radius: 0pt)
    content(lpos, anchor: lanchor, text(size: 8pt, fill: if accent { garnet } else { ink })[#lbl])
  }
  // observation node: open square
  let obs(p, lbl) = {
    rect((p.at(0) - so, p.at(1) - so), (p.at(0) + so, p.at(1) + so),
      fill: obsf, stroke: (paint: edge, thickness: 1.1pt), radius: 0pt)
    content(p, text(size: 10pt, fill: ink)[#lbl])
  }

  // directed arrow between two free points (already trimmed by caller)
  let arr(a, b, accent: false, thick: 1.1pt) = {
    line(a, b, stroke: (paint: if accent { garnet } else { edge }, thickness: thick),
      mark: (end: "stealth", scale: 0.8, fill: if accent { garnet } else { edge }))
  }

  // edge from state s through action-square at m to state t, trimmed to rims.
  //   draws s→action (solid stub) and action→t (the stochastic transition),
  //   places a (p, r) tag at the midpoint of the action→t segment.
  let trans(s, m, t, pr, rew, accent: false, tag-off: (0.0, 0.0)) = {
    // state s -> action square m
    let u1 = uvec(s, m)
    arr(along(s, u1, rs), along(m, u1, -sa - 0.02), accent: accent)
    // action square m -> state t
    let u2 = uvec(m, t)
    let aa = along(m, u2, sa + 0.02)
    let bb = along(t, u2, -rs - 0.02)
    arr(aa, bb, accent: accent)
    // (p, r) tag at midpoint of the transition segment
    let mid = ((aa.at(0) + bb.at(0)) / 2 + tag-off.at(0),
               (aa.at(1) + bb.at(1)) / 2 + tag-off.at(1))
    content(mid, text(size: 7.5pt, fill: if accent { garnet } else { muted })[#pr])
    content((mid.at(0), mid.at(1) - 0.30), text(size: 7.5pt, fill: if accent { garnet } else { muted })[#rew])
  }

  // a curved return edge (quadratic-ish), trimmed at both circle rims, with a
  // (p, r) tag at the apex. dir = +1 bows upward, -1 bows downward.
  let curve-return(s, t, pr, rew, bow: 0.9, dir: 1, tag-off: (0.0, 0.0)) = {
    let u = uvec(s, t)
    let a = along(s, u, rs)
    let b = along(t, u, -rs)
    // perpendicular bow control point at the midpoint
    let mx = (a.at(0) + b.at(0)) / 2
    let my = (a.at(1) + b.at(1)) / 2
    let px = -u.at(1) * bow * dir
    let py = u.at(0) * bow * dir
    let c = (mx + px, my + py)
    line((a.at(0), a.at(1)), (c.at(0), c.at(1)), (b.at(0), b.at(1)),
      stroke: (paint: edge, thickness: 1.1pt), mark: (end: "stealth", scale: 0.8, fill: edge))
    content((c.at(0) + tag-off.at(0), c.at(1) + tag-off.at(1)),
      text(size: 7.5pt, fill: muted)[#pr #h(0.3em) #rew])
  }

  // ════════════════════════════════════════════════════════════════════════
  //  TOP — MDP transition graph
  // ════════════════════════════════════════════════════════════════════════
  // states in a triangle: s0 at left, s1 top-right, s2 bottom-right
  let S0 = (0.7, 6.0)
  let S1 = (6.2, 7.6)
  let S2 = (6.2, 4.7)

  // action squares sit on the OUTBOUND edge from each state
  let A_s0 = (3.2, 6.3)  // a0 from s0 (focal) — stochastic fan to s1 and s2
  let A_s1 = (8.7, 7.6)  // a0 from s1 — deterministic return to s0
  let A_s2 = (8.7, 4.7)  // a1 from s2 — deterministic return to s0

  // ── transitions ───────────────────────────────────────────────────────────
  // FOCAL: action a0 from s0 is stochastic -> s1 (p=.8, r=+1) and s2 (p=.2, r=0)
  trans(S0, A_s0, S1, [$p = 0.8$], [$r = +1$], accent: true, tag-off: (-0.35, 0.58))
  trans(S0, A_s0, S2, [$p = 0.2$], [$r = 0$],  accent: true, tag-off: (-0.35, -0.62))

  // ── draw action squares + tags (after the s0 fan, before returns) ──────────
  action(A_s0, [$a_0$], (A_s0.at(0) - 0.04, A_s0.at(1) - sa - 0.30), lanchor: "north", accent: true)
  action(A_s1, [$a_0$], (A_s1.at(0), A_s1.at(1) + sa + 0.30), lanchor: "south")
  action(A_s2, [$a_1$], (A_s2.at(0), A_s2.at(1) - sa - 0.30), lanchor: "north")

  // a0 from s1 -> action square -> return to s0 along a HIGH arc over the top.
  {
    let u1 = uvec(S1, A_s1)
    arr(along(S1, u1, rs), along(A_s1, u1, -sa - 0.02))
    // explicit waypoints: leave the action top, sweep across high, enter s0 top-right
    let p0 = (A_s1.at(0), A_s1.at(1) + sa + 0.02)
    let w1 = (8.9, 8.85)
    let w2 = (1.6, 8.85)
    let p1 = (S0.at(0) + 0.42, S0.at(1) + rs - 0.04)
    line(p0, w1, w2, p1, stroke: (paint: edge, thickness: 1.1pt),
      mark: (end: "stealth", scale: 0.8, fill: edge))
    content((2.55, 7.75), anchor: "west", text(size: 7.5pt, fill: muted)[$p = 1.0, thick r = -2$])
  }
  // a1 from s2 -> action square -> return to s0 along a LOW arc under the bottom.
  {
    let u1 = uvec(S2, A_s2)
    arr(along(S2, u1, rs), along(A_s2, u1, -sa - 0.02))
    let p0 = (A_s2.at(0), A_s2.at(1) - sa - 0.02)
    let w1 = (9.5, 2.7)
    let w2 = (1.8, 2.7)
    let p1 = (S0.at(0) + 0.42, S0.at(1) - rs + 0.04)
    line(p0, w1, w2, p1, stroke: (paint: edge, thickness: 1.1pt),
      mark: (end: "stealth", scale: 0.8, fill: edge))
    content((6.6, 2.95), text(size: 7.5pt, fill: muted)[$p = 1.0 #h(0.4em) r = 0$])
  }

  // self-loop on s2 under its own action a': a compact circular loop hanging off
  // the BOTTOM-RIGHT rim of s2 (open space), action square on the loop.
  {
    let lc = (S2.at(0) - 0.05, S2.at(1) - rs - 0.42)
    let lr = 0.40
    let n = 30
    let a-start = 35   // degrees, measured from loop centre
    let a-end   = 325
    let pts-loop = range(n + 1).map(i => {
      let t = (a-start + (a-end - a-start) * i / n) * calc.pi / 180
      (lc.at(0) + lr * calc.cos(t), lc.at(1) + lr * calc.sin(t))
    })
    line(..pts-loop, stroke: (paint: edge, thickness: 1.0pt),
      mark: (end: "stealth", scale: 0.7, fill: edge))
    // action square on the bottom of the loop
    let m = (lc.at(0), lc.at(1) - lr)
    rect((m.at(0) - sa, m.at(1) - sa), (m.at(0) + sa, m.at(1) + sa),
      fill: actf, stroke: (paint: ink, thickness: 0.9pt), radius: 0pt)
    content((m.at(0) + sa + 0.16, m.at(1)), anchor: "west",
      text(size: 8pt, fill: ink)[$a'$])
    content((m.at(0) + sa + 0.52, m.at(1)), anchor: "west",
      text(size: 7.5pt, fill: muted)[$p = 1.0, thick r = -1$])
  }

  // ── draw state nodes (on top of everything) ────────────────────────────────
  state(S0, [$s_0$], focal: true)
  state(S1, [$s_1$])
  state(S2, [$s_2$])

  // section heading (sits left so it clears the top return arc + its tag)
  content((2.4, 9.55), anchor: "north", text(size: 11pt, weight: "bold", fill: ink)[Markov Decision Process])
  content((2.4, 9.12), anchor: "north", text(size: 8pt, fill: muted)[edge $s arrow.r a arrow.r s'$ labelled by $p = P(s' | s, a)$, reward $r = R(s, a, s')$])

  // ── divider ────────────────────────────────────────────────────────────────
  line((-1.3, 2.35), (10.6, 2.35), stroke: (paint: rgb("#C7C7C7"), thickness: 0.7pt, dash: "dotted"))

  // ════════════════════════════════════════════════════════════════════════
  //  BOTTOM — POMDP extension: hidden state layer + emitted observations
  // ════════════════════════════════════════════════════════════════════════
  // hidden state chain (latent), left -> right
  let H0 = (0.6,  1.0)
  let H1 = (4.5,  1.0)
  let H2 = (8.4,  1.0)
  // observation nodes below each hidden state
  let O0 = (0.6, -1.35)
  let O1 = (4.5, -1.35)
  let O2 = (8.4, -1.35)
  // action squares between hidden states
  let AH0 = (2.55, 1.0)
  let AH1 = (6.45, 1.0)

  // hidden dynamics (same MDP machinery, drawn over the latent layer).
  // transition label sits just BELOW the chain edge (clear of the action labels).
  trans(H0, AH0, H1, [$P(s' | s, a)$], [], tag-off: (0.0, -0.42))
  trans(H1, AH1, H2, [$P(s' | s, a)$], [], tag-off: (0.0, -0.42))

  // emission edges hidden -> observation (garnet = the focal POMDP addition)
  let emit(h, o) = {
    arr((h.at(0), h.at(1) - rs - 0.02), (o.at(0), o.at(1) + so + 0.02), accent: true)
    content((h.at(0) + 0.16, (h.at(1) - rs + o.at(1) + so) / 2), anchor: "west",
      text(size: 7pt, fill: garnet)[$Z(o | s')$])
  }
  emit(H0, O0)
  emit(H1, O1)
  emit(H2, O2)

  // action squares on the hidden chain (label tucked to the right of the square)
  action(AH0, [$a$], (AH0.at(0) + sa + 0.14, AH0.at(1) + sa + 0.04), lanchor: "west")
  action(AH1, [$a$], (AH1.at(0) + sa + 0.14, AH1.at(1) + sa + 0.04), lanchor: "west")

  // hidden states + observations
  hidden(H0, [$s$])
  hidden(H1, [$s'$])
  hidden(H2, [$s''$])
  obs(O0, [$o$])
  obs(O1, [$o'$])
  obs(O2, [$o''$])

  // section heading
  content((3.7, 2.28), anchor: "north", text(size: 11pt, weight: "bold", fill: ink)[POMDP — hidden state, observed emission])
  content((3.7, 1.9), anchor: "north", text(size: 8pt, fill: muted)[state is latent; agent sees only $o$ drawn from emission $Z(o | s') = P(o | s')$])

  // ── legend (right column) ───────────────────────────────────────────────────
  let lx = 10.9
  let ly = 6.2
  let lrow(i, draw-glyph, lbl) = {
    let yy = ly - i * 0.72
    draw-glyph(yy)
    content((lx + 0.62, yy), anchor: "west", text(size: 7.5pt, fill: ink)[#lbl])
  }
  rect((lx - 0.45, ly - 4.05), (lx + 4.0, ly + 0.5),
    stroke: (paint: rgb("#A2A2A2"), thickness: 0.8pt), radius: 0pt)
  content((lx - 0.25, ly + 0.95), anchor: "west", text(size: 8.5pt, weight: "bold", fill: ink)[legend])

  // observed state circle
  lrow(0, yy => {
    circle((lx, yy), radius: 0.26, fill: statef, stroke: (paint: edge, thickness: 1.1pt))
  }, [state $s$])
  // hidden state circle
  lrow(1, yy => {
    circle((lx, yy), radius: 0.26, fill: hidf, stroke: (paint: edge, thickness: 1.0pt, dash: "dashed"))
  }, [hidden state (POMDP)])
  // action square
  lrow(2, yy => {
    rect((lx - 0.20, yy - 0.20), (lx + 0.20, yy + 0.20), fill: actf, stroke: (paint: ink, thickness: 0.9pt), radius: 0pt)
  }, [action $a$])
  // observation square
  lrow(3, yy => {
    rect((lx - 0.24, yy - 0.24), (lx + 0.24, yy + 0.24), fill: obsf, stroke: (paint: edge, thickness: 1.1pt), radius: 0pt)
  }, [observation $o$])
  // transition edge
  lrow(4, yy => {
    line((lx - 0.30, yy), (lx + 0.30, yy), stroke: (paint: edge, thickness: 1.1pt), mark: (end: "stealth", scale: 0.7))
  }, [transition $p, r$])
  // emission edge (garnet)
  lrow(5, yy => {
    line((lx - 0.30, yy), (lx + 0.30, yy), stroke: (paint: garnet, thickness: 1.2pt), mark: (end: "stealth", scale: 0.7))
  }, [emission $Z(o | s')$])
})
