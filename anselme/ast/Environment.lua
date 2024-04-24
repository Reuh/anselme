local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

local Branched, ArgumentTuple, Overload, Overloadable, Table, Undefined

local VariableMetadata = ast.abstract.Runtime {
	type = "variable metadata",

	symbol = nil,
	branched = nil,

	init = function(self, state, symbol, value)
		self.symbol = symbol
		self.branched = Branched:new(state, value)
	end,
	get = function(self, state)
		local v = self.branched:get(state)
		if self.symbol.alias then
			return v:call(state, ArgumentTuple:new())
		else
			v.from_symbol = self.symbol
			return v
		end
	end,
	undefined = function(self, state)
		local v = self.branched:get(state)
		return Undefined:is(v)
	end,
	get_symbol = function(self)
		return self.symbol
	end,
	set = function(self, state, value)
		if self.symbol.value_check then
			local r = self.symbol.value_check:call(state, ArgumentTuple:new(value))
			if not r:truthy() then error(("can not set %s = %s; %s value check failed"):format(self.symbol.string:format(state), value, self.symbol.value_check:format_short(state)), 0) end
		end
		if self.symbol.alias then
			local assign_args = ArgumentTuple:new()
			assign_args:add_assignment(value)
			self.branched:get(state):call(state, assign_args)
		else
			self.branched:set(state, value)
		end
	end,

	_format = function(self, ...)
		return ("%s=%s"):format(self.symbol:format(...), self.branched:format(...))
	end,
	_format_priority = function(self)
		return operator_priority["_=_"]
	end,

	traverse = function(self, fn, ...)
		fn(self.symbol, ...)
		fn(self.branched, ...)
	end,

	_merge = function(self, state, cache)
		if not self.symbol.confined_to_branch then
			self.branched:merge(state, cache)
		end
	end
}

