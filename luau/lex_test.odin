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

@(test)
test_simple_ident_lex :: proc(t: ^testing.T) {
	str := "local"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Local))
}

@(test)
test_simple_two_ident_lex :: proc(t: ^testing.T) {
	str := "local bingo"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Local))
	testing.expect_value(t, toks[1], tok_make(.Ident, "bingo"))
}
