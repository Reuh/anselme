-- create a partial layer to define temporary variables

local ast = require("ast")
local Identifier, Quote

local attached_block_identifier, attached_block_symbol

local PartialScope
PartialScope = ast.abstract.Node {
	type = "partial scope",

	expression = nil,
	definitions = nil, -- {[sym]=value,...} where values are already evaluated!
	_identifiers = nil, -- {identifier,...} - just a cache so we don't rebuild it on every eval

	init = function(self, expression)
		self.expression = expression
		self.definitions = {}
		self._identifiers = {}
		self.format_priority = self.expression.format_priority
	end,
	define = function(self, symbol, value) -- for construction only
		assert(not self.definitions[symbol], ("%s already defined in partial layer"):format(symbol))
		table.insert(self._identifiers, symbol:to_identifier())
		self.definitions[symbol] = value
	end,

	_format = function(self, state, priority, indentation, ...)
		if self.definitions[attached_block_symbol] then
			local block = self.definitions[attached_block_symbol]
			local exp = self.expression:format(state, priority, indentation, ...)
			if exp:sub(-2) == " _" then exp = exp:sub(1, -3) end
			return exp.."\n\t"..block:format(state, priority, indentation + 1, ...)
		else
			return self.expression:format(state, priority, indentation, ...)
		end
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
		for sym, val in pairs(self.definitions) do
			fn(sym, ...)
			fn(val, ...)
		end
	end,

	_eval = function(self, state)
		state.scope:push_partial(table.unpack(self._identifiers))
		for sym, val in pairs(self.definitions) do state.scope:define(sym, val) end
		local exp = self.expression:eval(state)
		state.scope:pop()

		return exp
	end,

	_prepare = function(self, state)
		state.scope:push_partial(table.unpack(self._identifiers))
		for sym, val in pairs(self.definitions) do state.scope:define(sym, val) end
		self.expression:prepare(state)
		state.scope:pop()
	end,

	-- class method: if the identifier is currently defined, wrap node in an PartialScope so the identifier is still defined in this node
	-- used to e.g. preserve the defined _ block without the need to build a full closure
	-- used e.g. for -> translation, as we want to preserve _ while still executing the translation in the Translatable scope and not restore a different scope from a closure
	-- (operates on un-evaluated nodes!)
	preserve = function(self, state, expression, ...)
		local partial = PartialScope:new(expression)
		for _, ident in ipairs{...} do
			if state.scope:defined(ident) then
				partial:define(state.scope:get_symbol(ident), state.scope:get(ident))
			end
		end
		return partial
	end,
	-- class method: return a PartialScope that define the block identifier _ to a Quote of `block`
	attach_block = function(self, expression, block)
		local partial = ast.PartialScope:new(expression)
		partial:define(attached_block_symbol, Quote:new(block))
		return partial
	end
}

package.loaded[...] = PartialScope
Identifier, Quote = ast.Identifier, ast.Quote

attached_block_identifier = Identifier:new("_")
attached_block_symbol = attached_block_identifier:to_symbol()

return PartialScope
