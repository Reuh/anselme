-- same as infix, but skip if no valid expression or end-of-line after the operator instead of erroring
-- useful for operators that are both valid as infix and as suffix

local infix = require("anselme.parser.expression.secondary.infix.infix")
local escape = require("anselme.common").escape
local expression_to_ast = require("anselme.parser.expression.to_ast")

local ast = require("anselme.ast")
local Call = ast.Call

return infix {
	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, options, str, current_priority, operating_on_primary)
		if not self:match(str, current_priority, operating_on_primary) then
			return nil
		end
		return self:maybe_parse(source, options, str, current_priority, operating_on_primary)
	end,

	parse = function() error("no guaranteed parse for this operator") end,

	-- return AST, rem
	-- return nil
	maybe_parse = function(self, source, options, str, current_priority, primary)
		local start_source = source:clone()
		local escaped = escape(self.operator)

		local sright = source:consume(str:match("^("..escaped..")(.*)$"))
		local s, right, rem = pcall(expression_to_ast, source, options, sright, self.priority)
		if not s then return nil end

		if Call:is(right) and right:is_implicit_block_identifier() then return nil end -- skip if end-of-line, ignoring implicit _

		return self:build_ast(primary, right):set_source(start_source), rem
	end,
}
