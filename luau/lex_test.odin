package luau

import "core:testing"

// @(test)
// test_take_until :: proc(t: ^testing.T) {
// 	str := "123123123\"123123"
// 	l := lexer_make(str)
//
// 	took := take_until(&l, "\"1")
// 	testing.expect_value(t, took, "123123123")
// 	testing.expect_value(t, l.pos, 11)
// }

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
	str := "-- stylua: ignore start\nlocal x = 5\n\nlocal y = --[[comment]] 1\nlocal another = true\n-- stylua: ignore end"
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

@(test)
test_function_def_lex :: proc(t: ^testing.T) {
	str := "function test() end"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Function))
	testing.expect_value(t, toks[1], tok_make(.Ident, "test"))
	testing.expect_value(t, toks[2], tok_make(.Paren, .Left))
	testing.expect_value(t, toks[3], tok_make(.Paren, .Right))
	testing.expect_value(t, toks[4], tok_make(.Keyword, .End))
}

@(test)
test_array_lex :: proc(t: ^testing.T) {
	str := "[1, 2, 3]"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Bracket, .Left))
	testing.expect_value(t, toks[1], tok_make(.Number, 1))
	testing.expect_value(t, toks[2], tok_make(.Comma, nil))
	testing.expect_value(t, toks[3], tok_make(.Number, 2))
	testing.expect_value(t, toks[4], tok_make(.Comma, nil))
	testing.expect_value(t, toks[5], tok_make(.Number, 3))
	testing.expect_value(t, toks[6], tok_make(.Bracket, .Right))
}

@(test)
test_type_alias :: proc(t: ^testing.T) {
	str := "type t = number"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Type))
	testing.expect_value(t, toks[1], tok_make(.Ident, "t"))
	testing.expect_value(t, toks[2], tok_make(.Equal, nil))
	testing.expect_value(t, toks[3], tok_make(.Ident, "number"))
}

@(test)
test_real_type_definition :: proc(t: ^testing.T) {
	str := "export type character = Model & {\nHumanoid: Humanoid & { Animator: Animator }\n}"
	toks := lex(str)
	testing.expect_value(t, toks[0], tok_make(.Keyword, .Export))
	testing.expect_value(t, toks[1], tok_make(.Keyword, .Type))
	testing.expect_value(t, toks[2], tok_make(.Ident, "character"))
	testing.expect_value(t, toks[3], tok_make(.Equal, nil))
	testing.expect_value(t, toks[4], tok_make(.Ident, "Model"))
	testing.expect_value(t, toks[5], tok_make(.Ampersand, nil))
	testing.expect_value(t, toks[6], tok_make(.Brace, .Left))
	testing.expect_value(t, toks[7], tok_make(.Ident, "Humanoid"))
	testing.expect_value(t, toks[8], tok_make(.Colon, nil))
	testing.expect_value(t, toks[9], tok_make(.Ident, "Humanoid"))
	testing.expect_value(t, toks[10], tok_make(.Ampersand, nil))
	testing.expect_value(t, toks[11], tok_make(.Brace, .Left))
	testing.expect_value(t, toks[12], tok_make(.Ident, "Animator"))
	testing.expect_value(t, toks[13], tok_make(.Colon, nil))
	testing.expect_value(t, toks[14], tok_make(.Ident, "Animator"))
	testing.expect_value(t, toks[15], tok_make(.Brace, .Right))
	testing.expect_value(t, toks[16], tok_make(.Brace, .Right))
}
