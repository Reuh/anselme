local infix = require("anselme.parser.expression.secondary.infix.infix")
local identifier = require("anselme.parser.expression.primary.identifier")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Call, Identifier, ArgumentTuple = ast.Call, ast.Identifier, ast.ArgumentTuple

return infix {
	operator = "*",
	identifier = "_*_",
	priority = operator_priority["_implicit*_"],

	match = function(self, str, current_priority, primary)
		return self.priority > current_priority and identifier:match(str)
	end,

	parse = function(self, source, options, str, current_priority, primary)
		local start_source = source:clone()
		local right, rem = identifier:parse(source, options, str)
		local r = Call:new(Identifier:new(self.identifier), ArgumentTuple:new(primary, right)):set_source(start_source)
		r.explicit = false
		return r, rem
	end
}
