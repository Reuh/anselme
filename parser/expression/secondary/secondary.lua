local class = require("class")

return class {
	new = false, -- static class

	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, str, limit_pattern, current_priority, operating_on_primary)
		if not self:match(str, current_priority, operating_on_primary) then
			return nil
		end
		return self:parse(source, str, limit_pattern, current_priority, operating_on_primary)
	end,
	-- return bool
	-- (not needed if you redefined :search)
	match = function(self, str, current_priority, operating_on_primary)
		return false
	end,
	-- return AST, rem
	-- (not needed if you redefined :search)
	-- assumes that :match was checked before, and can not return nil (may error though)
	parse = function(self, source, str, limit_pattern, current_priority, operating_on_primary)
		error("unimplemented")
	end,

	-- class helpers --

	-- return AST, rem
	expect = function(self, source, str, limit_pattern, current_priority, operating_on_primary)
		local exp, rem = self:search(source, str, limit_pattern, current_priority, operating_on_primary)
		if not exp then error(("expected %s but got %s"):format(self.type, str)) end
		return exp, rem
	end
}
