module vm

import bytecode

struct VM {
	ram  [65536]u8
	zero u8
mut:
	pc u16 = 0x1000
	sp u16
	sr u16
	a  u8
	b  u8
	x  u8
	y  u8
	ra u8
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

fn (mut v VM) run() ! {
	for {
		instruction, length := bytecode.decode(v.ram[..], v.pc)!

		match instruction.opcode {
			.alu {}
			.trap {
				if instruction.op3 or { panic('') }.get_value() == 255 {
					return
				}
			}
			else {
				panic('oh ni!')
			}
		}

		v.pc += length
	}
}
