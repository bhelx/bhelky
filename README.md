# Bhelky

This codebase contains tools for my hand-built TTL computer (Bhelky JR). It currently has 3 pieces:

1. [Assembler](#Assembler)
2. [Emulator](#Emulator)
3. [Display Binary](#Display)

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

* `input` is the input binary program to run.
* `slowdown` is millisecond wait time b/w instructions. Set to `0` to go full speed.
* `history` is where to store the execution history of the run (for later inspection).

```bash
$ ./bhelky emulate --input /tmp/fibonacci.bin --slowdown 10 --history /tmp/fibonacci.hist
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

If you want to inspect the execution history, you can do so in iex:

``` bash
$ iex -S mix
```

```elixir
iex(1)> history = Bhelky.Machine.load_execution_history("/tmp/fibonacci.hist")
iex(2)> # The schema of the history data is [{opcode, arg}, %Bhelky.Machine{}]
iex(3)> # It can be useful to query this structure using elixir to debug problems
iex(4)> # For instance let's look at how each operation altered the a register
iex(5)> change_desc = fn (s1, s2) ->
...(5)>   cond do
...(5)>     s1 != s2 -> "changed register A from #{s1} to #{s2}"
...(5)>     true -> ""
...(5)>   end
...(5)> end
iex(6)> history |> Enum.chunk_every(2, 1, :discard) |> Enum.each(fn [{_c1, s1}, {c2, s2}] ->
...(6)>   IO.puts("#{inspect c2} #{change_desc.(s1.reg_a, s2.reg_a)}")
...(6)> end)
{:lda, 15}
{:add, 14} changed register A from 0 to 1
{:sta, 13}
{:lda, 14}
{:sta, 15}
{:lda, 13}
{:sta, 14}
{:out}
{:jnc, 0}
{:lda, 15}
{:add, 14} changed register A from 1 to 2
{:sta, 13}
{:lda, 14} changed register A from 2 to 1
{:sta, 15}
{:lda, 13} changed register A from 1 to 2
{:sta, 14}
{:out}
{:jnc, 0}
{:lda, 15} changed register A from 2 to 1
{:add, 14} changed register A from 1 to 3
{:sta, 13}
{:lda, 14} changed register A from 3 to 2
{:sta, 15}
{:lda, 13} changed register A from 2 to 3
{:sta, 14}
{:out}
# .......
# .......
# .......
{:jnc, 0}
{:hlt}
:ok
```

## Display

The display command shows a binary in a form that makes it easy
to enter by hand into RAM. The format is `address{4} => opcode{4} | arg{4}`.

```bash
$ ./bhelky display --input /tmp/fibonacci.bin
0000 => 0001 | 1111
0001 => 0010 | 1110
0010 => 0100 | 1101
0011 => 0001 | 1110
0100 => 0100 | 1111
0101 => 0001 | 1101
0110 => 0100 | 1110
0111 => 1110 | 0000
1000 => 1001 | 0000
1001 => 1111 | 0000
1010 => 0000 | 0000
1011 => 0000 | 0000
1100 => 0000 | 0000
1101 => 0000 | 0000
1110 => 0000 | 0001
1111 => 0000 | 0000
```
