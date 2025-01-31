module ui

import term
import arrays

pub enum TextAlignment {
	unaligned
	center
}

pub fn percent_to_coord(x f64, y f64) (int, int) {
	width, height := term.get_terminal_size()

	x_ret := int(width * x)
	y_ret := int(height * y)

	return x_ret, y_ret
}

fn draw_horizontal_line(x1 int, x2 int, y int) ! {
	if x1 >= x2 {
		return error('Drawing a line with flipped x1 x2, ${x1} >= ${x2}')
	}

	original_cursor_pos := term.get_cursor_position()!
	defer {
		term.set_cursor_position(original_cursor_pos)
	}

	term.set_cursor_position(x: x1, y: y)
	for _ in 0 .. (x2 - x1) + 1 {
		print('─')
	}
}

fn draw_vertical_line(y1 int, y2 int, x int) ! {
	if y1 >= y2 {
		return error('Drawing a line with flipped y1 y2, ${y1} >= ${y2}')
	}

	original_cursor_pos := term.get_cursor_position()!
	defer {
		term.set_cursor_position(original_cursor_pos)
	}

	term.set_cursor_position(y: y1, x: x)
	for _ in 0 .. (y2 - y1) + 1 {
		print('│')
		term.cursor_down(1)
		term.cursor_back(1)
	}
}

// Coords must be top left, bottom right, cannot be inverted or will fail
pub fn draw_box(x1 int, y1 int, x2 int, y2 int) ! {
	original_cursor_pos := term.get_cursor_position()!
	defer {
		term.set_cursor_position(original_cursor_pos)
	}

	width := x2 - x1
	height := y2 - y1

	if width <= 1 {
		return error('Drawing a rect with width ${width} <= 1')
	}

	if height <= 1 {
		return error('Drawing a rect with height ${height} <= 1')
	}

	// Top Left
	term.set_cursor_position(x: x1, y: y1)
	print('╭')
	// Top edge
	draw_horizontal_line(x1 + 1, x2 - 1, y1)!
	// Top Right
	term.set_cursor_position(x: x2, y: y1)
	print('╮')
	// Right edge
	draw_vertical_line(y1 + 1, y2 - 1, x2)!
	// Bottom Right
	term.set_cursor_position(x: x2, y: y2)
	print('╯')
	// Bottom edge
	draw_horizontal_line(x1 + 1, x2 - 1, y2)!
	// Bottom Left
	term.set_cursor_position(x: x1, y: y2)
	print('╰')
	// Left edge
	draw_vertical_line(y1 + 1, y2 - 1, x1)!
}

pub fn draw_text(x int, y int, text string) ! {
	original_cursor_pos := term.get_cursor_position()!
	defer {
		term.set_cursor_position(original_cursor_pos)
	}

	contents := text.split('\n')

	for i, line in contents {
		term.set_cursor_position(x: x, y: y + i)
		print(line)
	}
}

pub fn draw_text_box(x1 int, y1 int, x2 int, y2 int, text string, alignment TextAlignment) ! {
	draw_box(x1, y1, x2, y2)!

	match alignment {
		.unaligned {
			draw_text(x1 + 1, y1 + 1, text)!
		}
		.center {
			// Do we have room to center the text horizontally?
			max_line_width := arrays.max(text.split('\n').map(it.len))!
			box_width := x2 - x1 - 2

			new_x := if max_line_width >= box_width {
				x1 + 1
			} else {
				x1 + 1 + ((box_width - max_line_width) / 2)
			}

			// Do we have room to center the text vertically?
			box_height := y2 - y1 - 2

			new_y := if text.split('\n').len >= box_height {
				y1 + 1
			} else {
				y1 + 1 + ((box_height - text.split('\n').len) / 2)
			}

			draw_text(new_x, new_y, text)!
		}
	}
}

pub fn draw_text_box_w_title(x1 int, y1 int, x2 int, y2 int, text string, title string, alignment TextAlignment) ! {
	draw_text(x1 + 1, y1 - 1, title)!
	draw_text_box(x1, y1, x2, y2, text, alignment)!
}
