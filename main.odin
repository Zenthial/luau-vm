package main

import "core:fmt"
import "core:os"
import "luau"

main :: proc() {
	args := os.args
	if len(args) < 2 {
		panic("expected file path")
	}

	just_lex := false
	if len(args) == 3 {
		if args[2] == "lex" {
			just_lex = true
		}
	}

	lua_file := args[1]
	fmt.println(lua_file)
	ast := luau.file_to_ast(lua_file, just_lex)
	fmt.println(ast)
}
