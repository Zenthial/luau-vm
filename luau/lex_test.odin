package luau

import "core:testing"

@(test)
test_take_until :: proc(t: ^testing.T) {
	str := "123123123\"123123"
	l := Lexer {
		src = str,
		pos = 0,
	}

	took := take_until(&l, '"')
	testing.expect_value(t, took, "123123123")
	testing.expect_value(t, l.pos, 10)
}
