local string = require("parser.expression.primary.string")

local ast = require("ast")
local TextInterpolation, Translatable = ast.TextInterpolation, ast.Translatable

return string {
	type = "text",
	start_pattern = "|%s?",
	stop_char = "|",
	allow_implicit_stop = true,
	interpolation = TextInterpolation,

	parse = function(self, source, str, limit_pattern)
		local start_source = source:clone()
		local interpolation, rem = string.parse(self, source, str, limit_pattern)

		-- restore | when chaining with a choice operator
		if rem:match("^>") then
			rem = "|" .. rem
			source:increment(-1)
		end

		return Translatable:new(interpolation):set_source(start_source), rem
	end
}