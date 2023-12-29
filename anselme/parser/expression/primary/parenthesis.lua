-- either parentheses or nil ()

local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local Nil = ast.Nil

local expression_to_ast = require("anselme.parser.expression.to_ast")

return primary {
	match = function(self, str)
		return str:match("^%(")
	end,
	parse = function(self, source, str)
		local start_source = source:clone()
		local rem = source:consume(str:match("^(%()(.*)$"))

		local exp
		if rem:match("^%s*%)") then
			exp = Nil:new()
		else
			local s
			s, exp, rem = pcall(expression_to_ast, source, rem, "%)")
			if not s then error("invalid expression inside parentheses: "..exp, 0) end
			if not rem:match("^%s*%)") then error(("unexpected %q at end of parenthesis"):format(rem), 0) end
		end
		rem = source:consume(rem:match("^(%s*%))(.*)$"))

		return exp:set_source(start_source), rem
	end
}
