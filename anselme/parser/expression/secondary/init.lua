--- try to parse a secondary expression

local comment = require("anselme.parser.expression.comment")

local function r(name)
	return require("anselme.parser.expression.secondary."..name), nil
end

local secondaries = {
	-- binary infix operators,
	r("infix.semicolon"),
	r("infix.tuple"),
	r("infix.tag"),
	r("infix.translate"),
	r("infix.and"),
	r("infix.or"),
	r("infix.equal"),
	r("infix.different"),
	r("infix.greater_equal"),
	r("infix.lower_equal"),
	r("infix.greater"),
	r("infix.lower"),
	r("infix.addition"),
	r("infix.substraction"),
	r("infix.multiplication"),
	r("infix.division"),
	r("infix.modulo"),
	r("infix.implicit_multiplication"),
	r("infix.exponent"),
	r("infix.value_check"),
	r("infix.call"),
	r("infix.index_identifier"),
	r("infix.index"),
	r("infix.assignment_call"),
	r("infix.assignment"), -- deported after equal
	r("infix.pair"), -- deported after value_check

	-- unary suffix operators
	r("suffix.semicolon"),
	r("suffix.exclamation_call"),
	r("suffix.call"),
}

-- add generated assignement+infix operator combos, before the rest
local compound_assignments = r("infix.assignment_with_infix")
for i, op in ipairs(compound_assignments) do
	table.insert(secondaries, i, op)
end

return {
	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, options, str, current_priority, primary)
		local start_source = source:clone()
		str = source:consume_leading_whitespace(options, str)
		-- if there is a comment, restart the parsing after the comment ends
		local c, c_rem = comment:search(source, options, str)
		if c then
			local ce, ce_rem = self:search(source, options, c_rem, current_priority, primary)
			if ce then return ce, ce_rem
			else return primary, c_rem end -- noop
		end
		-- search secondary
		for _, secondary in ipairs(secondaries) do
			local exp, rem = secondary:search(source, options, str, current_priority, primary)
			if exp then return exp, rem end
		end
		-- nothing found, revert state change
		source:set(start_source)
	end
}
