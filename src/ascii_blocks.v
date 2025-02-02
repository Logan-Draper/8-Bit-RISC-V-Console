module ascii_blocks

import color
import graphics
import strings

struct AsciiBlocksError {
	Error
	message string
}

pub fn (err AsciiBlocksError) message() string {
	return err.message
}

pub struct AsciiBlocks implements graphics.GraphicsDevice {
	width       u16
	height      u16
	num_buffers u8
mut:
	current_buffer int
	buffers        [][][]color.Color
}

pub fn AsciiBlocks.init(width u16, height u16, buffers u8) AsciiBlocks {
	return AsciiBlocks{
		width:       width
		height:      height
		num_buffers: buffers
		buffers:     [][][]color.Color{len: int(buffers), init: [][]color.Color{len: int(height), init: []color.Color{len: int(width)}}}
	}
}

pub fn (ab AsciiBlocks) display_size() !(u16, u16) {
	return ab.width, ab.height
}

pub fn (ab AsciiBlocks) buffer_count() !u8 {
	return ab.num_buffers
}

pub fn (ab AsciiBlocks) buffer_display(buffer u8) ! {
	if buffer >= ab.num_buffers {
		return AsciiBlocksError{
			message: 'Error displaying buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	mut sb := strings.new_builder(ab.width * ab.height * 16)

	for row in ab.buffers[buffer] {
		for col in row {
			sb.write_string('\033[38;2;${col.r};${col.g};${col.b}m██')
		}
		sb.writeln('')
	}

	sb.write_string('\033[39m\033[49m')

	print('\x1bP=1s\x1b\\')
	print('\x1b[2J\x1b[3J')
	print(sb.str())
	print('\x1bP=2s\x1b\\')
}

pub fn (ab AsciiBlocks) buffer_set_background(buffer u8, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return AsciiBlocksError{
			message: 'Error setting buffer background on ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	for mut row in ab.buffers[buffer] {
		for mut col in row {
			col = c
		}
	}
}

pub fn (ab AsciiBlocks) buffer_clear(buffer u8) ! {
	if buffer >= ab.num_buffers {
		return AsciiBlocksError{
			message: 'Error clearing buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	for mut row in ab.buffers[buffer] {
		for mut col in row {
			col = color.black
		}
	}
}

pub fn (mut ab AsciiBlocks) draw_pixel(buffer u8, x u16, y u16, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return AsciiBlocksError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	if x >= ab.width {
		return AsciiBlocksError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y >= ab.height {
		return AsciiBlocksError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	ab.buffers[buffer][y][x] = c
}
