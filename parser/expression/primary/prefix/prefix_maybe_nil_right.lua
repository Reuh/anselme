local prefix = require("parser.expression.primary.prefix.prefix")
local escape = require("common").escape
local expression_to_ast = require("parser.expression.to_ast")

local ast = require("ast")
local Nil = ast.Nil

return prefix {
	parse = function(self, source, str, limit_pattern)
		local source_start = source:clone()
		local escaped = escape(self.operator)

		local sright = source:consume(str:match("^("..escaped..")(.*)$"))
		local s, right, rem = pcall(expression_to_ast, source, sright, limit_pattern, self.priority)
		if not s then
			return self:build_ast(Nil:new()):set_source(source_start), sright
		else
			return self:build_ast(right):set_source(source_start), rem
		end
	end,
}
