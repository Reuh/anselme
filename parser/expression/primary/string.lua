-- note: this is reused in primary.text, hence all the configurable fields

local primary = require("parser.expression.primary.primary")

local StringInterpolation = require("ast.StringInterpolation")

local ast = require("ast")
local String = ast.String

local expression_to_ast = require("parser.expression.to_ast")

local escape = require("common").escape

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
	parse = function(self, source, str, limit_pattern)
		local interpolation = self.interpolation:new()

		local stop_pattern = escape(self.stop_char)
		local start_source = source:clone()
		local rem = source:consume(str:match("^("..self.start_pattern..")(.-)$"))

		while not rem:match("^"..stop_pattern) do
			local text_source = source:clone()
			local text
			text, rem = rem:match("^([^%{%\\"..stop_pattern.."]*)(.-)$") -- get all text until something potentially happens

			-- cut the text prematurely at limit_pattern if relevant
			if self.allow_implicit_stop and limit_pattern and text:match(limit_pattern) then
				local pos = text:match("()"..limit_pattern) -- limit_pattern can contain $, so can't directly extract with captures
				text, rem = source:count(text:sub(1, pos-1)), ("%s%s%s"):format(self.stop_char, text:sub(pos), rem)
				source:increment(-1)
			else
				source:count(text)
			end

			interpolation:insert(String:new(text):set_source(text_source))

			if rem:match("^%{") then
				local ok, exp
				ok, exp, rem = pcall(expression_to_ast, source, source:consume(rem:match("^(%{)(.*)$")), "%}")
				if not ok then error("invalid expression inside interpolation: "..exp, 0) end
				if not rem:match("^%s*%}") then error(("unexpected %q at end of interpolation"):format(rem), 0) end
				rem = source:consume(rem:match("^(%s*%})(.*)$"))
				interpolation:insert(exp)
			elseif rem:match("^\\") then
				text, rem = source:consume(rem:match("^(\\(.))(.*)$"))
				interpolation:insert(String:new(escape_code[text] or text))
			elseif not rem:match("^"..stop_pattern) then
				if not self.allow_implicit_stop or rem:match("[^%s]") then
					error(("unexpected %q at end of "..self.type):format(rem), 0)
				-- consumed everything until end-of-line, implicit stop allowed, close your eyes and imagine the text has been closed
				else
					rem = rem .. self.stop_char
				end
			end
		end
		rem = source:consume(rem:match("^("..stop_pattern..")(.*)$"))

		return interpolation:set_source(start_source), rem
	end
}
