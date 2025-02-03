module graphics_console

import ascii_blocks as ab
import color
import time
import graphics
import math

const target_fps = 15
const width = 65
const height = 65

pub struct GraphicsConsoleError {
	Error
	message string
}

pub fn (err GraphicsConsoleError) msg() string {
	return err.message
}

pub fn run() ! {
	mut graphics_dev := graphics.GraphicsDevice(ab.AsciiBlocks.init(width, height, 2))

	star := [graphics.GeometricPoint{
		x: 0
		y: -12
	}, graphics.GeometricPoint{
		x: 5
		y: -2
	}, graphics.GeometricPoint{
		x: 15
		y: -2
	}, graphics.GeometricPoint{
		x: 6
		y: 3
	}, graphics.GeometricPoint{
		x: 10
		y: 13
	}, graphics.GeometricPoint{
		x: 0
		y: 6
	}, graphics.GeometricPoint{
		x: -10
		y: 13
	}, graphics.GeometricPoint{
		x: -6
		y: 3
	}, graphics.GeometricPoint{
		x: -15
		y: -2
	}, graphics.GeometricPoint{
		x: -5
		y: -2
	}, graphics.GeometricPoint{
		x: 0
		y: -12
	}]

	mut star1_vel := 1
	mut star2_vel := -1

	mut star1_x := 15
	mut star2_x := 40

	mut val := u8(0)
	mut f_val := 0.0
	for {
		current_buffer := u8(val % 2)
		mut sw := time.StopWatch{}
		sw.start()
		graphics_dev.buffer_clear((current_buffer + 1) % 2) or {
			return GraphicsConsoleError{
				message: 'Failed to clear buffer ${(current_buffer + 1) % 2}'
			}
		}

		graphics_dev.draw_poly_filled(current_buffer, star.map(graphics.Point{
			x: u16(it.x * (math.sin(f_val)) + star1_x)
			y: u16(it.y + 3 * math.sin(2 * f_val) + 17)
		}), color.Color.rgb(val % 256, 255, val % 128))!

		graphics_dev.draw_poly(current_buffer, star.map(graphics.Point{
			x: u16(it.x * (math.cos(f_val * 1.5)) + star2_x)
			y: u16(it.y + 3 * math.cos(1.25 * f_val) + 45)
		}), color.Color.rgb(255, val % 128, val % 64))!

		val++
		f_val += 0.08

		star1_x += star1_vel
		star2_x += star2_vel

		if star1_x <= 15 || star1_x >= 47 {
			star1_vel *= -1
		}

		if star2_x <= 15 || star2_x >= 47 {
			star2_vel *= -1
		}

		graphics_dev.buffer_display(current_buffer)!
		sw.stop()
		time.sleep(time.millisecond * (f64(1) / target_fps * 1000) - sw.elapsed())
	}
}
