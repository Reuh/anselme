local ast = require("anselme.ast")
local String

local StringInterpolation = ast.abstract.Node {
	type = "string interpolation",

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
		return ("\"%s\""):format(table.concat(l))
	end,

	_eval = function(self, state)
		local t = {}
		for _, e in ipairs(self.list) do
			local r = e:eval(state)
			if String:is(e) then -- raw string
				r = e.string
			else -- interpolation
				r = e:format_custom(state)
			end
			table.insert(t, r)
		end
		return String:new(table.concat(t))
	end
}

package.loaded[...] = StringInterpolation
String = ast.String

return StringInterpolation
