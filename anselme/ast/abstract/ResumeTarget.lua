-- nodes that can be resumed to

local ast = require("anselme.ast")
local Node = ast.abstract.Node

local resume_manager

local ResumeTarget = Node {
	type = "resume target",
	init = false,

	_list_resume_targets = function(self)
		self._list_resume_targets_cache[self:hash()] = self
	end,

	eval = function(self, state)
		if self:contains_current_resume_target(state) then
			resume_manager:set_reached(state)
		end
		return Node.eval(self, state)
	end
}

package.loaded[...] = ResumeTarget
resume_manager = require("anselme.state.resume_manager")

return ResumeTarget
