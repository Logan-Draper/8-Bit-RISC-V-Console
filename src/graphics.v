module graphics

import color

struct Point {
	x int
	y int
}

pub interface GraphicsDevice {
	display_size() !(u16, u16)

	buffer_count() !u8
	buffer_display(buffer u8) !
	buffer_set_background(buffer u8, color color.Color) !
	buffer_clear(buffer u8) !
mut:
	draw_pixel(buffer u8, x u16, y u16, color color.Color) !
	// draw_line(x1 int, y1 int, x2 int, y2 int, color Color)
	// draw_rectangle(x1 int, y1 int, x2 int, y2 int, color Color)
	// draw_rectangle_filled(x1 int, y1 int, x2 int, y2 int, color Color)
	// draw_poly(points []Point, color Color)
	// draw_poly_filled(points []Point, color Color)
}
