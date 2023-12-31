local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

local Tuple
Tuple = ast.abstract.Node {
	type = "tuple",
	explicit = true, -- false for implicitely created tuples, e.g. 1,2,3 without the brackets []

	list = nil,

	init = function(self, ...)
		self.list = { ... }
	end,
	insert = function(self, val) -- only for construction
		table.insert(self.list, val)
	end,

	_format = function(self, state, prio, ...)
		local l = {}
		for _, e in ipairs(self.list) do
			table.insert(l, e:format(state, operator_priority["_,_"], ...))
		end
		return ("[%s]"):format(table.concat(l, ", "))
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.list) do
			fn(e, ...)
		end
	end,

	_eval = function(self, state)
		local t = Tuple:new()
		for _, e in ipairs(self.list) do
			t:insert(e:eval(state))
		end
		if not self.explicit then
			t.explicit = false
		end
		return t
	end,
	copy = function(self)
		local t = Tuple:new()
		for _, e in ipairs(self.list) do
			t:insert(e)
		end
		return t
	end,

	to_lua = function(self, state)
		local l = {}
		for _, e in ipairs(self.list) do
			table.insert(l, e:to_lua(state))
		end
		return l
	end,

	get = function(self, index)
		if index < 0 then index = #self.list + 1 + index end
		if index > #self.list or index == 0 then error("tuple index out of bounds", 0) end
		return self.list[index]
	end,
	len =  function(self)
		return #self.list
	end
}

return Tuple
