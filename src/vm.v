module vm

import bytecode

struct VMError {
	Error
	message string
}

fn (vm_err VMError) msg() string {
	return vm_err.message
}

enum Traps as u8 {
	halt = 255
}

@[flag]
pub enum StatusRegister {
	zero
	carry
	overflow
	negative
	peripheral
}

pub struct VM {
	// input  io.Reader
	// output io.Writer
	zero u8
pub mut:
	ram [65536]u8
	pc  u16 = 0x1000
	sp  u16 = 0x0100
	ra  u16
	sr  StatusRegister
	r1  u8
	r2  u8
	r3  u8
	r4  u8
	r5  u8
	r6  u8
	r7  u8
	r8  u8
	r9  u8
	r10 u8
	r11 u8
	r12 u8
	r13 u8
	r14 u8
	r15 u8
}

pub fn create_vm_with_program(program []u8) !VM {
	if program.len > (65536 - 4096) {
		return VMError{
			message: 'Program too large!'
		}
	}

	mut ram := [65536]u8{}
	for index, val in program {
		ram[index + 4096] = val
	}

	return VM{
		ram: ram
	}
}

// Register: returns value in register
// Immediate: returns 8 bit immediate
// Memory: returns zero page value at value held in register
fn (v VM) get_value(source bytecode.Operand) u8 {
	return match source {
		bytecode.Register_Ref {
			match source.reg {
				.zero { 0 }
				.r1 { v.r1 }
				.r2 { v.r2 }
				.r3 { v.r3 }
				.r4 { v.r4 }
				.r5 { v.r5 }
				.r6 { v.r6 }
				.r7 { v.r7 }
				.r8 { v.r8 }
				.r9 { v.r9 }
				.r10 { v.r10 }
				.r11 { v.r11 }
				.r12 { v.r12 }
				.r13 { v.r13 }
				.r14 { v.r14 }
				.r15 { v.r15 }
			}
		}
		bytecode.Immediate {
			source.val
		}
		bytecode.Memory {
			match source.reg {
				.zero { v.ram[0] }
				.r1 { v.ram[v.r1] }
				.r2 { v.ram[v.r2] }
				.r3 { v.ram[v.r3] }
				.r4 { v.ram[v.r4] }
				.r5 { v.ram[v.r5] }
				.r6 { v.ram[v.r6] }
				.r7 { v.ram[v.r7] }
				.r8 { v.ram[v.r8] }
				.r9 { v.ram[v.r9] }
				.r10 { v.ram[v.r10] }
				.r11 { v.ram[v.r11] }
				.r12 { v.ram[v.r12] }
				.r13 { v.ram[v.r13] }
				.r14 { v.ram[v.r14] }
				.r15 { v.ram[v.r15] }
			}
		}
	}
}

// One more layer of indirection from the method above
// Register: Essentially like Memory from above, gets the value in the register, then uses that as a zero page offset
// Immediate: Uses 8 bit value as a zero page offset returning the value at the offset
// Memory: Grabs zero page value uses register contents as offset, then uses that value to offset again returning whats at the second offset
fn (v VM) get_memory(source bytecode.Operand) u8 {
	offset := v.get_value(source)
	return v.ram[offset]
}

fn (mut v VM) set_value(destination bytecode.Operand, value bytecode.Operand) ! {
	byte_value := v.get_value(value)

	match destination {
		bytecode.Register_Ref {
			match destination.reg {
				.zero {}
				.r1 { v.r1 = byte_value }
				.r2 { v.r2 = byte_value }
				.r3 { v.r3 = byte_value }
				.r4 { v.r4 = byte_value }
				.r5 { v.r5 = byte_value }
				.r6 { v.r6 = byte_value }
				.r7 { v.r7 = byte_value }
				.r8 { v.r8 = byte_value }
				.r9 { v.r9 = byte_value }
				.r10 { v.r10 = byte_value }
				.r11 { v.r11 = byte_value }
				.r12 { v.r12 = byte_value }
				.r13 { v.r13 = byte_value }
				.r14 { v.r14 = byte_value }
				.r15 { v.r15 = byte_value }
			}
		}
		bytecode.Immediate {
			return VMError{
				message: 'Attempting to set value with destination of an immediate'
			}
			// zero_page_offset := destination.val
			// v.ram[zero_page_offset] = byte_value
		}
		bytecode.Memory {
			match destination.reg {
				.zero { v.ram[0] = byte_value }
				.r1 { v.ram[v.r1] = byte_value }
				.r2 { v.ram[v.r2] = byte_value }
				.r3 { v.ram[v.r3] = byte_value }
				.r4 { v.ram[v.r4] = byte_value }
				.r5 { v.ram[v.r5] = byte_value }
				.r6 { v.ram[v.r6] = byte_value }
				.r7 { v.ram[v.r7] = byte_value }
				.r8 { v.ram[v.r8] = byte_value }
				.r9 { v.ram[v.r9] = byte_value }
				.r10 { v.ram[v.r10] = byte_value }
				.r11 { v.ram[v.r11] = byte_value }
				.r12 { v.ram[v.r12] = byte_value }
				.r13 { v.ram[v.r13] = byte_value }
				.r14 { v.ram[v.r14] = byte_value }
				.r15 { v.ram[v.r15] = byte_value }
			}
		}
	}
}

fn (mut v VM) set_memory(destination bytecode.Operand, value bytecode.Operand) {
	offset := v.get_value(destination)
	v.ram[offset] = v.get_value(value)
}

