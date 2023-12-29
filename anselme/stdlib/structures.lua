local ast = require("anselme.ast")
local Nil, List, Table, Number = ast.Nil, ast.List, ast.Table, ast.Number

return {
	-- tuple
	{
		"*_", "(t::tuple)",
		function(state, tuple)
			return List:new(state, tuple)
		end
	},
	{
		"_!", "(l::tuple, i::number)",
		function(state, l, i)
			return l:get(i.number)
		end
	},

	-- list
	{
		"_!", "(l::list, i::number)",
		function(state, l, i)
			return l:get(state, i.number)
		end
	},
	{
		"_!", "(l::list, i::number) = value",
		function(state, l, i, v)
			l:set(state, i.number, v)
			return Nil:new()
		end
	},
	{
		"insert", "(l::list, value)",
		function(state, l, v)
		l:insert(state, v)
			return Nil:new()
		end
	},
	{
		"len", "(l::list)",
		function(state, l)
			return Number:new(l:len(state))
		end
	},
	{
		"to tuple", "(l::list)",
		function(state, l)
			return l:to_tuple(state)
		end
	},

	-- struct
	{
		"*_", "(s::struct)",
		function(state, struct)
			return Table:new(state, struct)
		end
	},
	{
		"_!", "(s::struct, key)",
		function(state, s, k)
			return s:get(k)
		end
	},

	-- table
	{
		"_!", "(t::table, key)",
		function(state, t, key)
			return t:get(state, key)
		end
	},
	{
		"_!", "(t::table, key) = value",
		function(state, t, key, value)
		t:set(state, key, value)
			return Nil:new()
		end
	},
	{
		"to struct", "(t::table)",
		function(state, t)
			return t:to_struct(state)
		end
	},
}
