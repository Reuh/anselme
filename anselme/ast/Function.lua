-- note: functions only appear in non-evaluated nodes! once evaluated, they always become closures

local ast = require("anselme.ast")
local Overloadable = ast.abstract.Overloadable
local ReturnBoundary, Environment, Identifier, Symbol

local operator_priority = require("anselme.common").operator_priority

local resume_manager, calling_environment_manager

local function list_cache_upvalues(v, state, list, scope)
	if Identifier:is(v) then
		list[v.name] = scope:precache(state, v)
	elseif Symbol:is(v) then
		list[v.string] = scope:precache(state, v:to_identifier())
	end
	v:traverse(list_cache_upvalues, state, list, scope)
end

local Function
Function = Overloadable {
	type = "function",

	parameters = nil, -- ParameterTuple
	expression = nil, -- function content
	scope = nil, -- Environment; captured scope for closure (evaluated functions); not set when not evaluated
	upvalues = nil, -- {[name]=variable metadata}; not set when not evaluated. Contain _at least_ all the upvalues explicitely defined in the function code.

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
		local upvalues = {}
		self.expression:traverse(list_cache_upvalues, state, upvalues, scope)
		if scope:defined(state, Identifier:new("_")) then
			scope:get(state, Identifier:new("_")):traverse(list_cache_upvalues, state, upvalues, scope)
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
		assert(self.scope, "can't call unevaluated function")

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
		assert(self.scope, "can't resume unevaluated function")

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
	-- Only the upvalues that explicitely appear in the function body will be saved, so we don't have to keep a copy of the whole environment.
	-- TODO: we should also store variables that have been defined in the function scope, even if they are not referred directly in the body
	_serialize = function(self)
		return { parameters = self.parameters, expression = self.expression, upvalues = self.upvalues }
	end,
	_deserialize = function(self)
		local state = require("anselme.serializer_state")
		local scope
		if self.upvalues then
			-- rebuild scope: exported + normal layer so any upvalue that happen to be exported stay there
			-- (and link again to current scope to allow internal vars that are not considered explicit upvalues to still work, like _translations)
			scope = Environment:new(state, Environment:new(state, state.scope:capture(), nil, true))
			for _, var in pairs(self.upvalues) do
				scope:define(state, var:get_symbol(), var:get(state))
			end
		end
		return Function:new(self.parameters, self.expression, Environment:new(state, scope), self.upvalues)
	end
}

package.loaded[...] = Function
ReturnBoundary, Environment, Identifier, Symbol = ast.ReturnBoundary, ast.Environment, ast.Identifier, ast.Symbol

resume_manager = require("anselme.state.resume_manager")
calling_environment_manager = require("anselme.state.calling_environment_manager")

return Function
