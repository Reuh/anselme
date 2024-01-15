--- transform an expression string into raw AST

local primary, secondary

-- parse an expression, starting from a secondary element operating on operating_on_primary
-- returns expr, remaining
local function from_secondary(source, options, s, current_priority, operating_on_primary)
	current_priority = current_priority or 0
	-- secondary elements
	local exp, rem = secondary:search(source, options, s, current_priority, operating_on_primary)
	if exp then return from_secondary(source, options, rem, current_priority, exp) end
	-- nothing to apply on primary
	return operating_on_primary, s
end

--- parse an expression
-- current_priority: only elements of strictly higher priority will be parser
-- limit_pattern: set to a string pattern that will trigger the end of elements that would otherwise consume everything until end-of-line (pattern is not consumed)
-- fallback_exp: if no primary expression can be found, will return this instead. Used to avoid raising an error where an empty or comment-only expression is allowed.
-- return expr, remaining
local function expression_to_ast(source, options, s, current_priority)
	current_priority = current_priority or 0
	-- primary elements
	local exp, rem = primary:search(source, options, s)
	if exp then return from_secondary(source, options, rem, current_priority, exp) end
	-- no valid primary expression
	error(("no valid expression after %q"):format(s), 0)
end

package.loaded[...] = expression_to_ast

primary = require("anselme.parser.expression.primary")
secondary = require("anselme.parser.expression.secondary")

-- return expr, remaining
return function(source, options, s, current_priority, operating_on_primary)
	if operating_on_primary then return from_secondary(source, options, s, current_priority, operating_on_primary)
	else return expression_to_ast(source, options, s, current_priority) end
end
