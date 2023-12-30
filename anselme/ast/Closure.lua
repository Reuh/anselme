-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("anselme.ast")
local Overloadable, Runtime = ast.abstract.Overloadable, ast.abstract.Runtime
local Definition

local resume_manager

local Closure
Closure = Runtime(Overloadable) {
	type = "closure",

	func = nil, -- Function
	scope = nil, -- Environment
	exported_scope = nil, -- Environment

	init = function(self, func, state)
		self.func = func
		self.scope = state.scope:capture()

		-- layer a new export layer on top of captured/current scope
		state.scope:push_export()
		self.exported_scope = state.scope:capture()

		-- pre-define exports
		for _, target in pairs(self:list_resume_targets()) do
			if Definition:is(target) and target.symbol.exported then
				resume_manager:push_no_continue(state, target)
				state.scope:push() -- create temp func scope, in case non-export definitions are done in the resume
				self.func.expression:eval(state)
				state.scope:pop()
				resume_manager:pop(state)
			end
		end

		state.scope:pop()
	end,

	_format = function(self, ...)
		return self.func:format(...)
	end,

	traverse = function(self, fn, ...)
		fn(self.func, ...)
		fn(self.scope, ...)
		fn(self.exported_scope, ...)
	end,

	compatible_with_arguments = function(self, state, args)
		return args:match_parameter_tuple(state, self.func.parameters)
	end,
	format_parameters = function(self, state)
		return self.func.parameters:format(state)
	end,
	call_dispatched = function(self, state, args)
		state.scope:push(self.exported_scope)
		local exp = self.func:call_dispatched(state, args)
		state.scope:pop()
		return exp
	end,
}

package.loaded[...] = Closure
Definition = ast.Definition
resume_manager = require("anselme.state.resume_manager")

return Closure
