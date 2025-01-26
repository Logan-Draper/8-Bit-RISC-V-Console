# 8-Bit-Fantasy-Console

## Architecture Highlights
- 8 Registers
- 256 Byte zero page located at &0000-&00FF
- 3840 Byte stack with push/pop operations located at &0100-&0FFF
- Entry point for all programs is at &1000
- Variable Length Instruction Encoding
- 256 Instructions
- Dedicated instruction to communicate with peripherals/co-processors
### Register File
0. Zero
1. A
2. B
3. X
4. Y
5. RA
6. ??
7. ??

- Stack pointer is not user accessible
- Status register is not user accessible
- Controller register is not user accessible
- Program Counter is not user accessible

#### Status Register
The status register holds 8 flags
1. Zero
2. Carry
3. Overflow
4. Negative
5. Peripheral
6. ??
7. ??
8. ??

## Instruction Set
- Supports directly operating on memory through the `&` directive
- Branch instruction per flag in status register
- Branch instruction per flag in controller register
- Branch instruction to check busy status of a peripheral
- Push/Pop instructions to move 1 bytes to/from the stack
- Writing to memory through either the 0 page (1 byte addressing), or any other accessible region (2 byte addressing)

All operands can be either register references or memory locations (where applicable).

## Peripheral/Co-processor Support
- Graphics co processor that works by writing commands and arguments to a specific region of memory
- Dedicated instruction to issue the "GO" signal to the peripheral

## Instructions
| Instruction | Description                                                                                       | Operands      |
|:------------|:--------------------------------------------------------------------------------------------------|:--------------|
| NOP         | Do nothing                                                                                        |               |
| ADD         | Add `rs1` and `rs2` into `rd`                                                                     | rd, rs1, rs2  |
| SUB         | Subtract `rs2` from `rs1`, store result in `rd`                                                   | rd, rs1, rs2  |
| PUSH        | Push the byte in `rs1` onto the stack                                                             | rs1           |
| POP         | Pop a byte off the stack into `rd`                                                                | rd            |
| SBZ         | Store the byte in `rs1` into zero-page offset by `rs2`                                            | rs1, rs2      |
| SB          | Store the byte in `rs1` into the 16-bit address formed from `rs2:rs3`                             | rs1, rs2, rs3 |
| LBZ         | Load a byte from the zero page offset by `rs1` into `rd`                                          | rd, rs1       |
| LB          | Load a byte from the 16-bit address formed from `rs1:rs2` into `rd`                               | rd, rs1, rs2  |
| CMP         | Compare the operands `rs1` and `rs2` storing the result in the status register, `rs1`-`rs2`       | rs1, rs2      |
| BNEG (BLT)  | Jump to the 16-bit address `rs1:rs2` if the negative flag is set                                  | rs1, rs2      |
| BZO (BEQ)   | Jump to the 16-bit address `rs1:rs2` if the zero flag is set                                      | rs1, rs2      |
| BLE         | Jump to the 16-bit address `rs1:rs2` if either the negative or zero flag is set                   | rs1, rs2      |
| BOF         | Jump to the 16-bit address `rs1:rs2` if the overflow flag is set                                  | rs1, rs2      |
| BCA         | Jump to the 16-bit address `rs1:rs2` if the carry flag is set                                     | rs1, rs2      |
| JAL         | Stores the address of the next instruction in `ra`, then jumps to the 16-bit address of `rs1:rs2` | rs1, rs2      |
| J           | Jumps to the 16-bit address formed from `rs1:rs2`                                                 | rs1, rs2      |
| GO          | Signal to a peripheral, specified in rs1, to begin execution                                      | rs1           |

