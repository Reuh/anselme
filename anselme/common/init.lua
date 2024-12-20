local escape_cache = {}
local ansicolors = require("anselme.lib.ansicolors")

local common = {
	-- escape text to be used as an exact pattern
	escape = function(str)
		if not escape_cache[str] then
			escape_cache[str] = str:gsub("[^%w]", "%%%1")
		end
		return escape_cache[str]
	end,
	--- transform an identifier into a clean version (trim each part)
	trim = function(str)
		return str:match("^%s*(.-)%s*$")
	end,
	-- format ansi colored string
	fmt = function(str, ...)
		return ansicolors(str):format(...)
	end,
	-- generate a uuidv4
	uuid = function()
		return ("xxxxxxxx-xxxx-4xxx-Nxxx-xxxxxxxxxxxx") -- version 4
			:gsub("N", math.random(0x8, 0xb)) -- variant 1
			:gsub("x", function() return ("%x"):format(math.random(0x0, 0xf)) end) -- random hexadecimal digit
	end,
	-- same as assert, but do not add position information
	-- useful for errors raised from anselme (don't care about Lua error position)
	assert0 = function(v, message, ...)
		if not v then error(message, 0) end
		return v, message, ...
	end,
	-- list of operators and their priority that are handled through regular function calls & can be overloaded/etc. by the user
	regular_operators = {
		prefixes = {
			{ ">", 4 }, -- just above _=_
			{ "!", 11 },
			{ "+", 11 },
			{ "-", 11 },
			{ "*", 11 },
			{ "%", 11 },
		},
		suffixes = {
			{ "!", 12 }
		},
		infixes = {
			{ "#", 2 }, { "->", 2 },
			{ "=", 3 },
			{ "&", 5 }, { "|", 5 },
			{ "==", 6 }, { "!=", 6 }, { ">=", 6 }, { "<=", 6 }, { "<", 6 }, { ">", 6 },
			{ "+", 7 }, { "-", 7 },
			{ "/", 8 }, { "*", 8 }, { "%", 8 },
			{ "^", 10 },
			{ "::", 11 },
			{ ".", 14 },
			{ ":", 5 }
		}
	},
	-- list of all operators and their priority
	operator_priority = {
		["_;"] = 1,
		["_;_"] = 1,
		[";_"] = 1,
		["$_"] = 2,
		["_,_"] = 2,
		["_implicit*_"] = 9, -- just aboce _*_
		["_!_"] = 12,
		["_()"] = 13 -- just above _!
		-- generated at run-time for regular operators
	}
}

local function store_priority(t, fmt)
	for _, v in ipairs(t) do common.operator_priority[fmt:format(v[1])] = v[2] end
end
store_priority(common.regular_operators.infixes, "_%s_")
store_priority(common.regular_operators.prefixes, "%s_")
store_priority(common.regular_operators.suffixes, "_%s")

return common
