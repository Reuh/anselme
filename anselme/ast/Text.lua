local ast = require("anselme.ast")
local Event, Runtime = ast.abstract.Event, ast.abstract.Runtime
local ArgumentTuple

local Text = Runtime(Event) {
	type = "text",

	list = nil, -- { { String, tag Table }, ... }

	init = function(self)
		self.list = {}
	end,
	insert = function(self, str, tags) -- only for construction
		table.insert(self.list, { str, tags })
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.list) do
			fn(e[1], ...)
			fn(e[2], ...)
		end
	end,

	_format = function(self, ...)
		local t = {}
		for _, e in ipairs(self.list) do
			table.insert(t, ("%s%s"):format(e[2]:format(...), e[1]:format(...)))
		end
		return ("| %s |"):format(table.concat(t, " "))
	end,

	-- autocall when used directly as a statement
	eval_statement = function(self, state)
		return self:call(state, ArgumentTuple:new())
	end,

	-- Text comes from TextInterpolation which already evals the contents

	to_event_data = function(self)
		return self
	end
}

package.loaded[...] = Text
ArgumentTuple = ast.ArgumentTuple

return Text
