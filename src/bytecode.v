module bytecode

enum Opcode as u8 {
	nop = 0
	add
	sub
	push
	pop
	sbz
	sb
	lbz
	lb
	cmp
	b
	jal
	j
	_go
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

struct Instruction {
	opcode      Opcode
	branch_type ?Branch
	encoding    Encoding
	op1         Operand
	op2         ?Operand
	op3         ?Operand
}

fn decode_op(op u8) !(Opcode, Encoding) {
	opcode := Opcode.from(op >> 4) or { return error('Unknown opcode ${op >> 4}') }
	encoding := Encoding.from(op & 0xF) or { return error('Unknown encoding ${op & 0xF}') }

	return opcode, encoding
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

pub fn decode(program []u8, program_counter u16) !Instruction {
	if program_counter > program.len {
		return error('End of program reached!')
	}

	opcode, encoding := decode_op(program[program_counter])!

	if opcode == .nop {
		return Instruction{}
	}

	branch_type := if opcode == .b {
		?Branch(Branch.from(program[program_counter + 1]) or {
			return error('Unknown branch type ${program[program_counter + 1]}')
		})
	} else {
		?Branch(none)
	}

	op1, op2, op3 := decode_operands(program, program_counter +
		if branch_type != none { u16(2) } else { u16(1) }, encoding) or {
		return error('Error while decoding operands')
	}

	return Instruction{
		opcode:      opcode
		branch_type: branch_type
		encoding:    encoding
		op1:         op1
		op2:         op2
		op3:         op3
	}
}
