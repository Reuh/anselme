local primary = require("parser.expression.primary.primary")

local ast = require("ast")
local Tuple = ast.Tuple

local expression_to_ast = require("parser.expression.to_ast")

local escape = require("common").escape

return primary {
	match = function(self, str)
		return str:match("^%[")
	end,

	parse = function(self, source, str)
		return self:parse_tuple(source, str, "[", "]")
	end,

	parse_tuple = function(self, source, str, start_char, end_char)
		local start_source = source:clone()
		local rem = source:consume(str:match("^("..escape(start_char)..")(.*)$"))
		local end_match = escape(end_char)

		local l
		if not rem:match("^%s*"..end_match) then
			local s
			s, l, rem = pcall(expression_to_ast, source, rem, end_match)
			if not s then error("invalid expression in list: "..l, 0) end
		end

		if not Tuple:is(l) or l.explicit then l = Tuple:new(l) end -- single or no element

		if not rem:match("^%s*"..end_match) then
			error(("unexpected %q at end of list"):format(rem), 0)
		end
		rem = source:consume(rem:match("^(%s*"..end_match..")(.*)$"))

		l.explicit = true
		return l:set_source(start_source), rem
	end,
}
