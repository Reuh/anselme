local infix = require("anselme.parser.expression.secondary.infix.infix")
local escape = require("anselme.common").escape
local expression_to_ast = require("anselme.parser.expression.to_ast")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Tuple = ast.Tuple

return infix {
	operator = ",",
	identifier = "_,_",
	priority = operator_priority["_,_"],

	-- reminder: this :parse method is also called from primary.list as an helper to build list bracket litterals
	parse = function(self, source, options, str, current_priority, primary)
		local start_source = source:clone()
		local l = Tuple:new()
		l:insert(primary)

		local escaped = escape(self.operator)
		local rem = str
		while rem:match("^"..escaped) do
			rem = source:consume(rem:match("^("..escaped..")(.*)$"))

			local s, right
			s, right, rem = pcall(expression_to_ast, source, options, rem, self.priority)
			if not s then error(("invalid expression after binop %q: %s"):format(self.operator, right), 0) end
			rem = source:consume_leading_whitespace(options, rem)

			l:insert(right)
		end

		l.explicit = false
		return l:set_source(start_source), rem
	end
}
