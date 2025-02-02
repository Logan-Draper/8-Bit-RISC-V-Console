module graphics

import color

pub struct Point {
pub mut:
	x u16
	y u16
}

pub struct GeometricPoint {
pub mut:
	x int
	y int
}

pub interface GraphicsDevice {
	display_size() !(u16, u16)

	buffer_count() !u8
mut:
	buffer_display(buffer u8) !
	buffer_set_background(buffer u8, color color.Color) !
	buffer_clear(buffer u8) !

	draw_pixel(buffer u8, x u16, y u16, color color.Color) !
	draw_line(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, color color.Color) !
	draw_rectangle(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, color color.Color) !
	draw_rectangle_filled(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, color color.Color) !
	draw_poly(buffer u8, points []Point, color color.Color) !
	draw_poly_filled(buffer u8, points []Point, color color.Color) !
}
