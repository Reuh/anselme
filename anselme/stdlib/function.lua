local ast = require("anselme.ast")
local Nil, Boolean, Definition, Return = ast.Nil, ast.Boolean, ast.Definition, ast.Return
local assert0 = require("anselme.common").assert0

return {
	{
		"defined", "(c::function, s::string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined_in_current(state, s:to_identifier()))
		end
	},
	{
		"has upvalue", "(c::function, s::string)",
		function(state, c, s)
			return Boolean:new(c.scope:defined(state, s:to_identifier()))
		end
	},

	{
		"_._", "(c::function, s::string)",
		function(state, c, s)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			return c.scope:get(state, identifier)
		end
	},
	{
		"_._", "(c::function, s::string) = v",
		function(state, c, s, v)
			local identifier = s:to_identifier()
			assert0(c.scope:defined(state, identifier), ("no variable %q defined in closure"):format(s.string))
			c.scope:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		"_._", "(c::function, s::symbol) = v",
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
