-- LDoc doesn't like me so I don't like LDoc.
-- Behold! A documentation generator that doesn't try to be smart!
-- Call this from the root anselme repository directory: `lua doc/gendocs.lua`

local utf8 = utf8 or (love and require("utf8") or require("lua-utf8"))

local files = {
	"doc/api.md",
	"doc/server.md",
	"doc/standard_library.md"
}
local source_link_prefix = "../"
local base_header_level = 2

local function unescape(str)
	return str:gsub("\\(.)", "%1")
end

local title_extractors = {
	-- anselme luafunction definition
	{ "{?%s*\"(.-)\",%s*\"(.-)\",", function(name, params)
		name, params = unescape(name), unescape(params)
		-- assignment
		local assignment = ""
		if params:match("=[%w%s]+$") then
			params, assignment = params:match("^(.-)%s*=%s*([%w%s]+)%s*$")
			assignment = " = "..assignment
		end
		-- infix
		if name:match("^_[^%w]+_$") and params:match("^%(.-,.-%)$") then
			local left, right = params:match("^%(%s*(.-)%s*,%s*(.-)%s*%)$")
			return ("%s %s %s%s"):format(left, name:match("^_([^%w]+)_$"), right, assignment)
		-- suffix
		elseif name:match("^_[^%w]+$") and params:match("^%(.-%)$") then
			local left = params:match("^%(%s*(.-)%s*%)$")
			return ("%s %s%s"):format(left, name:match("^_([^%w]+)$"), assignment)
		-- prefix
		elseif name:match("^[^%w]+_$") and params:match("^%(.-%)$") then
			local right = params:match("^%(%s*(.-)%s*%)$")
			return ("%s %s%s"):format(name:match("^([^%w]+)_$"), right, assignment)
		end
		-- normal function
		return ("%s %s%s"):format(name, params, assignment)
	end },
	-- anselme field definition
	{ "{%s*\"(.-)\",", "%1"},

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

local valid_tags = { title = true, defer = true, titlelevel = true }
local function process(content)
	local deferred = {}
	local titlelevel

	-- process lua files
	local out = content:gsub("{{(.-)}}", function(lua_file)
		if not lua_file:match("^:") then
			local f = assert(io.open(lua_file, "r"))
			local c = f:read("a")
			f:close()

			local output = {}

			local comment_block
			local line_no = 1
			for line in c:gmatch("[^\n]*") do
				-- doc comment start
				if line:match("^%s*%-%-%-") then
					comment_block = {}
					table.insert(comment_block, (line:match("^%s*%-%-%-%s?(.-)$")))
				elseif comment_block then
					-- continue doc comment
					if line:match("^%s*%-%-") then
						local comment = line:match("^%s*%-%-%s?(.-)$")
						if comment:match("^%s*@") then
							local tag, data = comment:match("^%s*@%s*([^%s]*)%s*(.-)$")
							if valid_tags[tag] then comment_block[tag] = data
							else print(("[warning] unknown documentation tag @%s, at %s:%s"):format(tag, lua_file, line_no)) end
						else
							table.insert(comment_block, comment)
						end
					-- end doc comment
					else
						local detected_indent = 0
						if line:match("[^%s]") then
							local indent, code = line:match("^(%s*)(.-)$")
							detected_indent = utf8.len(indent)
							if not comment_block.title then comment_block.title = extract_block_title(code) end
							table.insert(comment_block, ("\n_defined at line %s of [%s](%s):_ `%s`"):format(line_no, lua_file, source_link_prefix..lua_file, code))
						end
						if comment_block.titlelevel then titlelevel = comment_block.titlelevel end
						if comment_block.title then
							local level = titlelevel or base_header_level+detected_indent
							table.insert(comment_block, 1, ("%s %s\n"):format(
								("#"):rep(level),
								comment_block.title
							))
						end
						table.insert(comment_block, "")
						local doc_block = table.concat(comment_block, "\n")
						if comment_block.defer then
							if not deferred[comment_block.defer] then deferred[comment_block.defer] = {} end
							table.insert(deferred[comment_block.defer], doc_block)
						else
							table.insert(output, doc_block)
						end
						comment_block = nil
					end
				end
				line_no = line_no + 1
			end

			return table.concat(output, "\n")
		end
	end)

	-- process deferred doc comments
	out = out:gsub("{{:(.-)}}", function(defer)
		if deferred[defer] then
			local output = table.concat(deferred[defer], "\n")
			deferred[defer] = nil
			return output
		else
			return ""
		end
	end)
	for k in pairs(deferred) do
		print("[warning] unused defer "..tostring(k))
	end

	return out .. ("\n---\n_file generated at %s_"):format(os.date("!%Y-%m-%dT%H:%M:%SZ"))
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
