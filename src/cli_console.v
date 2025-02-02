module cli_console

import vm
import bytecode
import arrays
import term.termios

pub fn run() ! {
	program := [
		bytecode.Instruction{
			opcode:   .trap
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Register_Ref{
				reg: .zero
			})
			op3:      ?bytecode.Operand(bytecode.Immediate{
				val: 3
			})
		},
		bytecode.Instruction{
			opcode:   .trap
			encoding: .rri
			op1:      bytecode.Operand(bytecode.Register_Ref{
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
			opcode:   .cmp
			encoding: .ri
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 255
			})
		},
		bytecode.Instruction{
			opcode:   .b
			encoding: .ii
			extra:    ?bytecode.Extra(bytecode.Branch.bzo)
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 16
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
				val: 18
			})
		},
		bytecode.Instruction{
			opcode:   .push
			encoding: .r
			op1:      bytecode.Operand(bytecode.Register_Ref{
				reg: .r1
			})
		},
		bytecode.Instruction{
			opcode:   .j
			encoding: .ii
			op1:      bytecode.Operand(bytecode.Immediate{
				val: 16
			})
			op2:      ?bytecode.Operand(bytecode.Immediate{
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

	mut original_term := termios.Termios{}
	termios.tcgetattr(0, mut original_term)

	mut silent_term := original_term
	silent_term.c_lflag &= (termios.invert(C.ECHO) & termios.invert(C.ICANON) & termios.invert(C.ISIG))
	termios.tcsetattr(0, C.TCSANOW, mut silent_term)

	at_exit(fn [mut original_term] () {
		termios.tcsetattr(0, C.TCSANOW, mut original_term)
	})!

	vm_instance.run()!
}
