local function_parameter = require("parser.expression.contextual.function_parameter")

return function_parameter {
	parse = function(self, source, str, limit_pattern)
		return function_parameter:parse(source, str, limit_pattern, true)
	end
}
