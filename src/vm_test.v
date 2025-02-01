module vm

import bytecode
import arrays
import rand
import v.reflection

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
	// LBZ r1, $200
	// ADD r2, zero, $2
	// SBZ r2, r2
	// LBZ r3, r2
	// ADD r4, zero, $3
	// SBZ r4, r4
	// SBZ &r4, &r4
	// LBZ r5, &r4
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
				reg: .r1
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
				reg: .r2
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
				reg: .r2
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
			})
		},
		bytecode.Instruction{
			opcode:   .lbz
			encoding: .rr
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r3
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
			})
		},
		// Third
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r4
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
				reg: .r4
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r4
			})
		},
		bytecode.Instruction{
			opcode:   .sbz
			encoding: .mm
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r4
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r4
			})
		},
		bytecode.Instruction{
			opcode:   .lbz
			encoding: .rm
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r5
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r4
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
	assert vm_instance.r1 == 42
	assert vm_instance.r2 == 2
	assert vm_instance.r3 == 2
	assert vm_instance.r4 == 3
	assert vm_instance.r5 == 3
}

fn test_vm_push_pop() {
	// ADD r4, zero, 3
	// PUSH $42
	// PUSH r4
	// POP r2
	// POP r1
	// TRAP zero, zero, $255
	program := [
		// Preload 3 into y
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r4
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
				reg: .r4
			})
		},
		bytecode.Instruction{
			opcode:   .pop
			encoding: .r
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
			})
		},
		bytecode.Instruction{
			opcode:   .pop
			encoding: .r
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
	assert vm_instance.r1 == 42
	assert vm_instance.r2 == 3
}

fn test_vm_sb_lb() {
	// ADD r1, zero, $255
	// SB r1, r1, $255
	// LB r2, r1, $255
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 255
			})
		},
		bytecode.Instruction{
			opcode:   .lb
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
	assert vm_instance.r1 == 255
	assert vm_instance.r2 == 255
}

fn test_vm_cmp() {
	// ADD r1, zero, $10
	// ADD r2, zero, $20
	// CMP r1, r2
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
				reg: .r2
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
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
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
	assert vm_instance.r1 == 10
	assert vm_instance.r2 == 20
	assert vm_instance.sr.has(.negative) == true
}

fn test_vm_branch_lt() {
	// ADD r1, zero, $10
	// ADD r2, zero, $20
	// CMP r1, r2
	// BLT $16, $21
	// ADD r1, zero, $72
	// ADD r2, zero, $73
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
				reg: .r2
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
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
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
				reg: .r1
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
				reg: .r2
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
	assert vm_instance.r1 == 10
	assert vm_instance.r2 == 20
}

fn test_vm_branch_j() {
	// J $16, $16
	// ADD r1, zero, 54
	// ADD r2, zero, 55
	// ADD r3, zero, 56
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .j
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 16
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 15
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
				reg: .r2
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
				reg: .r3
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 56
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
	assert vm_instance.r1 == 0
	assert vm_instance.r2 == 0
	assert vm_instance.r3 == 0
}

fn test_vm_branch_jal() {
	// JAL $16, $16
	// ADD r1, zero, 54
	// ADD r2, zero, 55
	// ADD r3, zero, 56
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .jal
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 16
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 15
			})
		},
		bytecode.Instruction{
			opcode:   .alu
			encoding: .rri
			extra:    ?bytecode.Extra(bytecode.Alu.add)
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
				reg: .r2
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
				reg: .r3
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 56
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
	assert vm_instance.r1 == 0
	assert vm_instance.r2 == 0
	assert vm_instance.r3 == 0
	assert vm_instance.ra == 0x1003
}

fn test_vm_branch_jal_ret() {
	// JAL $16, $18
	// ADD r1, r1, 1
	// ADD r2, r2, 1
	// ADD r3, r3, 1
	// TRAP zero, zero, $255
	// ADD r1, zero, 54
	// ADD r2, zero, 55
	// ADD r3, zero, 56
	// RET
	// TRAP zero, zero, $255
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
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
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
				reg: .r2
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r2
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
				reg: .r3
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .r3
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
				reg: .r1
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
				reg: .r2
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
				reg: .r3
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
	mut vm_instance := create_vm_with_program(binary)!
	mut ram := vm_instance.ram[..]

	vm_instance.run()!
	assert vm_instance.r1 == 55
	assert vm_instance.r2 == 56
	assert vm_instance.r3 == 57
}

fn test_vm_run_fuzz() {
	for _ in 0 .. 100 {
		mut vm_instance := VM{
			pc:  rand.u16()
			sp:  u16(rand.u32_in_range(256, 4096)!)
			ra:  rand.u16()
			r1:  rand.u8()
			r2:  rand.u8()
			r3:  rand.u8()
			r4:  rand.u8()
			r5:  rand.u8()
			r6:  rand.u8()
			r7:  rand.u8()
			r8:  rand.u8()
			r9:  rand.u8()
			r10: rand.u8()
			r11: rand.u8()
			r12: rand.u8()
			r13: rand.u8()
			r14: rand.u8()
			r15: rand.u8()
		}

		for i := 0; i < 65536; i++ {
			vm_instance.ram[i] = rand.u8()
		}

		vm_instance.run() or {
			match err {
				VMError { continue }
				else { panic(err) }
			}
		}
	}
}

