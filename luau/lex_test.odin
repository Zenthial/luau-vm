package luau

import "core:fmt"
import "core:testing"

@(test)
test_take_until :: proc(t: ^testing.T) {
	str := "123123123\"123123"
	l := lexer_make(str)

	took := take_until(&l, "\"1")
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
	str := "local a"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Local))
	testing.expect_value(t, toks[1], tok_make(.Ident, "a"))
}

@(test)
test_ignore_comment :: proc(t: ^testing.T) {
	str := "--herere\nlocal"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Local))
}

@(test)
test_num_assign_lex :: proc(t: ^testing.T) {
	str := "local a = 3"
	toks := lex(str)
	testing.expect_value(t, len(toks), 4)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Local))
	testing.expect_value(t, toks[1], tok_make(.Ident, "a"))
	testing.expect_value(t, toks[2], tok_make(.Equal, nil))
	testing.expect_value(t, toks[3], tok_make(.Number, 3))
}
