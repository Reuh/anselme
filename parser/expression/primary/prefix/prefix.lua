-- unary prefix operators, for example: the - in -5

local primary = require("parser.expression.primary.primary")
local escape = require("common").escape
local expression_to_ast = require("parser.expression.to_ast")

local ast = require("ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

return primary {
	operator = nil,
	identifier = nil,
	priority = nil,

	match = function(self, str)
		local escaped = escape(self.operator)
		return str:match("^"..escaped)
	end,

	parse = function(self, source, str, limit_pattern)
		local source_start = source:clone()
		local escaped = escape(self.operator)

		local sright = source:consume(str:match("^("..escaped..")(.*)$"))
		local s, right, rem = pcall(expression_to_ast, source, sright, limit_pattern, self.priority)
		if not s then error(("invalid expression after prefix operator %q: %s"):format(self.operator, right), 0) end

		return self:build_ast(right):set_source(source_start), rem
	end,

	build_ast = function(self, right)
		return Call:new(Identifier:new(self.identifier), ArgumentTuple:new(right))
	end
}
