local ast = require("anselme.ast")
local Nil, Boolean, Call, Quote, Return, Overload, Overloadable = ast.Nil, ast.Boolean, ast.Call, ast.Quote, ast.Return, ast.Overload, ast.abstract.Overloadable
local assert0 = require("anselme.common").assert0

return {
	{
		"defined", "(c::is function, s::is string, search parent::is boolean=false)",
		function(state, c, s, l)
			if l:truthy() then
				return Boolean:new(c.scope:defined(state, s:to_identifier()))
			else
				return Boolean:new(c.scope:defined_in_current(state, s:to_symbol()))
			end
		end
	},

	{
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
		"keep return", "(f::is function)",
		function(state, f)
			return f:without_return_boundary()
		end
	},

	{
		"call", "(func, args::is tuple)",
		function(state, fn, args)
			return fn:call(state, args:to_argument_tuple())
		end
	},
	{
		"call", "(func, args::is tuple) = v",
		function(state, fn, args, v)
			local argumenttuple = args:to_argument_tuple()
			argumenttuple:add_assignment(v)
			return fn:call(state, argumenttuple)
		end
	},
	{
		"can dispatch", "(func, args::is tuple)",
		function(state, fn, args)
			return Boolean:new(not not fn:dispatch(state, args:to_argument_tuple()))
		end,
	},
	{
		"can dispatch", "(func, args::is tuple) = v",
		function(state, fn, args, v)
			local argumenttuple = args:to_argument_tuple()
			argumenttuple:add_assignment(v)
			return Boolean:new(not not fn:dispatch(state, argumenttuple))
		end,
	},

	{
		"_._", "(c::is function, s::is string)",
		function(state, c, s)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			return c.scope:get(state, identifier)
		end
	},
	{
		"_._", "(c::is function, s::is string) = v",
		function(state, c, s, v)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			c.scope:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		"_._", "(c::is function, s::is symbol) = v",
		function(state, c, s, v)
			state.scope:push(c.scope)
			local r = Call:from_operator("_=_", Quote:new(s), v):eval(state)
			state.scope:pop()
			return r
		end
	},

	{
		"return", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val)
		end
	},
}
