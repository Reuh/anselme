local ast = require("ast")
local TextInterpolation, String

local operator_priority = require("common").operator_priority

local translation_manager

local Translatable = ast.abstract.Node {
	type = "translatable",
	format_priority = operator_priority["%_"],

	expression = nil,

	init = function(self, expression)
		self.expression = expression
		self.context = ast.Struct:new()
		self.context:set(String:new("source"), String:new(self.expression.source))
		if TextInterpolation:is(self.expression) then
			self.format_priority = expression.format_priority
		end
	end,

	_format = function(self, ...)
		if TextInterpolation:is(self.expression) then -- wrapped in translatable by default
			return self.expression:format(...)
		else
			return "%"..self.expression:format_right(...)
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

translation_manager = require("state.translation_manager")

return Translatable
