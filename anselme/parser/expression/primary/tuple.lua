local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local Tuple = ast.Tuple

local expression_to_ast = require("anselme.parser.expression.to_ast")

local escape = require("anselme.common").escape

return primary {
	match = function(self, str)
		return str:match("^%[")
	end,

	parse = function(self, source, options, str)
		return self:parse_tuple(source, options, str, "[", "]")
	end,

	parse_tuple = function(self, source, options, str, start_char, end_char)
		local start_source = source:clone()
		local opts = options:with{ limit_pattern = end_char, allow_newlines = true }

		local rem = source:consume(str:match("^("..escape(start_char)..")(.*)$"))
		rem = source:consume_leading_whitespace(opts, rem)
		local end_match = escape(end_char)

		local l
		if not rem:match("^"..end_match) then
			local s
			s, l, rem = pcall(expression_to_ast, source, opts, rem)
			if not s then error("invalid expression in list: "..l, 0) end
			rem = source:consume_leading_whitespace(opts, rem)
		end

		if not Tuple:is(l) or l.explicit then l = Tuple:new(l) end -- single or no element

		if not rem:match("^"..end_match) then
			error(("unexpected %q at end of list"):format(rem:match("^[^\n]*")), 0)
		end
		rem = source:consume(rem:match("^("..end_match..")(.*)$"))

		l.explicit = true
		return l:set_source(start_source), rem
	end,
}
