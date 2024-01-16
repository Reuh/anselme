local primary = require("anselme.parser.expression.primary.primary")

local comment
comment = primary {
	match = function(self, str)
		return str:match("^%/%*") or str:match("^%-%-")
	end,
	parse = function(self, source, options, str)
		local limit_pattern = options.limit_pattern

		local allow_implicit_stop, stop_str, stop_pattern, rem
		if str:match("^%/%*") then
			allow_implicit_stop = false
			stop_str = "*/"
			stop_pattern = "%*%/"
			rem = source:consume(str:match("^(%/%*)(.*)$"))
		else
			allow_implicit_stop = true
			stop_str = "--"
			stop_pattern = "%-%-"
			rem = source:consume(str:match("^(%-%-)(.*)$"))
		end

		local comment_pattern = "^([^%/%*%-"..(allow_implicit_stop and "\n" or "").."]*)(.-)$"
		local at_stop_pattern = "^"..stop_pattern

		local content_list = {}
		while not rem:match(at_stop_pattern) do
			local content
			content, rem = rem:match(comment_pattern)

			-- cut the text prematurely at limit_pattern if relevant
			if allow_implicit_stop and limit_pattern and content:match(limit_pattern) then
				local pos = content:match("()"..limit_pattern) -- limit_pattern can contain $, so can't directly extract with captures
				content, rem = source:count(content:sub(1, pos-1)), ("%s%s%s"):format(stop_str, content:sub(pos), rem)
				source:increment(-2)
			else
				source:count(content)
			end

			table.insert(content_list, content)

			-- nested comment
			if rem:match("^%/%*") then
				local subcomment
				subcomment, rem = comment:parse(source, options, rem)

				table.insert(content_list, "/*")
				table.insert(content_list, subcomment)
				table.insert(content_list, "*/")
			-- consumed everything until end-of-string, close your eyes and imagine the text has been closed
			elseif allow_implicit_stop and rem:match("^\n") or not rem:match("[^%s]") then
				rem = stop_str .. rem
				source:increment(-2)
			-- no end token after the comment
			elseif not rem:match(at_stop_pattern) then
				-- non-end *, /, or -, keep on commentin'
				if rem:match("^[%*%/%-]") then
					local s
					s, rem = source:count(rem:match("^([%*%/%-])(.-)$"))
					table.insert(content_list, s)
				-- anything else
				else
					error(("unexpected %q at end of comment"):format(rem:match("^[^\n]*")), 0)
				end
			end
		end
		rem = source:consume(rem:match("^("..stop_pattern..")(.*)$"))

		return table.concat(content_list, ""), rem
	end
}

return comment
