-- index/call

local secondary = require("anselme.parser.expression.secondary.secondary")
local parenthesis = require("anselme.parser.expression.primary.parenthesis")
local tuple = require("anselme.parser.expression.primary.tuple")
local struct = require("anselme.parser.expression.primary.struct")

local operator_priority = require("anselme.common").operator_priority

local ast = require("anselme.ast")
local Call, ArgumentTuple, Tuple, Nil = ast.Call, ast.ArgumentTuple, ast.Tuple, ast.Nil

return secondary {
	priority = operator_priority["_()"],

	match = function(self, str, current_priority, primary)
		return self.priority > current_priority and (parenthesis:match(str) or tuple:match(str) or struct:match(str))
	end,

	parse = function(self, source, options, str, current_priority, primary)
		local start_source = source:clone()
		local args = ArgumentTuple:new()

		local exp, rem

		if parenthesis:match(str) then
			exp, rem = parenthesis:parse(source, options, str)

			if Nil:is(exp) then
				if str:match("^%([ \t\n]*%([ \t\n]*%)[ \t\n]*%)") then -- special case: single nil argument
					exp = Tuple:new(Nil:new())
				else -- no arguments
					exp = Tuple:new()
				end
			elseif not Tuple:is(exp) or exp.explicit then -- single argument
				exp = Tuple:new(exp)
			end
		elseif tuple:match(str) then
			exp, rem = tuple:parse(source, options, str)
			exp = Tuple:new(exp)
		else
			exp, rem = struct:parse(source, options, str)
			exp = Tuple:new(exp)
		end

		for _, v in ipairs(exp.list) do
			if Call:is(v) and v:is_simple_assignment() then
				local pos = v.arguments.positional
				args:add_named(pos[1].expression.name, pos[2])
			else
				args:add_positional(v)
			end
		end

		return Call:new(primary, args):set_source(start_source), rem
	end
}
