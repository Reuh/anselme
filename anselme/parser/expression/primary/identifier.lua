local primary = require("anselme.parser.expression.primary.primary")

local Identifier = require("anselme.ast.Identifier")

local disallowed_set = ("\n.~`^+-=<>/[]*{}|\\_!?,;:()\"@&$#%"):gsub("[^%w]", "%%%1")
local identifier_pattern = "[ \t]*[^0-9%s'"..disallowed_set.."][^"..disallowed_set.."]*"

local common = require("anselme.common")
local trim, escape = common.trim, common.escape

-- for operator identifiers
local regular_operators = require("anselme.common").regular_operators
local operators = {}
for _, prefix in ipairs(regular_operators.prefixes) do table.insert(operators, prefix[1].."_") end
for _, infix in ipairs(regular_operators.infixes) do table.insert(operators, "_"..infix[1].."_") end
for _, suffix in ipairs(regular_operators.suffixes) do table.insert(operators, "_"..suffix[1]) end

-- all valid identifier patterns
local identifier_patterns = { identifier_pattern }
for _, operator in ipairs(operators) do table.insert(identifier_patterns, "[ \t]*"..escape(operator)) end

return primary {
	match = function(self, str)
		for _, pat in ipairs(identifier_patterns) do
			if str:match("^"..pat) then return true end
		end
		return false
	end,

	parse = function(self, source, options, str)
		for _, pat in ipairs(identifier_patterns) do
			if str:match("^"..pat) then
				local start_source = source:clone()
				local name, rem = source:count(str:match("^("..pat..")(.-)$"))
				name = trim(name)
				return Identifier:new(name):set_source(start_source), rem
			end
		end
	end
}
