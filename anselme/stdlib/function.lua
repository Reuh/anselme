local ast = require("anselme.ast")
local Nil, Boolean, Definition, Return, Overload, Overloadable = ast.Nil, ast.Boolean, ast.Definition, ast.Return, ast.Overload, ast.abstract.Overloadable
local assert0 = require("anselme.common").assert0

return {
	{
		"defined", "(c::is function, s::is string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined_in_current(state, s:to_identifier()))
		end
	},
	{
		"has upvalue", "(c::is function, s::is string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined(state, s:to_identifier()))
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
			local r = Definition:new(s, v):eval(state)
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
