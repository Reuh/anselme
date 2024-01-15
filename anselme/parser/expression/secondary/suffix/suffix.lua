-- unary suffix operators, for example the ! in func!

local secondary = require("anselme.parser.expression.secondary.secondary")
local escape = require("anselme.common").escape

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

return secondary {
	operator = nil,
	identifier = nil,
	priority = nil,

	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped)
	end,

	parse = function(self, source, options, str, current_priority, primary)
		local start_source = source:clone()
		local escaped = escape(self.operator)

		local rem = source:consume(str:match("^("..escaped..")(.*)$"))

		return self:build_ast(primary):set_source(start_source), rem
	end,

	build_ast = function(self, left)
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(left))
	end
}
