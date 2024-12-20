local ast = require("anselme.ast")
local Text, String

local tag_manager = require("anselme.state.tag_manager")

local TextInterpolation = ast.abstract.Node {
	type = "text interpolation",

	list = nil,

	init = function(self, ...)
		self.list = {...}
	end,
	insert = function(self, val) -- only for construction
		table.insert(self.list, val)
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.list) do
			fn(e, ...)
		end
	end,

	_format = function(self, state, prio, ...)
		local l = {}
		for _, e in ipairs(self.list) do
			if String:is(e) then
				local t = e.string:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\t", "\\t"):gsub("\"", "\\\"")
				table.insert(l, t)
			else
				table.insert(l, ("{%s}"):format(e:format(state, 0, ...)))
			end
		end
		return ("| %s |"):format(table.concat(l))
	end,

	_eval = function(self, state)
		local t = Text:new()
		local tags = tag_manager:get(state)
		for _, e in ipairs(self.list) do
			local r = e:eval(state)
			if String:is(e) then -- raw string
				t:insert(r, tags)
			elseif Text:is(r) then -- interpolation
				for _, v in ipairs(r.list) do
					t:insert(v[1], v[2])
				end
			else
				t:insert(String:new(r:format_custom(state)), tags)
			end
		end
		return t
	end,
}

package.loaded[...] = TextInterpolation
Text, String = ast.Text, ast.String

return TextInterpolation
