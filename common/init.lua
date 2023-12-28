local escape_cache = {}
local ansicolors = require("lib.ansicolors")

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
	fmt = function(str, ...)
		return ansicolors(str):format(...)
	end,
	uuid = function()
		return ("xxxxxxxx-xxxx-4xxx-Nxxx-xxxxxxxxxxxx") -- version 4
			:gsub("N", math.random(0x8, 0xb)) -- variant 1
			:gsub("x", function() return ("%x"):format(math.random(0x0, 0xf)) end) -- random hexadecimal digit
	end,
	-- list of operators and their priority that are handled through regular function calls & can be overloaded/etc. by the user
	regular_operators = {
		prefixes = {
			{ "~", 3.5 }, -- just below _~_ so else-if (~ condition ~ expression) parses as (~ (condition ~ expression))
			{ "!", 11 },
			{ "-", 11 },
			{ "*", 11 },
			{ "%", 11 },
		},
		suffixes = {
			{ ";", 1 },
			{ "!", 12 }
		},
		infixes = {
			{ ";", 1 },
			{ "#", 2 }, { "->", 2 }, { "~>", 2 },
			{ "~", 4 }, { "~?", 4 },
			{ "|>", 5 }, { "&", 5 }, { "|", 5 },
			{ "==", 7 }, { "!=", 7 }, { ">=", 7 }, { "<=", 7 }, { "<", 7 }, { ">", 7 },
			{ "+", 8 }, { "-", 8 },
			{ "//", 9 }, { "/", 9 }, { "*", 9 }, { "%", 9 },
			{ "^", 10 },
			{ "::", 11 },
			{ ".", 14 },
			{ ":", 5 }
		}
	},
	-- list of all operators and their priority
	operator_priority = {
		[";_"] = 1,
		["$_"] = 1,
		["@_"] = 1,
		["_,_"] = 2,
		["_=_"] = 3,
		["_!_"] = 12,
		["_()"] = 13
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
