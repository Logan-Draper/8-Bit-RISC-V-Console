module braille_dots

import color
import graphics
import strings
import math
import arrays
import os

struct Edge {
	min_y   f64
	max_y   f64
	x_min_y f64
	slope   f64
}

struct ActiveEdge {
	max_y   f64
	x_min_y f64
	slope   f64
}

fn integer_part(x f64) int {
	return int(math.floor(x))
}

fn round(x f64) f64 {
	return math.round(x)
}

fn fractional_part(x f64) f64 {
	return x - math.floor(x)
}

fn reciprocal_fractional_part(x f64) f64 {
	return 1 - fractional_part(x)
}

fn slope(x1 f64, y1 f64, x2 f64, y2 f64) f64 {
	bottom := x2 - x1
	if bottom == 0 {
		return 0
	}
	return (y2 - y1) / (x2 - x1)
}

struct BrailleDotsError {
	Error
	message string
}

pub fn (err BrailleDotsError) message() string {
	return err.message
}

pub struct BrailleDots implements graphics.GraphicsDevice {
	width       u16
	height      u16
	num_buffers u8
mut:
	current_buffer int
	buffers        [][][]color.Color
}

pub fn BrailleDots.init(width u16, height u16, buffers u8) BrailleDots {
	return BrailleDots{
		width:       width
		height:      height
		num_buffers: buffers
		buffers:     [][][]color.Color{len: int(buffers), init: [][]color.Color{len: int(height +
			(4 - height % 4)), init: []color.Color{len: int(width + (width % 2))}}}
	}
}

pub fn (ab BrailleDots) display_size() !(u16, u16) {
	return ab.width, ab.height
}

pub fn (ab BrailleDots) buffer_count() !u8 {
	return ab.num_buffers
}

pub fn (ab BrailleDots) buffer_display(buffer u8) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error displaying buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	mut sb := strings.new_builder(ab.width * ab.height * 16)
	base_block := u32(0x2800)
	blank := color.Color{}

	for row := 0; row < ab.height; row += 4 {
		for col := 0; col < ab.width; col += 2 {
			mut bf_byte := u8(0x0)
			mut red := 0
			mut green := 0
			mut blue := 0
			mut count := 0

			if ab.buffers[buffer][row + 0][col + 0] != blank {
				red += ab.buffers[buffer][row + 0][col + 0].r
				green += ab.buffers[buffer][row + 0][col + 0].g
				blue += ab.buffers[buffer][row + 0][col + 0].b
				count++
				bf_byte |= (1 << 0)
			}
			if ab.buffers[buffer][row + 1][col + 0] != blank {
				red += ab.buffers[buffer][row + 1][col + 0].r
				green += ab.buffers[buffer][row + 1][col + 0].g
				blue += ab.buffers[buffer][row + 1][col + 0].b
				count++
				bf_byte |= (1 << 1)
			}
			if ab.buffers[buffer][row + 2][col + 0] != blank {
				red += ab.buffers[buffer][row + 2][col + 0].r
				green += ab.buffers[buffer][row + 2][col + 0].g
				blue += ab.buffers[buffer][row + 2][col + 0].b
				count++
				bf_byte |= (1 << 2)
			}
			if ab.buffers[buffer][row + 0][col + 1] != blank {
				red += ab.buffers[buffer][row + 0][col + 1].r
				green += ab.buffers[buffer][row + 0][col + 1].g
				blue += ab.buffers[buffer][row + 0][col + 1].b
				count++
				bf_byte |= (1 << 3)
			}
			if ab.buffers[buffer][row + 1][col + 1] != blank {
				red += ab.buffers[buffer][row + 1][col + 1].r
				green += ab.buffers[buffer][row + 1][col + 1].g
				blue += ab.buffers[buffer][row + 1][col + 1].b
				count++
				bf_byte |= (1 << 4)
			}
			if ab.buffers[buffer][row + 2][col + 1] != blank {
				red += ab.buffers[buffer][row + 2][col + 1].r
				green += ab.buffers[buffer][row + 2][col + 1].g
				blue += ab.buffers[buffer][row + 2][col + 1].b
				count++
				bf_byte |= (1 << 5)
			}
			if ab.buffers[buffer][row + 3][col + 0] != blank {
				red += ab.buffers[buffer][row + 3][col + 0].r
				green += ab.buffers[buffer][row + 3][col + 0].g
				blue += ab.buffers[buffer][row + 3][col + 0].b
				count++
				bf_byte |= (1 << 6)
			}
			if ab.buffers[buffer][row + 3][col + 1] != blank {
				red += ab.buffers[buffer][row + 3][col + 1].r
				green += ab.buffers[buffer][row + 3][col + 1].g
				blue += ab.buffers[buffer][row + 3][col + 1].b
				count++
				bf_byte |= (1 << 7)
			}

			if count != 0 {
				sb.write_string('\033[38;2;${u8(red / count)};${u8(green / count)};${u8(blue / count)}m')
			} else {
				sb.write_string('\033[39m\033[49m')
			}
			sb.write_string(utf32_to_str(base_block | bf_byte))
		}
		sb.writeln('')
	}

	// for row in ab.buffers[buffer] {
	// 	for col in row {
	// 		sb.write_string('\033[38;2;${col.r};${col.g};${col.b}m██')
	// 	}
	// 	sb.writeln('')
	// }

	sb.write_string('\033[39m\033[49m')

	print('\x1bP=1s\x1b\\')
	print('\x1b[2J\x1b[3J')
	print(sb.str())
	print('\x1bP=2s\x1b\\')
}

