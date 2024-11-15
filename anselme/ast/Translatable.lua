local ast = require("anselme.ast")
local TextInterpolation, String, Struct

local operator_priority = require("anselme.common").operator_priority

local translation_manager

local Translatable = ast.abstract.Node {
	type = "translatable",
	hide_in_stacktrace = true,

	expression = nil,
	context = nil, -- struct

	init = function(self, expression)
		self.expression = expression
		self.context = Struct:new()
		self.context:set(String:new("source"), String:new(self.expression.source))
		self.context:set(String:new("file"), String:new(self.expression.source:match("^([^%:]*)")))
		-- TODO: add parent script/function name to context - should be more stable than source position
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
	-- pass on eval_statement state to the translated node
	eval_statement = function(self, state)
		return translation_manager:eval(state, self.context, self):eval_statement(state)
	end,

	list_translatable = function(self, t)
		t = t or {}
		table.insert(t, self)
		return t
	end
}

package.loaded[...] = Translatable
TextInterpolation, String, Struct = ast.TextInterpolation, ast.String, ast.Struct

translation_manager = require("anselme.state.translation_manager")

return Translatable
