-- create a partial layer to define temporary variables

local ast = require("anselme.ast")
local Identifier, Quote, Nil

local attached_block_identifier, attached_block_symbol
local unpack = table.unpack or unpack

local PartialScope
PartialScope = ast.abstract.Node {
	type = "partial scope",

	expression = nil,
	definitions = nil, -- {[sym]=value,...}
	_identifiers = nil, -- {identifier,...} - just a cache so we don't rebuild it on every eval

	init = function(self, expression)
		self.expression = expression
		self.definitions = {}
		self._identifiers = {}
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
	_format_priority = function(self)
		return self.expression:format_priority()
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
		for sym, val in pairs(self.definitions) do
			fn(sym, ...)
			fn(val, ...)
		end
	end,

	_eval = function(self, state)
		state.scope:push_partial(unpack(self._identifiers))
		for sym, val in pairs(self.definitions) do state.scope:define(sym:eval(state), val:eval(state)) end
		local exp = self.expression:eval(state)
		state.scope:pop()

		return exp
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
		local partial = PartialScope:new(expression)
		local unpartial = PartialScope:new(block)
		unpartial:define(attached_block_symbol:with{undefine=true}, Nil:new())
		partial:define(attached_block_symbol, Quote:new(unpartial))
		return partial
	end
}

package.loaded[...] = PartialScope
Identifier, Quote, Nil = ast.Identifier, ast.Quote, ast.Nil

attached_block_identifier = Identifier:new("_")
attached_block_symbol = attached_block_identifier:to_symbol()

return PartialScope
