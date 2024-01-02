local ast = require("anselme.ast")
local Identifier, String

local operator_priority = require("anselme.common").operator_priority

local Symbol
Symbol = ast.abstract.Node {
	type = "symbol",

	string = nil,
	constant = nil, -- bool
	type_check = nil, -- exp

	alias = nil, -- bool
	exported = nil, -- bool

	confined_to_branch = nil, -- bool
	undefine = nil, -- bool

	init = function(self, str, modifiers)
		modifiers = modifiers or {}
		self.string = str
		self.constant = modifiers.constant
		self.type_check = modifiers.type_check
		self.alias = modifiers.alias
		self.confined_to_branch = modifiers.confined_to_branch
		self.exported = modifiers.exported
		self.undefine = modifiers.undefine
	end,

	_eval = function(self, state)
		return self:with {
			type_check = self.type_check and self.type_check:eval(state)
		}
	end,

	with = function(self, modifiers)
		modifiers = modifiers or {}
		for _, k in ipairs{"constant", "type_check", "alias", "exported", "confined_to_branch", "undefine"} do
			if modifiers[k] == nil then
				modifiers[k] = self[k]
			end
		end
		return Symbol:new(self.string, modifiers)
	end,

	_hash = function(self)
		return ("symbol<%q>"):format(self.string)
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
		if self.type_check then
			s = s .. "::" .. self.type_check:format_right(state, operator_priority["_::_"], ...)
		end
		return s
	end,
	_format_priority = function(self)
		if self.type_check then
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
