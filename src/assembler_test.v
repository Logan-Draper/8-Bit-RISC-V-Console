module assembler

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
	memory := token_type('&a')!
	assert memory == Token{
		token: .memory
		value: '&a'
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
	error := token_type('!x5T') or {return}
	assert false
}
