local prefix = require("anselme.parser.expression.primary.prefix.prefix")
local parameter_tuple = require("anselme.parser.expression.contextual.parameter_tuple")
local escape = require("anselme.common").escape
local expression_to_ast = require("anselme.parser.expression.to_ast")

local ast = require("anselme.ast")
local Function, ParameterTuple = ast.Function, ast.ParameterTuple

local operator_priority = require("anselme.common").operator_priority

return prefix {
	operator = "$",
	priority = operator_priority["$_"],

	parse = function(self, source, options, str)
		local source_start = source:clone()
		local escaped = escape(self.operator)
		local rem = source:consume(str:match("^("..escaped..")(.*)$"))

		-- parse eventual parameters
		local parameters
		if parameter_tuple:match(rem) then
			parameters, rem = parameter_tuple:parse(source, options, rem)
		else
			parameters = ParameterTuple:new()
		end

		-- parse expression
		local s, right
		s, right, rem = pcall(expression_to_ast, source, options, rem, self.priority)
		if not s then error(("invalid expression after unop %q: %s"):format(self.operator, right), 0) end

		return Function:with_return_boundary(parameters, right):set_source(source_start), rem
	end
}
