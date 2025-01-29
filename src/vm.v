module vm

import bytecode

enum Traps as u8 {
	halt = 255
}

@[flag]
enum StatusRegister {
	zero
	carry
	overflow
	negative
	peripheral
}

struct VM {
	zero u8
mut:
	ram [65536]u8
	pc  u16 = 0x1000
	sp  u16
	ra  u16
	sr  StatusRegister
	a   u8
	b   u8
	c   u8
	d   u8
	x   u8
	y   u8
	z   u8
}

fn create_vm_with_program(program []u8) !VM {
	if program.len > (65536 - 4096) {
		return error('Program too large!')
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
				.a { v.a }
				.b { v.b }
				.c { v.c }
				.d { v.d }
				.x { v.x }
				.y { v.y }
				.z { v.z }
			}
		}
		bytecode.Immediate {
			source.val
		}
		bytecode.Memory {
			match source.reg {
				.zero { v.ram[0] }
				.a { v.ram[v.a] }
				.b { v.ram[v.b] }
				.c { v.ram[v.c] }
				.d { v.ram[v.d] }
				.x { v.ram[v.x] }
				.y { v.ram[v.y] }
				.z { v.ram[v.z] }
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
				.a { v.a = byte_value }
				.b { v.b = byte_value }
				.c { v.c = byte_value }
				.d { v.d = byte_value }
				.x { v.x = byte_value }
				.y { v.y = byte_value }
				.z { v.z = byte_value }
			}
		}
		bytecode.Immediate {
			return error('Attempting to set value with destination of an immediate')
			// zero_page_offset := destination.val
			// v.ram[zero_page_offset] = byte_value
		}
		bytecode.Memory {
			match destination.reg {
				.zero { v.ram[0] = byte_value }
				.a { v.ram[v.a] = byte_value }
				.b { v.ram[v.b] = byte_value }
				.c { v.ram[v.c] = byte_value }
				.d { v.ram[v.d] = byte_value }
				.x { v.ram[v.x] = byte_value }
				.y { v.ram[v.y] = byte_value }
				.z { v.ram[v.z] = byte_value }
			}
		}
	}
}

fn (mut v VM) set_memory(destination bytecode.Operand, value bytecode.Operand) {
	offset := v.get_value(destination)
	v.ram[offset] = v.get_value(value)
}

fn (mut v VM) run() ! {
	for {
		previous_sr := v.sr
		v.sr.clear_all()

		instruction, mut length := bytecode.decode(v.ram[..], v.pc) or {
			return error('Encoutered error while decoding instruction @ PC=0x${v.pc:X}:${err}')
		}

		match instruction.opcode {
			.alu {
				alu_code := instruction.extra or {
					return error('Attempting to execute alu call without an alu code')
				}

				match alu_code {
					bytecode.Branch {
						return error('Attempting to execute alu call with a branch extra')
					}
					bytecode.Alu {
						op2 := instruction.op2 or {
							return error('Attempting to execute an alu call without op2')
						}

						op3 := instruction.op3 or {
							return error('Attempting to execute an alu call without op3')
						}

						match alu_code {
							.add {
								v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{
									val: v.get_value(op2) + v.get_value(op3)
								}))!
							}
							.sub {
								v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{v.get_value(op2) - v.get_value(op3)}))!
							}
						}
					}
				}
			}
			.sbz {
				op2 := instruction.op2 or {
					return error('Attempting to execute an sbz call without op2')
				}

				v.set_memory(op2, instruction.op1)
			}
			.sb {
				value := v.get_value(instruction.op1)

				op2 := instruction.op2 or {
					return error('Attempting to execute a sb call without op2')
				}

				op3 := instruction.op3 or {
					return error('Attempting to execute a sb call without op3')
				}

				v.ram[(u16(v.get_value(op2)) << 8) | v.get_value(op3)] = value
			}
			.lbz {
				op2 := instruction.op2 or {
					return error('Attempting to execute an lbz call without op2')
				}

				v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{
					val: v.get_memory(op2)
				}))!
			}
			.lb {
				op2 := instruction.op2 or {
					return error('Attempting to execute a lb call without op2')
				}

				op3 := instruction.op3 or {
					return error('Attempting to execute a lb call without op3')
				}

				value := v.ram[(u16(v.get_value(op2)) << 8) | v.get_value(op3)]

				v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{ val: value }))!
			}
			.push {
				v.ram[256 + v.sp] = v.get_value(instruction.op1)
				v.sp++
			}
			.pop {
				v.sp--
				value := v.ram[256 + v.sp]
				v.set_value(instruction.op1, bytecode.Operand(bytecode.Immediate{ val: value }))!
			}
			.cmp {
				op2 := instruction.op2 or {
					return error('Attempting to execute a cmp call without op2')
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
					return error('Attempting to execute branch call without a branch code')
				}

				match branch_code {
					bytecode.Alu {
						return error('Attempting to execute branch call with alu extra')
					}
					bytecode.Branch {
						op2 := instruction.op2 or {
							return error('Attempting to execute a branch call without op2')
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
					return error('Attempting to execute a jump call without op2')
				}

				length = 0

				v.pc = (u16(v.get_value(instruction.op1)) << 8 | v.get_value(op2))
			}
			.jal {
				op2 := instruction.op2 or {
					return error('Attempting to execute a jump call without op2')
				}

				v.ra = v.pc + length
				length = 0

				v.pc = (u16(v.get_value(instruction.op1)) << 8 | v.get_value(op2))
			}
			.ret {
				println('Executing ret')
				length = 0
				v.pc = v.ra
				println('PC after ret: 0x${v.pc:X}')
			}
			.trap {
				trap_code := Traps.from(v.get_value(instruction.op3 or {
					return error('Attempting to execute trap call without a trap code')
				}))!

				match trap_code {
					.halt {
						v.sr = previous_sr
						return
					}
				}
			}
			else {
				panic('Unhandled instruction ${instruction.opcode}')
			}
		}

		v.pc += length
	}
}
