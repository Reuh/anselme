--- Contains all state relative to an Anselme interpreter. Each State is fully independant from each other.
-- Each State can run a single script at a time, and variable changes are isolated between each State (see [branching](#branching-and-merging)).

local class = require("anselme.lib.class")
local ScopeStack = require("anselme.state.ScopeStack")
local tag_manager = require("anselme.state.tag_manager")
local event_manager = require("anselme.state.event_manager")
local translation_manager = require("anselme.state.translation_manager")
local persistent_manager = require("anselme.state.persistent_manager")
local uuid = require("anselme.common").uuid
local parser = require("anselme.parser")
local binser = require("anselme.lib.binser")
local assert0 = require("anselme.common").assert0
local operator_priority = require("anselme.common").operator_priority
local anselme
local Identifier, Return, Node

local State
State = class {
	type = "anselme state",

	init = function(self, branch_from)
		-- create a new branch from an existing state
		-- note: the existing state must not currently have an active script
		if branch_from then
			self.branch_id = uuid()
			self.source_branch_id = branch_from.branch_id
			self.scope = ScopeStack:new(self, branch_from)

			event_manager:reset(self) -- events are isolated per branch
		-- create new empty state
		else
			self.scope = ScopeStack:new(self)

			event_manager:setup(self)
			tag_manager:setup(self)
			persistent_manager:setup(self)
			translation_manager:setup(self)
		end
	end,

	--- Load standard library.
	-- You will probably want to call this on every State right after creation.
	--
	-- Optionally, you can specify `language` (string) to instead load a translated version of the standaring library. Available translations:
	--
	-- * `"frFR"`
	load_stdlib = function(self, language)
		local stdlib = require("anselme.stdlib")
		if language then
			self.scope:push_export()
			self.scope:push()
			stdlib(self)
			self.scope:pop()
			local exported = self.scope:capture()
			self.scope:pop()
			-- redefine operators
			for name, var in exported.variables:iter(self) do
				if operator_priority[name.name] then
					self.scope:define(var:get_symbol(), var:get(self))
				end
			end
			-- load translated functions
			self.scope:push_partial(Identifier:new("stdlib"))
			self.scope:define(Identifier:new("stdlib"):to_symbol(), exported)
			parser(require("anselme.stdlib.language."..language), "stdlib/language/"..language..".ans"):eval(self)
			self.scope:pop()
		else
			stdlib(self)
		end
	end,

	---## Branching and merging

	--- Name of the branch associated to this State.
	branch_id = "main",
	--- Name of the branch this State was branched from.
	source_branch_id = "main",

	--- Return a new branch of this State.
	--
	-- Branches act as indepent copies of this State where any change will not be reflected in the source State until it is merged back into the source branch.
	-- Note: probably makes the most sense to create branches from the main State only.
	branch = function(self)
		assert(not self:active(), "can't branch while a script is active")
		return State:new(self)
	end,
	--- Merge everything that was changed in this branch back into the main State branch.
	--
	-- Recommendation: only merge if you know that the state of the variables is consistent, for example at the end of the script, checkpoints, ...
	-- If your script errored or was interrupted at an unknown point in the script, you might be in the middle of a calculation and variables won't contain
	-- values you want to merge.
	merge = function(self)
		self.scope:merge()
	end,

	---## Variable definition

	scope = nil, -- ScopeStack associated with the State. Contains *all* scopes related to this State.

	--- Define a value in the global scope, converting it from Lua to Anselme if needed.
	--
	-- * for lua functions: `define("name", "(x, y, z=5)", function(x, y, z) ... end)`, where arguments and return values of the function are automatically converted between anselme and lua values
	-- * for other lua values: `define("name", value)`
	-- * for anselme AST: `define("name", value)`
	--
	-- `name` can be prefixed with symbol modifiers, for example ":name" for a constant variable.
	--
	-- If `raw_mode` is true, no anselme-to/from-lua conversion will be performed in the function.
	-- The function will receive the state followed by AST nodes as arguments, and is expected to return an AST node.
	define = function(self, name, value, func, raw_mode)
		self.scope:push_global()
		self:define_local(name, value, func, raw_mode)
		self.scope:pop()
	end,
	--- Same as `:define`, but define the expression in the current scope.
	define_local = function(self, name, value, func, raw_mode)
		self.scope:define_lua(name, value, func, raw_mode)
	end,
	--- Returns true if `name` (string) is defined in the global scope.
	--- Returns false otherwise.
	defined = function(self, name)
		self.scope:push_global()
		local r = self:defined_local(name)
		self.scope:pop()
		return r
	end,
	--- Same as `:defined`, but check if the variable is defined in the current scope.
	defined_local = function(self, name)
		return self.scope:defined(Identifier:new(name))
	end,

	--- For anything more advanced, you can directly access the current scope stack stored in `state.scope`.
	-- See [state/ScopeStack.lua](../state/ScopeStack.lua) for details; the documentation is not as polished as this file but you should still be able to find your way around.

	---## Saving and loading persistent variables

	--- Return a serialized (string) representation of all persistent variables in this State.
	--
	-- This can be loaded back later using `:load`.
	save = function(self)
		local struct = persistent_manager:get_struct(self)
		return binser.serialize(anselme.versions.save) .. struct:serialize(self)
	end,
	--- Load a string generated by `:save`.
	--
	-- Variables that already exist will be overwritten with the loaded data.
	load = function(self, save)
		local version, nextindex = binser.deserializeN(save, 1)
		if version ~= anselme.versions.save then print("Loading a save file generated by a different Anselme version, things may break!") end
		local struct = Node:deserialize(self, save, nextindex)
		for key, val in struct:iter() do
			persistent_manager:set(self, key, val)
		end
	end,

	---## Current script state

	-- Currently active script
	_coroutine = nil,

	--- Indicate if a script is currently loaded in this branch.
	active = function(self)
		return not not self._coroutine
	end,
	--- Returns `"running`" if a script is currently loaded and running (i.e. this was called from the script).
	--
	-- Returns `"active"` if a script is loaded but not currently running (i.e. the script has not started or is waiting on an event).
	--
	-- Returns `"inactive"` if no script is loaded.
	state = function(self)
		if self:active() then
			return coroutine.status(self._coroutine) == "running" and "running" or "active"
		else
			return "inactive"
		end
	end,
	--- Load a script in this branch. It will become the active script.
	--
	-- `code` is the code string or AST to run. If `code` is a string, `source` is the source name string to show in errors (optional).
	--
	-- Note that this will only load the script; execution will only start by using the `:step` method. Will error if a script is already active in this State.
	run = function(self, code, source)
		assert(not self:active(), "a script is already active")
		self._coroutine = coroutine.create(function()
			local r = assert0(self:eval_local(code, source))
			event_manager:final_flush(self)
			if Return:is(r) then r = r.expression end
			return "return", r
		end)
	end,
	--- Same as `:run`, but read the code from a file.
	-- `source` will be set as the file path.
	run_file = function(self, path)
		local f = assert(io.open(path, "r"))
		local block = parser(f:read("a"), path)
		f:close()
		return self:run(block)
	end,
	--- When a script is active, will resume running it until the next event.
	--
	-- Will error if no script is active.
	--
	-- Returns `event type string, event data`.
	step = function(self)
		assert(self:active(), "trying to step but no script is currently active")
		local success, type, data = coroutine.resume(self._coroutine)
		if not success then
			self.scope:reset()
			type, data = "error", type
		end
		if self._coroutine and coroutine.status(self._coroutine) == "dead" then
			self._coroutine = nil
		end
		return type, data
	end,
	--- Stops the currently active script.
	--
	-- Will error if no script is active.
	--
	-- If `code` is given, the script will not be disabled but instead will be immediately replaced with this new script.
	-- The new script will then be started on the next `:step` and will preserve the current scope. This can be used to trigger an exit function or similar in the active script.
	--
	-- If this is called from within a running script, this will raise an `interrupt` event in order to stop the current script execution.
	interrupt = function(self, code, source)
		assert(self:active(), "trying to interrupt but no script is currently active")
		local called_from_script = self:state() == "running"
		if code then
			self._coroutine = coroutine.create(function()
				local r = assert0(self:eval_local(code, source))
				event_manager:final_flush(self)
				self.scope:reset() -- scope stack is probably messed up after the switch
				if Return:is(r) then r = r.expression end
				return "return", r
			end)
		else
			self.scope:reset()
			self._coroutine = nil
		end
		if called_from_script then coroutine.yield("interrupt") end
	end,

	--- Evaluate an expression in the global scope.
	--
	-- This can be called from outside a running script, but an error will be triggered the expression raise any event other than return.
	--
	-- * returns AST in case of success. Run `:to_lua(state)` on it to convert to a Lua value.
	-- * returns `nil, error message` in case of error.
	eval = function(self, code, source)
		self.scope:push_global()
		local r, e = self:eval_local(code, source)
		self.scope:pop()
		return r, e
	end,
	--- Same as `:eval`, but evaluate the expression in the current scope.
	eval_local = function(self, code, source)
		if type(code) == "string" then code = parser(code, source) end
		local stack_size = self.scope:size()
		local s, e = pcall(code.eval, code, self)
		if not s then
			self.scope:reset(stack_size)
			return nil, e
		else
			return e
		end
	end,
	--- If you want to perform more advanced manipulation of the resulting AST nodes, look at the `ast` modules.
	-- In particular, every Node inherits the methods from [ast.abstract.Node](../ast/abstract/Node.lua).
	-- Otherwise, each Node has its own module file defined in the [ast/](../ast) directory.

	__tostring = function(self)
		return ("anselme state, branch %s, %s"):format(self.branch_id, self:state())
	end
}

package.loaded[...] = State
anselme = require("anselme")
local ast = require("anselme.ast")
Identifier, Return, Node = ast.Identifier, ast.Return, ast.abstract.Node

return State
