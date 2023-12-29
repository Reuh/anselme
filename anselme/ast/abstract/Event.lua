-- for nodes that can be written to the event buffer

local ast = require("anselme.ast")

return ast.abstract.Node {
	type = "event",
	init = false,

	-- returns value that will be yielded by the whole event buffer data on flush
	-- by default a list of what is returned by :to_event_data for each event of the buffer
	build_event_data = function(self, state, event_buffer)
		local l = {}
		for _, event in event_buffer:iter(state) do
			table.insert(l, event:to_event_data(state))
		end
		return l
	end,
	to_event_data = function(self, state) error("unimplemented") end,

	-- post_flush_callback(self, state, event_buffer, event_data)
	post_flush_callback = false
}
