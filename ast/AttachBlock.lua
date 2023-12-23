local ast = require("ast")
local Identifier, Quote

local attached_block_identifier, attached_block_symbol

local AttachBlock
AttachBlock = ast.abstract.Node {
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
	end,

	-- class method: if the block identifier is defined in the current scope, wrap node in an AttachBlock so the block is still defined in this node
	-- used to preserve the defined _ block without the need to build a full closure
	-- used e.g. for -> translation, as we want to preserve _ while still executing the translation in the Translatable scope and not restore a different scope from a closure
	-- (operates on un-evaluated nodes!)
	preserve = function(self, state, node)
		if state.scope:defined_in_current(attached_block_symbol) then
			return AttachBlock:new(node, state.scope:get(attached_block_identifier).expression) -- unwrap Quote as that will be rewrap on eval
		end
		return node
	end,
}

package.loaded[...] = AttachBlock
Identifier, Quote = ast.Identifier, ast.Quote

attached_block_identifier = Identifier:new("_")
attached_block_symbol = attached_block_identifier:to_symbol()

return AttachBlock
