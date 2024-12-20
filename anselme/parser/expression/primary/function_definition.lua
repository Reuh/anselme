local primary = require("anselme.parser.expression.primary.primary")
local function_parameter_no_default = require("anselme.parser.expression.contextual.function_parameter_no_default")
local parameter_tuple = require("anselme.parser.expression.contextual.parameter_tuple")
local identifier = require("anselme.parser.expression.primary.identifier")

local expression_to_ast = require("anselme.parser.expression.to_ast")
local escape = require("anselme.common").escape

local ast = require("anselme.ast")
local Symbol, Call, Quote, Function, ParameterTuple = ast.Symbol, ast.Call, ast.Quote, ast.Function, ast.ParameterTuple

local regular_operators = require("anselme.common").regular_operators
local prefixes = regular_operators.prefixes
local suffixes = regular_operators.suffixes
local infixes = regular_operators.infixes

local operator_priority = require("anselme.common").operator_priority

-- same as function_parameter_no_default, but allow wrapping in (evenetual) parentheses
-- in order to solve some priotity issues (_._ has higher priority than _::_, leading to not being possible to overload it with type filtering without parentheses)
local function_parameter_maybe_parenthesis = function_parameter_no_default {
	match = function(self, str)
		if str:match("^%(") then
			return function_parameter_no_default:match(str:match("^%((.*)$"))
		else
			return function_parameter_no_default:match(str)
		end
	end,
	parse = function(self, source, options, str)
		if str:match("^%(") then
			str = source:consume(str:match("^(%()(.*)$"))

			local exp, rem = function_parameter_no_default:parse(source, options, str)
			rem = source:consume_leading_whitespace(options, rem)

			if not rem:match("^%)") then error(("unexpected %q at end of parenthesis"):format(rem:match("^[^\n]*")), 0) end
			rem = source:consume(rem:match("^(%))(.-)$"))

			return exp, rem
		else
			return function_parameter_no_default:parse(source, options, str)
		end
	end
}

-- signature type 1: unary prefix
-- :$-parameter exp
-- returns symbol, parameter_tuple, rem if success
-- return nil otherwise
local function search_prefix_signature(modifiers, source, options, str)
	for _, pfx in ipairs(prefixes) do
		local prefix = pfx[1]
		local prefix_pattern = "[ \t]*"..escape(prefix).."[ \t]*"
		if str:match("^"..prefix_pattern) then
			-- operator name
			local rem = source:consume(str:match("^("..prefix_pattern..")(.*)$"))
			local symbol = Symbol:new(prefix.."_", modifiers):set_source(source:clone():increment(-1))

			-- parameters
			local parameter
			parameter, rem = function_parameter_maybe_parenthesis:expect(source, options, rem)

			local parameters = ParameterTuple:new()
			parameters:insert(parameter)

			return symbol, parameters, rem
		end
	end
end

-- signature type 2: binary infix
-- should be checked before suffix signature
-- :$parameterA + parameterB exp
-- returns symbol, parameter_tuple, rem if success
-- return nil otherwise
local function search_infix_signature(modifiers, source, options, str)
	if function_parameter_maybe_parenthesis:match(str) then
		local src = source:clone() -- operate on clone source since search success is not yet guaranteed
		local parameter_a, rem = function_parameter_maybe_parenthesis:parse(src, options, str)

		local parameters = ParameterTuple:new()
		parameters:insert(parameter_a)

		for _, ifx in ipairs(infixes) do
			local infix = ifx[1]
			local infix_pattern = "[ \t]*"..escape(infix).."[ \t]*"
			if rem:match("^"..infix_pattern) then
				-- operator name
				rem = src:consume(rem:match("^("..infix_pattern..")(.*)$"))
				local symbol = Symbol:new("_"..infix.."_", modifiers):set_source(src:clone():increment(-1))

				-- parameters
				if function_parameter_maybe_parenthesis:match(rem) then
					local parameter_b
					parameter_b, rem = function_parameter_maybe_parenthesis:parse(src, options, rem)

					parameters:insert(parameter_b)

					source:set(src)
					return symbol, parameters, rem
				else
					return
				end
			end
		end
	end
end

-- signature type 3: unary suffix
-- :$parameter! exp
-- returns symbol, parameter_tuple, rem if success
-- return nil otherwise
local function search_suffix_signature(modifiers, source, options, str)
	if function_parameter_maybe_parenthesis:match(str) then
		local src = source:clone() -- operate on clone source since search success is not yet guaranteed
		local parameter_a, rem = function_parameter_maybe_parenthesis:parse(src, options, str)

		local parameters = ParameterTuple:new()
		parameters:insert(parameter_a)

		for _, sfx in ipairs(suffixes) do
			local suffix = sfx[1]
			local suffix_pattern = "[ \t]*"..escape(suffix).."[ \t]*"
			if rem:match("^"..suffix_pattern) then
				-- operator name
				rem = src:count(rem:match("^("..suffix_pattern..")(.*)$"))
				local symbol = Symbol:new("_"..suffix, modifiers):set_source(src:clone():increment(-1))

				source:set(src)
				return symbol, parameters, rem
			end
		end
	end
end

-- signature type 4: regular function
-- :$identifier(parameter_tuple, ...) exp
-- returns symbol, parameter_tuple, rem if success
-- return nil otherwise
local function search_function_signature(modifiers, source, options, str)
	if identifier:match(str) then
		local name_source = source:clone()
		local name, rem = identifier:parse(source, options, str)

		-- name
		local symbol = name:to_symbol(modifiers):set_source(name_source)

		-- parse eventual parameters
		local parameters
		if parameter_tuple:match(rem) then
			parameters, rem = parameter_tuple:parse(source, options, rem)
		else
			parameters = ParameterTuple:new()
		end

		return symbol, parameters, rem
	end
end

return primary {
	match = function(self, str)
		return str:match("^%:&?@?%$")
	end,

	parse = function(self, source, options, str)
		local source_start = source:clone()
		local mod_alias, mod_exported, rem = source:consume(str:match("^(%:(&?)(@?)%$)(.-)$"))

		-- get modifiers
		local exported, alias
		if mod_alias == "&" then alias = true end
		if mod_exported == "@" then exported = true end
		local modifiers = { exported = exported, alias = alias }

		-- search for a valid signature
		local symbol, parameters
		local s, p, r = search_prefix_signature(modifiers, source, options, rem)
		if s then symbol, parameters, rem = s, p, r
		else
			s, p, r = search_infix_signature(modifiers, source, options, rem)
			if s then symbol, parameters, rem = s, p, r
			else
				s, p, r = search_suffix_signature(modifiers, source, options, rem)
				if s then symbol, parameters, rem = s, p, r
				else
					s, p, r = search_function_signature(modifiers, source, options, rem)
					if s then symbol, parameters, rem = s, p, r end
				end
			end
		end

		-- done
		if symbol then
			-- parse expression
			local right
			s, right, rem = pcall(expression_to_ast, source, options, rem, operator_priority["$_"])
			if not s then error(("invalid expression in function definition: %s"):format(right), 0) end

			-- return function
			local fn = Function:with_return_boundary(parameters, right):set_source(source_start)
			return Call:from_operator("_=_", Quote:new(symbol), fn):set_source(source_start), rem
		end
	end
}
