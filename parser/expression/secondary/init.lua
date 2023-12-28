--- try to parse a secondary expression

local function r(name)
	return require("parser.expression.secondary."..name), nil
end

local secondaries = {
	-- binary infix operators
	-- 1
	r("infix.semicolon"),
	-- 2
	r("infix.tuple"),
	r("infix.tag"),
	r("infix.translate"),
	r("infix.resume"),
	-- 4
	r("infix.while"),
	r("infix.if"),
	-- 6
	r("infix.choice"),
	r("infix.and"),
	r("infix.or"),
	-- 7
	r("infix.equal"),
	r("infix.different"),
	r("infix.greater_equal"),
	r("infix.lower_equal"),
	r("infix.greater"),
	r("infix.lower"),
	-- 8
	r("infix.addition"),
	r("infix.substraction"),
	-- 9
	r("infix.multiplication"),
	r("infix.integer_division"),
	r("infix.division"),
	r("infix.modulo"),
	-- 9.5
	r("infix.implicit_multiplication"),
	-- 10
	r("infix.exponent"),
	-- 11
	r("infix.type_check"),
	-- 12
	r("infix.call"),
	-- 14
	r("infix.index"),
	-- 3
	r("infix.assignment"), -- deported after equal
	r("infix.assignment_call"),
	r("infix.definition"),
	-- 5
	r("infix.pair"), -- deported after type_check

	-- unary suffix operators
	-- 1
	r("suffix.semicolon"),
	-- 12
	r("suffix.exclamation_call"),
	-- 13
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
	-- returns nil, err if error
	search = function(self, source, str, limit_pattern, current_priority, primary)
		for _, secondary in ipairs(secondaries) do
			local exp, rem = secondary:search(source, str, limit_pattern, current_priority, primary)
			if exp then return exp, rem end
		end
	end
}
