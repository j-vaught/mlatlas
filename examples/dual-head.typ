// A shared backbone fanning out to two task heads — dedicated symmetric renderer.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 14pt, fill: white)

#dual-head(
  input: [Input],
  backbone: [Backbone],
  heads: (([Cls Head], [Class]), ([Box Head], [BBox])),
)
