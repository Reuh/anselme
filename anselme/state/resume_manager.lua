local class = require("anselme.lib.class")

local ast = require("anselme.ast")
local Nil, Identifier, ResumeTarget, Boolean

-- stack of resumable contexts
local resume_target_identifier, resume_target_symbol
local resume_no_continue_identifier, resume_no_continue_symbol
local resume_environment_identifier, resume_environment_symbol

local resume_manager = class {
	init = false,

	-- push a new resume context: all run code between this and the next push will try to resume to target
	push = function(self, state, target)
		assert(ResumeTarget:issub(target), "can only resume to a resume target")
		state.scope:push_partial(resume_target_identifier, resume_no_continue_identifier, resume_environment_identifier)
		state.scope:define(resume_target_symbol, target)
		state.scope:define(resume_no_continue_symbol, Boolean:new(false))
		state.scope:define(resume_environment_symbol, state.scope:capture())
	end,
	-- same as :push, but the resume will stop immediately after reaching the target or a node containing the target
	-- (we will stop even if the node is not directly reached - this is used to run a specific line containing a node,
	-- notably for Definition of exported variables)
	-- TODO unused?
	push_no_continue = function(self, state, target)
		assert(ResumeTarget:issub(target), "can only resume to a resume target")
		state.scope:push_partial(resume_target_identifier, resume_no_continue_identifier, resume_environment_identifier)
		state.scope:define(resume_target_symbol, target)
		state.scope:define(resume_no_continue_symbol, Boolean:new(true))
		state.scope:define(resume_environment_symbol, state.scope:capture())
	end,
	-- pop the current resume context
	pop = function(self, state)
		state.scope:pop()
	end,

	-- returns true if we are currently trying to resume to a target
	resuming = function(self, state)
		return state.scope:defined(resume_target_identifier) and not Nil:is(state.scope:get(resume_target_identifier))
	end,
	-- returns the target we are trying to resume to
	-- (assumes that we are currently :resuming)
	get = function(self, state)
		return state.scope:get(resume_target_identifier)
	end,
	-- mark the target as reached and stop the resume
	-- (assumes that we are currently :resuming)
	set_reached = function(self, state)
		state.scope:set(resume_target_identifier, Nil:new())
	end,
	-- indicate if the evaluation should stop after reaching a node containing the target
	-- (assumes that we are currently :resuming)
	no_continue = function(self, state)
		return state.scope:get(resume_no_continue_identifier):to_lua(state)
	end,
	-- returns the environment that was on top of the stack when the resume started
	-- (assumes that we are currently :resuming)
	resuming_environment = function(self, state)
		return state.scope:get(resume_environment_identifier)
	end
}

package.loaded[...] = resume_manager

Nil, Identifier, ResumeTarget, Boolean = ast.Nil, ast.Identifier, ast.abstract.ResumeTarget, ast.Boolean

resume_target_identifier = Identifier:new("_resume_target")
resume_target_symbol = resume_target_identifier:to_symbol()

resume_environment_identifier = Identifier:new("_resume_environment")
resume_environment_symbol = resume_environment_identifier:to_symbol()

resume_no_continue_identifier = Identifier:new("_resume_no_continue")
resume_no_continue_symbol = resume_no_continue_identifier:to_symbol()

return resume_manager