pub fn (ab BrailleDots) buffer_set_background(buffer u8, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error setting buffer background on ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	for mut row in ab.buffers[buffer] {
		for mut col in row {
			col = c
		}
	}
}

pub fn (ab BrailleDots) buffer_clear(buffer u8) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error clearing buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	for mut row in ab.buffers[buffer] {
		for mut col in row {
			col = color.black
		}
	}
}

pub fn (mut ab BrailleDots) draw_pixel(buffer u8, x u16, y u16, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	if x >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	ab.buffers[buffer][y][x] = c
}

pub fn (mut ab BrailleDots) draw_line(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	if x1 >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y1 >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	if x2 >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y2 >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	steep := math.abs(y2 - y1) > math.abs(x2 - x1)

	mut x1f := f64(x1)
	mut x2f := f64(x2)
	mut y1f := f64(y1)
	mut y2f := f64(y2)

	if steep {
		tmp := x1f
		x1f = y1f
		y1f = tmp

		tmp2 := x2f
		x2f = y2f
		y2f = tmp2
	}

	if x1f > x2f {
		tmp := x1f
		x1f = x2f
		x2f = tmp

		tmp2 := y1f
		y1f = y2f
		y2f = tmp2
	}

	dx := x2f - x1f
	dy := y2f - y1f
	gradient := if dx == 0 { f64(1) } else { dy / dx }

	mut xpx11 := int(0)
	mut intery := f64(0)
	{
		xend := round(x1f)
		yend := y1f + gradient * (xend - x1f)
		xgap := reciprocal_fractional_part(x1f + 0.5)
		xpx11 = int(xend)
		ypx11 := integer_part(yend)

		if steep {
			ab.buffers[buffer][xpx11][ypx11] = c.change_brightness(reciprocal_fractional_part(yend) * xgap)
			ab.buffers[buffer][xpx11][ypx11 + 1] = c.change_brightness(fractional_part(yend) * xgap)
		} else {
			ab.buffers[buffer][ypx11][xpx11] = c.change_brightness(reciprocal_fractional_part(yend) * xgap)
			ab.buffers[buffer][ypx11 + 1][xpx11] = c.change_brightness(fractional_part(yend) * xgap)
		}

		intery = yend + gradient
	}
	mut xpx12 := int(0)
	{
		xend := round(x2f)
		yend := y2f + gradient * (xend - x2f)
		xgap := reciprocal_fractional_part(x2f + 0.5)
		xpx12 = int(xend)
		ypx12 := integer_part(yend)

		if steep {
			ab.buffers[buffer][xpx12][ypx12] = c.change_brightness(reciprocal_fractional_part(yend) * xgap)
			ab.buffers[buffer][xpx12][ypx12 + 1] = c.change_brightness(fractional_part(yend) * xgap)
		} else {
			ab.buffers[buffer][ypx12][xpx12] = c.change_brightness(reciprocal_fractional_part(yend) * xgap)
			ab.buffers[buffer][ypx12 + 1][xpx12] = c.change_brightness(fractional_part(yend) * xgap)
		}
	}
	if steep {
		for x := xpx11 + 1; x < xpx12; x++ {
			ab.buffers[buffer][x][integer_part(intery)] = c.change_brightness(reciprocal_fractional_part(intery))
			ab.buffers[buffer][x][integer_part(intery) + 1] = c.change_brightness(fractional_part(intery))
			intery += gradient
		}
	} else {
		for x := xpx11 + 1; x < xpx12; x++ {
			ab.buffers[buffer][integer_part(intery)][x] = c.change_brightness(reciprocal_fractional_part(intery))
			ab.buffers[buffer][integer_part(intery) + 1][x] = c.change_brightness(fractional_part(intery))
			intery += gradient
		}
	}
}

