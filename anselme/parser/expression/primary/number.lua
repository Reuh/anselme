local primary = require("anselme.parser.expression.primary.primary")

local Number = require("anselme.ast.Number")

return primary {
	match = function(self, str)
		return str:match("^%d*%.%d+") or str:match("^%d+")
	end,
	parse = function(self, source, options, str)
		local start_source = source:clone()
		local d, r = str:match("^(%d*%.%d+)(.*)$")
		if not d then
			d, r = source:count(str:match("^(%d+)(.*)$"))
		else
			source:count(d)
		end
		return Number:new(tonumber(d)):set_source(start_source), r
	end
}
