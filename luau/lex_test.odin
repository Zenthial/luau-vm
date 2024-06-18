package luau

import "core:fmt"
import "core:testing"

@(test)
test_take_until :: proc(t: ^testing.T) {
	str := "123123123\"123123"
	l := lexer_make(str)

	took := take_until(&l, "\"1")
	testing.expect_value(t, took, "123123123")
	testing.expect_value(t, l.pos, 11)
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

@(test)
test_decent_syntax_lex :: proc(t: ^testing.T) {
	str := "-- stylua: ignore start\nlocal x = 5\n\nlocal y = --[[comment]] 1\nlocal another = true"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Local))
	testing.expect_value(t, toks[1], tok_make(.Ident, "x"))
	testing.expect_value(t, toks[2], tok_make(.Equal, nil))
	testing.expect_value(t, toks[3], tok_make(.Number, 5))
	testing.expect_value(t, toks[4], tok_make(.Keyword, .Local))
	testing.expect_value(t, toks[5], tok_make(.Ident, "y"))
	testing.expect_value(t, toks[6], tok_make(.Equal, nil))
	testing.expect_value(t, toks[7], tok_make(.Number, 1))
	testing.expect_value(t, toks[8], tok_make(.Keyword, .Local))
	testing.expect_value(t, toks[9], tok_make(.Ident, "another"))
	testing.expect_value(t, toks[10], tok_make(.Equal, nil))
	testing.expect_value(t, toks[11], tok_make(.Bool, true))
}
