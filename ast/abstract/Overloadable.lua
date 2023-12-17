local ast = require("ast")

return ast.abstract.Node {
	type = "overloadable",
	init = false,

	-- return specificity (number>=0), secondary specificity (number >=0)
	-- return false, failure message (string)
	compatible_with_arguments = function(self, state, args)
		error("not implemented for "..self.type)
	end,
	-- same as :call, but assumes :compatible_with_arguments was checked before the call
	call_compatible = function(self, state, args)
		error("not implemented for "..self.type)
	end,

	-- return string
	format_parameters = function(self, state)
		return self:format(state)
	end,

	-- default for :call
	call = function(self, state, args)
		assert(self:compatible_with_arguments(state, args))
		return self:call_compatible(state, args)
	end
}
