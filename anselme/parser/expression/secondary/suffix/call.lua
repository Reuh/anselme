-- index/call

local secondary = require("anselme.parser.expression.secondary.secondary")
local parenthesis = require("anselme.parser.expression.primary.parenthesis")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Call, ArgumentTuple, Tuple, Assignment, Nil = ast.Call, ast.ArgumentTuple, ast.Tuple, ast.Assignment, ast.Nil

return secondary {
	priority = operator_priority["_()"],

	match = function(self, str, current_priority, primary)
		return self.priority > current_priority and parenthesis:match(str)
	end,

	parse = function(self, source, str, limit_pattern, current_priority, primary)
		local start_source = source:clone()
		local args = ArgumentTuple:new()

		local exp, rem = parenthesis:parse(source, str, limit_pattern)

		if Nil:is(exp) then
			exp = Tuple:new()
		elseif not Tuple:is(exp) or exp.explicit then -- single argument
			exp = Tuple:new(exp)
		end

		for _, v in ipairs(exp.list) do
			if Assignment:is(v) then
				args:add_named(v.identifier, v.expression)
			else
				args:add_positional(v)
			end
		end

		return Call:new(primary, args):set_source(start_source), rem
	end
}