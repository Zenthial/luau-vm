package main

import "core:fmt"
import "core:os"
import "luau"

main :: proc() {
	args := os.args
	if len(args) < 2 {
		panic("expected file path")
	}

	lua_file := args[1]
	fmt.println(lua_file)
	toks := luau.parse(lua_file)
	fmt.println(toks)
}