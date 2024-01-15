local class = require("anselme.lib.class")

return class {
	new = false, -- static class

	-- returns exp, rem if expression found
	-- returns nil if no expression found
	search = function(self, source, options, str)
		if not self:match(str) then
			return nil
		end
		return self:parse(source, options, str)
	end,
	-- return bool
	-- (not needed if you redefined :search)
	match = function(self, str)
		return false
	end,
	-- return AST, rem
	-- (not needed if you redefined :search)
	parse = function(self, source, options, str)
		error("unimplemented")
	end,

	-- class helpers --

	-- return AST, rem
	expect = function(self, source, options, str)
		local exp, rem = self:search(source, options, str)
		if not exp then error(("expected %s but got %s"):format(self.type, str)) end
		return exp, rem
	end
}
