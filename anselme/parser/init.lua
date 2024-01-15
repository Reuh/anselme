local block = require("anselme.parser.expression.block")
local Source = require("anselme.parser.Source")
local Options = require("anselme.parser.Options")

local function expect_end(exp, rem)
	if rem:match("[^%s]") then
		error(("expected end of expression before %q"):format(rem))
	end
	return exp
end

-- parse code (string) with the associated source (Source)
-- the returned AST tree is stateless and can be stored/evaluated/etc as you please
return function(code, source)
	return expect_end(block(Source:new(source, 1, 1), Options:new(), code))
end
