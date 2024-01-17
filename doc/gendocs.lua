-- LDoc doesn't like me so I don't like LDoc.
-- Behold! A documentation generator that doesn't try to be smart!
-- Call this from the root anselme repository directory: `lua doc/gendocs.lua`

local utf8 = utf8 or require("lua-utf8")

local files = {
	"doc/api.md"
}
local source_link_prefix = "../"
local base_header_level = 2

local title_extractors = {
	-- methods
	{ "(.-)%s*=%s*function%s*%(%s*self%s*%)", ":%1 ()" },
	{ "(.-)%s*=%s*function%s*%(%s*self%s*%,%s*(.-)%)", ":%1 (%2)" },

	-- functions
	{ "(.-)%s*=%s*function%s*%((.-)%)", ".%1 (%2)" },

	-- fields
	{ "(.-)%s*=", ".%1" },
}
local function extract_block_title(line)
	local title = line
	for _, ext in ipairs(title_extractors) do
		if line:match(ext[1]) then
			title = line:gsub(("^%s.-$"):format(ext[1]), ext[2])
			break
		end
	end
	return title
end

local function process(content)
	return content:gsub("{{(.-)}}", function(lua_file)
		local f = io.open(lua_file, "r")
		local c = f:read("a")
		f:close()

		local output = {}

		local comment_block
		local line_no = 1
		for line in c:gmatch("[^\n]*") do
			if line:match("^%s*%-%-%-") then
				comment_block = {}
				table.insert(comment_block, (line:match("^%s*%-%-%-%s?(.-)$")))
			elseif comment_block then
				if line:match("^%s*%-%-") then
					table.insert(comment_block, (line:match("^%s*%-%-%s?(.-)$")))
				else
					if line:match("[^%s]") then
						local ident, code = line:match("^(%s*)(.-)$")
						table.insert(comment_block, 1, ("%s %s\n"):format(
							("#"):rep(base_header_level+utf8.len(ident)),
							extract_block_title(code)
						))
						table.insert(comment_block, ("\n_defined at line %s of [%s](%s):_ `%s`"):format(line_no, lua_file, source_link_prefix..lua_file, code))
					end
					table.insert(comment_block, "")
					table.insert(output, table.concat(comment_block, "\n"))
					comment_block = nil
				end
			end
			line_no = line_no + 1
		end

		table.insert(output, ("\n---\n_file generated at %s_"):format(os.date("!%Y-%m-%dT%H:%M:%SZ")))

		return table.concat(output, "\n")
	end)
end

local function generate_file(input, output)
	local f = assert(io.open(input, "r"))
	local content = f:read("a")
	f:close()

	local out = process(content)
	f = assert(io.open(output, "w"))
	f:write(out)
	f:close()
end

for _, path in ipairs(files) do
	generate_file(path..".template", path)
end
