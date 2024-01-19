local block = require("anselme.parser.expression.block")
local Source = require("anselme.parser.Source")
local Options = require("anselme.parser.Options")

local function expect_end(exp, rem)
	if rem:match("[^%s]") then
		error(("expected end of expression before %q"):format(rem))
	end
	return exp
end

-- we require UTF-8 but life is full of disapointments
-- remove BOM
-- \r\n and \r -> \n
local function normalize_encoding(str)
	return str:gsub("^"..string.char(0xEF, 0xBB, 0xBF), "")
	            :gsub("\r\n?", "\n")
end

-- parse code (string) with the associated source (Source)
-- the returned AST tree is stateless and can be stored/evaluated/etc as you please
return function(code, source)
	return expect_end(block(Source:new(source, 1, 1), Options:new(), normalize_encoding(code)))
end
