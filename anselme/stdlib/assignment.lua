local ast = require("anselme.ast")
local Nil, Boolean, LuaCall, ParameterTuple, FunctionParameter, Identifier, Overloadable, Overload, Call, Quote = ast.Nil, ast.Boolean, ast.LuaCall, ast.ParameterTuple, ast.FunctionParameter, ast.Identifier, ast.abstract.Overloadable, ast.Overload, ast.Call, ast.Quote

return {
	{
		"constant", "(exp)",
		function(state, exp)
			return Boolean:new(false)
		end
	},

	{
		"is tuple", "(exp)",
		function(state, exp)
			return Boolean:new(exp.type == "tuple")
		end
	},

	-- for internal usage, user should'nt interact with quotes
	{
		"is quote", "(exp)",
		function(state, exp)
			return Boolean:new(exp.type == "quote")
		end
	},
	-- for internal usage, user should'nt interact with quotes
	{
		"is quoted", "(type::($(x) x!type == \"string\"))",
		function(state, type)
			return LuaCall:make_function(state,
				ParameterTuple:new(FunctionParameter:new(Identifier:new("quote"), nil, Identifier:new("is quote"))),
				function(state, quote)
					return Boolean:new(quote.expression.type == type.string)
				end
			)
		end
	},

	{
		"_=_", "(quote::is quoted(\"identifier\"), value)", function(state, quote, value)
			state.scope:set(quote.expression, value)
			return Nil:new()
		end
	},
	{
		"_=_", "(quote::is quoted(\"symbol\"), value)", function(state, quote, value)
			local symbol = quote.expression:eval(state)
			if Overloadable:issub(value) or Overload:is(value) then
				state.scope:define_overloadable(symbol, value)
			else
				state.scope:define(symbol, value)
			end
			return Nil:new()
		end
	},
	{
		"_=_", "(quote::is quoted(\"tuple\"), value::is tuple)", function(state, quote, tuple)
			assert(quote.expression:len() == tuple:len(), "left and right tuple do no have the same number of elements")
			for i, left in quote.expression:iter() do
				Call:from_operator("_=_", Quote:new(left), tuple:get(i)):eval(state)
			end
			return Nil:new()
		end
	},
}
