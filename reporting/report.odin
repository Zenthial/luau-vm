package reporting

import "../file_util"
import "core:os"
import "core:strings"

DiagKind :: enum {
	Error,
	Warning,
}

Diagnostic :: struct {
	line_start: u32,
	line_end:   u32,
	col_start:  u32,
	col_end:    u32,
	note:       string,
	kind:       DiagKind,
}

SourceFile :: struct {
	file_name:   string,
	diagnostics: [dynamic]Diagnostic,
}

file_mk :: proc(file_name: string) -> ^SourceFile {
	sf := new(SourceFile)
	sf.file_name = file_name

	return sf
}

file_add_diag :: proc(
	sf: ^SourceFile,
	line_start: u32,
	line_end: u32,
	col_start: u32,
	col_end: u32,
	note: string,
	kind: DiagKind,
) {
	diag := Diagnostic {
		line_start = line_start,
		line_end   = line_end,
		col_start  = col_start,
		col_end    = col_end,
		note       = note,
		kind       = kind,
	}

	append(&sf.diagnostics, diag)
}

// destroys the file after rendering it
file_render :: proc(sf: ^SourceFile) {
	str := file_util.get_file_content(sf.file_name)
	lines := file_util.split_lines(str)
}
