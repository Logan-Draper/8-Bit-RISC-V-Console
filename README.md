# 8-Bit-Fantasy-Console

## Architecture Highlights
- 8 Registers
- 4096 Byte stack with push/pop operations
- Variable Length Instruction Encoding
- 256 Instructions
- Dedicated instruction to communicate with peripherals/co-processors
### Register File
1. A
2. B
3. X
4. Y
5. RA
6. ??
7. ??
8. ??

Stack pointer is not user accessible
Status register is not user accessible
Controller register is not user accessible
Program Counter is not user accessible

## Instruction Set
Supports directly operating on memory through the `&` directive
Branch instruction per flag in status register
Branch instruction per flag in controller register
Branch instruction to check busy status of a peripheral
Push/Pop instructions to move 1 bytes to/from the stack
Writing to memory through either the 0 page (1 byte addressing), or any other accessible region (2 byte addressing)

All operands can be either register references or memory locations (where applicable).

## Peripheral/Co-processor Support
Graphics co processor that works by writing commands and arguments to a specific region of memory
Dedicated instruction to issue the "GO" signal to the peripheral

## Instructions
| Instruction | Description                               | Operands      |
|:------------|:------------------------------------------|:--------------|
| ADD         | Add rs1 and rs2 into rd                   | rd, rs1, rs2  |
| SUB         | Subtract rs2 from rs1, store result in rd | rd, rs1, rs2  |
