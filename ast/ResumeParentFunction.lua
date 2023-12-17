-- intended to be wrapped in a Function, so that when resuming from the function, will keep resuming to where the function was called from
-- used in Choices to resume back from where the event was flushed
-- note: when resuming, the return value will be discarded, instead returning what the parent function will return

local ast = require("ast")
local ArgumentTuple

local resumable_manager

local ResumeParentFunction = ast.abstract.Node {
	type = "resume parent function",

	expression = nil,

	init = function(self, expression)
		self.expression = expression
		self.format_priority = expression.format_priority
	end,

	_format = function(self, ...)
		return self.expression:format(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		if resumable_manager:resuming(state, self) then
			self.expression:eval(state)
			return resumable_manager:get_data(state, self):call(state, ArgumentTuple:new())
		else
			resumable_manager:set_data(state, self, resumable_manager:capture(state, 1))
			return self.expression:eval(state)
		end
	end
}

package.loaded[...] = ResumeParentFunction
ArgumentTuple = ast.ArgumentTuple

resumable_manager = require("state.resumable_manager")

return ResumeParentFunction
