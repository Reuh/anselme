local ast = require("anselme.ast")
local Identifier, String

local operator_priority = require("anselme.common").operator_priority

local Symbol
Symbol = ast.abstract.Node {
	type = "symbol",

	string = nil,
	constant = nil, -- bool
	alias = nil, -- bool
	exported = nil, -- bool
	value_check = nil, -- exp

	confined_to_branch = nil, -- bool

	init = function(self, str, modifiers)
		modifiers = modifiers or {}
		self.string = str
		self.constant = modifiers.constant
		self.value_check = modifiers.value_check
		self.alias = modifiers.alias
		self.confined_to_branch = modifiers.confined_to_branch
		self.exported = modifiers.exported
	end,
	with = function(self, modifiers)
		modifiers = modifiers or {}
		for _, k in ipairs{"constant", "value_check", "alias", "exported", "confined_to_branch"} do
			if modifiers[k] == nil then
				modifiers[k] = self[k]
			end
		end
		return Symbol:new(self.string, modifiers)
	end,

	traverse = function(self, fn, ...)
		if self.value_check then
			fn(self.value_check, ...)
		end
	end,

	_eval = function(self, state)
		return self:with {
			value_check = self.value_check and self.value_check:eval(state)
		}
	end,

	_hash = function(self)
		local prefix = ""
		if self.constant then
			prefix = prefix .. ":"
		end
		if self.alias then
			prefix = prefix .. "&"
		end
		if self.exported then
			prefix = prefix .. "@"
		end
		if self.value_check then
			return ("symbol<%s%q;%s>"):format(prefix, self.string, self.value_check:hash())
		else
			return ("symbol<%s%q>"):format(prefix, self.string)
		end
	end,

	_format = function(self, state, prio, ...)
		local s = ":"
		if self.constant then
			s = s .. ":"
		end
		if self.alias then
			s = s .. "&"
		end
		if self.exported then
			s = s .. "@"
		end
		s = s .. self.string
		if self.value_check then
			s = s .. "::" .. self.value_check:format_right(state, operator_priority["_::_"], ...)
		end
		return s
	end,
	_format_priority = function(self)
		if self.value_check then
			return operator_priority["_::_"]
		end
		return math.huge
	end,

	to_lua = function(self, state)
		return self.string
	end,
	to_identifier = function(self)
		return Identifier:new(self.string)
	end,
	to_string = function(self)
		return String:new(self.string)
	end
}

package.loaded[...] = Symbol
Identifier, String = ast.Identifier, ast.String

return Symbol
