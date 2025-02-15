module bytecode

import rand
import v.reflection

fn test_get_extra() {
	alu_opcode := Opcode.alu
	$for alu_op in Alu.values {
		assert alu_opcode.get_extra(u8(alu_op.value))? == Extra(alu_op.value)
	}
	b_opcode := Opcode.b
	$for b_op in Branch.values {
		assert b_opcode.get_extra(u8(b_op.value))? == Extra(b_op.value)
	}
	j_opcode := Opcode.j
	assert j_opcode.get_extra(42) == none
}

fn test_decode_op() {
	$for op in Opcode.values {
		// We have all possible encodings in the opcodes attribute
		// Form an array of those encoding enums
		encodings := op.attrs.filter(it != 'EXTRA').map(Encoding.from(it) or { Encoding.rrr })

		// Loop through all possible encodings for a opcode
		for enc in encodings {
			opcode, encoding := decode_op((u8(op.value) << 4) | u8(enc))!
			assert opcode == op.value
			assert encoding == enc
		}
	}
}

fn test_decode_op_fail() {
	all_encodings := []u8{len: 16, init: u8(index)}.map(Encoding.from(it)!)
	$for op in Opcode.values {
		// We have all possible encodings in the opcodes attribute
		// Form an array of those encoding enums which are not valid
		encodings := op.attrs.filter(it != 'EXTRA').map(Encoding.from(it) or { Encoding.rrr })

		invalid_encodings := all_encodings.filter(it !in encodings)

		// Loop through all invalid encodings for a opcode
		for enc in invalid_encodings {
			opcode, encoding := decode_op((u8(op.value) << 4) | u8(enc)) or {
				match err {
					BytecodeError {
						continue
					}
					else {
						assert false, '${err}'
						panic(err)
					}
				}
			}
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
		op1, op2, op3, length := decode_operands(program, 0, enc.value)!

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

fn test_encoder_operands() {
	reg1 := Operand(Register_Ref{
		reg: Register.r1
	})
	reg2 := Operand(Register_Ref{
		reg: Register.r2
	})
	reg3 := Operand(Register_Ref{
		reg: Register.zero
	})

	mem1 := Operand(Memory{
		reg: Register.r1
	})
	mem2 := Operand(Memory{
		reg: Register.r2
	})

	imm1 := Operand(Immediate{
		val: 1
	})
	imm2 := Operand(Immediate{
		val: 2
	})

	assert encode_operands(Encoding.rrr, reg1, reg2, reg3)? == [
		u8(reg1.get_value() << 4 | reg2.get_value()),
		reg3.get_value() << 4,
	]
	assert encode_operands(Encoding.rrm, reg1, reg2, mem2)? == [
		u8(reg1.get_value() << 4 | reg2.get_value()),
		mem2.get_value() << 4,
	]
	assert encode_operands(Encoding.mrr, mem1, reg2, reg3)? == [
		u8(mem1.get_value() << 4 | reg2.get_value()),
		reg3.get_value() << 4,
	]
	assert encode_operands(Encoding.mrm, mem1, reg2, mem2)? == [
		u8(mem1.get_value() << 4 | reg2.get_value()),
		mem2.get_value() << 4,
	]

	assert encode_operands(Encoding.rri, reg1, reg2, imm2)? == [
		u8(reg1.get_value() << 4 | reg2.get_value()),
		imm2.get_value(),
	]
	assert encode_operands(Encoding.mri, mem1, reg2, imm2)? == [
		u8(mem1.get_value() << 4 | reg2.get_value()),
		imm2.get_value(),
	]

	assert encode_operands(Encoding.rr, reg1, reg2, ?Operand(none))? == [
		u8(reg1.get_value() << 4 | reg2.get_value()),
	]
	assert encode_operands(Encoding.rm, reg1, mem2, ?Operand(none))? == [
		u8(reg1.get_value() << 4 | mem2.get_value()),
	]
	assert encode_operands(Encoding.mr, mem1, reg2, ?Operand(none))? == [
		u8(mem1.get_value() << 4 | reg2.get_value()),
	]
	assert encode_operands(Encoding.mm, mem1, mem2, ?Operand(none))? == [
		u8(mem1.get_value() << 4 | mem2.get_value()),
	]

	assert encode_operands(Encoding.ri, reg1, imm2, ?Operand(none))? == [
		u8(reg1.get_value() << 4),
		imm2.get_value(),
	]
	assert encode_operands(Encoding.mi, mem1, imm2, ?Operand(none))? == [
		u8(mem1.get_value() << 4),
		imm2.get_value(),
	]

	assert encode_operands(Encoding.ii, imm1, imm2, ?Operand(none))? == [
		u8(imm1.get_value()),
		imm2.get_value(),
	]

	assert encode_operands(Encoding.r, reg1, ?Operand(none), ?Operand(none))? == [
		u8(reg1.get_value() << 4),
	]
	assert encode_operands(Encoding.m, mem1, ?Operand(none), ?Operand(none))? == [
		u8(mem1.get_value() << 4),
	]

	assert encode_operands(Encoding.i, imm1, ?Operand(none), ?Operand(none))? == [
		u8(imm1.get_value()),
	]
}

fn test_encode_operands_fail() {
	// This function returns ? not ! so we don't pattern match the error type
	encode_operands(.rrr, Immediate{ val: 42 }, ?Operand(none), ?Operand(none)) or { return }
	assert false, 'Test failed'
}

fn test_decode_nop() {
	program := Instruction{
		encoding: Encoding.i
	}

	instruction, length := decode(program.encode_instruction()!, 0)!
	assert instruction.opcode == Opcode.nop
	assert length == 1
}

fn test_decode() {
	program := Instruction{
		opcode:   .alu
		encoding: .rrr
		extra:    ?Extra(Alu.add)
		op1:      Operand(Register_Ref{
			reg: .r1
		})
		op2:      ?Operand(Register_Ref{
			reg: .r2
		})
		op3:      ?Operand(Register_Ref{
			reg: .r3
		})
	}

	instruction, length := decode(program.encode_instruction()!, 0)!
	assert instruction == program
	assert length == 4
}

fn test_decode_multi() {
	instruction1 := Instruction{
		opcode:   .alu
		encoding: .rrr
		extra:    ?Extra(Alu.add)
		op1:      Operand(Register_Ref{
			reg: .r1
		})
		op2:      ?Operand(Register_Ref{
			reg: .r2
		})
		op3:      ?Operand(Register_Ref{
			reg: .r3
		})
	}
	instruction2 := Instruction{
		opcode:   .alu
		encoding: .rri
		extra:    ?Extra(Alu.add)
		op1:      Operand(Register_Ref{
			reg: .r1
		})
		op2:      ?Operand(Register_Ref{
			reg: .r2
		})
		op3:      ?Operand(Immediate{
			val: 42
		})
	}

	mut program := instruction1.encode_instruction()!
	program << instruction2.encode_instruction()!

	mut instruction, mut length := decode(program, 0)!
	assert instruction == instruction1
	assert length == 4

	instruction, length = decode(program, length)!
	assert instruction == instruction2
	assert length == 4
}

fn generate_random_instruction() !Instruction {
	enums := reflection.get_enums().filter(it.name in ['Register', 'Opcode', 'Encoding', 'Alu',
		'Branch'])
	mut m := map[string]int{}
	for e in enums {
		m[e.name] = (e.sym.info as reflection.Enum).vals.len
	}

	reg1 := Operand(Register_Ref{
		reg: Register.from(rand.intn(m['Register'])!)!
	})
	reg2 := ?Operand(Register_Ref{
		reg: Register.from(rand.intn(m['Register'])!)!
	})
	reg3 := ?Operand(Register_Ref{
		reg: Register.from(rand.intn(m['Register'])!)!
	})

	imm1 := Operand(Immediate{
		val: u8(rand.intn(256)!)
	})
	imm2 := ?Operand(Immediate{
		val: u8(rand.intn(256)!)
	})

	mem1 := Operand(Memory{
		reg: Register.from(rand.intn(m['Register'])!)!
	})
	mem2 := ?Operand(Memory{
		reg: Register.from(rand.intn(m['Register'])!)!
	})
	mem3 := ?Operand(Memory{
		reg: Register.from(rand.intn(m['Register'])!)!
	})

	opcode := Opcode.from(rand.intn(m['Opcode'])!)!
	encoding := Encoding.from(rand.intn(m['Encoding'])!)!
	extra := if opcode in [.alu, .b] {
		match opcode {
			.alu { ?Extra(Alu.from(rand.intn(m['Alu'])! + 1)!) }
			.b { ?Extra(Branch.from(rand.intn(m['Branch'])!)!) }
			else { panic('Unreachable') }
		}
	} else {
		?Extra(none)
	}

	op1, op2, op3 := match encoding {
		.rrr { reg1, reg2, reg3 }
		.rri { reg1, reg2, imm2 }
		.rrm { reg1, reg2, mem3 }
		.mrr { mem1, reg2, reg3 }
		.mri { mem1, reg2, imm2 }
		.mrm { mem1, reg2, mem3 }
		.rr { reg1, reg2, ?Operand(none) }
		.ri { reg1, imm2, ?Operand(none) }
		.rm { reg1, mem2, ?Operand(none) }
		.mr { mem1, reg2, ?Operand(none) }
		.mi { mem1, imm2, ?Operand(none) }
		.mm { mem1, mem2, ?Operand(none) }
		.ii { imm1, imm2, ?Operand(none) }
		.r { reg1, ?Operand(none), ?Operand(none) }
		.i { imm1, ?Operand(none), ?Operand(none) }
		.m { mem1, ?Operand(none), ?Operand(none) }
	}

	return Instruction{
		opcode:   opcode
		encoding: encoding
		extra:    extra
		op1:      op1
		op2:      op2
		op3:      op3
	}
}

fn test_instruction_gen_decode() {
	for i in 0 .. 1_000 {
		random_instruction := generate_random_instruction()!
		instruction, length := decode(random_instruction.encode_instruction() or {
			if !random_instruction.opcode.is_valid_encoding(random_instruction.encoding) {
				continue
			} else {
				assert false, 'Decode failed with valid instruction ${random_instruction}'
				[]u8{}
			}
		}, 0) or {
			if !random_instruction.opcode.is_valid_encoding(random_instruction.encoding) {
				continue
			} else {
				assert false, 'Decode failed with valid instruction ${random_instruction}'
				Instruction{}, u16(0)
			}
		}
	}
}

fn test_fuzz_decode() {
	for i in 0 .. 1_000 {
		random_data := rand.bytes(4)!

		instruction, length := decode(random_data, 0) or {
			match err {
				BytecodeError {
					continue
				}
				else {
					assert false, '${err}'
					panic(err)
				}
			}
		}

		assert length > 0
	}
}
