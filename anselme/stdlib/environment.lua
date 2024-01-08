local ast = require("anselme.ast")
local Nil, Boolean, Definition = ast.Nil, ast.Boolean, ast.Definition
local assert0 = require("anselme.common").assert0
local parser = require("anselme.parser")

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

	{
		"import", "(env::is environment, symbol tuple::is tuple)",
		function(state, env, l)
			for _, sym in l:iter(state) do
				Definition:new(sym, env:get(state, sym:to_identifier())):eval(state)
			end
			return env
		end
	},
	{
		"import", "(env::is environment, symbol::is symbol)",
		function(state, env, sym)
			Definition:new(sym, env:get(state, sym:to_identifier())):eval(state)
			return env
		end
	},

	{
		"load", "(path::is string)",
		function(state, path)
			-- read file
			local f = assert(io.open(path.string, "r"))
			local block = parser(f:read("a"), path.string)
			f:close()
			-- exec in new scope
			state.scope:push_global()
			state.scope:push_export()
			state.scope:push()
			block:eval(state)
			state.scope:pop()
			local exported = state.scope:capture()
			state.scope:pop()
			state.scope:pop()
			return exported
		end
	},
}
