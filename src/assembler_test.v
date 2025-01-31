module assembler

import rand

fn test_token_type() {
	instruction := token_type('ADD')!
	assert instruction == Token{
		token: .instruction
		value: 'ADD'
	}
	immediate := token_type('$123')!
	assert immediate == Token{
		token: .immediate
		value: '$123'
	}
	memory := token_type('&r1')!
	assert memory == Token{
		token: .memory
		value: '&r1'
	}
	comma := token_type(',')!
	assert comma == Token{
		token: .comma
		value: ','
	}
	r1 := token_type('r1')!
	assert r1 == Token{
		token: .register
		value: 'r1'
	}
	junk := token_type('!x5T')!
	assert junk == Token{
		token: .junk
	}
}

fn test_generated_strings() {
	// Instructions
	for str_len in 1 .. 5 {
		for _ in 0 .. 25 {
			rand_str := rand.string(str_len).to_upper()
			token := token_type(rand_str)!
			assert token == Token{
				token: .instruction
				value: rand_str
			}
		}
	}
	// Immediates
	for imm in 0 .. 256 {
		token := token_type('$${imm}')!
		assert token == Token{
			token: .immediate
			value: '$${imm}'
		}
	}
	// Memory
	// &
	// Registers
	for reg in 1 .. 17 {
		mem := token_type('&r${reg}')!
		assert mem == Token{
			token: .memory
			value: '&r${reg}'
		}

		register := token_type('r${reg}')!
		assert register == Token{
			token: .register
			value: 'r${reg}'
		}
	}
	// Comma
	assert token_type(',')! == Token{
		token: .comma
		value: ','
	}
}

fn test_token_type_fuzz() {
	for _ in 0 .. 10000 {
		str_len := rand.intn(10)!
		rand_str := rand.string(str_len)
		token_type(rand_str) or { assert false, 'token_type failed on input ${rand_str}' }
	}
}
