package luau

import "core:fmt"
import "core:testing"

@(test)
test_simple_local_number_binding :: proc(t: ^testing.T) {
	str := "local test = 1"
	toks := lex(str)
	ast := parse(&toks)

	testing.expect_value(t, ast[0], Local{name = "test", binding = 1})
}

@(test)
test_simple_local_string_binding :: proc(t: ^testing.T) {
	str := "local test = \"t\""
	toks := lex(str)
	ast := parse(&toks)

	testing.expect_value(t, ast[0], Local{name = "test", binding = "t"})
}
