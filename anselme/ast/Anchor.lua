local ast = require("anselme.ast")

local resume_manager

local Anchor
Anchor = ast.abstract.Node {
	type = "anchor",

	name = nil,

	init = function(self, name)
		self.name = name
		self._list_anchors_cache = { [name] = true }
	end,

	_hash = function(self)
		return ("anchor<%q>"):format(self.name)
	end,

	_format = function(self, ...)
		return "#"..self.name
	end,

	_eval = function(self, state)
		if self:contains_resume_target(state) then
			resume_manager:set_reached(state)
		end
		return Anchor:new(self.name)
	end
}

package.loaded[...] = Anchor
resume_manager = require("anselme.state.resume_manager")

return Anchor
