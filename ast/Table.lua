local ast = require("ast")
local Branched, Struct, Nil = ast.Branched, ast.Struct, ast.Nil

local operator_priority = require("common").operator_priority

local Table
Table = ast.abstract.Runtime {
	type = "table",

	format_priority = operator_priority["*_"],

	-- note: technically this isn't mutable, only .branched is

	-- note: this a Branched of Struct, and we *will* forcefully mutate the tuples, so make sure to not disseminate any reference to them outside the Table
	-- unless you want rumors about mutable structs to spread
	branched = nil,

	init = function(self, state, from_struct)
		from_struct = from_struct or Struct:new()
		self.branched = Branched:new(state, from_struct:copy())
	end,

	_format = function(self, ...)
		return "*"..self.branched:format_right(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.branched, ...)
	end,

	-- Table is always created from an evaluated Struct, so no need to _eval here

	-- create copy of the table in branch if not here
	-- do this before any mutation
	-- return the struct for the current branch
	_prepare_branch = function(self, state)
		if not self.branched:in_branch(state) then
			self.branched:set(state, self.branched:get(state):copy())
		end
		return self.branched:get(state)
	end,

	get = function(self, state, key)
		local s = self.branched:get(state)
		return s:get(key)
	end,
	set = function(self, state, key, val)
		local s = self:_prepare_branch(state)
		local hash = key:hash()
		if Nil:is(val) then
			s.table[hash] = nil
		else
			s.table[hash] = { key, val }
		end
	end,
	has = function(self, state, key)
		local s = self.branched:get(state)
		return s:has(key)
	end,
	iter = function(self, state)
		local s = self.branched:get(state)
		return s:iter()
	end,

	to_struct = function(self, state)
		return self.branched:get(state):copy()
	end,
	to_lua = function(self, state)
		return self.branched:get(state):to_lua(state)
	end,
	copy = function(self, state)
		return Table:new(state, self:to_struct(state))
	end
}

package.loaded[...] = Table
Branched, Struct, Nil = ast.Branched, ast.Struct, ast.Nil

return Table
