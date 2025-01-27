module vm

import bytecode
import arrays

fn test_vm_add() {
	program := [
		bytecode.Instruction{
			opcode:   .alu
			encoding: .mri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Memory{
				reg: .zero
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 42
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
	mut vm_instance := create_vm_with_program(binary)!
	mut ram := vm_instance.ram[..]
	ram[0] = 42

	vm_instance.run()!
	assert vm_instance.ram[..] == ram
}
