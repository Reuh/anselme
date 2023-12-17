local class = require("class")

local ast = require("ast")
local Resumable, Nil, List, Identifier

-- stack of resumable contexts
local resumable_stack_identifier, resumable_stack_symbol

local resumable_manager = class {
	init = false,

	setup = function(self, state)
		state.scope:define(resumable_stack_symbol, List:new(state))
		self:push(state, Resumable:new(state, Nil:new(), state.scope:capture()))
	end,
	reset = function(self, state)
		state.scope:set(resumable_stack_identifier, List:new(state))
		self:push(state, Resumable:new(state, Nil:new(), state.scope:capture()))
	end,

	push = function(self, state, resumable)
		local stack = state.scope:get(resumable_stack_identifier)
		stack:insert(state, resumable)
	end,
	pop = function(self, state)
		local stack = state.scope:get(resumable_stack_identifier)
		stack:remove(state)
	end,
	_get = function(self, state)
		return state.scope:get(resumable_stack_identifier):get(state, -1)
	end,

	-- returns the Resumable object that resumes from this point
	-- level indicate which function to resume: level=0 means resume the current function, level=1 the parent function (resume from the call to the current function in the parent function), etc.
	capture = function(self, state, level)
		level = level or 0
		return state.scope:get(resumable_stack_identifier):get(state, -1-level):capture(state)
	end,

	eval = function(self, state, exp)
		self:push(state, Resumable:new(state, exp, state.scope:capture()))
		local r = exp:eval(state)
		self:pop(state)
		return r
	end,

	set_data = function(self, state, node, data)
		self:_get(state).data:set(state, node, data)
	end,
	get_data = function(self, state, node)
		return self:_get(state).data:get(state, node)
	end,
	resuming = function(self, state, node)
		local resumable = self:_get(state)
		if node then
			return resumable.resuming and resumable.data:has(state, node)
		else
			return resumable.resuming
		end
	end
}

package.loaded[...] = resumable_manager

Resumable, Nil, List, Identifier = ast.Resumable, ast.Nil, ast.List, ast.Identifier

resumable_stack_identifier = Identifier:new("_resumable_stack")
resumable_stack_symbol = resumable_stack_identifier:to_symbol{ confined_to_branch = true } -- per-branch, global variables

return resumable_manager
