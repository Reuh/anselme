-- note: this is reused in primary.text, hence all the configurable fields

local primary = require("anselme.parser.expression.primary.primary")

local ast = require("anselme.ast")
local String, StringInterpolation = ast.String, ast.StringInterpolation

local expression_to_ast = require("anselme.parser.expression.to_ast")

local escape = require("anselme.common").escape

local escape_code = {
	["n"] = "\n",
	["t"] = "\t",
	-- everything else is identity by default
}

return primary {
	type = "string", -- interpolation type - used for errors
	start_pattern = "\"", -- pattern that start the string interpolation
	stop_char = "\"", -- character that stops the string interpolation - must be a single character!

	allow_implicit_stop = false, -- set to true to allow the string to be closed implicitely when reaching the end of the expression or limit_pattern

	interpolation = StringInterpolation,

	match = function(self, str)
		return str:match("^"..self.start_pattern)
	end,
	parse = function(self, source, options, str)
		local limit_pattern = options.limit_pattern
		local interpolation = self.interpolation:new()

		local stop_pattern = escape(self.stop_char)
		local start_source = source:clone()
		local rem = source:consume(str:match("^("..self.start_pattern..")(.-)$"))

		while not rem:match("^"..stop_pattern) do
			local text_source = source:clone()
			local text
			text, rem = rem:match("^([^\n%{%\\"..stop_pattern.."]*)(.-)$") -- get all text until something potentially happens

			-- cut the text prematurely at limit_pattern if relevant
			if self.allow_implicit_stop and limit_pattern and text:match(limit_pattern) then
				local pos = text:match("()"..limit_pattern) -- limit_pattern can contain $, so can't directly extract with captures
				text, rem = source:count(text:sub(1, pos-1)), ("%s%s%s"):format(self.stop_char, text:sub(pos), rem)
				source:increment(-1)
			else
				source:count(text)
			end

			interpolation:insert(String:new(text):set_source(text_source))

			-- interpolated expression
			if rem:match("^%{") then
				local opts = options:with { limit_pattern = "%}", allow_newlines = false }
				local ok, exp
				ok, exp, rem = pcall(expression_to_ast, source, opts, source:consume(rem:match("^(%{)(.*)$")))
				if not ok then error("invalid expression inside interpolation: "..exp, 0) end
				rem = source:consume_leading_whitespace(opts, rem)
				if not rem:match("^%}") then error(("unexpected %q at end of interpolation"):format(rem:match("^[^\n]*")), 0) end
				rem = source:consume(rem:match("^(%})(.*)$"))
				interpolation:insert(exp)
			-- escape sequence
			elseif rem:match("^\\") then
				text, rem = source:consume(rem:match("^(\\(.))(.*)$"))
				interpolation:insert(String:new(escape_code[text] or text))
			-- consumed everything until end-of-line/file, implicit stop allowed, close your eyes and imagine the text has been closed
			elseif self.allow_implicit_stop and (rem:match("^\n") or not rem:match("[^%s]")) then
				rem = self.stop_char .. rem
				source:increment(-1)
			-- no end token after the comment
			elseif not rem:match("^"..stop_pattern) then
				error(("unexpected %q at end of "..self.type):format(rem:match("^[^\n]*")), 0)
			end
		end
		rem = source:consume(rem:match("^("..stop_pattern..")(.*)$"))

		return interpolation:set_source(start_source), rem
	end
}
