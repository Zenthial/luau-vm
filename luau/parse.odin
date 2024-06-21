package luau

import "core:fmt"
import "core:log"

Ident :: distinct string

AstValue :: union {
	string,
	Ident,
	FieldAccess,
	FunctionCall,
	Function,
	f64,
	bool,
	Table,
}

Return :: struct {
	val: AstValue,
}

Local :: struct {
	name:    Ident,
	binding: AstValue,
}

Table :: map[Ident]AstValue

Param :: struct {
	name: Ident,
	type: Maybe(Ident),
}

Function :: struct {
	name:     Ident,
	method:   bool,
	generics: Maybe([dynamic]Param),
	params:   [dynamic]Param,
	body:     [dynamic]Ast,
}

FunctionCall :: struct {
	name:        Ident,
	call_params: [dynamic]AstValue,
}

FieldAccess :: struct {
	table_name: Ident,
	field:      Ident,
}

Ast :: union {
	Local,
	Function,
	FunctionCall,
	Return,
}

Parser :: struct {
	toks:          ^[dynamic]Tok,
	tables:        ^map[string]Table,
	current_local: Maybe(string), // the name of the current local we're in, if it exists
}

parse_table :: proc(p: ^Parser) -> Table {
	tab := make(map[Ident]AstValue)
	for {
		ident := pop_front(p.toks)

		if ident.kind == .Brace && ident.data == .Right {
			break
		} else {
			name := Ident(ident.data.(string))
			binding := parse_value(p)
			tab[name] = binding
		}
	}

	p.tables[p.current_local.(string)] = tab
	return tab
}

@(private)
parse_function_definition :: proc(p: ^Parser, function_name: Tok, is_method: bool) -> Function {
	lparen := pop_front(p.toks)
	// generic function
	generics: Maybe([dynamic]Ident)
	if lparen.kind == .Crocodile && lparen.data == .Left {
		gens := [dynamic]Ident{}
		found_generic := false // must find at least one generic
		for {
			tok := pop_front(p.toks)
			if tok.kind == .Crocodile && tok.data == .Right {
				if !found_generic {
					panic("no generic provided")
				}
				lparen = pop_front(p.toks)
				break
			} else if tok.kind == .Ident {
				found_generic = true
				append(&gens, Ident(tok.data.(string)))
			} else {
				panic("token found that isnt an ident or crocodile in generic definition")
			}
		}

		generics = gens
	}

	assert(lparen.kind == .Paren && lparen.data == .Left, "expected lparen")
	params: [dynamic]Param
	expecting_type: bool = false
	is_paren :: proc(tok: Tok) -> bool {
		return tok.kind == .Paren && tok.data == .Right
	}
	for {
		value := pop_front(p.toks)
		if value.kind == .Ident {
			snd := pop_front(p.toks)
			if is_paren(snd) {
				append(&params, Param{name = Ident(value.data.(string)), type = nil})
				break
			} else if snd.kind == .Comma {
				append(&params, Param{name = Ident(value.data.(string)), type = nil})
				continue
			} else if snd.kind == .Colon {
				type := pop_front(p.toks)
				append(
					&params,
					Param{name = Ident(value.data.(string)), type = Ident(type.data.(string))},
				)
			} else {
				panic("unexpected token in function definition")
			}
		} else if is_paren(value) {
			break
		} else if value.kind == .Comma {
			continue
		} else {
			panic("unexpected token in function definition")
		}
	}

	body: [dynamic]Ast
	// now have parsed all the def params
	for {
		tok := pop_front(p.toks)
		if tok.kind == .Keyword && tok.data == .End {
			break
		}
	}

	return Function{name = Ident(function_name.data.(string)), params = params, body = body}
}

