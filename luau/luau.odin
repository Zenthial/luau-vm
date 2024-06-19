package luau

import "core:fmt"
import "core:os"
import "core:strings"

Error :: enum {
	EOF,
	Unrecognized,
}

Result :: union($T: typeid) #no_nil {
	T,
	Error,
}

get_file_content :: proc(file_path: string) -> string {
	data, ok := os.read_entire_file(file_path, context.allocator)
	if !ok {
		panic("could not read file")
	}
	// defer delete(data, context.allocator)

	it := string(data)
	return strings.clone(it)
}


file_to_ast :: proc(file_path: string) -> [dynamic]Ast {
	content := get_file_content(file_path)
	tok_stream := lex(content)
	ast := parse(&tok_stream)
	return ast
}
