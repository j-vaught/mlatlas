// Unrolled RNN (3-D cells, garnet hidden-state recurrence) + an LSTM cell with C_t/h_t conveyor.
#import "../lib.typ": *
#set page(width: auto, height: auto, margin: 16pt, fill: white)
#rnn-unroll3d(steps: 4, cell: [RNN], hidden: 128)
#v(20pt)
#lstm-cell3d()
