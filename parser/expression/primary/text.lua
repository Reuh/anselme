local string = require("parser.expression.primary.string")

local ast = require("ast")
local TextInterpolation = ast.TextInterpolation

return string {
	type = "text",
	start_pattern = "|%s?",
	stop_char = "|",
	allow_implicit_stop = true,
	interpolation = TextInterpolation,

	parse = function(self, source, str, limit_pattern)
		local interpolation, rem = string.parse(self, source, str, limit_pattern)

		-- restore | when chaining with a choice operator
		if rem:match("^>") then
			rem = "|" .. rem
			source:increment(-1)
		end

		return interpolation, rem
	end
}
