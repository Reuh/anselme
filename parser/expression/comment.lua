local primary = require("parser.expression.primary.primary")

local comment
comment = primary {
	match = function(self, str)
		return str:match("^%(%(")
	end,
	parse = function(self, source, str, limit_pattern)
		local rem = source:consume(str:match("^(%(%()(.*)$"))

		local content_list = {}
		while not rem:match("^%)%)") do
			local content
			content, rem = rem:match("^([^%(%)]*)(.-)$")

			-- cut the text prematurely at limit_pattern if relevant
			if limit_pattern and content:match(limit_pattern) then
				local pos = content:match("()"..limit_pattern) -- limit_pattern can contain $, so can't directly extract with captures
				content, rem = source:count(content:sub(1, pos-1)), ("))%s%s"):format(content:sub(pos), rem)
				source:increment(-2)
			else
				source:count(content)
			end

			table.insert(content_list, content)

			-- nested comment
			if rem:match("^%(%(") then
				local subcomment
				subcomment, rem = comment:parse(source, rem, limit_pattern)

				table.insert(content_list, "((")
				table.insert(content_list, subcomment)
				table.insert(content_list, "))")
			-- no end token after the comment
			elseif not rem:match("^%)%)") then
				-- single ) or (, keep on commentin'
				if rem:match("^[%)%(]") then
					local s
					s, rem = source:count(rem:match("^([%)%(])(.-)$"))
					table.insert(content_list, s)
				-- anything other than end-of-line
				elseif rem:match("[^%s]") then
					error(("unexpected %q at end of comment"):format(rem), 0)
				-- consumed everything until end-of-line, close your eyes and imagine the text has been closed
				else
					rem = rem .. "))"
				end
			end
		end
		rem = source:consume(rem:match("^(%)%))(.*)$"))

		return table.concat(content_list, ""), rem
	end
}

return comment
