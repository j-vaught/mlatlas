// A shared backbone with two task heads — built with `branch`.
#import "../lib.typ": *

#standalone(branch(
  seq(block(label: [Input], role: "data"), block(label: [Backbone], role: "attention")),
  seq(block(label: [Cls Head], role: "op"), block(label: [Class], role: "output")),
  seq(block(label: [Box Head], role: "op"), block(label: [BBox], role: "output")),
  gap: 2,
))
