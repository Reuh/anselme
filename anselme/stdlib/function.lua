--- # Function
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil, Boolean, Call, Quote, Return, Overload, Overloadable = ast.Nil, ast.Boolean, ast.Call, ast.Quote, ast.Return, ast.Overload, ast.abstract.Overloadable
local assert0 = require("anselme.common").assert0

return {
	{
		--- Returns true if the variable named `var` is defined in in the function `fn`'s scope, false otherwise.
		--
		-- If `search parent` is true, this will also search in parent scopes of the function scope.
		"defined", "(fn::is function, var::is string, search parent::is boolean=false)",
		function(state, c, s, l)
			if l:truthy() then
				return Boolean:new(c.scope:defined(state, s:to_identifier()))
			else
				return Boolean:new(c.scope:defined_in_current(state, s:to_symbol()))
			end
		end
	},

	{
		--- Creates and returns a new overload containing all the callables in sequence `l`.
		"overload", "(l::is sequence)",
		function(state, l)
			local r = Overload:new()
			for _, fn in l:iter(state) do
				assert0(Overloadable:issub(fn), ("trying to add a non overloadable %s to an overload"):format(fn:format(state)))
				r:insert(fn)
			end
			return r
		end
	},

	{
		--- Returns a copy of the function that keeps return values intact when returned, instead of only returning the associated value.
		"keep return", "(f::is function)",
		function(state, f)
			return f:without_return_boundary()
		end
	},

	{
		--- Call `func` with the arguments in `args`, and returns the result.
		-- If pairs with a string name appear in `args`, they are interpreted as named arguments.
		"call", "(func, args::is tuple)",
		function(state, fn, args)
			return fn:call(state, args:to_argument_tuple())
		end
	},
	{
		--- Call `func` with the arguments in `args` and assignment argument `v`, and returns the result.
		-- If pairs with a string name appear in `args`, they are interpreted as named arguments.
		"call", "(func, args::is tuple) = v",
		function(state, fn, args, v)
			local argumenttuple = args:to_argument_tuple()
			argumenttuple:add_assignment(v)
			return fn:call(state, argumenttuple)
		end
	},
	{
		--- Returns true if `func` can be called with arguments `args`.
		-- If pairs with a string name appear in `args`, they are interpreted as named arguments.
		"can dispatch", "(func, args::is tuple)",
		function(state, fn, args)
			return Boolean:new(not not fn:dispatch(state, args:to_argument_tuple()))
		end,
	},
	{
		--- Returns true if `func` can be called with arguments `args` and assignment argument `v`.
		-- If pairs with a string name appear in `args`, they are interpreted as named arguments.
		"can dispatch", "(func, args::is tuple) = v",
		function(state, fn, args, v)
			local argumenttuple = args:to_argument_tuple()
			argumenttuple:add_assignment(v)
			return Boolean:new(not not fn:dispatch(state, argumenttuple))
		end,
	},

	{
		--- Returns the value of the variable `var` defined in the function `fn`'s scope.
		"_._", "(fn::is function, var::is string)",
		function(state, c, s)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			return c.scope:get(state, identifier)
		end
	},
	{
		--- Sets the value of the variable `var` defined in the function `fn`'s scope to `v`.
		"_._", "(fn::is function, var::is string) = v",
		function(state, c, s, v)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			c.scope:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		--- Define a variable `var` in the function `fn`'s scope with the value `v`.
		"_._", "(fn::is function, var::is symbol) = v",
		function(state, c, s, v)
			state.scope:push(c.scope)
			local r = Call:from_operator("_=_", Quote:new(s), v):eval(state)
			state.scope:pop()
			return r
		end
	},

	{
		--- Returns a return value with an associated value `value`.
		-- This can be used to exit a function.
		"return", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val)
		end
	},
}
