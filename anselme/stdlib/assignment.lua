---# Variable assignment
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil, Boolean, LuaCall, ParameterTuple, FunctionParameter, Identifier, Overloadable, Overload, Call, Quote = ast.Nil, ast.Boolean, ast.LuaCall, ast.ParameterTuple, ast.FunctionParameter, ast.Identifier, ast.abstract.Overloadable, ast.Overload, ast.Call, ast.Quote

return {
	{
		--- Always return false.
		-- Can be used as variable value checking function to prevent any reassignment and thus make the variable constant.
		-- ```
		-- :var::constant = 42
		-- ```
		-- @defer value checking
		"constant", "(exp)",
		function(state, exp)
			return Boolean:new(false)
		end
	},

	{
		--- Returns true if the expression is a tuple, false otherwise.
		-- @defer value checking
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
		--- Assign `value` to the variable `identifier`.
		-- ```
		-- var = 42
		-- ```
		-- @title identifier = value
		"_=_", "(quote::is quoted(\"identifier\"), value)",
		function(state, quote, value)
			state.scope:set(quote.expression, value)
			return Nil:new()
		end
	},
	{
		--- Define the variable using the symbol `symbol` with the initial value `value`.
		-- ```
		-- :var = 42
		-- ```
		-- @title symbol::is symbol = value
		"_=_", "(quote::is quoted(\"symbol\"), value)",
		function(state, quote, value)
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
		--- For each `variable` element of the variable tuple and associated `value` element of the value tuple, call `variable = value`.
		-- ```
		-- (:a, :b) = (24, 42)
		-- (a, b) = (b, a)
		-- ```
		-- @title variable tuple::is tuple = value tuple::is tuple
		"_=_", "(quote::is quoted(\"tuple\"), value::is tuple)",
		function(state, quote, tuple)
			assert(quote.expression:len() == tuple:len(), "left and right tuple do no have the same number of elements")
			for i, left in quote.expression:iter() do
				Call:from_operator("_=_", Quote:new(left), tuple:get(i)):eval(state)
			end
			return Nil:new()
		end
	},
}
