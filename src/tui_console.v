module tui_console

import bytecode
import vm
import arrays
import ui
import term
import os
import time

struct DebugInstruction {
	location    u16
	instruction bytecode.Instruction
}

fn zero_page(v vm.VM) string {
	return arrays.map_indexed(arrays.chunk(v.ram[0..256], 16).map(it.map('${it:02X}').join(' ')),
		fn (idx int, elem string) string {
		return '0x${idx * 16:02X}: ' + elem
	}).join('\n')
}

fn bits(b u8) string {
	mut str := ''
	for i := 7; i >= 0; i-- {
		str += '${(b >> i) & 1}'
	}

	return str
}

fn bits16(b u16) string {
	mut str := ''
	for i := 15; i >= 0; i-- {
		str += '${(b >> i) & 1}'
	}

	return str
}

fn registers(v vm.VM) string {
	return ['PC: 0x${v.pc:04X} ${bits16(v.pc)}', 'SP: 0x${v.sp:04X} ${bits16(v.sp)}',
		'RA: 0x${v.ra:04X} ${bits16(v.ra)}', '', ' A: 0x${v.a:02X}   ${bits(v.a)}',
		' B: 0x${v.b:02X}   ${bits(v.b)}', ' C: 0x${v.c:02X}   ${bits(v.c)}',
		' D: 0x${v.d:02X}   ${bits(v.d)}', ' X: 0x${v.x:02X}   ${bits(v.x)}',
		' Y: 0x${v.y:02X}   ${bits(v.y)}', ' Z: 0x${v.z:02X}   ${bits(v.z)}'].join('\n')
}

fn status_register(v vm.VM) string {
	return ['Z C O N P ? ? ?',
		'${int(v.sr.has(.zero))} ${int(v.sr.has(.carry))} ${int(v.sr.has(.overflow))} ${int(v.sr.has(.negative))} ${int(v.sr.has(.peripheral))} 0 0 0'].join('\n')
}

fn stack(v vm.VM, rows int) string {
	small_idx := if v.sp - (rows / 2) < 0 {
		256
	} else {
		256 + v.sp - (rows / 2)
	}
	big_idx := if v.sp + (rows / 2) > 4096 {
		4096
	} else {
		256 + v.sp + (rows / 2)
	}

	sp_idx := 256 + v.sp - small_idx

	stack_slice := v.ram[small_idx..big_idx]

	mut stack_str := arrays.map_indexed(stack_slice, fn [sp_idx] (idx int, elem u8) string {
		if idx == sp_idx {
			return '> ${elem:02X}'
		} else {
			return '  ${elem:02X}'
		}
	})

	if small_idx == 256 {
		// Pad beginning
		for stack_str.len < rows {
			stack_str.prepend('')
		}
	} else if big_idx == 4096 {
		// Pad end
		for stack_str.len < rows {
			stack_str << ''
		}
	}

	return stack_str.reverse().join('\n')
}

fn code(v vm.VM, instructions []DebugInstruction, rows int) string {
	current_instruction_idx := arrays.index_of_first(instructions, fn [v] (idx int, di DebugInstruction) bool {
		return di.location == v.pc
	})

	small_idx := if current_instruction_idx - (rows / 2) < 0 {
		0
	} else {
		current_instruction_idx - (rows / 2)
	}
	big_idx := if current_instruction_idx + (rows / 2) > instructions.len {
		instructions.len
	} else {
		current_instruction_idx + (rows / 2)
	}

	pc_idx := current_instruction_idx - small_idx

	program_slice := instructions[small_idx..big_idx]

	mut program_str := arrays.map_indexed(program_slice, fn [pc_idx] (idx int, elem DebugInstruction) string {
		if idx == pc_idx {
			return '> 0x${elem.location:04X}: ${elem.instruction.disassemble()}'
		} else {
			return '  0x${elem.location:04X}: ${elem.instruction.disassemble()}'
		}
	})

	if small_idx == 0 {
		for program_str.len < rows {
			program_str.prepend('')
		}
	} else if big_idx == instructions.len {
		for program_str.len < rows {
			program_str << ''
		}
	}

	return program_str.join('\n')
}

fn render(v vm.VM, instructions []DebugInstruction) ! {
	width, height := term.get_terminal_size()
	term.clear()

	mut x1, mut y1 := ui.percent_to_coord(0.025, 0.1)
	mut x2, mut y2 := ui.percent_to_coord(0.525, 0.5)
	ui.draw_text_box_w_title(x1, y1, x2, y2, code(v, instructions, y2 - y1 - 2), 'Code',
		ui.TextAlignment.unaligned)!

	x1, y1 = ui.percent_to_coord(0.025, 0.55)
	x2, y2 = ui.percent_to_coord(0.525, 1)
	ui.draw_text_box_w_title(x1, y1, x2, y2, zero_page(v), 'Zero Page', ui.TextAlignment.unaligned)!

	x1, y1 = ui.percent_to_coord(0.55, 0.1)
	x2, y2 = ui.percent_to_coord(0.7, 1)
	ui.draw_text_box_w_title(x1, y1, x2, y2, stack(v, y2 - y1 - 2), 'Stack', ui.TextAlignment.center)!

	x1, y1 = ui.percent_to_coord(0.73, 0.1)
	x2, y2 = ui.percent_to_coord(0.99, 0.75)
	ui.draw_text_box_w_title(x1, y1, x2, y2, registers(v), 'Registers', ui.TextAlignment.unaligned)!

	x1, y1 = ui.percent_to_coord(0.73, 0.85)
	x2, y2 = ui.percent_to_coord(0.99, 1)
	ui.draw_text_box_w_title(x1, y1, x2, y2, status_register(v), 'Status Regsiter', ui.TextAlignment.center)!

	term.set_cursor_position(x: 0, y: height)
	println('')
}

pub fn run() ! {
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
				reg: .a
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .a
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
				reg: .b
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .b
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
				reg: .c
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .c
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
				reg: .a
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
				reg: .b
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
				reg: .c
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 56
			})
		},
		bytecode.Instruction{
			opcode:   .push
			encoding: .i
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 69
			})
		},
		bytecode.Instruction{
			opcode:   .sbz
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 69
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 69
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
	mut vm_instance := vm.create_vm_with_program(binary)!

	mut instructions := []DebugInstruction{}

	mut i := u16(0)
	for i < binary.len {
		instruction, length := bytecode.decode(binary, i)!

		instructions << DebugInstruction{
			location:    0x1000 + i
			instruction: instruction
		}

		i += length
	}

	// println('\nBEGIN BINARY')
	// for instruction in instructions {
	// 	println('0x${instruction.location:X}: ${instruction.instruction.disassemble()}')
	// }
	// println('END BINARY\n')

	for {
		render(vm_instance, instructions)!
		current_instruction, _ := bytecode.decode(vm_instance.ram[..], vm_instance.pc)!
		done := vm_instance.step()!

		_ := os.input('')

		if done {
			break
		}
	}
}
