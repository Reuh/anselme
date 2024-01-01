local ast = require("anselme.ast")
local ArgumentTuple, Nil, Boolean, Identifier, Return = ast.ArgumentTuple, ast.Nil, ast.Boolean, ast.Identifier, ast.Return

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
		"if", "(condition, expression=attached block keep return!)", function(state, condition, expression)
			ensure_if_variable(state)
			if condition:truthy() or expression:contains_current_resume_target(state) then
				set_if_variable(state, true)
				return expression:call(state, ArgumentTuple:new())
			else
				set_if_variable(state, false)
				return Nil:new()
			end
		end
	},
	{
		"if", "(condition, true, false)", function(state, condition, if_true, if_false)
			ensure_if_variable(state)
			if condition:truthy() or if_true:contains_current_resume_target(state) then
				set_if_variable(state, true)
				return if_true:call(state, ArgumentTuple:new())
			else
				set_if_variable(state, false)
				return if_false:call(state, ArgumentTuple:new())
			end
		end
	},
	{
		"else if", "(condition, expression=attached block keep return!)",
		function(state, condition, expression)
			ensure_if_variable(state)
			if (not last_if_success(state) and condition:truthy()) or expression:contains_current_resume_target(state) then
				set_if_variable(state, true)
				return expression:call(state, ArgumentTuple:new())
			else
				set_if_variable(state, false)
				return Nil:new()
			end
		end
	},
	{
		"else", "(expression=attached block keep return!)",
		function(state, expression)
			ensure_if_variable(state)
			if not last_if_success(state) or expression:contains_current_resume_target(state) then
				set_if_variable(state, true)
				return expression:call(state, ArgumentTuple:new())
			else
				return Nil:new()
			end
		end
	},
	{
		"while", "(condition, expression=attached block keep return!)",
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
				if Return:is(r) then
					if r.subtype == "continue" then
						r = r.expression -- consume return & pass
					elseif r.subtype == "break" then
						return r.expression -- consume return & break
					else
						return r
					end
				end
				cond = condition:call(state, ArgumentTuple:new())
			end
			return r
		end
	},
}
