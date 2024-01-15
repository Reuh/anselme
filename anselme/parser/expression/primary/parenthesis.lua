-- either parentheses or nil ()

local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local Nil = ast.Nil

local expression_to_ast = require("anselme.parser.expression.to_ast")

return primary {
	match = function(self, str)
		return str:match("^%(")
	end,
	parse = function(self, source, options, str)
		local start_source = source:clone()
		local opts = options:with{ limit_pattern = "%)", allow_newlines = true }

		local rem = source:consume(str:match("^(%()(.*)$"))
		rem = source:consume_leading_whitespace(opts, rem)

		local exp
		if rem:match("^%)") then
			exp = Nil:new()
		else
			local s
			s, exp, rem = pcall(expression_to_ast, source, opts, rem)
			if not s then error("invalid expression inside parentheses: "..exp, 0) end
			rem = source:consume_leading_whitespace(opts, rem)
			if not rem:match("^%)") then error(("unexpected %q at end of parenthesis"):format(rem:match("^[^\n]*")), 0) end
		end
		rem = source:consume(rem:match("^(%))(.*)$"))

		return exp:set_source(start_source), rem
	end
}