@(private)
parse_function_call :: proc(p: ^Parser, method_ident: Maybe(Tok)) -> FunctionCall {
	_ = pop_front(p.toks) // pop the colon
	function_name := pop_front(p.toks)
	assert(function_name.kind == .Ident, "function name expected to be an ident")
	lparen := pop_front(p.toks)
	assert(lparen.kind == .Paren && lparen.data == .Left, "expected lparen")
	params: [dynamic]AstValue
	if ident, ok := method_ident.(Tok); ok {
		append(&params, Ident(ident.data.(string)))
	}
	outer: for {
		value := p.toks[0]
		#partial switch value.kind {
		case .Paren:
			assert(value.data == .Right)
			pop_front(p.toks)
			break outer
		case .Comma:
			pop_front(p.toks)
		case:
			append(&params, parse_value(p))
		}
	}

	return FunctionCall{name = Ident(function_name.data.(string)), call_params = params}
}

@(private)
parse_value :: proc(p: ^Parser) -> AstValue {
	head_tok := pop_front(p.toks)
	#partial switch head_tok.kind {
	case .Number:
		return head_tok.data.(f64)
	case .String:
		return head_tok.data.(string)
	case .Bool:
		return head_tok.data.(bool)
	case .Brace:
		assert(head_tok.data == .Left)
		return parse_table(p)
	case .Ident:
		if len(p.toks) >= 1 {
			if p.toks[0].kind == .Colon {
				return parse_function_call(p, head_tok)
			} else if p.toks[0].kind == .Dot {
				if p.toks[1].kind == .Ident {
					pop_front(p.toks)
					field := pop_front(p.toks)
					return FieldAccess {
						table_name = Ident(head_tok.data.(string)),
						field = Ident(field.data.(string)),
					}
				}
			}
		} else {
			return Ident(head_tok.data.(string))
		}
	}
	fmt.println(head_tok)
	panic("unsupported token tried to be parsed into a value")
}

@(private)
parse_local :: proc(p: ^Parser) -> Result(Ast) {
	fst := pop_front(p.toks)
	snd := pop_front(p.toks)

	if fst.kind == .Ident && snd.kind == .Equal {
		local_name := fst.data.(string)
		p.current_local = local_name
		value := parse_value(p)
		return Ast(Local{name = Ident(local_name), binding = value})
	} else if fst.kind == .Keyword && fst.data == .Function && snd.kind == .Ident {
		local_name := snd.data.(string)
		p.current_local = local_name
		return Ast(parse_function_definition(p, snd, false))
	}

	fmt.println(fst, snd)
	return .Unrecognized
}

@(private)
parse_current_token :: proc(p: ^Parser) -> Result(Ast) {
	tok := p.toks[0]
	if tok.kind == .Keyword && tok.data.(Keyword) == .Local {
		pop_front(p.toks)
		return parse_local(p)
	} else if tok.kind == .Keyword && tok.data.(Keyword) == .Return {
		pop_front(p.toks)
		value := parse_value(p)
		return Ast(Return{val = value})
	} else if tok.kind == .Keyword && tok.data.(Keyword) == .Function {
		pop_front(p.toks)
		function_name := pop_front(p.toks)
		tab: Maybe(Tok) = nil
		is_method := false
		if ok := function_name.data.(string) in p.tables; ok {
			assert(p.toks[0].kind == .Dot || p.toks[1].kind == .Colon)
			if p.toks[0].kind == .Colon {is_method = true}
			tab = function_name
			pop_front(p.toks)
			function_name = pop_front(p.toks)
		}
		func_def := parse_function_definition(p, function_name, is_method)
		tab_token, ok := tab.?
		if ok {
			table := p.tables[tab_token.data.(string)]
			table[Ident(function_name.data.(string))] = AstValue(func_def)
		}

		return Ast(func_def)
	}

	fmt.println(tok)

	return .Unrecognized
}

parse :: proc(toks: ^[dynamic]Tok) -> [dynamic]Ast {
	p := new(Parser)
	p.toks = toks
	tabs := make(map[string]Table)
	p.tables = &tabs
	// log.info("stream: ", toks)

	ast: [dynamic]Ast
	for len(p.toks) > 0 {
		node, ok := parse_current_token(p).(Ast)
		if !ok {
			panic("unrecognized token in parser")
		}
		append(&ast, node)
		fmt.println(ast)
	}

	return ast
}
