local ast = require("ast")
local Pair, Number, Nil

local operator_priority = require("common").operator_priority

local Struct

local TupleToStruct = ast.abstract.Node {
	type = "tuple to struct",

	tuple = nil,

	init = function(self, tuple)
		self.tuple = tuple
	end,
	traverse = function(self, fn, ...)
		fn(self.tuple, ...)
	end,

	_format = function(self, ...)
		return self.tuple:format(...):gsub("^%[", "{"):gsub("%]$", "}")
	end,

	_eval = function(self, state)
		local t = Struct:new()
		for i, e in ipairs(self.tuple.list) do
			if Pair:is(e) then
				t:set(e.name, e.value)
			else
				t:set(Number:new(i), e)
			end
		end
		return t
	end
}

Struct = ast.abstract.Runtime {
	type = "struct",

	table = nil,

	init = function(self)
		self.table = {}
	end,
	set = function(self, key, value) -- only for construction
		self.table[key:hash()] = { key, value }
	end,
	include = function(self, other) -- only for construction
		for _, e in pairs(other.table) do
			self:set(e[1], e[2])
		end
	end,

	copy = function(self)
		local s = Struct:new()
		for _, e in pairs(self.table) do
			s:set(e[1], e[2])
		end
		return s
	end,

	-- build from (non-evaluated) tuple
	-- results needs to be evaluated
	from_tuple = function(self, tuple)
		return TupleToStruct:new(tuple)
	end,

	_format = function(self, state, prio, ...)
		local l = {}
		for _, e in pairs(self.table) do
			-- _:_ has higher priority than _,_
			table.insert(l, e[1]:format(state, operator_priority["_:_"], ...)..":"..e[2]:format_right(state, operator_priority["_:_"], ...))
		end
		table.sort(l)
		return ("{%s}"):format(table.concat(l, ", "))
	end,

	traverse = function(self, fn, ...)
		for _, e in pairs(self.table) do
			fn(e[1], ...)
			fn(e[2], ...)
		end
	end,

	-- need to redefine hash to include a table.sort as pairs() in :traverse is non-deterministic
	_hash = function(self)
		local t = {}
		for _, e in pairs(self.table) do
			table.insert(t, ("%s;%s"):format(e[1]:hash(), e[2]:hash()))
		end
		table.sort(t)
		return ("%s<%s>"):format(self.type, table.concat(t, ";"))
	end,

	-- regarding eval: Struct is built from TupleToStruct function call which already eval, so every Struct should be fully evaluated

	to_lua = function(self, state)
		local l = {}
		for _, e in ipairs(self.table) do
			l[e[1]:to_lua(state)] = e[2]:to_lua(state)
		end
		return l
	end,

	get = function(self, key)
		local hash = key:hash()
		if self.table[hash] then
			return self.table[hash][2]
		else
			return Nil:new()
		end
	end,
	has = function(self, key)
		local hash = key:hash()
		return not not self.table[hash]
	end,
	iter = function(self)
		local t, h = self.table, nil
		return function()
			local e
			h, e = next(t, h)
			if h == nil then return nil
			else return e[1], e[2]
			end
		end
	end,
}

package.loaded[...] = Struct
Pair, Number, Nil = ast.Pair, ast.Number, ast.Nil

return Struct
