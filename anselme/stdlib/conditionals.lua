--- # Control flow
--
-- ```
-- if(5 > 3)
-- 	print("called")
--
-- if(3 > 5)
-- 	print("not called")
-- else if(1 > 5)
-- 	print("not called")
-- else!
-- 	print("called")
-- ```
-- @titlelevel 3

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
		--- Call `expression` if `condition` is true.
		-- Returns the result of the call to `expression`, or nil if the condition was false.
		--
		-- If we are currently resuming to an anchor contained in `expression`, `expression` is called regardless of the condition result.
		"if", "(condition, expression=attached block(keep return=true))", function(state, condition, expression)
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
		--- Call `if true` if `condition` is true, `if false` otherwise.
		-- Return the result of the call.
		--
		-- If we are currently resuming to an anchor contained in `if true` or `if false`, `if true` or `if false` (respectively) is called regardless of the condition result.
		"if", "(condition, if true, if false)", function(state, condition, if_true, if_false)
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
		--- Call `expression` if `condition` is true and the last if, else if or else's condition was false, or the last while loop was never entered.
		-- Returns the result of the call to `expression`, or nil if not called.
		--
		-- If we are currently resuming to an anchor contained in `expression`, `expression` is called regardless of the condition result.
		"else if", "(condition, expression=attached block(keep return=true))",
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
		--- Call `expression` if the last if, else if or else's condition was false, or the last while loop was never entered.
		-- Returns the result of the call to `expression`, or nil if not called.
		--
		-- If we are currently resuming to an anchor contained in `expression`, `expression` is called regardless of the condition result.
		"else", "(expression=attached block(keep return=true))",
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
		--- Call `condition`, if it returns a true value, call `expression`, and repeat until `condition` returns a false value.
		--
		-- Returns the value returned by the the last loop.
		-- If `condition` returns a false value on its first call, returns nil.
		--
		-- If a `continue` happens in the loop, the current iteration is stopped and skipped.
		-- If a `break` happens in the loop, the whole loop is stopped.
		--
		-- ```
		-- :i = 1
		-- while(i <= 5)
		-- 	print(i)
		-- 	i += 1
		-- // 1, 2, 3, 4, 5
		-- ```
		--
		-- ```
		-- :i = 1
		-- while(i <= 5)
		-- 	if(i == 3, break)
		-- 	print(i)
		-- 	i += 1
		-- // 1, 2
		-- ```
		--
		-- ```
		-- :i = 1
		-- while(i <= 5)
		-- 	if(i == 3, continue)
		-- 	print(i)
		-- 	i += 1
		-- // 1, 2, 4, 5
		-- ```
		--
		-- ```
		-- :i = 10
		-- while(i <= 5)
		-- 	print(i)
		-- 	i += 1
		-- else!
		-- 	print("the while loop was never entered")
		-- // the while loop was never entered
		-- ```
		"while", "(condition, expression=attached block(keep return=true))",
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
	{
		--- Returns a `break` return value, eventually with an associated value.
		-- This can be used to exit a loop.
		"break", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val, "break")
		end
	},
	{
		--- Returns a `continue` return value, eventually with an associated value.
		-- This can be used to skip the current loop iteration.
		"continue", "(value=())",
		function(state, val)
			if Return:is(val) then val = val.expression end
			return Return:new(val, "continue")
		end
	},
}
