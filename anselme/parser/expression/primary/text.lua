local string = require("anselme.parser.expression.primary.string")

local ast = require("anselme.ast")
local TextInterpolation, Translatable, String = ast.TextInterpolation, ast.Translatable, ast.String

return string {
	type = "text",
	start_pattern = "|[ \t]?",
	stop_char = "|",
	allow_implicit_stop = true,
	interpolation = TextInterpolation,

	parse = function(self, source, options, str)
		local start_source = source:clone()
		local interpolation, rem = string.parse(self, source, options, str)

		-- remove final space
		local last = interpolation.list[#interpolation.list]
		if String:is(last) then last.string = last.string:gsub("[ \t]$", "") end

		return Translatable:new(interpolation):set_source(start_source), rem
	end
}
