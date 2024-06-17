package luau

import "core:fmt"
import "core:os"

get_file_content :: proc(file_path: string) -> string {
	data, ok := os.read_entire_file(file_path, context.allocator)
	if !ok {
		panic("failed to read file")
	}
	defer delete(data, context.allocator)
	return string(data)
}


parse :: proc(file_path: string) {
	content := get_file_content(file_path)
	tok_stream := lex(content)
}
