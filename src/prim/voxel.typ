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