pub fn (mut v VM) step() !bool {
	mut done := false
	previous_sr := v.sr
	v.sr.clear_all()

	instruction, mut length := bytecode.decode(v.ram[..], v.pc) or {
		return VMError{
			message: 'Encoutered error while decoding instruction @ PC=0x${v.pc:X}:${err}'
		}
	}

	match instruction.opcode {
		.nop {}
		.alu {
			alu_code := instruction.extra or {
				return VMError{
					message: 'Attempting to execute alu call without an alu code'
				}
			}

			match alu_code {
				bytecode.Branch {
					return VMError{
						message: 'Attempting to execute alu call with a branch extra'
					}
				}
				bytecode.Alu {
					op2 := instruction.op2 or {
						return VMError{
							message: 'Attempting to execute an alu call without op2'
						}
					}

					op3 := instruction.op3 or {
						return VMError{
							message: 'Attempting to execute an alu call without op3'
						}
					}

					match alu_code {
						.add {
							v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{
								val: v.get_value(op2) + v.get_value(op3)
							})) or {
								return VMError{
									message: 'Failed to set vm value ${instruction.op1} in add'
								}
							}
						}
						.sub {
							v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{v.get_value(op2) - v.get_value(op3)})) or {
								return VMError{
									message: 'Failed to set vm value ${instruction.op1} in sub'
								}
							}
						}
					}
				}
			}
		}
		.sbz {
			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute an sbz call without op2'
				}
			}

			v.set_memory(op2, instruction.op1)
		}
		.sb {
			value := v.get_value(instruction.op1)

			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute a sb call without op2'
				}
			}

			op3 := instruction.op3 or {
				return VMError{
					message: 'Attempting to execute a sb call without op3'
				}
			}

			v.ram[(u16(v.get_value(op2)) << 8) | v.get_value(op3)] = value
		}
		.lbz {
			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute an lbz call without op2'
				}
			}

			v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{
				val: v.get_memory(op2)
			})) or {
				return VMError{
					message: 'Failed to set vm value ${instruction.op1} in lbz'
				}
			}
		}
		.lb {
			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute a lb call without op2'
				}
			}

			op3 := instruction.op3 or {
				return VMError{
					message: 'Attempting to execute a lb call without op3'
				}
			}

			value := v.ram[(u16(v.get_value(op2)) << 8) | v.get_value(op3)]

			v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{ val: value })) or {
				return VMError{
					message: 'Failed to set vm value ${instruction.op1} in lb'
				}
			}
		}
		.push {
			v.ram[v.sp] = v.get_value(instruction.op1)
			v.sp++
		}
		.pop {
			v.sp--
			value := v.ram[v.sp]
			v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{ val: value })) or {
				return VMError{
					message: 'Failed to set vm value ${instruction.op1} in pop'
				}
			}
		}
		.cmp {
			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute a cmp call without op2'
				}
			}

			result := int(v.get_value(instruction.op1)) - int(v.get_value(op2))

			if result < 0 {
				v.sr.set(.negative)
			}
			if result == 0 {
				v.sr.set(.zero)
			}
			if result > max_u8 {
				v.sr.set(.overflow)
			}
		}
		.b {
			branch_code := instruction.extra or {
				return VMError{
					message: 'Attempting to execute branch call without a branch code'
				}
			}

			match branch_code {
				bytecode.Alu {
					return VMError{
						message: 'Attempting to execute branch call with alu extra'
					}
				}
				bytecode.Branch {
					op2 := instruction.op2 or {
						return VMError{
							message: 'Attempting to execute a branch call without op2'
						}
					}

					length = 0

					match branch_code {
						.bneg {
							if previous_sr.has(.negative) {
								v.pc = (u16(v.get_value(instruction.op1)) << 8) | v.get_value(op2)
							}
						}
						.bzo {
							if previous_sr.has(.zero) {
								v.pc = (u16(v.get_value(instruction.op1)) << 8) | v.get_value(op2)
							}
						}
						.bof {
							if previous_sr.has(.overflow) {
								v.pc = (u16(v.get_value(instruction.op1)) << 8) | v.get_value(op2)
							}
						}
						.bca {
							if previous_sr.has(.carry) {
								v.pc = (u16(v.get_value(instruction.op1)) << 8) | v.get_value(op2)
							}
						}
					}
				}
			}
		}
		.j {
			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute a jump call without op2'
				}
			}

			length = 0

			v.pc = (u16(v.get_value(instruction.op1)) << 8 | v.get_value(op2))
		}
		.jal {
			op2 := instruction.op2 or {
				return VMError{
					message: 'Attempting to execute a jump call without op2'
				}
			}

			v.ra = v.pc + length
			length = 0

			v.pc = (u16(v.get_value(instruction.op1)) << 8 | v.get_value(op2))
		}
		.ret {
			length = 0
			v.pc = v.ra
		}
		.trap {
			trap_code := Traps.from(v.get_value(instruction.op3 or {
				return VMError{
					message: 'Attempting to execute trap call without a trap code'
				}
			})) or {
				return VMError{
					message: 'Attempting to create trap with unsupported code ${v.get_value(instruction.op3 or {
						bytecode.Operand{}
					})}'
				}
			}

			match trap_code {
				.halt {
					v.sr = previous_sr
					length = 0
					done = true
				}
			}
		}
	}

	v.pc += length
	return done
}

pub fn (mut v VM) run() ! {
	for {
		done := v.step()!

		if done {
			return
		}
	}
}
