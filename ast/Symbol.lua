local ast = require("ast")
local Identifier, String

local operator_priority = require("common").operator_priority

local Symbol
Symbol = ast.abstract.Node {
	type = "symbol",

	string = nil,
	constant = nil, -- bool
	type_check = nil, -- exp

	exported = nil, -- bool
	persistent = nil, -- bool, imply exported

	confined_to_branch = nil, -- bool

	init = function(self, str, modifiers)
		modifiers = modifiers or {}
		self.string = str
		self.constant = modifiers.constant
		self.persistent = modifiers.persistent
		self.type_check = modifiers.type_check
		self.confined_to_branch = modifiers.confined_to_branch
		self.exported = modifiers.exported or modifiers.persistent
		if self.type_check then
			self.format_priority = operator_priority["_::_"]
		end
	end,

	_eval = function(self, state)
		return Symbol:new(self.string, {
			constant = self.constant,
			persistent = self.persistent,
			type_check = self.type_check and self.type_check:eval(state),
			confined_to_branch = self.confined_to_branch,
			exported = self.exported
		})
	end,

	_hash = function(self)
		return ("symbol<%q>"):format(self.string)
	end,

	_format = function(self, state, prio, ...)
		local s = ":"
		if self.constant then
			s = s .. ":"
		end
		if self.persistent then
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