### Instruction Op Codes
| Instruction       | Op Code | Operand Encoding | 2nd Byte |
|:------------------|:--------|:-----------------|:---------|
| NOP               | 0       | n/a              |          |
| ADD reg, reg, reg | 1       | 0                | 1        |
| ADD reg, reg, imm | 1       | 1                | 1        |
| ADD reg, reg, mem | 1       | 2                | 1        |
| ADD mem, reg, reg | 1       | 3                | 1        |
| ADD mem, reg, imm | 1       | 4                | 1        |
| ADD mem, reg, mem | 1       | 5                | 1        |
| SUB reg, reg, reg | 1       | 0                | 2        |
| SUB reg, reg, imm | 1       | 1                | 2        |
| SUB reg, reg, mem | 1       | 2                | 2        |
| SUB mem, reg, reg | 1       | 3                | 2        |
| SUB mem, reg, imm | 1       | 4                | 2        |
| SUB mem, reg, mem | 1       | 5                | 2        |
| PUSH reg          | 2       | 13               |          |
| PUSH imm          | 2       | 14               |          |
| PUSH mem          | 2       | 15               |          |
| POP reg           | 3       | 14               |          |
| POP mem           | 3       | 15               |          |
| SBZ reg, reg      | 4       | 6                |          |
| SBZ reg, imm      | 4       | 7                |          |
| SBZ reg, mem      | 4       | 8                |          |
| SBZ imm, imm      | 4       | 12               |          |
| SBZ mem, reg      | 4       | 9                |          |
| SBZ mem, imm      | 4       | 10               |          |
| SBZ mem, mem      | 4       | 11               |          |
| SB reg, reg, reg  | 5       | 0                |          |
| SB reg, reg, imm  | 5       | 1                |          |
| SB reg, reg, mem  | 5       | 2                |          |
| SB mem, reg, reg  | 5       | 3                |          |
| SB mem, reg, imm  | 5       | 4                |          |
| SB mem, reg, mem  | 5       | 5                |          |
| LBZ reg, reg      | 6       | 6                |          |
| LBZ reg, imm      | 6       | 7                |          |
| LBZ reg, mem      | 6       | 8                |          |
| LBZ mem, reg      | 6       | 9                |          |
| LBZ mem, imm      | 6       | 10               |          |
| LBZ mem, mem      | 6       | 11               |          |
| LB reg, reg, reg  | 7       | 0                |          |
| LB reg, reg, imm  | 7       | 1                |          |
| LB reg, reg, mem  | 7       | 2                |          |
| LB mem, reg, reg  | 7       | 3                |          |
| LB mem, reg, imm  | 7       | 4                |          |
| LB mem, reg, mem  | 7       | 5                |          |
| CMP reg, reg      | 8       | 6                |          |
| CMP reg, imm      | 8       | 7                |          |
| CMP imm, imm      | 8       | 12               |          |
| CMP reg, mem      | 8       | 8                |          |
| CMP mem, reg      | 8       | 9                |          |
| CMP mem, mem      | 8       | 11               |          |
| CMP mem, imm      | 8       | 10               |          |
| BNEG reg, reg     | 9       | 6                | 1        |
| BNEG reg, imm     | 9       | 7                | 1        |
| BNEG imm, imm     | 9       | 12               | 1        |
| BNEG reg, mem     | 9       | 8                | 1        |
| BNEG mem, reg     | 9       | 9                | 1        |
| BNEG mem, mem     | 9       | 11               | 1        |
| BNEG mem, imm     | 9       | 10               | 1        |
| BZO reg, reg      | 9       | 6                | 2        |
| BZO reg, imm      | 9       | 7                | 2        |
| BZO imm, imm      | 9       | 12               | 2        |
| BZO reg, mem      | 9       | 8                | 2        |
| BZO mem, reg      | 9       | 9                | 2        |
| BZO mem, mem      | 9       | 11               | 2        |
| BZO mem, imm      | 9       | 10               | 2        |
| BLE reg, reg      | 9       | 6                | 3        |
| BLE reg, imm      | 9       | 7                | 3        |
| BLE imm, imm      | 9       | 12               | 3        |
| BLE reg, mem      | 9       | 8                | 3        |
| BLE mem, reg      | 9       | 9                | 3        |
| BLE mem, mem      | 9       | 11               | 3        |
| BLE mem, imm      | 9       | 10               | 3        |
| BOF reg, reg      | 9       | 6                | 4        |
| BOF reg, imm      | 9       | 7                | 4        |
| BOF imm, imm      | 9       | 12               | 4        |
| BOF reg, mem      | 9       | 8                | 4        |
| BOF mem, reg      | 9       | 9                | 4        |
| BOF mem, mem      | 9       | 11               | 4        |
| BOF mem, imm      | 9       | 10               | 4        |
| BCA reg, reg      | 9       | 6                | 5        |
| BCA reg, imm      | 9       | 7                | 5        |
| BCA imm, imm      | 9       | 12               | 5        |
| BCA reg, mem      | 9       | 8                | 5        |
| BCA mem, reg      | 9       | 9                | 5        |
| BCA mem, mem      | 9       | 11               | 5        |
| BCA mem, imm      | 9       | 10               | 5        |
| JAL reg, reg      | 10      | 6                |          |
| JAL reg, imm      | 10      | 7                |          |
| JAL imm, imm      | 10      | 12               |          |
| JAL reg, mem      | 10      | 8                |          |
| JAL mem, reg      | 10      | 9                |          |
| JAL mem, mem      | 10      | 11               |          |
| JAL mem, imm      | 10      | 10               |          |
| J reg, reg        | 11      | 6                |          |
| J reg, imm        | 11      | 7                |          |
| J imm, imm        | 11      | 12               |          |
| J reg, mem        | 11      | 8                |          |
| J mem, reg        | 11      | 9                |          |
| J mem, mem        | 11      | 11               |          |
| J mem, imm        | 11      | 10               |          |
| GO reg            | 12      | 12               |          |
| GO imm            | 12      | 13               |          |
| GO mem            | 12      | 14               |          |


- Some instructions will use the same opcode as others, with the 2nd byte representing the specific instruction type (OPCODE + 1)
  - The encoded operands will then start on the following byte (OPCODE + 2)

### Instruction Encoding
| Code | Operand Arrangement | Byte 1 | Byte 2 |
|:-----|:--------------------|:-------|:-------|
| 0    | r, r, r             | [r:r]  | [r:0]  |
| 1    | r, r, i             | [r:r]  | [i]    |
| 2    | r, r, m             | [r:r]  | [m:0]  |
| 3    | m, r, r             | [m:r]  | [r:0]  |
| 4    | m, r, i             | [m:r]  | [i]    |
| 5    | m, r, m             | [m:r]  | [m:0]  |
| 6    | r, r                | [r:r]  | n/a    |
| 7    | r, i                | [r:0]  | [i]    |
| 8    | r, m                | [r:m]  | n/a    |
| 9    | m, r                | [m:r]  | n/a    |
| 10   | m, i                | [m:0]  | [i]    |
| 11   | m, m                | [m:m]  | n/a    |
| 12   | i, i                | [i]    | [i]    |
| 13   | r                   | [r:0]  | n/a    |
| 14   | i                   | [i]    | n/a    |
| 15   | m                   | [m:0]  | n/a    |

- [x:y] means the top 4 bits represent x, the lower 4 bits represent y
- [y] means the entire 8-bits are dedicated to y
- `r` is a register reference, which uses the value in the register directly
- `m` is a register reference, which uses the value in the register as a zero page offset
- `i` is an 8-bit immediate

### Example Program

```
start:
  ADD x, x, $1
  PUSH x
  SBZ x, $0
  ADD y, y, 12
  CMP x, y
  BLT $0, $0
```
