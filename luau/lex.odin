package luau

import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

// Only allows for ASCII whitespace
ASCII_WHITESPACE :: distinct bit_set['\x00' ..< utf8.RUNE_SELF;u128]
WHITESPACE :: ASCII_WHITESPACE{'\t', '\n', '\r', ' '}

Kind :: enum {
	Ident,
}

Tok :: struct {
	kind: Kind,
	data: union {
		string,
	},
}

Lexer :: struct {
	src: string,
	pos: uint,
}

take_until :: proc(l: ^Lexer, until: rune) -> string {
	b := strings.Builder{}
	found := false
	for !found {
		if strings.rune_count(l.src) == 0 {
			panic("cannot take anymore")
		}

		r := rune(l.src[l.pos]) // we don't support utf8
		if r == until {
			found = true
		} else {
			strings.write_rune(&b, r)
		}
		l.pos += 1
	}

	return strings.to_string(b)
}

is_ident_rune :: proc(ch: rune, i: int) -> bool {
	return ch == '_' || unicode.is_letter(ch) || unicode.is_digit(ch) && i > 0
}

peak :: proc(l: ^Lexer) -> rune {
	return rune(l.src[l.pos])
}

build_ident :: proc(l: ^Lexer) -> string {
	i := 0
	ident := strings.Builder{}
	for is_ident_rune(peak(l), i) {
		strings.write_rune(&ident, advance(l))
	}

	return strings.to_string(ident)
}

advance :: proc(l: ^Lexer) -> rune {
	c := rune(l.src[l.pos])
	l.pos += 1
	return c
}

scan :: proc(l: ^Lexer) -> Maybe(Tok) {
	next_rune := peak(l)
	if next_rune in WHITESPACE {
		advance(l)
		return scan(l)
	} else if is_ident_rune(next_rune, 0) {
		ident := build_ident(l)
		return Tok{kind = .Ident, data = ident}
	}

	return nil
}

lex :: proc(s: string) -> []Tok {
	return nil
}
