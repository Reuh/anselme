local ast = require("ast")
local Identifier, Quote

local attached_block_identifier, attached_block_symbol

local AttachBlock = ast.abstract.Node {
	type = "attach block",

	expression = nil,
	block = nil,

	init = function(self, expression, block)
		self.expression = expression
		self.block = block
		self.format_priority = self.expression.format_priority
	end,

	_format = function(self, state, priority, indentation, ...)
		return self.expression:format(state, priority, indentation, ...).."\n\t"..self.block:format(state, priority, indentation + 1, ...)
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
		fn(self.block, ...)
	end,

	_eval = function(self, state)
		state.scope:push_partial(attached_block_identifier)
		state.scope:define(attached_block_symbol, Quote:new(self.block)) -- _ is always wrapped in a Call when it appears
		local exp = self.expression:eval(state)
		state.scope:pop()

		return exp
	end,

	_prepare = function(self, state)
		state.scope:push_partial(attached_block_identifier)
		state.scope:define(attached_block_symbol, Quote:new(self.block))
		self.expression:prepare(state)
		state.scope:pop()
	end
}

package.loaded[...] = AttachBlock
Identifier, Quote = ast.Identifier, ast.Quote

attached_block_identifier = Identifier:new("_")
attached_block_symbol = attached_block_identifier:to_symbol()

return AttachBlock
