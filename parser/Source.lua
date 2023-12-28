local class = require("class")
local utf8 = utf8 or require("lua-utf8")

local Source
Source = class {
	name = "?",
	line = -1,
	position = -1,

	init = function(self, name, line, position)
		self.name = name
		self.line = line
		self.position = position
	end,
	increment = function(self, n, ...)
		self.position = self.position + n
	end,
	count = function(self, capture, ...)
		self:increment(utf8.len(capture))
		return capture, ...
	end,
	consume = function(self, capture, ...)
		self:increment(utf8.len(capture))
		return ...
	end,

	clone = function(self)
		return Source:new(self.name, self.line, self.position)
	end,
	set = function(self, other)
		self.name, self.line, self.position = other.name, other.line, other.position
	end,

	__tostring = function(self)
		return ("%s:%s:%s"):format(self.name, self.line, self.position)
	end
}

return Source
