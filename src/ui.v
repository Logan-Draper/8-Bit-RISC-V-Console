module tui_console

import arrays

pub enum TextAlignment {
	unaligned
	center
}

pub fn percent_to_coord(a App, x f64, y f64) (int, int) {
	width := a.tui.window_width
	height := a.tui.window_height

	x_ret := int(width * x)
	y_ret := int(height * y)

	return x_ret, y_ret
}

fn draw_horizontal_line(mut a App, x1 int, x2 int, y int) ! {
	if x1 >= x2 {
		return error('Drawing a line with flipped x1 x2, ${x1} >= ${x2}')
	}

	for pos in x1 .. x2 + 1 {
		a.tui.draw_text(pos, y, '─')
	}
}

fn draw_vertical_line(mut a App, y1 int, y2 int, x int) ! {
	if y1 >= y2 {
		return error('Drawing a line with flipped y1 y2, ${y1} >= ${y2}')
	}

	for pos in y1 .. y2 + 1 {
		a.tui.draw_text(x, pos, '│')
	}
}

// Coords must be top left, bottom right, cannot be inverted or will fail
pub fn draw_box(mut a App, x1 int, y1 int, x2 int, y2 int) ! {
	width := x2 - x1
	height := y2 - y1

	if width <= 1 {
		return error('Drawing a rect with width ${width} <= 1')
	}

	if height <= 1 {
		return error('Drawing a rect with height ${height} <= 1')
	}

	// Top Left
	a.tui.draw_text(x1, y1, '╭')
	// Top edge
	draw_horizontal_line(mut a, x1 + 1, x2 - 1, y1)!
	// Top Right
	a.tui.draw_text(x2, y1, '╮')
	// Right edge
	draw_vertical_line(mut a, y1 + 1, y2 - 1, x2)!
	// Bottom Right
	a.tui.draw_text(x2, y2, '╯')
	// Bottom edge
	draw_horizontal_line(mut a, x1 + 1, x2 - 1, y2)!
	// Bottom Left
	a.tui.draw_text(x1, y2, '╰')
	// Left edge
	draw_vertical_line(mut a, y1 + 1, y2 - 1, x1)!
}

pub fn draw_text(mut a App, x int, y int, text []string) ! {
	for i, line in text {
		a.tui.draw_text(x, y + i, line)
	}
}

pub fn draw_text_box(mut a App, x1 int, y1 int, x2 int, y2 int, text []string, alignment TextAlignment) ! {
	draw_box(mut a, x1, y1, x2, y2)!

	match alignment {
		.unaligned {
			draw_text(mut a, x1 + 1, y1 + 1, text)!
		}
		.center {
			// Do we have room to center the text horizontally?
			max_line_width := arrays.max(text.map(it.len))!
			box_width := x2 - x1 - 2

			new_x := if max_line_width >= box_width {
				x1 + 1
			} else {
				x1 + 1 + ((box_width - max_line_width) / 2)
			}

			// Do we have room to center the text vertically?
			box_height := y2 - y1 - 2

			new_y := if text.len >= box_height {
				y1 + 1
			} else {
				y1 + 1 + ((box_height - text.len) / 2)
			}

			draw_text(mut a, new_x, new_y, text)!
		}
	}
}

pub fn draw_text_box_w_title(mut a App, x1 int, y1 int, x2 int, y2 int, text []string, title string, alignment TextAlignment) ! {
	draw_text(mut a, x1 + 1, y1 - 1, [title])!
	draw_text_box(mut a, x1, y1, x2, y2, text, alignment)!
}
