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


file_to_ast :: proc(file_path: string, dump_toks: bool) -> [dynamic]Ast {
	content := get_file_content(file_path)
	tok_stream := lex(content)
	if dump_toks {
		fmt.println(tok_stream)
	}
	ast := parse(&tok_stream)
	return ast
}
