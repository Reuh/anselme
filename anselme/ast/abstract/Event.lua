-- for nodes that can be written to the event buffer

local ast = require("anselme.ast")

return ast.abstract.Node {
	type = "event",
	init = false,

	-- returns value that will be yielded by the whole event buffer data on flush
	build_event_data = function(self, state, event_buffer)
		error("build_event_data not implemented for "..self.type)
	end,

	-- post_flush_callback(self, state, event_buffer, event_data)
	post_flush_callback = false
}
