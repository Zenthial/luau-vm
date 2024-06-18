package luau

import "core:fmt"
import "core:os"
import "core:strings"

get_file_content :: proc(file_path: string) -> string {
	data, ok := os.read_entire_file(file_path, context.allocator)
	if !ok {
		panic("could not read file")
	}
	defer delete(data, context.allocator)

	it := string(data)
	return strings.clone(it)
}


parse :: proc(file_path: string) -> [dynamic]Tok {
	content := get_file_content(file_path)
	tok_stream := lex(content)
	return tok_stream
}
