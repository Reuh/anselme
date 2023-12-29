-- for nodes that can be put in an Overload

local ast = require("anselme.ast")

return ast.abstract.Node {
	type = "overloadable",
	init = false,

	-- return specificity (number>=0), secondary specificity (number >=0)
	-- return false, failure message (string)
	compatible_with_arguments = function(self, state, args)
		error("not implemented for "..self.type)
	end,

	-- return string
	format_parameters = function(self, state)
		return self:format(state)
	end,

	-- can be called either after a successful :dispatch or :compatible_with_arguments
	call_dispatched = function(self, state, args)
		error("not implemented for "..self.type)
	end,

	-- default for :dispatch
	dispatch = function(self, state, args)
		local s, err = self:compatible_with_arguments(state, args)
		if s then return self, args
		else return nil, err end
	end,
}
