module draw_calls

import color
import strings
import graphics

pub struct DrawCallsError {
	Error
	message string
}

pub fn (err DrawCallsError) msg() string {
	return err.message
}

pub struct DrawCalls implements graphics.GraphicsDevice {
	width  u16
	height u16
pub mut:
	sb strings.Builder = strings.new_builder(10)
}

pub fn (dc DrawCalls) display_size() !(u16, u16) {
	return dc.width, dc.height
}

pub fn (dc DrawCalls) buffer_count() !u8 {
	return DrawCallsError{
		message: 'Not implemented'
	}
}

pub fn (mut dc DrawCalls) buffer_display(buffer u8) ! {
	dc.sb.writeln('DISPLAY BUFFER ${buffer}')
}

pub fn (mut dc DrawCalls) buffer_set_background(buffer u8, c color.Color) ! {
	dc.sb.writeln('SETBACKGROUND BUFFER ${buffer} rgb(${c.r}, ${c.g}, ${c.b})')
}

pub fn (mut dc DrawCalls) buffer_clear(buffer u8) ! {
	dc.sb.writeln('CLEAR BUFFER ${buffer}')
}

pub fn (mut dc DrawCalls) draw_pixel(buffer u8, x u16, y u16, c color.Color) ! {
	dc.sb.writeln('DRAW BUFFER ${buffer} (${x}, ${y}) rgb(${c.r}, ${c.g}, ${c.b})')
}

pub fn (mut dc DrawCalls) draw_line(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, c color.Color) ! {
	dc.sb.writeln('DRAWLINE BUFFER ${buffer} ((${x1}, ${y1}), (${x2}, ${y2})) rgb(${c.r}, ${c.g}, ${c.b})')
}

pub fn (mut dc DrawCalls) draw_rectangle(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, c color.Color) ! {
	dc.sb.writeln('DRAWRECT BUFFER ${buffer} ((${x1}, ${y1}), (${x2}, ${y2})) rgb(${c.r}, ${c.g}, ${c.b})')
}

pub fn (mut dc DrawCalls) draw_rectangle_filled(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, c color.Color) ! {
	dc.sb.writeln('DRAWRECTFILLED BUFFER ${buffer} ((${x1}, ${y1}), (${x2}, ${y2})) rgb(${c.r}, ${c.g}, ${c.b})')
}

pub fn (mut dc DrawCalls) draw_poly(buffer u8, points []graphics.Point, c color.Color) ! {
	points_str := points.map('(${it.x}, ${it.y})').join(', ')
	dc.sb.writeln('DRAWPOLY BUFFER ${buffer} (${points_str}) rgb(${c.r}, ${c.g}, ${c.b})')
}

pub fn (mut dc DrawCalls) draw_poly_filled(buffer u8, points []graphics.Point, c color.Color) ! {
	points_str := points.map('(${it.x}, ${it.y})').join(', ')
	dc.sb.writeln('DRAWPOLYFILLED BUFFER ${buffer} (${points_str}) rgb(${c.r}, ${c.g}, ${c.b})')
}
