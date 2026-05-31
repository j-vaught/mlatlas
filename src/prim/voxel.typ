// mlatlas · prim/voxel.typ
// A depth-sorted voxel lattice + a conv kernel highlighted inside a volume. Uses the engine's
// linearity: a voxel at world (x,y,z) is drawn by block3d at the 2-D origin project((x,y,z)),
// so the local cube corners land in the correct world position. Far->near painter order.
#import "@preview/cetz:0.5.2"
#import "../adapters/3d.typ": block3d, project, project-z, cam-iso

#let voxel-palette = (
  fill: rgb("#CBE0F4"), edge: rgb("#243038"), kernel: rgb("#73000A"), text: rgb("#222222"),
)

// dims = (nx, ny, nz). occupancy: auto (full) or an array of (ix,iy,iz) to draw. outline-only
// fills cells white (hollow lattice). Big grids: pass outline-only:true and cap dims.
#let voxel-grid(
  draw, origin: (0, 0), dims: (4, 4, 4), cell: 0.5, gap: 0.07,
  base: rgb("#CBE0F4"), edge: rgb("#243038"), cam: cam-iso, occupancy: auto, outline-only: false, shade: true,
) = {
  let (nx, ny, nz) = dims
  let step = cell + gap
  let cells = ()
  for ix in range(nx) {
    for iy in range(ny) {
      for iz in range(nz) {
        if occupancy == auto or occupancy.contains((ix, iy, iz)) {
          let wx = (ix - (nx - 1) / 2) * step
          let wy = (iy - (ny - 1) / 2) * step
          let wz = (iz - (nz - 1) / 2) * step
          cells.push((wx, wy, wz))
        }
      }
    }
  }
  // far -> near
  let ordered = cells.sorted(key: c => project-z((c.at(0), c.at(1), c.at(2)), cam: cam))
  for c in ordered {
    let o2 = project((c.at(0), c.at(1), c.at(2)), cam: cam, origin: origin)
    block3d(
      draw, origin: o2, w: cell, h: cell, dep: cell,
      base: if outline-only { white } else { base }, edge: edge, cam: cam, shade: shade and not outline-only,
    )
  }
}

// a small kernel cube (garnet outline) overlaid on a face of a larger volume at grid index (ix,iy,iz).
#let conv3d-kernel(
  draw, origin: (0, 0), vol: (6, 6, 6), kernel: (3, 3, 3), at: (0, 0, 0), cell: 0.42, gap: 0.06,
  base: rgb("#E9EDF0"), kcolor: rgb("#73000A"), edge: rgb("#243038"), cam: cam-iso,
) = {
  voxel-grid(draw, origin: origin, dims: vol, cell: cell, gap: gap, base: base, edge: edge, cam: cam, outline-only: true, shade: false)
  let (nx, ny, nz) = vol
  let step = cell + gap
  let (kx, ky, kz) = kernel
  let (ax, ay, az) = at
  // world center of the kernel block
  let cx = (ax + (kx - 1) / 2 - (nx - 1) / 2) * step
  let cy = (ay + (ky - 1) / 2 - (ny - 1) / 2) * step
  let cz = (az + (kz - 1) / 2 - (nz - 1) / 2) * step
  let o2 = project((cx, cy, cz), cam: cam, origin: origin)
  block3d(draw, origin: o2, w: kx * step, h: ky * step, dep: kz * step, base: kcolor.lighten(62%), edge: kcolor, cam: cam, sil-weight: 1.4pt, opacity: 78%)
}

// kernel-slide: an input volume, a conv kernel shown at several slide positions (one solid +
// faint ghosts), an output volume, and arrows mapping each kernel position to its output cell.
// The hero figure for 3-D convolution.
#let kernel-slide(
  input: (5, 5, 3), kernel: (3, 3, 3), out: (3, 3, 1),
  positions: ((0, 0, 0), (1, 0, 0), (2, 2, 0)),
  cell: 0.4, gap: 0.06, arm: 5.2,
  base: rgb("#E9EDF0"), kcolor: rgb("#73000A"), edge: rgb("#243038"), cam: cam-iso,
) = cetz.canvas(length: 1cm, {
  import cetz.draw
  let p = (paint: kcolor, thickness: 1.0pt, dash: "dashed")
  let step = cell + gap
  let (nx, ny, nz) = input
  let (kx, ky, kz) = kernel
  let (ox-, oy-, oz-) = out
  let in-o = (0, 0)
  let out-o = (arm, 0)
  // input volume (hollow lattice) + output volume (hollow)
  voxel-grid(draw, origin: in-o, dims: input, cell: cell, gap: gap, base: base, edge: edge, cam: cam, outline-only: true, shade: false)
  voxel-grid(draw, origin: out-o, dims: out, cell: cell, gap: gap, base: base, edge: edge, cam: cam, outline-only: true, shade: false)
  // helper: world center of a sub-block of size k at grid index `at` inside a volume of size dim
  let wc(dim, k, at) = {
    let (dx, dy, dz) = dim
    let (kxx, kyy, kzz) = k
    let (ax, ay, az) = at
    (
      (ax + (kxx - 1) / 2 - (dx - 1) / 2) * step,
      (ay + (kyy - 1) / 2 - (dy - 1) / 2) * step,
      (az + (kzz - 1) / 2 - (dz - 1) / 2) * step,
    )
  }
  // draw ghosts first, the primary kernel last (on top)
  for (i, at) in positions.enumerate() {
    let primary = i == 0
    let c = wc(input, kernel, at)
    let o2 = project(c, cam: cam, origin: in-o)
    block3d(
      draw, origin: o2, w: kx * step, h: ky * step, dep: kz * step,
      base: if primary { kcolor.lighten(58%) } else { kcolor.lighten(85%) }, edge: kcolor,
      cam: cam, sil-weight: if primary { 1.5pt } else { 1.0pt }, opacity: if primary { 80% } else { 45% },
    )
    // corresponding output cell + mapping arrow
    let oc = wc(out, (1, 1, 1), (at.at(0), at.at(1), 0))
    let oo2 = project(oc, cam: cam, origin: out-o)
    block3d(draw, origin: oo2, w: step, h: step, dep: step, base: kcolor.lighten(if primary { 45% } else { 80% }), edge: kcolor, cam: cam, opacity: if primary { 90% } else { 55% })
    draw.line(o2, oo2, stroke: (paint: kcolor, thickness: if primary { 1.3pt } else { 0.8pt }, dash: if primary { none } else { "dashed" }), mark: (end: "stealth", scale: 0.6))
  }
  draw.content((in-o.at(0), -nz * step / 2 - 1.0), text(size: 8pt, weight: "bold", fill: edge)[input #nx×#ny×#nz])
  draw.content((out-o.at(0), -1.0), text(size: 8pt, weight: "bold", fill: edge)[output])
  draw.content(((in-o.at(0) + out-o.at(0)) / 2, 2.4), text(size: 7.5pt, fill: kcolor)[#kx×#ky×#kz kernel slides])
})
