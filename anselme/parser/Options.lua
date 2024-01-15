local class = require("anselme.lib.class")

local options = { "limit_pattern", "allow_newlines" }

local Options
Options = class {
	limit_pattern = nil,
	allow_newlines = false,

	with = function(self, t)
		local r = Options:new()
		for _, opt in ipairs(options) do
			if t[opt] ~= nil then
				r[opt] = t[opt]
			else
				r[opt] = self[opt]
			end
		end
		return r
	end
}

return Options
