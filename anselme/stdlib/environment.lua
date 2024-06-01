--- # Environment
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil, Boolean, Call, Quote = ast.Nil, ast.Boolean, ast.Call, ast.Quote
local assert0 = require("anselme.common").assert0
local parser = require("anselme.parser")

return {
	{
		--- Returns true if the variable named `var` is defined in in the environment `env`, false otherwise.
		--
		-- If `search parent` is true, this will also search in parent scopes of the environment `env`.
		"defined", "(env::is environment, var::is string, search parent::is boolean=false)",
		function(state, env, s, l)
			if l:truthy() then
				return Boolean:new(env:defined(state, s:to_identifier()))
			else
				return Boolean:new(env:defined_in_current(state, s:to_identifier()))
			end
		end
	},

	{
		--- Gets the variable named `s` defined in the environment `c`.
		"_._", "(c::is environment, s::is string)",
		function(state, env, s)
			local identifier = s:to_identifier()
			assert0(env:defined(state, identifier), ("no variable %q defined in environment"):format(s.string))
			return env:get(state, identifier)
		end
	},
	{
		--- Sets the variable named `s` defined in the environment `c` to `v`.
		"_._", "(c::is environment, s::is string) = v",
		function(state, env, s, v)
			local identifier = s:to_identifier()
			assert0(env:defined(state, identifier), ("no variable %q defined in environment"):format(s.string))
			env:set(state, identifier, v)
			return Nil:new()
		end
	},
	{
		--- Define a new variable `s` in the environment `c` with the value `v`.
		"_._", "(c::is environment, s::is symbol) = v",
		function(state, env, s, v)
			state.scope:push(env)
			local r = Call:from_operator("_=_", Quote:new(s), v):eval(state)
			state.scope:pop()
			return r
		end
	},

	{
		--- Get all the variables indicated in the tuple `symbol typle` from the environment `env`,
		-- and define them in the current scope.
		-- ```
		-- import(env, [:a, :b])
		-- // is the same as
		-- :a = env.a
		-- :b = env.b
		-- ```
		"import", "(env::is environment, symbol tuple::is tuple)",
		function(state, env, l)
			for _, sym in l:iter(state) do
				Call:from_operator("_=_", Quote:new(sym), env:get(state, sym:to_identifier())):eval(state)
			end
			return env
		end
	},
	{
		--- Get the variable `symbol` from the environment `env`,
		-- and define it in the current scope.
		-- ```
		-- import(env, :a)
		-- // is the same as
		-- :a = env.a
		-- ```
		"import", "(env::is environment, symbol::is symbol)",
		function(state, env, sym)
			Call:from_operator("_=_", Quote:new(sym), env:get(state, sym:to_identifier())):eval(state)
			return env
		end
	},

	{
		--- Load an Anselme script from a file and run it.
		-- Returns the environment containing the exported variables from the file.
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
