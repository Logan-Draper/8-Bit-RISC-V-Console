module noblock

import os
import io

pub interface NoblockReader {
	io.Reader
	data_ready() bool
}

pub struct NoblockFD implements NoblockReader {
pub:
	file os.File
}

pub fn (fd NoblockFD) data_ready() bool {
	return os.fd_is_pending(fd.file.fd)
}

pub fn (fd NoblockFD) read(mut buf []u8) !int {
	return fd.file.read(mut buf)!
}

pub struct NoblockString implements NoblockReader {
pub:
	internal_string string
pub mut:
	internal_idx int
}

pub fn (s NoblockString) data_ready() bool {
	return s.internal_idx < s.internal_string.len
}

pub fn (mut s NoblockString) read(mut buf []u8) !int {
	if s.internal_idx >= s.internal_string.len {
		return io.Eof{}
	}
	read := copy(mut buf, s.internal_string[s.internal_idx..s.internal_idx + buf.len].bytes())
	s.internal_idx += read
	return read
}
