module assembler

import bytecode

enum TokenType {
	instruction
	register
	memory
	comma
	immediate
}

struct Token {
	value string
	token TokenType
}

struct LexString {
	remaining string
	success   bool
	token     Token
}

//Find better condition for instruction catch
fn token_type(s string) !Token {
	if s.bytes().all(it >= 'A'[0] && it <= 'Z'[0])
	{
		return Token{
			token: .instruction
			value: s
		}
	} else if s[0] == u8('$'[0]) {
		return Token{
			token: .immediate
			value: s
		}
	} else if s[0] == u8('&'[0]) {
		return Token{
			token: .memory
			value: s
		}
	} else if (u8(s[0]) == u8('r'[0]) && s[1..].is_int()) || s == 'zero' {
		return Token{
			token: .register
			value: s
		}
	} else if s == ',' {
		return Token{
			token: .comma
			value: s
		}
	} else {
		return error('')
	}
}
