local class = require("class")

return class {
	new = false, -- static class

	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, str, limit_pattern)
		if not self:match(str) then
			return nil
		end
		return self:parse(source, str, limit_pattern)
	end,
	-- return bool
	-- (not needed if you redefined :search)
	match = function(self, str)
		return false
	end,
	-- return AST, rem
	-- (not needed if you redefined :search)
	parse = function(self, source, str, limit_pattern)
		error("unimplemented")
	end,

	-- class helpers --

	-- return AST, rem
	expect = function(self, source, str, limit_pattern)
		local exp, rem = self:search(source, str, limit_pattern)
		if not exp then error(("expected %s but got %s"):format(self.type, str)) end
		return exp, rem
	end
}
