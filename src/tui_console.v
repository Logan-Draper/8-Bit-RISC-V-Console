module tui_console

import bytecode
import vm
import arrays
import os

struct DebugInstruction {
	location    u16
	instruction bytecode.Instruction
}

pub fn run() ! {
	program := [
		bytecode.Instruction{
			opcode:   .jal
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 16
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 18
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 1
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 1
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .c
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .c
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 1
			})
		},
		bytecode.Instruction{
			opcode:   .trap
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op2:      bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      bytecode.Operand(bytecode.Immediate{
				val: 255
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 54
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 55
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .c
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 56
			})
		},
		bytecode.Instruction{
			opcode:   .ret
			encoding: .i
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 0
			})
		},
		bytecode.Instruction{
			opcode:   .trap
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op2:      bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      bytecode.Operand(bytecode.Immediate{
				val: 255
			})
		},
	]

	binary := arrays.flatten(program.map(it.encode_instruction()!))
	mut vm_instance := vm.create_vm_with_program(binary)!

	mut instructions := []DebugInstruction{}

	mut i := u16(0)
	for i < binary.len {
		instruction, length := bytecode.decode(binary, i)!

		instructions << DebugInstruction{
			location:    0x1000 + i
			instruction: instruction
		}

		i += length
	}

	println('\nBEGIN BINARY')
	for instruction in instructions {
		println('0x${instruction.location:X}: ${instruction.instruction.disassemble()}')
	}
	println('END BINARY\n')

	for {
		current_instruction, _ := bytecode.decode(vm_instance.ram[..], vm_instance.pc)!
		done := vm_instance.step()!

		if done {
			println('PC: 0x${vm_instance.pc + 2:X} A: ${vm_instance.a:3} B: ${vm_instance.b:3} C: ${vm_instance.c:3} | ${current_instruction.disassemble()}')
			break
		}

		println('PC: 0x${vm_instance.pc:X} A: ${vm_instance.a:3} B: ${vm_instance.b:3} C: ${vm_instance.c:3} | ${current_instruction.disassemble()}')
		// _ := os.input('')
	}
}