pub fn (mut ab BrailleDots) draw_rectangle(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	if x1 >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y1 >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	if x2 >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y2 >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	// Top
	ab.draw_horizontal_line(buffer, x1, x2, y1, c)
	// Right
	ab.draw_vertical_line(buffer, x2, y1, y2, c)
	// Bottom
	ab.draw_horizontal_line(buffer, x2, x1, y2, c)
	// Left
	ab.draw_vertical_line(buffer, x1, y2, y1, c)
}

// Unchecked because private
fn (mut ab BrailleDots) draw_horizontal_line(buffer int, x1 u16, x2 u16, y u16, c color.Color) {
	for x := math.min(x1, x2); x <= math.max(x1, x2); x++ {
		ab.buffers[buffer][y][x] = c
	}
}

// Unchecked because private
fn (mut ab BrailleDots) draw_vertical_line(buffer int, x u16, y1 u16, y2 u16, c color.Color) {
	for y := math.min(y1, y2); y <= math.max(y1, y2); y++ {
		ab.buffers[buffer][y][x] = c
	}
}

pub fn (mut ab BrailleDots) draw_rectangle_filled(buffer u8, x1 u16, y1 u16, x2 u16, y2 u16, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	if x1 >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y1 >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	if x2 >= ab.width {
		return BrailleDotsError{
			message: 'Error drawing pixel, x coord out of bounds, valid indicies [0-${ab.width}]'
		}
	}
	if y2 >= ab.height {
		return BrailleDotsError{
			message: 'Error drawing pixel, y coord out of bounds, valid indicies [0-${ab.height}]'
		}
	}

	for y := math.min(y1, y2); y <= math.max(y1, y2); y++ {
		for x := math.min(x1, x2); x <= math.max(x1, x2); x++ {
			ab.buffers[buffer][y][x] = c
		}
	}
}

pub fn (mut ab BrailleDots) draw_poly(buffer u8, points []graphics.Point, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	for point in points {
		if point.x >= ab.width {
			return BrailleDotsError{
				message: 'Point (${point.x}, ${point.y}) has x coordinate out of bounds, must be <= ${ab.width}'
			}
		}

		if point.y >= ab.height {
			return BrailleDotsError{
				message: 'Point (${point.x}, ${point.y}) has y coordinate out of bounds, must be <= ${ab.height}'
			}
		}
	}

	for i := 0; i < points.len - 1; i++ {
		p1 := points[i]
		p2 := points[i + 1]
		ab.draw_line(buffer, p1.x, p1.y, p2.x, p2.y, c)!
	}
}

