local string = require("anselme.parser.expression.primary.string")

local ast = require("anselme.ast")
local TextInterpolation, Translatable = ast.TextInterpolation, ast.Translatable

return string {
	type = "text",
	start_pattern = "|[ \t]?",
	stop_char = "|",
	allow_implicit_stop = true,
	interpolation = TextInterpolation,

	parse = function(self, source, str, limit_pattern)
		local start_source = source:clone()
		local interpolation, rem = string.parse(self, source, str, limit_pattern)

		-- remove terminal space
		local last = interpolation.list[#interpolation.list]
		if ast.String:is(last) then last.string = last.string:gsub("[ \t]$", "") end

		return Translatable:new(interpolation):set_source(start_source), rem
	end
}
