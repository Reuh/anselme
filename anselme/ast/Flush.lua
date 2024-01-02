local ast = require("anselme.ast")
local Nil

local event_manager = require("anselme.state.event_manager")

local Flush = ast.abstract.Node {
	type = "flush",

	init = function(self) end,

	_format = function(self)
		return "\n"
	end,

	_eval = function(self, state)
		event_manager:flush(state)
		return Nil:new()
	end
}

package.loaded[...] = Flush
Nil = ast.Nil

return Flush
