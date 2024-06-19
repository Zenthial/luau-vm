package luau

import "core:log"

AstValue :: union {
	string,
	f64,
}

Local :: struct {
	name:    string,
	binding: AstValue,
}
Ast :: union {
	Local,
}

Parser :: struct {
	toks: ^[dynamic]Tok,
}

parse_value :: proc(p: ^Parser) -> AstValue {
	head_tok := pop_front(p.toks)
	#partial switch head_tok.kind {
	case .Number:
		return head_tok.data.(f64)
	case .String:
		return head_tok.data.(string)
	}
	panic("unsupported token tried to be parsed into a value")
}

parse_local :: proc(p: ^Parser) -> Result(Ast) {
	name := pop_front(p.toks)
	equal := pop_front(p.toks)

	if name.kind == .Ident && equal.kind == .Equal {
		value := parse_value(p)
		return Ast(Local{name = name.data.(string), binding = value})
	}

	return .Unrecognized
}

parse_current_token :: proc(p: ^Parser) -> Result(Ast) {
	tok := p.toks[0]
	log.info(tok)
	if tok.kind == .Keyword && tok.data.(Keyword) == .Local {
		pop_front(p.toks)
		return parse_local(p)
	}

	return .Unrecognized
}

parse :: proc(toks: ^[dynamic]Tok) -> [dynamic]Ast {
	p := new(Parser)
	p.toks = toks

	ast: [dynamic]Ast
	for len(p.toks) > 0 {
		node, ok := parse_current_token(p).(Ast)
		if !ok {
			panic("unrecognized token in parser")
		}
		append(&ast, node)
	}

	return ast
}
