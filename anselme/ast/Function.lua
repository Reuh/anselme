-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("anselme.ast")
local ReturnBoundary, Identifier

local operator_priority = require("anselme.common").operator_priority

local resume_manager, calling_environment_manager

local Function
Function = ast.abstract.Overloadable {
	type = "function",

	parameters = nil, -- ParameterTuple
	expression = nil, -- function content
	scope = nil, -- Environment; captured scope for closure (evaluated functions); not set when not evaluated
	upvalues = nil, -- {variable metadata, ...}; not set when not evaluated. Contain _at least_ all the upvalues explicitely defined in the function code.

	init = function(self, parameters, expression, scope, upvalues)
		self.parameters = parameters
		self.expression = expression
		self.scope = scope
		self.upvalues = upvalues
		if self.scope then self._evaluated = true end
	end,
	with_return_boundary = function(self, parameters, expression)
		return Function:new(parameters, ReturnBoundary:new(expression))
	end,

	-- returns the same function, without the return boundary
	-- this does not create a new function scope
	without_return_boundary = function(self)
		if ReturnBoundary:is(self.expression) then
			return Function:new(self.parameters, self.expression.expression, self.scope, self.upvalues)
		else
			return self
		end
	end,

	_format = function(self, ...)
		if self.parameters.assignment then
			return "$"..self.parameters:format_short(...).."; "..self.expression:format_right(...)
		else
			return "$"..self.parameters:format_short(...).." "..self.expression:format_right(...)
		end
	end,
	_format_priority = function(self)
		return operator_priority["$_"]
	end,

	traverse = function(self, fn, ...)
		fn(self.parameters, ...)
		fn(self.expression, ...)
		if self.scope then
			fn(self.scope, ...)
		end
	end,

	_eval = function(self, state)
		-- layer a new scope layer on top of captured/current scope
		-- to allow future define in the function (fn.:var = "foo")
		state.scope:push()
		local scope = state.scope:capture() -- capture current scope to build closure
		state.scope:pop()

		-- list & cache upvalues so they aren't affected by future redefinition in a parent scope
		local used_identifiers = {}
		self.parameters:list_used_identifiers(used_identifiers)
		self.expression:list_used_identifiers(used_identifiers)
		if scope:defined(state, Identifier:new("_")) then
			scope:get(state, Identifier:new("_")):list_used_identifiers(used_identifiers)
		end
		local upvalues = {}
		for _, identifier in ipairs(used_identifiers) do
			local var = scope:precache(state, identifier)
			if var then table.insert(upvalues, var) end
		end

		return Function:new(self.parameters:eval(state), self.expression, scope, upvalues)
	end,

	compatible_with_arguments = function(self, state, args)
		return args:match_parameter_tuple(state, self.parameters)
	end,
	format_signature = function(self, state)
		return "$"..self.parameters:format_short(state)
	end,
	hash_signature = function(self)
		return self.parameters:hash()
	end,
	call_dispatched = function(self, state, args)
		assert(self._evaluated, "can't call unevaluated function")

		-- push captured closure scope
		local calling_environment = state.scope:capture()
		state.scope:push(self.scope)
		calling_environment_manager:push(state, calling_environment)

		-- push function scope
		state.scope:push()
		args:bind_parameter_tuple(state, self.parameters)
		local exp = self.expression:eval(state)
		state.scope:pop()

		calling_environment_manager:pop(state)
		state.scope:pop()
		return exp
	end,
	resume = function(self, state, target)
		if self.parameters.min_arity > 0 then error("can't resume function with parameters") end
		assert(self._evaluated, "can't resume unevaluated function")

		-- push captured closure scope
		local calling_environment = state.scope:capture()
		state.scope:push(self.scope)
		calling_environment_manager:push(state, calling_environment)

		-- push function scope
		state.scope:push()
		resume_manager:push(state, target)
		local exp = self.expression:eval(state)
		resume_manager:pop(state)
		state.scope:pop()

		calling_environment_manager:pop(state)
		state.scope:pop()
		return exp
	end,

	-- Note: when serializing and reloading a function, its upvalues will not be linked anymore to their original definition.
	-- The reloaded function will not be able to affect variables defined outside its body.
	-- Only the upvalues that explicitely appear in the function body and variables directly defined in the function scope will be saved, so we don't have to keep a full copy of the whole environment.
	_serialize = function(self)
		local state = require("anselme.serializer_state")
		return self.parameters, self.expression, self.scope.variables:to_struct(state), self.upvalues
	end,
	_deserialize = function(parameters, expression, variables, upvalues)
		local r = Function:new(parameters, expression):set_source("saved")
		r._deserialize_data = { variables = variables, upvalues = upvalues }
		return r
	end,
	-- we need variables to be fully deserialized before rebuild the function scope
	_post_deserialize = function(self, state, cache)
		if self._deserialize_data then
			local upvalues, variables = self._deserialize_data.upvalues, self._deserialize_data.variables
			self._deserialize_data = nil
			-- rebuild upvalues: exported + normal layer so any upvalue that happen to be exported stay there
			-- (and link again to global scope to allow internal vars that are not serialized to still work, like _translations)
			state.scope:push_global()
			state.scope:push_export()
			state.scope:push()
			self.upvalues = {}
			for _, var in ipairs(upvalues) do
				state.scope:define(var:get_symbol(), var:get(state))
				table.insert(self.upvalues, state.scope.current:precache(state, var:get_symbol():to_identifier()))
			end
			-- rebuild function variables
			state.scope:push()
			self.scope = state.scope:capture()
			for _, var in variables:iter() do
				self.scope:define(state, var:get_symbol(), var:get(state))
			end
			state.scope:pop()
			state.scope:pop()
			state.scope:pop()
			state.scope:pop()
			self._evaluated = true
		end
	end
}

package.loaded[...] = Function
ReturnBoundary, Identifier = ast.ReturnBoundary, ast.Identifier

resume_manager = require("anselme.state.resume_manager")
calling_environment_manager = require("anselme.state.calling_environment_manager")

return Function
