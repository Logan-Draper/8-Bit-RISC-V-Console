module main

import tui_console
import cli
import os
import dst

fn main() {
	mut app := cli.Command{
		name:        'fantavm'
		description: 'fantavm, fantasy 8 bit computer'
	}

	mut tui_cmd := cli.Command{
		name:          'tui'
		description:   'tui step debugger'
		usage:         'nothing for now'
		required_args: 0
		execute:       tui_func
	}

	app.add_command(tui_cmd)

	mut dst_cmd := cli.Command{
		name:          'dst'
		description:   'Deterministic Simulation Testing'
		usage:         'nothing for now'
		required_args: 0
		execute:       dst_func
	}

	dst_cmd.add_flag(cli.Flag{
		flag:          .int
		required:      false
		name:          'simulation runs'
		abbrev:        'r'
		description:   'Number of simulation runs to perform'
		default_value: ['10']
	})

	dst_cmd.add_flag(cli.Flag{
		flag:        .int
		required:    false
		name:        'seed'
		abbrev:      's'
		description: 'Specific u32 seed to be run'
	})

	dst_cmd.add_flag(cli.Flag{
		flag:          .int
		required:      false
		name:          'max timesteps'
		abbrev:        't'
		description:   'Maximum number of timesteps to allow the VM to run'
		default_value: ['500']
	})

	app.add_command(dst_cmd)

	app.setup()
	app.parse(os.args)
}

fn tui_func(cmd cli.Command) ! {
	tui_console.run()!
}

fn dst_func(cmd cli.Command) ! {
	runs := cmd.flags.get_int('simulation runs') or {
		panic('No flag `simulation runs` with type `int`')
	}

	seed := cmd.flags.get_int('seed') or { 0 }
	if seed != 0 && runs > 1 {
		return error('If a seed is provided runs must be == 1, got ${runs}')
	}
	passed_seed := if seed != 0 { ?int(seed) } else { ?int(none) }

	max_time := cmd.flags.get_int('max timesteps') or { -1 }
	passed_time := if max_time != -1 { ?int(max_time) } else { ?int(none) }

	for _ in 0 .. runs {
		tested_seed := dst.run(passed_seed, passed_time) or {
			match err {
				dst.DSTError {
					eprintln(err.message)
					panic('DST Failed! seed: ${err.seed}')
				}
				else {
					panic(err)
				}
			}
		}

		println('DST Passed! seed: ${tested_seed}')
	}
}
