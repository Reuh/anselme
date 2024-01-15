local secondary = require("anselme.parser.expression.secondary.secondary")
local escape = require("anselme.common").escape
local expression_to_ast = require("anselme.parser.expression.to_ast")

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

return secondary {
	operator = nil,
	identifier = nil,
	priority = nil,

	-- return bool
	match = function(self, str, current_priority, primary)
		local escaped = escape(self.operator)
		return self.priority > current_priority and str:match("^"..escaped)
	end,

	-- return AST, rem
	parse = function(self, source, str, limit_pattern, current_priority, primary)
		local start_source = source:clone()
		local escaped = escape(self.operator)

		local sright = source:consume(str:match("^("..escaped..")(.*)$"))
		local s, right, rem = pcall(expression_to_ast, source, sright, limit_pattern, self.priority)
		if not s then error(("invalid expression after infix operator %q: %s"):format(self.operator, right), 0) end

		return self:build_ast(primary, right):set_source(start_source), rem
	end,

	build_ast = function(self, left, right)
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(left, right))
	end
}
