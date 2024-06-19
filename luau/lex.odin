package luau

import "core:fmt"
import "core:log"
import "core:strconv"
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
	And,
	Or,
	Return,
	// luau specific
	Type,
	Export,
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
	} else if s == "and" {
		return .And
	} else if s == "or" {
		return .Or
	} else if s == "return" {
		return .Return
	} else if s == "type" {
		return .Type
	} else if s == "export" {
		return .Export
	}

	return nil
}

@(private)
to_bool :: proc(s: string) -> Maybe(bool) {
	if s == "true" {
		return true
	}

	if s == "false" {
		return false
	}

	return nil
}

Kind :: enum {
	Ident,
	Keyword,
	String,
	Equal,
	Number,
	Bool,
	Paren,
	Brace,
	Bracket,
	Crocodile,
	Comma,
	Tilda, // not
	QuestionMark,
	Colon,
	Ampersand,
	Pipe,
	Arrow, // used in return type definitions
}

Side :: enum {
	Left,
	Right,
}

Data :: union {
	string,
	Keyword,
	f64,
	bool,
	Side,
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
is_ident_rune :: proc(ch: rune, i: int) -> bool {
	return ch == '_' || unicode.is_letter(ch) || unicode.is_digit(ch) && i > 0
}

@(private)
is_number :: proc(ch: rune) -> bool {
	return unicode.is_digit(ch) || ch == '.'
}

@(private)
peak :: proc(l: ^Lexer) -> rune {
	return rune(l.src[l.pos])
}

@(private)
peak_width :: proc(l: ^Lexer, width: int) -> string {
	b := strings.builder_make()
	for i := 0; i < width; i += 1 {
		strings.write_rune(&b, rune(l.src[l.pos + i]))
	}

	return strings.to_string(b)
}

@(private = "file")
take_until :: proc(l: ^Lexer, until: string) -> Maybe(string) {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	width := len(until)
	found := false
	for !found {
		if len(l.src) - l.pos < width {
			// panic("cannot take anymore")
			return nil
		}

		s := peak_width(l, width)
		if s == until {
			found = true
			l.pos += width
			break
		} else {
			strings.write_rune(&b, rune(s[0]))
		}
		l.pos += 1
	}

	return strings.to_string(b)
}

@(private)
advance :: proc(l: ^Lexer, width: int) -> string {
	b := strings.builder_make()
	defer strings.builder_destroy(&b)
	for i := l.pos; i < l.pos + width; i += 1 {
		c := rune(l.src[i])
		strings.write_rune(&b, c)
	}
	l.pos += width
	built_str := strings.to_string(b)
	return strings.clone(built_str)
}

@(private)
build_ident :: proc(l: ^Lexer) -> string {
	i := 0
	ident := strings.builder_make()
	defer strings.builder_destroy(&ident)
	for len(l.src) > l.pos && is_ident_rune(peak(l), i) {
		s := advance(l, 1)
		strings.write_string(&ident, s)
	}

	return strings.clone(strings.to_string(ident))
}

@(private)
build_num :: proc(l: ^Lexer) -> f64 {
	num := strings.builder_make()
	defer strings.builder_destroy(&num)
	for len(l.src) > l.pos && is_number(peak(l)) {
		strings.write_string(&num, advance(l, 1))
	}

	num_str := strings.to_string(num)
	f := strconv.atof(num_str)
	return f
}

// note for future tom
// could add the builder to the lexer, rather than creating many
// currently, deleting a builder results in the underlying buffer being freed, which results in the strings its created being corrupted
@(private)
scan :: proc(l: ^Lexer) -> Result(Tok) {
	next_rune := peak(l)
	if next_rune in WHITESPACE {
		advance(l, 1)
		return scan(l)
	} else if is_ident_rune(next_rune, 0) {
		ident := build_ident(l)
		keyword, ok := to_keyword(ident).?
		if ok {
			return Tok{kind = .Keyword, data = keyword}
		} else {
			b, ok := to_bool(ident).?
			if ok {
				return Tok{kind = .Bool, data = b}
			}
			return Tok{kind = .Ident, data = ident}
		}
	} else if next_rune == '-' && peak_width(l, 2) == "--" {
		advance(l, 2)
		s: Maybe(string)
		if peak_width(l, 2) == "[[" {
			s = take_until(l, "]]")
		} else {
			s = take_until(l, "\n")
		}
		if s == nil {
			return .EOF
		}
		return scan(l)
	} else if next_rune == '-' && peak_width(l, 2) == "->" {
		advance(l, 2)
		return Tok{kind = .Arrow, data = nil}
	} else if next_rune == '"' {
		s, ok := take_until(l, "\"").?
		if !ok {
			return .EOF
		}

		return Tok{kind = .String, data = s}
	} else if is_number(next_rune) {
		num := build_num(l)
		return Tok{kind = .Number, data = num}
	} else if next_rune == '=' {
		advance(l, 1)
		return Tok{kind = .Equal, data = nil}
	} else if next_rune == '(' {
		advance(l, 1)
		return Tok{kind = .Paren, data = .Left}
	} else if next_rune == ')' {
		advance(l, 1)
		return Tok{kind = .Paren, data = .Right}
	} else if next_rune == '{' {
		advance(l, 1)
		return Tok{kind = .Brace, data = .Left}
	} else if next_rune == '}' {
		advance(l, 1)
		return Tok{kind = .Brace, data = .Right}
	} else if next_rune == '[' {
		advance(l, 1)
		return Tok{kind = .Bracket, data = .Left}
	} else if next_rune == ']' {
		advance(l, 1)
		return Tok{kind = .Bracket, data = .Right}
	} else if next_rune == '<' {
		advance(l, 1)
		return Tok{kind = .Crocodile, data = .Left}
	} else if next_rune == '>' {
		advance(l, 1)
		return Tok{kind = .Crocodile, data = .Right}
	} else if next_rune == ',' {
		advance(l, 1)
		return Tok{kind = .Comma, data = nil}
	} else if next_rune == '?' {
		advance(l, 1)
		return Tok{kind = .QuestionMark, data = nil}
	} else if next_rune == '~' {
		advance(l, 1)
		return Tok{kind = .Tilda, data = nil}
	} else if next_rune == ':' {
		advance(l, 1)
		return Tok{kind = .Colon, data = nil}
	} else if next_rune == '&' {
		advance(l, 1)
		return Tok{kind = .Ampersand, data = nil}
	} else if next_rune == '|' {
		advance(l, 1)
		return Tok{kind = .Pipe, data = nil}
	}

	fmt.eprintln(
		"rune did not match anything:",
		next_rune,
		" next width: ",
		peak_width(l, 2),
		l.pos,
	)
	log.errorf("rune did not match anything %c\n%s", next_rune)
	return .Unrecognized
}

lex :: proc(s: string) -> [dynamic]Tok {
	trimmed := strings.trim_space(s)
	l := lexer_make(trimmed)
	tok_stream: [dynamic]Tok
	// defer delete(tok_stream)
	for len(l.src) > l.pos {
		result := scan(&l)
		tok, ok := result.(Tok)
		if ok {
			append(&tok_stream, tok)
		} else {
			err, _ := result.(Error)
			if err != .EOF {
				log.error(err)
				panic("a lexing error occured")
			}
		}
	}
	return tok_stream
}
