local ast = require("ast")
local Nil, Boolean, Definition = ast.Nil, ast.Boolean, ast.Definition

return {
	{
		"defined", "(c::closure, s::string)",
		function(state, c, s)
			return Boolean:new(c.exported_scope:defined_in_current_strict(state, s:to_identifier()))
		end
	},
	{
		"_._", "(c::closure, s::string)",
		function(state, c, s)
			local identifier = s:to_identifier()
			assert(c.exported_scope:defined_in_current_strict(state, identifier), ("no exported variable %q defined in closure"):format(s.string))
			return c.exported_scope:get(state, identifier)
		end
	},
	{
		"_._", "(c::closure, s::string) = v",
		function(state, c, s, v)
			local identifier = s:to_identifier()
			assert(c.exported_scope:defined_in_current_strict(state, identifier), ("no exported variable %q defined in closure"):format(s.string))
			c.exported_scope:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		"_._", "(c::closure, s::symbol) = v",
		function(state, c, s, v)
			assert(s.exported, "can't define a non-exported variable from the outside of the closure")
			state.scope:push(c.exported_scope)
			local r = Definition:new(s, v):eval(state)
			state.scope:pop()
			return r
		end
	}
}
