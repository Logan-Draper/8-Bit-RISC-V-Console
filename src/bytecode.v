module bytecode

pub enum Opcode as u8 {
	nop = 0   @[i]
	alu   @[EXTRA; mri; mrm; mrr; rri; rrm; rrr]
	push  @[i; m; r]
	pop   @[m; r]
	sbz   @[ii; mi; mm; mr; ri; rm; rr]
	sb    @[mri; mrm; mrr; rri; rrm; rrr]
	lbz   @[mi; mm; mr; ri; rm; rr]
	lb    @[mri; mrm; mrr; rri; rrm; rrr]
	cmp   @[ii; mi; mm; mr; ri; rm; rr]
	b     @[EXTRA; ii; mi; mm; mr; ri; rm; rr]
	jal   @[ii; mi; mm; mr; ri; rm; rr]
	j     @[ii; mi; mm; mr; ri; rm; rr]
	ret   @[i]
	trap  @[mri; mrm; mrr; rri; rrm; rrr]
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

pub fn (opcode Opcode) is_valid_encoding(encoding Encoding) bool {
	$for op in Opcode.values {
		if op.value == opcode && encoding.str() !in op.attrs {
			return false
		}
	}
	return true
}

pub enum Encoding as u8 {
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

pub enum Branch as u8 {
	bneg = 0
	bzo
	bof
	bca
}

pub enum Alu as u8 {
	add = 1
	sub
}

pub type Extra = Branch | Alu

pub fn (extra Extra) get_value() u8 {
	return match extra {
		Branch { u8(extra) }
		Alu { u8(extra) }
	}
}

pub enum Register as u8 {
	zero = 0
	r1
	r2
	r3
	r4
	r5
	r6
	r7
	r8
	r9
	r10
	r11
	r12
	r13
	r14
	r15
}

pub struct Register_Ref {
pub:
	reg Register
}

pub struct Immediate {
pub:
	val u8
}

pub struct Memory {
pub:
	reg Register
}

pub type Operand = Register_Ref | Immediate | Memory

fn (operand Operand) get_value() u8 {
	return match operand {
		Register_Ref { u8(operand.reg) & 0xF }
		Immediate { operand.val }
		Memory { u8(operand.reg) & 0xF }
	}
}

pub struct Instruction {
pub:
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

	if !opcode.is_valid_encoding(encoding) {
		return error('Unsupported encoding ${encoding} for opcode ${opcode}')
	}

	return opcode, encoding
}

pub fn (instruction Instruction) encode_instruction() ![]u8 {
	if instruction == Instruction{} {
		return [u8(0)]
	}

	if !instruction.opcode.is_valid_encoding(instruction.encoding) {
		return error('Unsupported encoding ${instruction.encoding} for opcode ${instruction.opcode}')
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

fn decode_operands(program []u8, offset u16, encoding Encoding) !(Operand, ?Operand, ?Operand, u16) {
	return match encoding {
		.rrr {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset + 1] >> 4)!
			}), 2
		}
		.rri {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), 2
		}
		.rrm {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset + 1] >> 4)!
			}), 2
		}
		.mrr {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset + 1] >> 4)!
			}), 2
		}
		.mri {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), 2
		}
		.mrm {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset + 1] >> 4)!
			}), 2
		}
		.rr {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none), 1
		}
		.ri {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), ?Operand(none), 2
		}
		.rm {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none), 1
		}
		.mr {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Register_Ref{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none), 1
		}
		.mi {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), ?Operand(none), 2
		}
		.mm {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(Memory{
				reg: Register.from(program[offset] & 0xF)!
			}), ?Operand(none), 1
		}
		.ii {
			Operand(Immediate{
				val: program[offset]
			}), ?Operand(Immediate{
				val: program[offset + 1]
			}), ?Operand(none), 2
		}
		.r {
			Operand(Register_Ref{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(none), ?Operand(none), 1
		}
		.i {
			Operand(Immediate{
				val: program[offset]
			}), ?Operand(none), ?Operand(none), 1
		}
		.m {
			Operand(Memory{
				reg: Register.from(program[offset] >> 4)!
			}), ?Operand(none), ?Operand(none), 1
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

pub fn decode(program []u8, program_counter u16) !(Instruction, u16) {
	if program_counter > program.len {
		return error('End of program reached!')
	}

	mut instruction_length := u16(1)

	opcode, encoding := decode_op(program[program_counter])!

	if opcode == .nop {
		return Instruction{}, instruction_length
	}

	extra := opcode.get_extra(program[program_counter + 1])
	if extra != none {
		instruction_length++
	}

	op1, op2, op3, operands_length := decode_operands(program, program_counter +
		if extra == none { u16(1) } else { u16(2) }, encoding) or {
		return error('Error while decoding operands')
	}

	instruction_length += operands_length

	return Instruction{
		opcode:   opcode
		encoding: encoding
		extra:    extra
		op1:      op1
		op2:      op2
		op3:      op3
	}, instruction_length
}

fn disassemble_operand(o ?Operand) string {
	op := o or { return '' }

	return match op {
		Register_Ref {
			op.reg.str()
		}
		Immediate {
			'\$${op.val}'
		}
		Memory {
			'&' + op.reg.str()
		}
	}
}

// This function isn't critial to the operation of the vm
// so it's going to do some unsafe casting internally
pub fn (i Instruction) disassemble() string {
	op1 := disassemble_operand(i.op1)
	op2 := disassemble_operand(i.op2)
	op3 := disassemble_operand(i.op3)

	instruction := match i.opcode {
		.nop, .push, .pop, .sbz, .sb, .lbz, .lb, .cmp, .jal, .j, .ret, .trap {
			i.opcode.str()
		}
		.alu, .b {
			extra := i.extra or {
				panic('Attempting to disassemble ${i.opcode} without an extra byte encoded')
			}

			match extra {
				Branch {
					extra.str()
				}
				Alu {
					extra.str()
				}
			}
		}
	}.to_upper()

	return match i.encoding {
		.rrr, .rri, .rrm, .mrr, .mri, .mrm { '${instruction} ${op1}, ${op2}, ${op3}' }
		.rr, .ri, .rm, .mr, .mi, .mm, .ii { '${instruction} ${op1}, ${op2}' }
		.r, .i, .m { '${instruction} ${op1}' }
	}
}
