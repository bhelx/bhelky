#include "bhelky.cpu"

; variable addresses
; variables initialized in data section
n1 = 15
n2 = 14
nth = 13

loop:
  ; nth = n1 + n2
  lda n1
  add n2
  sta nth

  ; n1 = n2
  lda n2
  sta n1

  ; n2 = nth
  lda nth
  sta n2

  ; print(n2)
  out

  ; loop unless the carry bit is set
  ; (the sum register has overflowed)
  jnc loop

hlt

; data section
numvars = 3
#addr 0x10 - numvars

; nth = 0
#d8 0x00

; n2 = 1
#d8 0x01

; n1 = 0
#d8 0x00
