local ast = require("anselme.ast")
local TextInterpolation, String

local operator_priority = require("anselme.common").operator_priority

local translation_manager

local Translatable = ast.abstract.Node {
	type = "translatable",
	hide_in_stacktrace = true,

	expression = nil,

	init = function(self, expression)
		self.expression = expression
		self.context = ast.Struct:new()
		self.context:set(String:new("source"), String:new(self.expression.source))
	end,

	_format = function(self, ...)
		if TextInterpolation:is(self.expression) then -- wrapped in translatable by default
			return self.expression:format(...)
		else
			return "%"..self.expression:format_right(...)
		end
	end,
	_format_priority = function(self)
		if TextInterpolation:is(self.expression) then
			return self.expression:format_priority()
		else
			return operator_priority["%_"]
		end
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
	end,

	_eval = function(self, state)
		return translation_manager:eval(state, self.context, self)
	end,

	list_translatable = function(self, t)
		table.insert(t, self)
	end
}

package.loaded[...] = Translatable
TextInterpolation, String = ast.TextInterpolation, ast.String

translation_manager = require("anselme.state.translation_manager")

return Translatable
