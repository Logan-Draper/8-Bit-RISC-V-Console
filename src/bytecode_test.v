module bytecode

fn test_decode_opcode() {
	$for op in Opcode.values {
		opcode, _ := decode_op(u8(op.value) << 4)!
		assert opcode == op.value
	}
}

fn test_decode_encoding() {
	$for enc in Encoding.values {
		_, encoding := decode_op(u8(enc.value))!
		assert encoding == enc.value
	}
}

fn test_decode_op() {
	// V doesn't seem to like nested compile-time loops?
	// I split this out, but should probably file a bug report
	$for op in Opcode.values {
		$for enc in Encoding.values {
			_, encoding := decode_op((u8(op.value) << 4) | u8(enc.value))!
			assert encoding == enc.value
		}
	}
	$for enc in Encoding.values {
		$for op in Opcode.values {
			opcode, _ := decode_op((u8(op.value) << 4) | u8(enc.value))!
			assert opcode == op.value
		}
	}
}

fn test_decode_operands() {
	program := [u8((1 << 4) | 2), ((3 << 4) | 4)]
	expected_reg1 := Operand(Register_Ref{
		reg: Register.from(program[0] >> 4)!
	})
	expected_reg2 := Operand(Register_Ref{
		reg: Register.from(program[0] & 0xF)!
	})
	expected_reg3 := Operand(Register_Ref{
		reg: Register.from(program[1] >> 4)!
	})

	expected_imm1 := Operand(Immediate{
		val: program[0]
	})
	expected_imm2 := Operand(Immediate{
		val: program[1]
	})

	expected_mem1 := Operand(Memory{
		reg: Register.from(program[0] >> 4)!
	})
	expected_mem2 := Operand(Memory{
		reg: Register.from(program[0] & 0xF)!
	})
	expected_mem3 := Operand(Memory{
		reg: Register.from(program[1] >> 4)!
	})

	$for enc in Encoding.values {
		op1, op2, op3 := decode_operands(program, 0, enc.value)!

		match enc.value {
			.rrr {
				assert op1 == expected_reg1
				assert op2? == expected_reg2
				assert op3? == expected_reg3
			}
			.rri {
				assert op1 == expected_reg1
				assert op2? == expected_reg2
				assert op3? == expected_imm2
			}
			.rrm {
				assert op1 == expected_reg1
				assert op2? == expected_reg2
				assert op3? == expected_mem3
			}
			.mrr {
				assert op1 == expected_mem1
				assert op2? == expected_reg2
				assert op3? == expected_reg3
			}
			.mri {
				assert op1 == expected_mem1
				assert op2? == expected_reg2
				assert op3? == expected_imm2
			}
			.mrm {
				assert op1 == expected_mem1
				assert op2? == expected_reg2
				assert op3? == expected_mem3
			}
			.rr {
				assert op1 == expected_reg1
				assert op2? == expected_reg2
				assert op3 == none
			}
			.ri {
				assert op1 == expected_reg1
				assert op2? == expected_imm2
				assert op3 == none
			}
			.rm {
				assert op1 == expected_reg1
				assert op2? == expected_mem2
				assert op3 == none
			}
			.mr {
				assert op1 == expected_mem1
				assert op2? == expected_reg2
				assert op3 == none
			}
			.mi {
				assert op1 == expected_mem1
				assert op2? == expected_imm2
				assert op3 == none
			}
			.mm {
				assert op1 == expected_mem1
				assert op2? == expected_mem2
				assert op3 == none
			}
			.ii {
				assert op1 == expected_imm1
				assert op2? == expected_imm2
				assert op3 == none
			}
			.r {
				assert op1 == expected_reg1
				assert op2 == none
				assert op3 == none
			}
			.i {
				assert op1 == expected_imm1
				assert op2 == none
				assert op3 == none
			}
			.m {
				assert op1 == expected_mem1
				assert op2 == none
				assert op3 == none
			}
		}
	}
}

fn test_decode() {
	program := [u8(0)]
	pc := u16(0)

	instruction := decode(program, pc)!
	assert instruction.opcode == Opcode.nop
}
