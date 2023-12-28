--- transform raw code string into a nested tree of lines

local utf8 = utf8 or require("lua-utf8")

local Source = require("parser.Source")

local function indented_to_tree(indented)
	local tree = {}
	local current_parent = tree
	local current_level = 0
	local last_line_empty = nil

	for _, l in ipairs(indented) do
		-- indentation of empty line is determined using the next line
		-- (consecutive empty lines are merged into one)
		if l.content == "" then
			last_line_empty = l
		else
			-- raise indentation
			if l.level > current_level then
				if #current_parent == 0 then -- can't add children to nil
					error(("invalid indentation; at %s"):format(l.source))
				end
				current_parent = current_parent[#current_parent]
				current_level = l.level
			-- lower indentation
			elseif l.level < current_level then
				current_parent = tree
				current_level = 0
				while current_level < l.level do -- find correct level starting back from the root
					current_parent = current_parent[#current_parent]
					current_level = current_parent[1].level
				end
				if current_level ~= l.level then
					error(("invalid indentation; at %s"):format(l.source))
				end
			end
			-- add line
			if last_line_empty then
				last_line_empty.level = current_level
				table.insert(current_parent, last_line_empty)
				last_line_empty = nil
			end
			table.insert(current_parent, l)
		end
	end

	return tree
end

local function code_to_indented(code, source_name)
	local indented = {}

	local i = 1
	for line in (code.."\n"):gmatch("(.-)\n") do
		local indent, rem = line:match("^(%s*)(.-)$")
		local indent_len = utf8.len(indent)
		table.insert(indented, { level = indent_len, content = rem, source = Source:new(source_name, i, 1+indent_len) })
		i = i + 1
	end

	return indented
end

return function(code, source_name)
	return indented_to_tree(code_to_indented(code, source_name or "?"))
end