// Copied this over for purposes of random vm testing
// Not the best option but it works for now
// Plus its just testing
fn generate_random_instruction() !bytecode.Instruction {
	enums := reflection.get_enums().filter(it.name in ['Register', 'Opcode', 'Encoding', 'Alu',
		'Branch'])
	mut m := map[string]int{}
	for e in enums {
		m[e.name] = (e.sym.info as reflection.Enum).vals.len
	}

	reg1 := bytecode.Operand(bytecode.Register_Ref{
		reg: bytecode.Register.from(rand.intn(m['Register'])!)!
	})
	reg2 := ?bytecode.Operand(bytecode.Register_Ref{
		reg: bytecode.Register.from(rand.intn(m['Register'])!)!
	})
	reg3 := ?bytecode.Operand(bytecode.Register_Ref{
		reg: bytecode.Register.from(rand.intn(m['Register'])!)!
	})

	imm1 := bytecode.Operand(bytecode.Immediate{
		val: u8(rand.intn(256)!)
	})
	imm2 := ?bytecode.Operand(bytecode.Immediate{
		val: u8(rand.intn(256)!)
	})

	mem1 := bytecode.Operand(bytecode.Memory{
		reg: bytecode.Register.from(rand.intn(m['Register'])!)!
	})
	mem2 := ?bytecode.Operand(bytecode.Memory{
		reg: bytecode.Register.from(rand.intn(m['Register'])!)!
	})
	mem3 := ?bytecode.Operand(bytecode.Memory{
		reg: bytecode.Register.from(rand.intn(m['Register'])!)!
	})

	opcode := bytecode.Opcode.from(rand.intn(m['Opcode'])!)!
	mut encoding := bytecode.Encoding.from(rand.intn(m['Encoding'])!)!
	for !opcode.is_valid_encoding(encoding) {
		encoding = bytecode.Encoding.from(rand.intn(m['Encoding'])!)!
	}
	extra := if opcode in [.alu, .b] {
		match opcode {
			.alu { ?bytecode.Extra(bytecode.Alu.from(rand.intn(m['Alu'])! + 1)!) }
			.b { ?bytecode.Extra(bytecode.Branch.from(rand.intn(m['Branch'])!)!) }
			else { panic('Unreachable') }
		}
	} else {
		?bytecode.Extra(none)
	}

	op1, op2, op3 := match encoding {
		.rrr { reg1, reg2, reg3 }
		.rri { reg1, reg2, imm2 }
		.rrm { reg1, reg2, mem3 }
		.mrr { mem1, reg2, reg3 }
		.mri { mem1, reg2, imm2 }
		.mrm { mem1, reg2, mem3 }
		.rr { reg1, reg2, ?bytecode.Operand(none) }
		.ri { reg1, imm2, ?bytecode.Operand(none) }
		.rm { reg1, mem2, ?bytecode.Operand(none) }
		.mr { mem1, reg2, ?bytecode.Operand(none) }
		.mi { mem1, imm2, ?bytecode.Operand(none) }
		.mm { mem1, mem2, ?bytecode.Operand(none) }
		.ii { imm1, imm2, ?bytecode.Operand(none) }
		.r { reg1, ?bytecode.Operand(none), ?bytecode.Operand(none) }
		.i { imm1, ?bytecode.Operand(none), ?bytecode.Operand(none) }
		.m { mem1, ?bytecode.Operand(none), ?bytecode.Operand(none) }
	}

	return bytecode.Instruction{
		opcode:   opcode
		encoding: encoding
		extra:    extra
		op1:      op1
		op2:      op2
		op3:      op3
	}
}

fn test_vm_run_fuzz_valid_intructions() {
	for _ in 0 .. 2 {
		mut vm_instance := VM{}

		mut i := 0x1000
		for i < 0xFFFF {
			bytes := generate_random_instruction()!.encode_instruction()!
			for j in 0 .. bytes.len {
				if i + j >= 65536 {
					break
				}
				vm_instance.ram[i + j] = bytes[j]
			}
			i += bytes.len
		}

		for k in 0 .. 50 {
			done := vm_instance.step() or {
				// This essentially allows us to say allow `VMError` and
				// panic on all other error types. That way we know all
				// edge cases are at least being caught and thus not
				// panicing
				match err {
					VMError {
						break
					}
					else {
						panic(err)
					}
				}
			}
			if done {
				break
			}
		}
	}
}

fn test_vm_input() {
	// TRAP r1, zero, $1
	// TRAP zero, zero, $255
	program := [
		bytecode.Instruction{
			opcode:   .trap
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Memory{
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
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
