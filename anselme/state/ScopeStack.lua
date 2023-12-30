-- The current scope stack. One scope stack per State branch.
-- Only the scope currently on top of the stack will be used by the running script.

local class = require("anselme.lib.class")
local ast = require("anselme.ast")
local to_anselme = require("anselme.common.to_anselme")
local unpack = table.unpack or unpack

local LuaFunction, Environment, Node

local parameter_tuple = require("anselme.parser.expression.contextual.parameter_tuple")
local symbol = require("anselme.parser.expression.primary.symbol")

local ScopeStack = class {
	state = nil,

	stack = nil, -- stack of Environment
	current = nil, -- Environment

	initial_size = nil, -- number, size of the stack at creation (i.e. the "global" scopes only)

	init = function(self, state, branch_from_state)
		self.state = state
		self.stack = {}
		if branch_from_state then
			-- load existing environments from branched from state instead of creating new ones
			for _, env in ipairs(branch_from_state.scope.stack) do
				self:push(env)
			end
		else
			self:push_export() -- root scope is the global scope, stuff can be exported there
			self:push() -- for non-exported variables
		end
		self.initial_size = #self.stack
	end,

	-- store all changed variables back into the main branch
	merge = function(self)
		local cache = {}
		for _, env in ipairs(self.stack) do
			env:merge(self.state, cache)
		end
	end,

	-- helper to define stuff from lua easily in the current scope
	-- for lua functions: define_lua("name", "(x, y, z=5)", function(x, y, z) ... end), where arguments and return values of the function are automatically converted between anselme and lua values
	-- for other lua values: define_lua("name", value)
	-- for anselme AST: define_lua("name", value)
	-- name can be prefixed with symbol modifiers, for example ":name" for a constant variable
	-- if `raw_mode` is true, no anselme-to/from-lua conversion will be performed in the function
	-- the function will receive the state followed by AST nodes as arguments, and is expected to return an AST node
	define_lua = function(self, name, value, func, raw_mode)
		local source = require("anselme.parser.Source"):new()
		local sym = symbol:parse(source, (":%s"):format(name))
		if func then
			local parameters = parameter_tuple:parse(source, value)
			if not raw_mode then
				local original_func = func
				func = function(state, ...)
					local lua_args = {}
					for _, arg in ipairs{...} do
						table.insert(lua_args, arg:to_lua(state))
					end
					return to_anselme(original_func(unpack(lua_args)))
				end
			end
			self:define_overloadable(sym, LuaFunction:new(parameters, func):eval(self.state))
		elseif Node:issub(value) then
			self:define(sym, value)
		else
			self:define(sym, to_anselme(value))
		end
	end,

	-- methods that call the associated method from the current scope, see ast.Environment for details
	define = function(self, symbol, exp) self.current:define(self.state, symbol, exp) end,
	define_overloadable = function(self, symbol, exp) return self.current:define_overloadable(self.state, symbol, exp) end,
	defined = function(self, identifier) return self.current:defined(self.state, identifier) end,
	defined_in_current = function(self, symbol) return self.current:defined_in_current(self.state, symbol) end,
	set = function(self, identifier, exp) self.current:set(self.state, identifier, exp) end,
	get = function(self, identifier) return self.current:get(self.state, identifier)	end,
	get_symbol = function(self, identifier) return self.current:get_symbol(self.state, identifier)	end,
	depth = function(self) return self.current:depth() end,

	-- push new scope
	-- if environment is given, it will be used instead of creating a new children of the current environment
	push = function(self, environment)
		local env
		if environment then
			env = environment
		else
			env = Environment:new(self.state, self.current)
		end
		table.insert(self.stack, env)
		self.current = env
	end,
	-- push a partial layer on the current scope
	-- this is used to shadow or temporarly define specific variable in the current scope
	-- a partial layer is considered to be part of the current scope when looking up and defining variables, and any
	-- other variable will still be defined in the current scope
	-- ... is a list of identifiers
	-- (still use :pop to pop it though)
	push_partial = function(self, ...)
		local is_partial = {}
		for _, id in ipairs{...} do is_partial[id.name] = true end
		local env = Environment:new(self.state, self.current, is_partial)
		self:push(env)
	end,
	-- push an export layer on the current scope
	-- this is where any exported variable defined on this or children scope will end up being defined
	-- note: non-exported variables will not be defined in such a layer, make sure to add a normal layer on top as needed
	-- still need to be :pop'd
	push_export = function(self)
		local env = Environment:new(self.state, self.current, nil, true)
		self:push(env)
	end,
	-- push the global scope on top of the stack
	push_global = function(self)
		self:push(self.stack[self.initial_size])
	end,
	-- pop current scope
	pop = function(self)
		table.remove(self.stack)
		self.current = self.stack[#self.stack]
		assert(self.current, "popped the root scope!")
	end,
	-- get the size of the stack
	size = function(self)
		return #self.stack
	end,
	-- pop all the scopes until only n are left (by default, only keep the global scopes)
	reset = function(self, n)
		n = n or self.initial_size
		while self.stack[n+1] do
			self:pop()
		end
	end,

	-- return current environment, to use with :push later (mostly for closures)
	-- reminder: scopes are mutable
	capture = function(self)
		return self.current
	end,

	_debug_state = function(self, filter)
		filter = filter or ""
		local s = "current branch id: "..self.state.branch_id.."\n"
		return s .. table.concat(self.current:_debug_state(self.state, filter), "\n")
	end
}

package.loaded[...] = ScopeStack
LuaFunction, Environment, Node = ast.LuaFunction, ast.Environment, ast.abstract.Node

return ScopeStack