local Environment = ast.abstract.Runtime {
	type = "environment",

	parent = nil, -- environment or nil
	variables = nil, -- Table of { {identifier} = variable metadata, ... }

	partial = nil, -- { [name string] = true, ... }
	export = nil, -- bool

	_lookup_cache = nil, -- Table of { [identifier] = variable metadata, ... }
	_lookup_cache_current = nil, -- Table of { [identifier] = variable metadata, ... }

	init = function(self, state, parent, partial_names, is_export)
		self.variables = Table:new(state)
		self.parent = parent
		self.partial = partial_names
		self.export = is_export
		self._lookup_cache = Table:new(state)
		self._lookup_cache_current = Table:new(state)
	end,
	-- precache variable and return its variable metadata
	-- when cached, if a variable is defined in a parent scope after it has been cached here from a higher parent, it will not be used in this env
	-- most of the time scopes are discarded after a pop so there's no possibility for this anyway, except for closures as they restore an old environment
	-- in which case we may want to precache variables that appear in the function so future definitions don't affect the closure
	precache = function(self, state, identifier)
		self:_lookup(state, identifier)
		self:_lookup_in_current(state, identifier:to_symbol())
		return self:_lookup(state, identifier)
	end,

	traverse = function(self, fn, ...)
		if self.parent then
			fn(self.parent, ...)
		end
		fn(self.variables, ...)
		fn(self._lookup_cache, ...)
		fn(self._lookup_cache_current, ...)
	end,
	_format = function(self, state)
		return "<environment>"
	end,

	-- define new variable in the environment
	define = function(self, state, symbol, exp)
		local name = symbol.string
		if self:defined_in_current(state, symbol) then
			error(name.." is already defined in the current scope", 0)
		end
		if (self.partial and not self.partial[name])
			or (self.export ~= symbol.exported) then
			return self.parent:define(state, symbol, exp)
		end
		local variable = VariableMetadata:new(state, symbol, exp)
		local identifier = symbol:to_identifier()
		self.variables:set(state, identifier, variable)
		self._lookup_cache:set(state, identifier, variable)
		self._lookup_cache_current:set(state, identifier, variable)
	end,
	-- define or redefine new overloadable variable in current environment, inheriting existing overload variants from (parent) scopes
	define_overloadable = function(self, state, symbol, exp)
		assert(Overloadable:issub(exp) or Overload:is(exp), "trying to add an non-overloadable value to an overload")

		local identifier = symbol:to_identifier()

		-- add overload variants already defined in current or parent scope
		if self:defined(state, identifier) then
			local val = self:get(state, identifier)
			if Overload:is(val) then
				exp = Overload:new(exp)
				for _, v in ipairs(val.list) do
					exp:insert(v)
				end
			elseif Overloadable:issub(val) then
				exp = Overload:new(exp, val)
			elseif self:defined_in_current(state, symbol) then
				error(("can't add an overload variant to non-overloadable variable %s defined in the same scope"):format(identifier), 0)
			end
		end

		-- update/define in current scope
		if self:defined_in_current(state, symbol) then
			self:set(state, identifier, exp)
		else
			self:define(state, symbol, exp)
		end
	end,

	-- lookup variable in current or parent scope, cache the result
	-- returns nil if undefined
	_lookup = function(self, state, identifier)
		local _cache = self._lookup_cache
		local var = _cache:get_strict(state, identifier)
		if not var then
			if self.variables:has(state, identifier) then
				var = self.variables:get(state, identifier)
			elseif self.parent then
				var = self.parent:_lookup(state, identifier)
			end
			if var then _cache:set(state, identifier, var) end
		end
		if var and not var:undefined(state) then
			return var
		end
	end,
	-- lookup variable in current scope, cache the result
	-- returns nil if undefined
	_lookup_in_current = function(self, state, symbol)
		local identifier = symbol:to_identifier()
		local _cache = self._lookup_cache_current
		local var = _cache:get_strict(state, identifier)
		if not var then
			local name = symbol.string
			if self.variables:has(state, identifier) then
				var = self.variables:get(state, identifier)
			elseif self.parent then
				if (self.partial and not self.partial[name]) or (self.export ~= symbol.exported) then
					var = self.parent:_lookup_in_current(state, symbol)
				end
			end
			if var then _cache:set(state, identifier, var) end
		end
		if var and not var:undefined(state) then
			return var
		end
	end,

	-- returns bool if variable defined in current or parent environment
	defined = function(self, state, identifier)
		return self:_lookup(state, identifier) ~= nil
	end,
	-- returns bool if variable defined in current environment layer
	-- (note: by current layer, we mean the closest one where the variable is able to exist - if it is exported, the closest export layer, etc.)
	defined_in_current = function(self, state, symbol)
		return self:_lookup_in_current(state, symbol) ~= nil
	end,

	-- get variable in current or parent scope, with metadata
	_get_variable = function(self, state, identifier)
		if self:defined(state, identifier) then
			return self:_lookup(state, identifier)
		else
			error(("identifier %q is undefined in branch %s"):format(identifier.name, state.branch_id), 0)
		end
	end,
	-- get variable value in current or parent environment
	get = function(self, state, identifier)
		return self:_get_variable(state, identifier):get(state)
	end,
	-- get the symbol that was used to define the variable in current or parent environment
	get_symbol = function(self, state, identifier)
		return self:_get_variable(state, identifier):get_symbol()
	end,
	-- set variable value in current or parent environment
	set = function(self, state, identifier, val)
		return self:_get_variable(state, identifier):set(state, val)
	end,

	-- return the depth of the environmenet, i.e. the number of parents
	depth = function(self)
		local d = 0
		local e = self
		while e.parent do
			e = e.parent
			if not (e.partial or e.export) then -- only count full layers
				d = d + 1
			end
		end
		return d
	end,

	_debug_state = function(self, state, filter, t, level)
		level = level or 0
		t = t or {}

		local indentation = string.rep(" ", level)
		table.insert(t, ("%s> %s %s scope"):format(indentation, self.export and "exported" or "", self.partial and "partial" or ""))

		for name, var in self.variables:iter(state) do
			if name.name:match(filter) then
				table.insert(t, ("%s| %s = %s"):format(indentation, name, var:get(state)))
			end
		end
		if self.parent then
			self.parent:_debug_state(state, filter, t, level+1)
		end
		return t
	end,
}

package.loaded[...] = Environment
Branched, ArgumentTuple, Overload, Overloadable, Table, Undefined = ast.Branched, ast.ArgumentTuple, ast.Overload, ast.abstract.Overloadable, ast.Table, ast.Undefined

return Environment
