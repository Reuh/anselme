local function_parameter = require("anselme.parser.expression.contextual.function_parameter")

return function_parameter {
	parse = function(self, source, options, str)
		return function_parameter:parse(source, options, str, true)
	end
}
