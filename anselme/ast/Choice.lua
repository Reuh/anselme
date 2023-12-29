local ast = require("anselme.ast")
local ArgumentTuple

local operator_priority = require("anselme.common").operator_priority

local Choice
Choice = ast.abstract.Runtime {
	type = "choice",

	text = nil,
	func = nil,
	format_priority = operator_priority["_|>_"],

	init = function(self, text, func)
		self.text = text
		self.func = func
	end,

	traverse = function(self, fn, ...)
		fn(self.text, ...)
		fn(self.func, ...)
	end,

	_format = function(self, ...)
		return ("%s |> %s"):format(self.text:format(...), self.func:format_right(...))
	end,

	build_event_data = function(self, state, event_buffer)
		local l = {
			_selected = nil,
			choose = function(self, choice)
				self._selected = choice
			end
		}
		for _, c in event_buffer:iter(state) do
			table.insert(l, c.text)
		end
		return l
	end,
	post_flush_callback = function(self, state, event_buffer, data)
		local choice = data._selected
		assert(choice, "no choice made")
		assert(choice > 0 and choice <= event_buffer:len(state), "choice out of bounds")

		event_buffer:get(state, choice).func:call(state, ArgumentTuple:new())
	end
}

package.loaded[...] = Choice
ArgumentTuple = ast.ArgumentTuple

return Choice
