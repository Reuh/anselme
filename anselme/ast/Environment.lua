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
		if self.symbol.constant then
			error(("trying to change the value of constant %s"):format(self.symbol.string), 0)
		end
		if self.symbol.type_check then
			local r = self.symbol.type_check:call(state, ArgumentTuple:new(value))
			if not r:truthy() then error(("type check failure for %s; %s does not satisfy %s"):format(self.symbol.string, value, self.symbol.type_check), 0) end
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

	_lookup_cache = nil, -- { [name string] = variable metadata, ... }
	_lookup_cache_current = nil, -- { [name string] = variable metadata, ... }

	init = function(self, state, parent, partial_names, is_export)
		self.variables = Table:new(state)
		self.parent = parent
		self.partial = partial_names
		self.export = is_export
		self._lookup_cache = {}
		self._lookup_cache_current = {}
	end,
	-- precache variable
	-- when cached, if a variable is defined in a parent scope after it has been cached here from a higher parent, it will not be used in this env
	-- most of the time scopes are discarded after a pop so there's no possibility for this anyway, except for closures as they restore an old environment
	-- in which case we may want to precache variables that appear in the function so future definitions don't affect the closure
	precache = function(self, state, identifier)
		self:_lookup(state, identifier)
		self:_lookup_in_current(state, identifier:to_symbol())
	end,

	traverse = function(self, fn, ...)
		if self.parent then
			fn(self.parent, ...)
		end
		fn(self.variables, ...)
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
		self.variables:set(state, symbol:to_identifier(), variable)
		self._lookup_cache[name] = variable
		self._lookup_cache_current[name] = variable
	end,
	-- define or redefine new overloadable variable in current environment, inheriting existing overload variants from (parent) scopes
	define_overloadable = function(self, state, symbol, exp)
		assert(Overloadable:issub(exp), "trying to add an non-overloadable value to an overload")

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
	_lookup = function(self, state, identifier)
		local name = identifier.name
		local _cache = self._lookup_cache
		if _cache[name] == nil then
			if self.variables:has(state, identifier) then
				_cache[name] = self.variables:get(state, identifier)
			elseif self.parent then
				_cache[name] = self.parent:_lookup(state, identifier)
			end
		end
		local var = _cache[name]
		if var and not var:undefined(state) then
			return var
		end
		return nil
	end,
	_lookup_in_current = function(self, state, symbol)
		local name = symbol.string
		local _cache = self._lookup_cache_current
		if _cache[name] == nil then
			local identifier = symbol:to_identifier()
			if self.variables:has(state, identifier) then
				_cache[name] = self.variables:get(state, identifier)
			elseif self.parent then
				if (self.partial and not self.partial[name]) or (self.export ~= symbol.exported) then
					_cache[name] = self.parent:_lookup_in_current(state, symbol)
				end
			end
		end
		local var = _cache[name]
		if var and not var:undefined(state) then
			return var
		end
		return nil
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
	-- return bool if variable is defined in the current environment only - won't search in parent env for exported & partial names
	defined_in_current_strict = function(self, state, identifier)
		return self.variables:has(state, identifier) and not self.variables:get(state, identifier):undefined(state)
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
			d = d + 1
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
