local ast = require("ast")
local ArgumentTuple, Nil, Boolean, Identifier = ast.ArgumentTuple, ast.Nil, ast.Boolean, ast.Identifier

local if_identifier = Identifier:new("_if_status")
local if_symbol = if_identifier:to_symbol()

local function ensure_if_variable(state)
	if not state.scope:defined_in_current(if_symbol) then
		state.scope:define(if_symbol, Boolean:new(false))
	end
end
local function set_if_variable(state, bool)
	state.scope:set(if_identifier, Boolean:new(bool))
end
local function last_if_success(state)
	return state.scope:get(if_identifier):truthy()
end

return {
	{
		"_~_", "(condition, expression)", function(state, condition, expression)
			ensure_if_variable(state)
			if condition:truthy() then
				set_if_variable(state, true)
				return expression:call(state, ArgumentTuple:new())
			else
				set_if_variable(state, false)
				return Nil:new()
			end
		end
	},
	{
		"~_", "(expression)",
		function(state, expression)
			ensure_if_variable(state)
			if last_if_success(state) then
				return Nil:new()
			else
				set_if_variable(state, true)
				return expression:call(state, ArgumentTuple:new())
			end
		end
	},

	{
		"_~?_", "(condition, expression)",
		function(state, condition, expression)
			ensure_if_variable(state)
			local cond = condition:call(state, ArgumentTuple:new())
			local r
			if cond:truthy() then
				set_if_variable(state, true)
			else
				set_if_variable(state, false)
				return Nil:new()
			end
			while cond:truthy() do
				r = expression:call(state, ArgumentTuple:new())
				cond = condition:call(state, ArgumentTuple:new())
			end
			return r
		end
	},
}
