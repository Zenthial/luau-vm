package file_util

import "core:os"
import "core:strings"

get_file_content :: proc(file_path: string) -> string {
	data, ok := os.read_entire_file(file_path, context.allocator)
	if !ok {
		panic("could not read file")
	}
	// defer delete(data, context.allocator)

	it := string(data)
	return strings.clone(it)
}

split_lines :: proc(s: string) -> [dynamic]string {
	lines: [dynamic]string
	it := string(s)
	for line in strings.split_lines_iterator(&it) {
		append(&lines, line)
	}

	return lines
}
