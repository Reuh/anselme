local class = require("class")

local ast = require("ast")
local Nil, Identifier, Anchor

-- stack of resumable contexts
local resume_anchor_identifier, resume_anchor_symbol

local resume_manager = class {
	init = false,

	-- push a new resume context: all run code between this and the next push will try to resume to anchor
	push = function(self, state, anchor)
		assert(Anchor:is(anchor), "can only resume to an anchor target") -- well technically it wouldn't be hard to allow to resume to any node, but I feel like there's already enough stuff in Anselme that was done just because it could be done
		state.scope:push_partial(resume_anchor_identifier)
		state.scope:define(resume_anchor_symbol, anchor)
	end,
	-- pop the current resume context
	pop = function(self, state)
		state.scope:pop()
	end,

	-- returns true if we are currently trying to resume to an anchor
	resuming = function(self, state)
		return state.scope:defined(resume_anchor_identifier) and not Nil:is(state.scope:get(resume_anchor_identifier))
	end,
	-- returns the anchor we are trying to resume to
	get = function(self, state)
		return state.scope:get(resume_anchor_identifier)
	end,
	-- mark the anchor as reached and stop the resume
	set_reached = function(self, state)
		state.scope:set(resume_anchor_identifier, Nil:new())
	end,
}

package.loaded[...] = resume_manager

Nil, Identifier, Anchor = ast.Nil, ast.Identifier, ast.Anchor

resume_anchor_identifier = Identifier:new("_resume_anchor")
resume_anchor_symbol = resume_anchor_identifier:to_symbol()

return resume_manager
