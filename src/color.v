module color

pub struct Color {
pub:
	r u8
	g u8
	b u8
}

pub fn Color.rgb(r u8, g u8, b u8) Color {
	return Color{
		r: r
		g: g
		b: b
	}
}

pub fn (c Color) change_brightness(brightness f64) Color {
	return Color{
		r: u8(c.r * brightness)
		g: u8(c.g * brightness)
		b: u8(c.b * brightness)
	}
}

pub const white = Color.rgb(255, 255, 255)
pub const silver = Color.rgb(192, 192, 192)
pub const gray = Color.rgb(128, 128, 128)
pub const black = Color.rgb(0, 0, 0)
pub const red = Color.rgb(255, 0, 0)
pub const maroon = Color.rgb(128, 0, 0)
pub const yellow = Color.rgb(255, 255, 0)
pub const olive = Color.rgb(128, 128, 0)
pub const lime = Color.rgb(0, 255, 0)
pub const green = Color.rgb(0, 128, 0)
pub const aqua = Color.rgb(0, 255, 255)
pub const teal = Color.rgb(0, 128, 128)
pub const blue = Color.rgb(0, 0, 255)
pub const navy = Color.rgb(0, 0, 128)
pub const fuchsia = Color.rgb(255, 0, 255)
pub const purple = Color.rgb(128, 0, 128)
