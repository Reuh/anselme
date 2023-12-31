local ast = require("anselme.ast")
local Branched, Tuple

local operator_priority = require("anselme.common").operator_priority

local List
List = ast.abstract.Runtime {
	type = "list",

	-- note: yeah technically this isn't mutable, only .branched is

	-- note: this a Branched of Tuple, and we *will* forcefully mutate the tuples, so make sure to not disseminate any reference to them outside the List
	-- unless you want rumors about mutable tuples to spread
	branched = nil,

	init = function(self, state, from_tuple)
		from_tuple = from_tuple or Tuple:new()
		self.branched = Branched:new(state, from_tuple:copy())
	end,

	_format = function(self, ...)
		return "*"..self.branched:format_right(...)
	end,
	_format_priority = function(self)
		return operator_priority["*_"]
	end,

	traverse = function(self, fn, ...)
		fn(self.branched, ...)
	end,

	-- List is always created from an evaluated Tuple, so no need to _eval here

	-- create copy of the list in branch if not here
	-- do this before any mutation
	-- return the tuple for the current branch
	_prepare_branch = function(self, state)
		if not self.branched:in_branch(state) then
			self.branched:set(state, self.branched:get(state):copy())
		end
		return self.branched:get(state)
	end,

	len = function(self, state)
		return self.branched:get(state):len()
	end,
	iter = function(self, state)
		return ipairs(self.branched:get(state).list)
	end,
	get = function(self, state, index)
		local list = self.branched:get(state)
		if index < 0 then index = #list.list + 1 + index end
		if index > #list.list or index == 0 then error("list index out of bounds", 0) end
		return list.list[index]
	end,
	set = function(self, state, index, val)
		local list = self:_prepare_branch(state)
		if index < 0 then index = #list.list + 1 + index end
		if index > #list.list+1 or index == 0 then error("list index out of bounds", 0) end
		list.list[index] = val
	end,
	insert = function(self, state, val)
		local l = self:_prepare_branch(state)
		table.insert(l.list, val)
	end,
	remove = function(self, state)
		local l = self:_prepare_branch(state)
		table.remove(l.list)
	end,

	to_tuple = function(self, state)
		return self.branched:get(state):copy()
	end,
	to_lua = function(self, state)
		return self.branched:get(state):to_lua(state)
	end,
}

package.loaded[...] = List
Branched, Tuple = ast.Branched, ast.Tuple

return List