pub fn (mut ab BrailleDots) draw_poly_filled(buffer u8, points []graphics.Point, c color.Color) ! {
	if buffer >= ab.num_buffers {
		return BrailleDotsError{
			message: 'Error drawing pixel on buffer ${buffer}, valid indicies [0-${ab.num_buffers}]'
		}
	}

	for point in points {
		if point.x >= ab.width {
			return BrailleDotsError{
				message: 'Point (${point.x}, ${point.y}) has x coordinate out of bounds, must be <= ${ab.width}'
			}
		}

		if point.y >= ab.height {
			return BrailleDotsError{
				message: 'Point (${point.x}, ${point.y}) has y coordinate out of bounds, must be <= ${ab.height}'
			}
		}
	}

	ab.draw_poly(buffer, points, c)!

	// Make all edges
	mut edges := []Edge{}
	for i := 0; i < points.len - 1; i++ {
		x1 := points[i].x
		y1 := points[i].y
		x2 := points[i + 1].x
		y2 := points[i + 1].y

		min_y := if y1 < y2 { y1 } else { y2 }
		max_y := if y1 > y2 { y1 } else { y2 }

		x_min_y := if y1 <= y2 { x1 } else { x2 }
		s := slope(x1, y1, x2, y2)

		edges << Edge{
			min_y:   min_y
			max_y:   max_y
			x_min_y: x_min_y
			slope:   s
		}
	}

	// Make global edge table
	mut global_edge_table := edges.sorted_with_compare(fn (a &Edge, b &Edge) int {
		if a.min_y == b.min_y {
			if a.x_min_y < b.x_min_y {
				return -1
			} else if b.x_min_y < a.x_min_y {
				return 1
			} else {
				return 0
			}
		}

		if a.min_y < b.min_y {
			return -1
		} else if b.min_y < a.min_y {
			return 1
		} else {
			return 0
		}
	}).filter(it.slope != 0)

	// Initialize scan-line and active edge table
	mut scan_line := int(arrays.min(edges.map(it.min_y))!)
	mut active_edge_table := global_edge_table.filter(int(it.min_y) == scan_line).map(ActiveEdge{
		max_y:   int(it.max_y)
		x_min_y: it.x_min_y
		slope:   1 / it.slope
	}).sorted(a.x_min_y < b.x_min_y)
	global_edge_table.delete_many(0, active_edge_table.len)

	ab.buffers[buffer][points[0].y][points[0].x] = c

	for active_edge_table.len > 0 {
		odd_edges := arrays.filter_indexed(active_edge_table, fn (idx int, elem ActiveEdge) bool {
			return idx % 2 == 1
		})
		even_edges := arrays.filter_indexed(active_edge_table, fn (idx int, elem ActiveEdge) bool {
			return idx % 2 == 0
		})

		// Draw pixels between odd&even pairs
		for i in 0 .. even_edges.len {
			if i >= odd_edges.len {
				break
			}

			x_start := int(even_edges[i].x_min_y + 0.99)
			x_end := int(odd_edges[i].x_min_y)

			for x := x_start; x <= x_end; x++ {
				if scan_line >= ab.buffers[buffer].len || x >= ab.buffers[buffer][scan_line].len {
					continue
				}
				ab.buffers[buffer][scan_line][x] = c
			}
		}

		// Update scanline
		scan_line += 1
		active_edge_table = active_edge_table.filter(int(it.max_y) != scan_line)
		active_edge_table = active_edge_table.map(ActiveEdge{
			max_y:   int(it.max_y)
			x_min_y: it.x_min_y + it.slope
			slope:   it.slope
		})

		// Add new edges
		for global_edge_table.len > 0 && int(global_edge_table[0].min_y) == scan_line {
			active_edge_table << ActiveEdge{
				max_y:   int(global_edge_table[0].max_y)
				x_min_y: global_edge_table[0].x_min_y
				slope:   1 / global_edge_table[0].slope
			}

			global_edge_table.delete(0)
		}

		active_edge_table.sort(a.x_min_y < b.x_min_y)
	}
}
