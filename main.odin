package main

import "core:fmt"
import "core:os"
import "luau"

main :: proc() {
	args := os.args
	if len(args) < 2 {
		panic("expected file path")
	}

	dump_toks := false
	if len(args) == 3 {
		dump_toks = true
	}

	lua_file := args[1]
	fmt.println(lua_file)
	ast := luau.file_to_ast(lua_file, dump_toks)
	fmt.println(ast)
}
