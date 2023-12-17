--- transform an expression string into raw AST

local primary, secondary

local comment = require("parser.expression.comment")

-- parse an expression, starting from a secondary element operating on operating_on_primary
-- returns expr, remaining
local function from_secondary(source, s, limit_pattern, current_priority, operating_on_primary)
	s = source:consume(s:match("^(%s*)(.*)$"))
	current_priority = current_priority or 0
	-- if there is a comment, restart the parsing after the comment ends
	local c, c_rem = comment:search(source, s, limit_pattern)
	if c then return from_secondary(source, c_rem, limit_pattern, current_priority, operating_on_primary) end
	-- secondary elements
	local exp, rem = secondary:search(source, s, limit_pattern, current_priority, operating_on_primary)
	if exp then return from_secondary(source, rem, limit_pattern, current_priority, exp) end
	-- nothing to apply on primary
	return operating_on_primary, s
end

--- parse an expression
-- current_priority: only elements of strictly higher priority will be parser
-- limit_pattern: set to a string pattern that will trigger the end of elements that would otherwise consume everything until end-of-line (pattern is not consumed)
-- fallback_exp: if no primary expression can be found, will return this instead. Used to avoid raising an error where an empty or comment-only expression is allowed.
-- return expr, remaining
local function expression_to_ast(source, s, limit_pattern, current_priority, fallback_exp)
	s = source:consume(s:match("^(%s*)(.*)$"))
	current_priority = current_priority or 0
	-- if there is a comment, restart the parsing after the comment ends
	local c, c_rem = comment:search(source, s, limit_pattern)
	if c then return expression_to_ast(source, c_rem, limit_pattern, current_priority, fallback_exp) end
	-- primary elements
	local exp, rem = primary:search(source, s, limit_pattern)
	if exp then return from_secondary(source, rem, limit_pattern, current_priority, exp) end
	-- no valid primary expression
	if fallback_exp then return fallback_exp, s end
	error(("no valid expression before %q"):format(s), 0)
end

package.loaded[...] = expression_to_ast

primary = require("parser.expression.primary")
secondary = require("parser.expression.secondary")

-- return expr, remaining
return function(source, s, limit_pattern, current_priority, operating_on_primary, fallback_exp)
	if operating_on_primary then return from_secondary(source, s, limit_pattern, current_priority, operating_on_primary)
	else return expression_to_ast(source, s, limit_pattern, current_priority, fallback_exp) end
end
