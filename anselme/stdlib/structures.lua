local ast = require("anselme.ast")
local Nil, List, Table, Number, LuaCall, ParameterTuple, Boolean = ast.Nil, ast.List, ast.Table, ast.Number, ast.LuaCall, ast.ParameterTuple, ast.Boolean

return {
	-- tuple
	{
		"*_", "(t::is tuple)",
		function(state, tuple)
			return List:new(state, tuple)
		end
	},
	{
		"_!", "(l::is tuple, i::is number)",
		function(state, l, i)
			return l:get(i.number)
		end
	},
	{
		"len", "(l::is tuple)",
		function(state, l)
			return Number:new(l:len())
		end
	},
	{
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
		"_!", "(l::is list, i::is number)",
		function(state, l, i)
			return l:get(state, i.number)
		end
	},
	{
		"_!", "(l::is list, i::is number) = value",
		function(state, l, i, v)
			l:set(state, i.number, v)
			return Nil:new()
		end
	},
	{
		"len", "(l::is list)",
		function(state, l)
			return Number:new(l:len(state))
		end
	},
	{
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
		"insert", "(l::is list, value)",
		function(state, l, v)
			l:insert(state, v)
			return Nil:new()
		end
	},
	{
		"insert", "(l::is list, position::is number, value)",
		function(state, l, position, v)
			l:insert(state, position.number, v)
			return Nil:new()
		end
	},
	{
		"remove", "(l::is list)",
		function(state, l)
			l:remove(state)
			return Nil:new()
		end
	},
	{
		"remove", "(l::is list, position::is number)",
		function(state, l, position)
			l:remove(state, position.number)
			return Nil:new()
		end
	},
	{
		"to tuple", "(l::is list)",
		function(state, l)
			return l:to_tuple(state)
		end
	},

	-- struct
	{
		"*_", "(s::is struct)",
		function(state, struct)
			return Table:new(state, struct)
		end
	},
	{
		"_!", "(s::is struct, key)",
		function(state, s, k)
			return s:get(k)
		end
	},
	{
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
		"has", "(s::is struct, key)",
		function(state, s, k)
			return Boolean:new(s:has(k))
		end
	},
	{
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
		"_!", "(t::is table, key)",
		function(state, t, key)
			return t:get(state, key)
		end
	},
	{
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
		"_!", "(t::is table, key) = value",
		function(state, t, key, value)
		t:set(state, key, value)
			return Nil:new()
		end
	},
	{
		"has", "(t::is table, key)",
		function(state, t, k)
			return Boolean:new(t:has(state, k))
		end
	},
	{
		"to struct", "(t::is table)",
		function(state, t)
			return t:to_struct(state)
		end
	},
}
