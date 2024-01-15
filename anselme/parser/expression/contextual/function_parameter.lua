local primary = require("anselme.parser.expression.primary.primary")
local identifier = require("anselme.parser.expression.primary.identifier")
local expression_to_ast = require("anselme.parser.expression.to_ast")

local ast = require("anselme.ast")
local FunctionParameter = ast.FunctionParameter

local operator_priority = require("anselme.common").operator_priority
local assignment_priority = operator_priority["_=_"]
local value_check_priority = operator_priority["_::_"]

return primary {
	match = function(self, str)
		return identifier:match(str)
	end,
	parse = function(self, source, options, str, no_default_value)
		local source_param = source:clone()

		-- name
		local ident, rem = identifier:parse(source, options, str)
		rem = source:consume_leading_whitespace(options, rem)

		-- value check
		local value_check
		if rem:match("^::") then
			local scheck = source:consume(rem:match("^(::)(.*)$"))
			value_check, rem = expression_to_ast(source, options, scheck, value_check_priority)
		end

		-- default value
		local default
		if not no_default_value then
			if rem:match("^=") then
				local sdefault = source:consume(rem:match("^(=)(.*)$"))
				default, rem = expression_to_ast(source, options, sdefault, assignment_priority)
			end
		end

		return FunctionParameter:new(ident, default, value_check):set_source(source_param), rem
	end
}
