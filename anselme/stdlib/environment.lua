local ast = require("anselme.ast")
local Nil, Boolean, Definition = ast.Nil, ast.Boolean, ast.Definition
local assert0 = require("anselme.common").assert0

return {
	{
		"defined", "(c::is environment, s::is string, search parent::is boolean=false)",
		function(state, env, s, l)
			if l:truthy() then
				return Boolean:new(env:defined(state, s:to_identifier()))
			else
				return Boolean:new(env:defined_in_current(state, s:to_identifier()))
			end
		end
	},

	{
		"_._", "(c::is environment, s::is string)",
		function(state, env, s)
			local identifier = s:to_identifier()
			assert0(env:defined(state, identifier), ("no variable %q defined in environment"):format(s.string))
			return env:get(state, identifier)
		end
	},
	{
		"_._", "(c::is environment, s::is string) = v",
		function(state, env, s, v)
			local identifier = s:to_identifier()
			assert0(env:defined(state, identifier), ("no variable %q defined in environment"):format(s.string))
			env:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		"_._", "(c::is environment, s::is symbol) = v",
		function(state, env, s, v)
			state.scope:push(env)
			local r = Definition:new(s, v):eval(state)
			state.scope:pop()
			return r
		end
	},
}
