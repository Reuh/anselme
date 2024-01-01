--- try to parse a primary expression

local function r(name)
	return require("anselme.parser.expression.primary."..name), nil
end

local primaries = {
	r("number"),
	r("string"),
	r("text"),
	r("parenthesis"),
	r("function_definition"),
	r("symbol"),
	r("identifier"),
	r("anchor"),
	r("block_identifier"),
	r("tuple"),
	r("struct"),

	-- prefixes
	r("prefix.semicolon"),
	r("prefix.function"),
	r("prefix.wrap"),
	r("prefix.negation"),
	r("prefix.not"),
	r("prefix.mutable"),
	r("prefix.translatable"),
}

return {
	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, str, limit_pattern)
		for _, primary in ipairs(primaries) do
			local exp, rem = primary:search(source, str, limit_pattern)
			if exp then return exp, rem end
		end
	end
}
