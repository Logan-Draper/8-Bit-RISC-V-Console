module graphics_console

import ascii_blocks as ab
import color
import time

const target_fps = 240

pub fn run() ! {
	graphics := ab.AsciiBlocks.init(10, 10, 1)

	for times in 0 .. 1000 {
		for val in 0 .. 256 {
			mut sw := time.StopWatch{}
			sw.start()
			graphics.buffer_set_background(0, color.Color.rgb(val, 128, val))!
			graphics.buffer_display(0)!
			sw.stop()
			time.sleep(time.millisecond * (f64(1) / target_fps * 1000) - sw.elapsed())
		}
	}
}
