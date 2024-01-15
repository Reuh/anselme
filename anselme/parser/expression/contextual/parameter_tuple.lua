local primary = require("anselme.parser.expression.primary.primary")
local function_parameter = require("anselme.parser.expression.contextual.function_parameter")
local function_parameter_no_default = require("anselme.parser.expression.contextual.function_parameter_no_default")

local ast = require("anselme.ast")
local ParameterTuple = ast.ParameterTuple

return primary {
	match = function(self, str)
		return str:match("^%(")
	end,
	parse = function(self, source, options, str)
		local source_start = source:clone()
		local parameters = ParameterTuple:new()
		local rem = source:consume(str:match("^(%()(.*)$"))
		rem = source:consume_leading_whitespace(options, rem)

		-- i would LOVE to reuse the regular list parsing code for this, but unfortunately the list parsing code
		-- itself depends on this and expect this to be available quite early, and it's ANNOYING
		while not rem:match("^%)") do
			-- parameter
			local func_param
			func_param, rem = function_parameter:expect(source, options, rem)
			rem = source:consume_leading_whitespace(options, rem)

			-- next! comma separator
			if not rem:match("^%)") then
				if not rem:match("^,") then
					error(("unexpected %q at end of argument list"):format(rem:match("^[^\n]*")), 0)
				end
				rem = source:consume(rem:match("^(,)(.*)$"))
				rem = source:consume_leading_whitespace(options, rem)
			end

			-- add
			parameters:insert(func_param)
		end
		rem = rem:match("^%)(.*)$")
		rem = source:consume_leading_whitespace(options, rem)

		-- assigment param
		if rem:match("^=") then
			rem = source:consume(rem:match("^(=)(.*)$"))
			rem = source:consume_leading_whitespace(options, rem)

			local func_param
			func_param, rem = function_parameter_no_default:expect(source, options, rem)

			parameters:insert_assignment(func_param)
		end

		return parameters:set_source(source_start), rem
	end
}
