--- # Structures
--
-- Anselme offers:
-- * indexed structures: tuple (immutable) and list (mutable)
-- * dictionary structures: struct (immutable) and table (mutable)
--
-- ```
-- :tuple = ["a","b",42]
-- tuple(2) // "b"
--
-- :list = *["a","b",42]
-- list(2) = "c"
--
-- :struct = { a: 42, 2: "b" }
-- struct("a") // 42
--
-- :table = *{ a: 42, 2: "b" }
-- table(2) = "c"
-- ```
--
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil, List, Table, Number, LuaCall, ParameterTuple, Boolean = ast.Nil, ast.List, ast.Table, ast.Number, ast.LuaCall, ast.ParameterTuple, ast.Boolean

return {
	-- tuple
	{
		--- Create a list from the tuple.
		"*_", "(t::is tuple)",
		function(state, tuple)
			return List:new(state, tuple)
		end
	},
	{
		--- Returns the `i`-th element of the tuple.
		"_!", "(l::is tuple, i::is number)",
		function(state, l, i)
			return l:get(i.number)
		end
	},
	{
		--- Returns the length of the tuple.
		"len", "(l::is tuple)",
		function(state, l)
			return Number:new(l:len())
		end
	},
	{
		--- Returns the index of the `value` element in the tuple. If `value` is not in the tuple, returns nil.
		"find", "(l::is tuple, value)",
		function(state, l, v)
			local i = l:find(v)
			if i then
				return Number:new(i)
			else
				return Nil:new()
			end
		end
	},

	-- list
	{
		--- Returns the `i`-th element of the list.
		"_!", "(l::is list, i::is number)",
		function(state, l, i)
			return l:get(state, i.number)
		end
	},
	{
		--- Set the `i`-th element of the list to `value`.
		"_!", "(l::is list, i::is number) = value",
		function(state, l, i, v)
			l:set(state, i.number, v)
			return Nil:new()
		end
	},
	{
		--- Returns the length of the list.
		"len", "(l::is list)",
		function(state, l)
			return Number:new(l:len(state))
		end
	},
	{
		--- Returns the index of the `value` element in the list. If `value` is not in the list, returns nil.
		"find", "(l::is list, value)",
		function(state, l, v)
			local i = l:find(state, v)
			if i then
				return Number:new(i)
			else
				return Nil:new()
			end
		end
	},
	{
		--- Insert a new value `value` at the end of the list.
		"insert", "(l::is list, value)",
		function(state, l, v)
			l:insert(state, v)
			return Nil:new()
		end
	},
	{
		--- Insert a new value `value` at the `i`-th position in list, shifting the `i`, `i`+1, etc. elements by one.
		"insert", "(l::is list, i::is number, value)",
		function(state, l, position, v)
			l:insert(state, position.number, v)
			return Nil:new()
		end
	},
	{
		--- Remove the last element of the list.
		"remove", "(l::is list)",
		function(state, l)
			l:remove(state)
			return Nil:new()
		end
	},
	{
		--- Remove the `i`-th element of the list, shifting the `i`, `i`+1, etc. elements by minus one.
		"remove", "(l::is list, i::is number)",
		function(state, l, position)
			l:remove(state, position.number)
			return Nil:new()
		end
	},
	{
		--- Returns a tuple with the same content as this list.
		"to tuple", "(l::is list)",
		function(state, l)
			return l:to_tuple(state)
		end
	},

	-- struct
	{
		--- Create a table from the struct.
		"*_", "(s::is struct)",
		function(state, struct)
			return Table:new(state, struct)
		end
	},
	{
		--- Returns the value associated with `key` in the struct.
		"_!", "(s::is struct, key)",
		function(state, s, k)
			return s:get(k)
		end
	},
	{
		--- Returns the value associated with `key` in the struct.
		-- If the `key` is not present in the struct, returns `default` instead.
		"_!", "(s::is struct, key, default)",
		function(state, s, k, default)
			if s:has(k) then
				return s:get(k)
			else
				return default
			end
		end
	},
	{
		--- Returns true if the struct contains the key `key`, false otherwise.
		"has", "(s::is struct, key)",
		function(state, s, k)
			return Boolean:new(s:has(k))
		end
	},
	{
		--- Returns an iterator over the keys of the struct.
		"iter", "(s::is struct)",
		function(state, struct)
			local iter = struct:iter()
			return LuaCall:make_function(state, ParameterTuple:new(), function()
				local k = iter()
				if k == nil then return Nil:new()
				else return k end
			end)
		end
	},

	-- table
	{
		--- Returns the value associated with `key` in the table.
		"_!", "(t::is table, key)",
		function(state, t, key)
			return t:get(state, key)
		end
	},
	{
		--- Returns the value associated with `key` in the table.
		-- If the `key` is not present in the table, returns `default` instead.
		"_!", "(t::is table, key, default)",
		function(state, t, key, default)
			if t:has(state, key) then
				return t:get(state, key)
			else
				return default
			end
		end
	},
	{
		--- Sets the value associated with `key` in the table to `value`, creating it if not present
		-- If `value` is nil, deletes the entry in the table.
		"_!", "(t::is table, key) = value",
		function(state, t, key, value)
			t:set(state, key, value)
			return Nil:new()
		end
	},
	{
		--- Sets the value associated with `key` in the table to `value`, creating it if not present
		-- If `value` is nil, deletes the entry in the table.
		"_!", "(t::is table, key, default) = value",
		function(state, t, key, default, value)
			t:set(state, key, value)
			return Nil:new()
		end
	},
	{
		--- Returns true if the table contains the key `key`, false otherwise.
		"has", "(t::is table, key)",
		function(state, t, k)
			return Boolean:new(t:has(state, k))
		end
	},
	{
		--- Returns a struct with the same content as this table.
		"to struct", "(t::is table)",
		function(state, t)
			return t:to_struct(state)
		end
	},
}
