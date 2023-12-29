local primary = require("anselme.parser.expression.primary.primary")
local identifier = require("anselme.parser.expression.primary.identifier")
local expression_to_ast = require("anselme.parser.expression.to_ast")

local ast = require("anselme.ast")
local FunctionParameter = ast.FunctionParameter

local operator_priority = require("anselme.common").operator_priority
local assignment_priority = operator_priority["_=_"]
local type_check_priority = operator_priority["_::_"]

return primary {
	match = function(self, str)
		return identifier:match(str)
	end,
	parse = function(self, source, str, limit_pattern, no_default_value)
		local source_param = source:clone()

		-- name
		local ident, rem = identifier:parse(source, str)

		-- type check
		local type_check
		if rem:match("^%s*::") then
			local scheck = source:consume(rem:match("^(%s*::%s*)(.*)$"))
			type_check, rem = expression_to_ast(source, scheck, limit_pattern, type_check_priority)
		end

		-- default value
		local default
		if not no_default_value then
			if rem:match("^%s*=") then
				local sdefault = source:consume(rem:match("^(%s*=%s*)(.*)$"))
				default, rem = expression_to_ast(source, sdefault, limit_pattern, assignment_priority)
			end
		end

		return FunctionParameter:new(ident, default, type_check):set_source(source_param), rem
	end
}
