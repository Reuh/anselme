-- index/call

local secondary = require("parser.expression.secondary.secondary")
local parenthesis = require("parser.expression.primary.parenthesis")

local operator_priority = require("common").operator_priority

local ast = require("ast")
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

		for i, v in ipairs(exp.list) do
			if Assignment:is(v) then
				args:set_named(v.identifier, v.expression)
			else
				args:set_positional(i, v)
			end
		end

		return Call:new(primary, args):set_source(start_source), rem
	end
}
