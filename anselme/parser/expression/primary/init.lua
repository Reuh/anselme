--- try to parse a primary expression

local comment = require("anselme.parser.expression.comment")

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
	r("implicit_block_identifier"),
	r("tuple"),
	r("struct"),

	-- prefixes
	r("prefix.semicolon"),
	r("prefix.function"),
	r("prefix.wrap"),
	r("prefix.negation"),
	r("prefix.positive"),
	r("prefix.not"),
	r("prefix.mutable"),
	r("prefix.translatable"),
}

return {
	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, options, str)
		str = source:consume_leading_whitespace(options, str)
		-- if there is a comment, restart the parsing after the comment ends
		local c, c_rem = comment:search(source, options, str)
		if c then return self:search(source, options, c_rem) end
		-- search primary
		for _, primary in ipairs(primaries) do
			local exp, rem = primary:search(source, options, str)
			if exp then return exp, rem end
		end
	end
}
