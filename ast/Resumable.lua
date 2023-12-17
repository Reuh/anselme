local ast = require("ast")
local Table

local resumable_manager

local Resumable
Resumable = ast.abstract.Runtime {
	type = "resumable",

	resuming = false,

	expression = nil,
	scope = nil,
	data = nil,

	init = function(self, state, expression, scope, data)
		self.expression = expression
		self.scope = scope
		self.data = data or Table:new(state)
	end,

	_format = function(self)
		return "<resumable>"
	end,

	traverse = function(self, fn, ...)
		fn(self.expression, ...)
		fn(self.data, ...)
		fn(self.scope, ...)
	end,

	-- returns a copy with the data copied
	capture = function(self, state)
		return Resumable:new(state, self.expression, self.scope, self.data:copy(state))
	end,

	-- resume from this resumable
	call = function(self, state, args)
		assert(args.arity == 0, "Resumable! does not accept arguments")

		state.scope:push(self.scope)

		local resuming = self:capture(state)
		resuming.resuming = true
		resumable_manager:push(state, resuming)
		local r = self.expression:eval(state)
		resumable_manager:pop(state)

		state.scope:pop()

		return r
	end,
}

package.loaded[...] = Resumable
Table = ast.Table

resumable_manager = require("state.resumable_manager")

return Resumable
