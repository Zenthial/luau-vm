package luau

import "core:strings"
import "core:unicode"
import "core:unicode/utf8"

// Only allows for ASCII whitespace
ASCII_WHITESPACE :: distinct bit_set['\x00' ..< utf8.RUNE_SELF;u128]
WHITESPACE :: ASCII_WHITESPACE{'\t', '\n', '\r', ' '}
Keyword :: enum {
	Local,
	Function,
	End,
	If,
	ElseIf,
	While,
	Do,
	For,
}

@(private)
to_keyword :: proc(s: string) -> Maybe(Keyword) {
	if s == "local" {
		return .Local
	} else if s == "function" {
		return .Function
	} else if s == "end" {
		return .End
	} else if s == "if" {
		return .If
	} else if s == "elseif" {
		return .ElseIf
	} else if s == "while" {
		return .While
	} else if s == "do" {
		return .Do
	} else if s == "for" {
		return .For
	}

	return nil
}

Kind :: enum {
	Ident,
	Keyword,
}

Data :: union {
	string,
	Keyword,
}

Tok :: struct {
	kind: Kind,
	data: Data,
}

@(private)
tok_make :: proc(kind: Kind, data: Data) -> Tok {
	return Tok{kind = kind, data = data}
}

Lexer :: struct {
	src:      string,
	pos:      int,
	finished: bool,
}

@(private)
lexer_make :: proc(src: string) -> Lexer {
	return Lexer{src = src, pos = 0, finished = false}
}

@(private)
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

@(private)
is_ident_rune :: proc(ch: rune, i: int) -> bool {
	return ch == '_' || unicode.is_letter(ch) || unicode.is_digit(ch) && i > 0
}

@(private)
peak :: proc(l: ^Lexer) -> rune {
	return rune(l.src[l.pos])
}

@(private)
build_ident :: proc(l: ^Lexer) -> string {
	i := 0
	ident := strings.Builder{}
	for len(l.src) > l.pos && is_ident_rune(peak(l), i) {
		strings.write_rune(&ident, advance(l))
	}

	return strings.to_string(ident)
}

@(private)
advance :: proc(l: ^Lexer) -> rune {
	c := rune(l.src[l.pos])
	l.pos += 1
	return c
}

@(private)
scan :: proc(l: ^Lexer) -> Maybe(Tok) {
	next_rune := peak(l)
	if next_rune in WHITESPACE {
		advance(l)
		return scan(l)
	} else if is_ident_rune(next_rune, 0) {
		ident := build_ident(l)
		keyword, ok := to_keyword(ident).?
		if ok {
			return Tok{kind = .Keyword, data = keyword}
		} else {
			return Tok{kind = .Ident, data = ident}
		}
	}

	return nil
}

lex :: proc(s: string) -> [dynamic]Tok {
	l := lexer_make(s)
	tok_stream: [dynamic]Tok
	for !(l.pos >= len(l.src)) {
		tok, ok := scan(&l).?
		if ok {
			append(&tok_stream, tok)
		} else {
			panic("a lexing error occured")
		}
	}
	return tok_stream
}
