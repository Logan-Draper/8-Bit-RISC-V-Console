module dst

import vm
import rand
import rand.musl

pub struct DSTError {
	Error
pub:
	message string
	seed    u32
}

pub fn (dst_err DSTError) msg() string {
	return dst_err.message
}

pub fn (dst_err DSTError) seed() u32 {
	return dst_err.seed
}

pub fn run(seed ?int, max_time ?int) !u32 {
	random_seed := if seed != none {
		u32(seed)
	} else {
		rand.u32()
	}
	mut rng := &rand.PRNG(musl.MuslRNG{})
	rng.seed([random_seed])

	ram := rng.bytes(0x10000)!

	mut vm_instance := vm.VM{
		pc:  rng.u16()
		sp:  u16(rng.u32_in_range(256, 4096)!)
		ra:  rng.u16()
		r1:  rng.u8()
		r2:  rng.u8()
		r3:  rng.u8()
		r4:  rng.u8()
		r5:  rng.u8()
		r6:  rng.u8()
		r7:  rng.u8()
		r8:  rng.u8()
		r9:  rng.u8()
		r10: rng.u8()
		r11: rng.u8()
		r12: rng.u8()
		r13: rng.u8()
		r14: rng.u8()
		r15: rng.u8()
	}

	for i, b in ram {
		vm_instance.ram[i] = b
	}

	if max_time != none {
		for _ in 0 .. max_time {
			done := vm_instance.step() or {
				match err {
					vm.VMError {
						return random_seed
					}
					else {
						return DSTError{
							message: 'Simulator failed on ${err}'
							seed:    random_seed
						}
					}
				}
			}

			if done {
				break
			}
		}
	} else {
		vm_instance.run() or {
			match err {
				vm.VMError {
					return random_seed
				}
				else {
					return DSTError{
						message: 'Simulator failed on ${err}'
						seed:    random_seed
					}
				}
			}
		}
	}

	return random_seed
}
