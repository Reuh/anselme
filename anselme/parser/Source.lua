local class = require("anselme.lib.class")
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
	increment_line = function(self, n, ...)
		self.line = self.line + n
	end,
	count = function(self, capture, ...)
		return capture, self:consume(capture, ...)
	end,
	consume = function(self, capture, ...)
		for _ in capture:gmatch(".-\n") do
			self.position = 1
			self:increment_line(1)
		end
		self:increment(utf8.len(capture:match("[^\n]*$")))
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
