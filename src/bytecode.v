module bytecode

enum Opcode as u8 {
	nop = 0
	alu  @[EXTRA]
	push
	pop
	sbz
	sb
	lbz
	lb
	cmp
	b  @[EXTRA]
	jal
	j
	_go
}

fn (opcode Opcode) get_extra(value u8) ?Extra {
	$for op in Opcode.values {
		if 'EXTRA' in op.attrs && opcode == op.value {
			return match opcode {
				.alu { ?Extra(Alu.from(value)!) }
				.b { ?Extra(Branch.from(value)!) }
				else { panic('Unreachable') }
			}
		}
	}
	return none
}

enum Encoding as u8 {
	rrr = 0
	rri
	rrm
	mrr
	mri
	mrm
	rr
	ri
	rm
	mr
	mi
	mm
	ii
	r
	i
	m
}

enum Branch as u8 {
	bneg = 0
	bzo
	ble
	bof
	bca
}

enum Alu as u8 {
	add = 1
	sub
}

type Extra = Branch | Alu

fn (extra Extra) get_value() u8 {
	return match extra {
		Branch { u8(extra) }
		Alu { u8(extra) }
	}
}

enum Register as u8 {
	a = 0
	b
	x
	y
	ra
}

struct Register_Ref {
	reg Register
}

struct Immediate {
	val u8
}

struct Memory {
	reg Register
}

type Operand = Register_Ref | Immediate | Memory

fn (operand Operand) get_value() u8 {
	return match operand {
		Register_Ref { u8(operand.reg) & 0xF }
		Immediate { operand.val }
		Memory { u8(operand.reg) & 0xF }
	}
}

struct Instruction {
	opcode   Opcode
	encoding Encoding
	extra    ?Extra
	op1      Operand
	op2      ?Operand
	op3      ?Operand
}

fn decode_op(op u8) !(Opcode, Encoding) {
	opcode := Opcode.from(op >> 4) or { return error('Unknown opcode ${op >> 4}') }
	encoding := Encoding.from(op & 0xF) or { return error('Unknown encoding ${op & 0xF}') }

	return opcode, encoding
}

fn (instruction Instruction) encode_instruction() ![]u8 {
	if instruction == Instruction{} {
		return [u8(0)]
	}

	mut encoding := []u8{}

	encoding << ((u8(instruction.opcode) << 4) | u8(instruction.encoding))

	if extra := instruction.extra {
		encoding << extra.get_value()
	}

	encoding << encode_operands(instruction.encoding, instruction.op1, instruction.op2,
		instruction.op3) or { return error('Unable to encode operands') }

	return encoding
}

fn decode_operands(program []u8, offset u16, encoding Encoding) !(Operand, ?Operand, ?Operand) {
	return match encoding {
		.rrr {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset + 1] >> 4)!
			})
		}
		.rri {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			})
		}
		.rrm {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset + 1] >> 4)!
			})
		}
		.mrr {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset + 1] >> 4)!
			})
		}
		.mri {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			})
		}
		.mrm {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset + 1] >> 4)!
			})
		}
		.rr {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none)
		}
		.ri {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), ?Operand(none)
		}
		.rm {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none)
		}
		.mr {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none)
		}
		.mi {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), ?Operand(none)
		}
		.mm {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none)
		}
		.ii {
			Operand(Immediate{
				val: program[offset]
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), ?Operand(none)
		}
		.r {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(none), ?Operand(none)
		}
		.i {
			Operand(Immediate{
				val: program[offset]
			}), ?Operand(none), ?Operand(none)
		}
		.m {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(none), ?Operand(none)
		}
	}
}

fn encode_operands(encoding Encoding, op1 Operand, op2 ?Operand, op3 ?Operand) ?[]u8 {
	return match encoding {
		.rrr, .rrm, .mrr, .mrm { [(op1.get_value() << 4) | op2?.get_value(), op3?.get_value() << 4] }
		.rri, .mri { [(op1.get_value() << 4) | op2?.get_value(), op3?.get_value()] }
		.rr, .rm, .mr, .mm { [op1.get_value() << 4 | op2?.get_value()] }
		.ri, .mi { [op1.get_value() << 4, op2?.get_value()] }
		.ii { [op1.get_value(), op2?.get_value()] }
		.r, .m { [op1.get_value() << 4] }
		.i { [op1.get_value()] }
	}
}

pub fn decode(program []u8, program_counter u16) !Instruction {
	if program_counter > program.len {
		return error('End of program reached!')
	}

	opcode, encoding := decode_op(program[program_counter])!

	if opcode == .nop {
		return Instruction{}
	}

	extra := opcode.get_extra(program[program_counter + 1])
	op1, op2, op3 := decode_operands(program, program_counter +
		if extra == none { u16(1) } else { u16(2) }, encoding) or {
		return error('Error while decoding operands')
	}

	return Instruction{
		opcode:   opcode
		extra:    extra
		encoding: encoding
		op1:      op1
		op2:      op2
		op3:      op3
	}
}
