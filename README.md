# Bhelky

This codebase contains tools for my hand-built TTL computer (Bhelky JR). It currently has 2 pieces:

1. [Assembler](#Assembler)
2. [Emulator](#Emulator)

## Dependencies

1. Working install of elixir.
2. [customasm](https://github.com/hlorenzi/customasm) (must be installed on your path to assemble a binary).

## Install

To build the bhelky binary:

```bash
mix escript.build
```

## Assembler

The assembler takes an `asm` file and assembles it into a binary that can be uploaded
to the machine's RAM. Bhelky JR only has 16 bytes of RAM, so the program and the data must all fit
in 16 1-byte slots. The instructions are all 1 bite a piece. There is also no stack, so you must manage memory locations yourself.
ASM syntax is derived from the customasm project. See their [documentation](https://github.com/hlorenzi/customasm/blob/master/doc/index.md).

To understand how to program the machine, see the [fibonacci example](asm/fibonacci.asm):

```asm
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

; you must end with a halt command
hlt

; data section
; here we initialize our n* variables

; first we must offset our position 3 bytes
; from the end of RAM since we are storing
; 3 variables
numvars = 3
#addr 0x10 - numvars

; nth = 0
#d8 0x00

; n2 = 1
#d8 0x01

; n1 = 0
#d8 0x00
```

To assemble a program:

```bash
$ ./bhelky assemble --input asm/fibonacci.asm --output /tmp/fibonacci.bin
$ xxd -c 1 -b /tmp/fibonacci.bin                                                                            (bhelky) 15:36:52
00000000: 00011111  .
00000001: 00101110  .
00000002: 01001101  M
00000003: 00011110  .
00000004: 01001111  O
00000005: 00011101  .
00000006: 01001110  N
00000007: 11100000  .
00000008: 10010000  .
00000009: 11110000  .
0000000a: 00000000  .
0000000b: 00000000  .
0000000c: 00000000  .
0000000d: 00000000  .
0000000e: 00000001  .
0000000f: 00000000  .
```

## Emulator

The emulator can take a bhelky formatted binary and run it on your system. This allows me to experiment
with different instructions as well as develop and test my programs before I run them on the
hardware.

To run a binary on the emulator, use the `emulate` command.
Slowdown is millisecond wait time b/w instructions:

```bash
$ ./bhelky emulate --input /tmp/fibonacci.bin --slowdown 10
Out [1]
Out [2]
Out [3]
Out [5]
Out [8]
Out [13]
Out [21]
Out [34]
Out [55]
Out [89]
Out [144]
Out [233]
Out [377]
{{:hlt}, %Bhelky.Machine{carry_bit: true, memory: [{:lda, 15}, {:add, 14}, {:sta, 13}, {:lda, 14}, {:sta, 15}, {:lda, 13}, {:sta, 14}, {:out}, {:jnc, 0}, {:hlt}, 0, 0, 0, 377, 377, 233], pc: 9, reg_a: 377, reg_b: 233, reg_o: 377}}
```

The program will display anything called with `out` and when it terminates it will dump the state of the machine and the last command.

