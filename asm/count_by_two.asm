;
; Counts by 2 and outputs to the display.
; Never really halts

#include "bhelky.cpu"

; incr_by is the location where
; we store the value to increment by
incr_by = 15

ldi 0

loop:
  add incr_by
  out
  jmp loop
hlt

; data section
numvars = 1
#addr 16 - numvars

; incr_by = 2
#d8 2
