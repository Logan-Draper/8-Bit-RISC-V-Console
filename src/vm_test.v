module vm

import bytecode
import arrays

fn test_vm_add() {
	// ADD &zero, zero, $42
	// TRAP zero, zero, $255
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
	assert vm_instance.ram[..] == ram[..]
	assert vm_instance.pc == 0x1004
	// When we halt the PC doesn't move past the beginning of the halt instruction,
	// otherwise this would be 0x1008
}

fn test_vm_sub() {
	// SUB &zero, zero, $42
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .alu
			encoding: .mri
			extra:    ?bytecode.Extra(bytecode.Alu.sub)
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
	ram[0] = -42

	vm_instance.run()!
	assert vm_instance.ram[..] == ram[..]
	assert vm_instance.pc == 0x1004
	// When we halt the PC doesn't move past the beginning of the halt instruction,
	// otherwise this would be 0x1008
}

fn test_vm_load_store_zero_page() {
	// SBZ $42, $200
	// LBZ a, $200
	// ADD b, zero, $2
	// SBZ b, b
	// LBZ x, b
	// ADD y, zero, $3
	// SBZ y, y
	// SBZ &y, &y
	// LBZ ra, &y
	// TRAP zero, zero, $255

	// First via immediates
	// Second via registers
	// Third via memory
	program := [
		// First
		bytecode.Instruction{
			opcode:   .sbz
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 42
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 200
			})
		},
		bytecode.Instruction{
			opcode:   .lbz
			encoding: .ri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 200
			})
		},
		// Second
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
				val: 2
			})
		},
		bytecode.Instruction{
			opcode:   .sbz
			encoding: .rr
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
		},
		bytecode.Instruction{
			opcode:   .lbz
			encoding: .rr
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .x
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
		},
		// Third
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 3
			})
		},
		// Write the value 3 to position 3 in memory
		// This is so that the following instructions using `m` encoding
		// are referencing the correct value
		bytecode.Instruction{
			opcode:   .sbz
			encoding: .rr
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
		},
		bytecode.Instruction{
			opcode:   .sbz
			encoding: .mm
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
		},
		bytecode.Instruction{
			opcode:   .lbz
			encoding: .rm
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .ra
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
		},
		// Program End
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
	ram[2] = 2
	ram[3] = 3
	ram[200] = 42

	vm_instance.run()!
	assert vm_instance.ram[..] == ram[..]
	assert vm_instance.a == 42
	assert vm_instance.b == 2
	assert vm_instance.x == 2
	assert vm_instance.y == 3
	assert vm_instance.ra == 3
}

fn test_vm_push_pop() {
	// ADD y, zero, 3
	// PUSH $42
	// PUSH y
	// POP b
	// POP a
	// TRAP zero, zero, $255
	program := [
		// Preload 3 into y
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 3
			})
		},
		bytecode.Instruction{
			opcode:   .push
			encoding: .i
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 42
			})
		},
		bytecode.Instruction{
			opcode:   .push
			encoding: .r
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .y
			})
		},
		bytecode.Instruction{
			opcode:   .pop
			encoding: .r
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
		},
		bytecode.Instruction{
			opcode:   .pop
			encoding: .r
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
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
	ram[256] = 42
	ram[257] = 3

	vm_instance.run()!
	assert vm_instance.ram[..] == ram[..]
	assert vm_instance.a == 42
	assert vm_instance.b == 3
}

fn test_vm_sb_lb() {
	// ADD a, zero, $255
	// SB a, a, $255
	// LB b, a, $255
	// TRAP zero, zero, $255
	program := [
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
				val: 255
			})
		},
		bytecode.Instruction{
			opcode:   .sb
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 255
			})
		},
		bytecode.Instruction{
			opcode:   .lb
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 255
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
	ram[0xFFFF] = 255

	vm_instance.run()!
	assert vm_instance.ram[..] == ram[..]
	assert vm_instance.a == 255
	assert vm_instance.b == 255
}

fn test_vm_cmp() {
	// ADD a, zero, $10
	// ADD b, zero, $20
	// CMP a, b
	// TRAP zero, zero, $255
	program := [
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
				val: 10
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
				val: 20
			})
		},
		bytecode.Instruction{
			opcode:   .cmp
			encoding: .rr
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .b
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

	vm_instance.run()!
	assert vm_instance.a == 10
	assert vm_instance.b == 20
	assert vm_instance.sr.has(.negative) == true
}

fn test_vm_branch_lt() {
	// ADD a, zero, $10
	// ADD b, zero, $20
	// CMP a, b
	// BLT $16, $21
	// ADD a, zero, $72
	// ADD b, zero, $73
	// TRAP zero, zero, $255
	program := [
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
				val: 10
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
				val: 20
			})
		},
		bytecode.Instruction{
			opcode:   .cmp
			encoding: .rr
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .b
			})
		},
		bytecode.Instruction{
			opcode:   .b
			extra:    ?bytecode.Extra(bytecode.Branch.bneg)
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 16
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 22
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
				val: 72
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
				val: 73
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

	vm_instance.run()!
	assert vm_instance.a == 10
	assert vm_instance.b == 20
}
