--- anselme main module

--- Anselme Lua API reference
--
-- We actively support LuaJIT and Lua 5.4. Lua 5.1, 5.2 and 5.3 *should* work but I don't always test against them.
--
-- This documentation is generated from the main module file `anselme.lua` using `ldoc --ext md anselme.lua`.
--
-- Example usage:
-- ```lua
-- local anselme = require("anselme") -- load main module
--
-- local vm = anselme() -- create new VM
-- vm:loadgame("game") -- load some scripts, etc.
-- local interpreter = vm:rungame() -- create a new interpreter using what was loaded with :loadgame
--
-- -- simple function to convert text event data into a string
-- -- in your game you may want to handle tags, here we ignore them for simplicity
-- local function format_text(text)
--   local r = ""
--   for _, l in ipairs(t) do
--     r = r .. l.text
--   end
--   return r
-- end
--
-- -- event loop
-- repeat
--   local event, data = interpreter:step() -- progress script until next event
--   if event == "text" then
--     print(format_text(d))
--   elseif event == "choice" then
--     for j, choice in ipairs(d) do
--       print(j.."> "..format_text(choice))
--     end
--     interpreter:choose(io.read())
--   elseif event == "error" then
--     error(data)
--   end
-- until t == "return" or t == "error"
-- ```
--
-- Calling the Anselme main module will create a return a new [VM](#vms).
--
-- The main module also contain a few fields:
--
-- @type anselme
local anselme = {
	--- Anselme version information table.
	--
	-- Contains version informations as number (higher means more recent) of Anselme divied in a few categories:
	--
	-- * `save`, which is incremented at each update which may break save compatibility
	-- * `language`, which is incremented at each update which may break script file compatibility
	-- * `api`, which is incremented at each update which may break Lua API compatibility
	versions = {
		save = 1,
		language = 22,
		api = 5
	},
	--- General version number.
	--
	-- It is incremented at each update.
	version = 23,
	--- Currently running [interpreter](#interpreters).
	-- `nil` if no interpreter running.
	running = nil
}
package.loaded[...] = anselme

-- load libs
local anselme_root = (...):gsub("anselme$", "")
local preparse = require(anselme_root.."parser.preparser")
local postparse = require(anselme_root.."parser.postparser")
local expression = require(anselme_root.."parser.expression")
local eval = require(anselme_root.."interpreter.expression")
local injections = require(anselme_root.."parser.common").injections
local run_line = require(anselme_root.."interpreter.interpreter").run_line
local run = require(anselme_root.."interpreter.interpreter").run
local to_lua = require(anselme_root.."interpreter.common").to_lua
local merge_state = require(anselme_root.."interpreter.common").merge_state
local stdfuncs = require(anselme_root.."stdlib.functions")
local bootscript = require(anselme_root.."stdlib.bootscript")
local copy = require(anselme_root.."common").copy
local should_keep_variable = require(anselme_root.."interpreter.common").should_keep_variable

-- wrappers for love.filesystem / luafilesystem
local function list_directory(path)
	local t = {}
	if love then
		t = love.filesystem.getDirectoryItems(path)
	else
		local lfs = require("lfs")
		for item in lfs.dir(path) do
			table.insert(t, item)
		end
	end
	return t
end
local function is_directory(path)
	if love then
		return not not love.filesystem.getInfo(path, "directory")
	else
		local lfs = require("lfs")
		return lfs.attributes(path, "mode") == "directory"
	end
end
local function is_file(path)
	if love then
		return not not love.filesystem.getInfo(path, "file")
	else
		local lfs = require("lfs")
		return lfs.attributes(path, "mode") == "file"
	end
end

--- Interpreters
--
-- An interpreter is in charge of running Anselme code and is spawned from a [VM](#vms).
-- Several interpreters from the same VM can run at the same time.
--
-- Typically, you would have a interpreter for each script that need at the same time, for example one for every NPC
-- that is currently talking.
--
-- Each interpreter can only run one script at a time, and will run it sequentially.
-- You can advance in the script by calling the `:step` method, which will run the script until an event is sent (for example some text needs to be displayed),
-- which will pause the whole interpreter until `:step` is called again.
--
-- @type interpreter
local interpreter_methods = {
	--- interpreter state
	-- for internal use, you shouldn't touch this
	-- @local
	state = nil,
	--- [VM](#vms) this interpreter belongs to.
	vm = nil,
	--- String, type of the event that stopped the interpreter (`nil` if interpreter is still running).
	end_event = nil,

	--- Run the interpreter until the next event.
	-- Returns event type (string), data (any).
	--
	-- Will merge changed variables on successful script end.
	--
	-- If event is `"return"` or `"error"`, the interpreter can not be stepped further and should be discarded.
	--
	-- Default event types and their associated data:
	-- * `text`: text to display, data is a list of text elements, each with a `text` field, containing the text contents, and a `tags` field, containing the tags associated with this text
	-- * `choice`: choices to choose from, data is a list of choices Each of these choice is a list of text elements like for the `text` event
	-- * `return`: when the script ends, data is the returned value (`nil` if nothing returned)
	-- * `error`: when there is an error, data is the error message.
	--
	-- See [LANGUAGE.md](LANGUAGE.md) for more details on events.
	step = function(self)
		-- check status
		if self.end_event then
			return "error", ("interpreter can't be restarted after receiving a %s event"):format(self.end_event)
		end
		if coroutine.status(self.state.interpreter.coroutine) ~= "suspended" then
			return "error", ("can't step interpreter because it has already finished or is already running (coroutine status: %s)"):format(coroutine.status(self.state.interpreter.coroutine))
		end
		-- handle interrupt
		if self.state.interpreter.interrupt then
			local expr = self.state.interpreter.interrupt
			if expr == true then
				return "return", "" -- nothing to do after interrupt
			else
				local line = self.state.interpreter.running_line
				local namespace = self:current_namespace()
				-- replace state with interrupted state
				local exp, err = expression(expr, self.state.interpreter.global_state, namespace or "")
				if not exp then return "error", ("%s; during interrupt %q at %s"):format(err, expr, line and line.source or "unknown") end
				local r, e = self.vm:run(exp)
				if not r then return "error", e end
				self.state = r.state
			end
		end
		-- run
		local previous = anselme.running
		anselme.running = self
		local success, event, data = coroutine.resume(self.state.interpreter.coroutine)
		anselme.running = previous
		if not success then event, data = "error", event end
		if event == "return" then merge_state(self.state) end
		if event == "return" or event == "error" then self.end_event = event end
		return event, data
	end,

	--- Select a choice.
	-- `i` is the index (number) of the choice in the choice list (from the choice event's data).
	--
	-- The choice will be selected on the next interpreter step.
	--
	-- Returns this interpreter.
	choose = function(self, i)
		self.state.interpreter.choice_selected = tonumber(i)
		return self
	end,

	--- Interrupt (abort the currently running script) the interpreter on the next step, executing an expression (string, if specified) in the current namespace instead.
	--
	-- Returns this interpreter.
	interrupt = function(self, expr)
		self.state.interpreter.interrupt = expr or true
		return self
	end,

	--- Returns the namespace (string) the last ran line belongs to.
	current_namespace = function(self)
		local line = self.state.interpreter.running_line
		local namespace = ""
		if line then
			local cur_line = line
			namespace = cur_line.namespace
			while not namespace do
				local block = cur_line.parent_block
				if not block.parent_line then break end -- reached root
				cur_line = block.parent_line
				namespace = cur_line.namespace
			end
		end
		return namespace
	end,

	--- Run an expression (string) or block, optionally in a specific namespace (string, will use root namespace if not specified).
	-- This may trigger events and must be called from within the interpreter coroutine (i.e. from a function called from a running script).
	--
	-- No automatic merge if this change the interpreter state, merge is done once we reach end of script in a call to `:step` as usual.
	--
	-- Returns the returned value (nil if nothing returned).
	run = function(self, expr, namespace)
		-- check status
		if coroutine.status(self.state.interpreter.coroutine) ~= "running" then
			error("run must be called from whithin the interpreter coroutine")
		end
		-- parse
		local err
		if type(expr) ~= "table" then expr, err = expression(tostring(expr), self.state.interpreter.global_state, namespace or "") end
		if not expr then coroutine.yield("error", err) end
		-- run
		local r, e
		if expr.type == "block" then
			r, e = run(self.state, expr)
		else
			r, e = eval(self.state, expr)
		end
		if not r then coroutine.yield("error", e) end
		if self.state.interpreter.current_event then -- flush final events
			local rf, re = run_line(self.state, { type = "flush_events" })
			if re then coroutine.yield("error", re) end
			if rf then r = rf end
		end
		return to_lua(r)
	end,
	--- Evaluate an expression (string) or block, optionally in a specific namespace (string, will use root namespace if not specified).
	-- The expression can't yield events.
	-- Can be called from outside the interpreter coroutine. Will create a new coroutine that operate on this interpreter state.
	--
	-- No automatic merge if this change the interpreter state, merge is done once we reach end of script in a call to `:step` as usual.
	--
	-- Returns the returned value in case of success (nil if nothing returned).
	--
	-- Returns nil, error message in case of error.
	eval = function(self, expr, namespace)
		if self.end_event then
			return "error", ("interpreter can't be restarted after receiving a %s event"):format(self.end_event)
		end
		-- parse
		local err
		if type(expr) ~= "table" then expr, err = expression(tostring(expr), self.state.interpreter.global_state, namespace or "") end
		if not expr then return nil, err end
		-- run
		local co = coroutine.create(function()
			local r, e
			if expr.type == "block" then
				r, e = run(self.state, expr)
			else
				r, e = eval(self.state, expr)
			end
			if not r then return "error", e end
			return "return", r
		end)
		local previous = anselme.running
		anselme.running = self
		local success, event, data = coroutine.resume(co)
		anselme.running = previous
		if not success then
			return nil, event
		elseif event == "error" then
			self.end_event = "error"
			return nil, data
		elseif event ~= "return" then
			return nil, ("evaluated expression generated an %q event; at %s"):format(event, self.state.interpreter.running_line.source)
		else
			return to_lua(data)
		end
	end,
}
interpreter_methods.__index = interpreter_methods

--- VMs
--
-- A VM stores the state required to run Anselme scripts. Each VM is completely independant from each other.
--
-- @type vm
local vm_mt = {
	--- anselme state
	-- for internal use, you shouldn't touch this
	-- @local
	state = nil,

	--- loaded game state
	-- for internal use, you shouldn't touch this
	-- @local
	game = nil,

	--- Wrapper for loading a whole set of scripts (a "game").
	-- Should be preferred to other loading functions if possible as this sets all the common options on its own.
	--
	-- Requires LÖVE or LuaFileSystem.
	--
	-- Will load from the directory given by `path` (string), in order:
	-- * `config.ans`, which will be executed in the "config" namespace and may contains various optional configuration options:
	--   * `anselme version`: number, version of the anselme language this game was made for
	--   * `game version`: any, version information of the game. Can be used to perform eventual migration of save with an old version in the main file.
	--                        Always included in saved variables.
	--   * `language`: string, built-in language file to load
	--   * `inject directory`: string, directory that may contain "function start.ans", "checkpoint end.ans", etc. which content will be used to setup
	--                       the custom code injection methods (see vm:setinjection)
	--   * `global directory`: string, path of global script directory. Every script file and subdirectory in the path will be loaded in the global namespace.
	--   * `start expression`: string, expression that will be ran when starting the game
	-- * files in the global directory, if defined in config.ans
	-- * every other file in the path and subdirectories, using their path as namespace (i.e., contents of path/world1/john.ans will be defined in a function world1.john)
	--
	-- Returns this VM in case of success.
	--
	-- Returns nil, error message in case of error.
	loadgame = function(self, path)
		if self.game then error("game already loaded") end
		-- load config
		if is_file(path.."/config.ans") then
			local s, e = self:loadfile(path.."/config.ans", "config")
			if not s then return s, e end
			s, e = self:eval("config")
			if e then return s, e end
		end
		-- get config
		self.game = {
			anselme_version = self:eval("config.anselme version"),
			game_version = self:eval("config.game version"),
			language = self:eval("config.language"),
			inject_directory = self:eval("config.inject directory"),
			global_directory = self:eval("config.global directory"),
			start_expression = self:eval("config.start expression")
		}
		-- check language version
		if self.game.anselme_version and self.game.anselme_version ~= anselme.versions.language then
			return nil, ("trying to load game made for Anselme language %s, but currently using version %s"):format(self.game.anselme_version, anselme.versions.language)
		end
		-- load language
		if self.game.language then
			local s, e = self:loadlanguage(self.game.language)
			if not s then return s, e end
		end
		-- load injections
		if self.game.inject_directory then
			for inject, ninject in pairs(injections) do
				local f = io.open(path.."/"..self.game.inject_directory.."/"..inject..".ans", "r")
				if f then
					self.state.inject[ninject] = f:read("*a")
					f:close()
				end
			end
		end
		-- load global scripts
		for _, item in ipairs(list_directory(path.."/"..self.game.global_directory)) do
			if item:match("[^%.]") then
				local p = path.."/"..self.game.global_directory.."/"..item
				local s, e
				if is_directory(p) then
					s, e = self:loaddirectory(p)
				elseif item:match("%.ans$") then
					s, e = self:loadfile(p)
				end
				if not s then return s, e end
			end
		end
		-- load other files
		for _, item in ipairs(list_directory(path)) do
			if item:match("[^%.]") and
				item ~= "config.ans" and
				item ~= self.game.global_directory and
				item ~= self.game.inject_directory
			then
				local p = path.."/"..item
				local s, e
				if is_directory(p) then
					s, e = self:loaddirectory(p, item)
				elseif item:match("%.ans$") then
					s, e = self:loadfile(p, item:gsub("%.ans$", ""))
				end
				if not s then return s, e end
			end
		end
		return self
	end,
	--- Return a interpreter which runs the game start expression (if given).
	--
	-- Returns interpreter in case of success.
	--
	-- Returns nil, error message in case of error.
	rungame = function(self)
		if not self.game then error("no game loaded") end
		if self.game.start_expression then
			return self:run(self.game.start_expression)
		else
			return self:run("()")
		end
	end,

	--- Load code from a string.
	-- Similar to Lua's code loading functions.
	--
	-- Compared to their Lua equivalents, these also take an optional `name` argument (default="") that set the namespace to load the code in. Will define a new function is specified; otherwise, code will be parsed but not executable from an expression (as it is not named).
	--
	-- Returns parsed block in case of success.
	--
	-- Returns nil, error message in case of error.
	loadstring = function(self, str, name, source)
		local s, e = preparse(self.state, str, name or "", source)
		if not s then return s, e end
		return s
	end,
	--- Load code from a file.
	-- See `vm:loadstring`.
	loadfile = function(self, path, name)
		local content
		if love then
			local e
			content, e = love.filesystem.read(path)
			if not content then return content, e end
		else
			local f, e = io.open(path, "r")
			if not f then return f, e end
			content = f:read("*a")
			f:close()
		end
		local s, err = self:loadstring(content, name, path)
		if not s then return s, err end
		return s
	end,
	-- Load every file in a directory, using filename (without .ans extension) as its namespace.
	--
	-- Requires LÖVE or LuaFileSystem.
	--
	-- Returns this VM in case of success.
	--
	-- Returns nil, error message in case of error.
	loaddirectory = function(self, path, name)
		if not name then name = "" end
		name = name == "" and "" or name.."."
		for _, item in ipairs(list_directory(path)) do
			if item:match("[^%.]") then
				local p = path.."/"..item
				local s, e
				if is_directory(p) then
					s, e = self:loaddirectory(p, name..item)
				elseif item:match("%.ans$") then
					s, e = self:loadfile(p, name..item:gsub("%.ans$", ""))
				end
				if not s then return s, e end
			end
		end
		return self
	end,

	--- Set aliases for built-in variables 👁️, 🔖 and 🏁 that will be defined on every new checkpoint and function.
	-- This does not affect variables that were defined before this function was called.
	-- Set to nil for no alias.
	--
	-- Returns this VM.
	setaliases = function(self, seen, checkpoint, reached)
		self.state.builtin_aliases["👁️"] = seen
		self.state.builtin_aliases["🔖"] = checkpoint
		self.state.builtin_aliases["🏁"] = reached
		return self
	end,
	--- Set some code that will be injected at specific places in all code loaded after this is called.
	-- Can typically be used to define variables for every function like 👁️, setting some value on every function resume, etc.
	--
	-- Possible inject types:
	-- * `"function start"`: injected at the start of every non-scoped function
	-- * `"function end"`: injected at the end of every non-scoped function
	-- * `"function return"`: injected at the end of each return's children that is contained in a non-scoped function
	-- * `"checkpoint start"`: injected at the start of every checkpoint
	-- * `"checkpoint end"`: injected at the end of every checkpoint
	-- * `"scoped function start"`: injected at the start of every scoped function
	-- * `"scoped function end"`: injected at the end of every scoped function
	-- * `"scoped function return"`: injected at the end of each return's children that is contained in a scoped function
	--
	-- Set `code` to nil to disable the inject.
	--
	-- Returns this VM.
	setinjection = function(self, inject, code)
		assert(injections[inject], ("unknown injection type %q"):format(inject))
		self.state.inject[injections[inject]] = code
		return self
	end,

	--- Load and execute a built-in language file.
	--
	-- The language file may optionally contain the special variables:
	--   * alias 👁️: string, default alias for 👁️
	--   * alias 🏁: string, default alias for 🏁
	--   * alias 🔖: string, default alias for 🔖
	--
	-- Returns this VM in case of success.
	--
	-- Returns nil, error message in case of error.
	loadlanguage = function(self, lang)
		local namespace = "anselme.languages."..lang
		-- execute language file
		local code = require(anselme_root.."stdlib.languages."..lang)
		local s, e = self:loadstring(code, namespace, lang)
		if not s then return s, e end
		s, e = self:eval(namespace)
		if e then return s, e end
		-- set aliases for built-in variables
		local seen_alias = self:eval(namespace..".alias 👁️")
		local checkpoint_alias = self:eval(namespace..".alias 🔖")
		local reached_alias = self:eval(namespace..".alias 🏁")
		self:setaliases(seen_alias, checkpoint_alias, reached_alias)
		return self
	end,

	--- Define functions from Lua.
	--
	-- * `signature`: string, full signature of the function
	-- * `fn`: function (Lua function or table, see examples in `stdlib/functions.lua`)
	--
	-- Returns this VM.
	loadfunction = function(self, signature, fn)
		if type(signature) == "table" then
			for k, v in pairs(signature) do
				local s, e = self:loadfunction(k, v)
				if not s then return nil, e end
			end
		else
			if type(fn) == "function" then fn = { value = fn } end
			self.state.link_next_function_definition_to_lua_function = fn
			local s, e = self:loadstring("$"..signature, "", "lua")
			if not s then return nil, e end
			assert(self.state.link_next_function_definition_to_lua_function == nil, "unexpected error while defining lua function")
			return self
		end
		return self
	end,

	--- Save/load script state
	--
	-- Only saves variables full names and values, so make sure to not change important variables, checkpoints and functions names between a save and a load.
	-- Also only save variables with usable identifiers, so will skip functions with arguments, operators, etc. (i.e. every scoped functions).
	-- Loading should be done after loading all the game scripts (otherwise you will "variable already defined" errors).
	--
	-- Returns this VM.
	load = function(self, data)
		assert(anselme.versions.save == data.anselme.versions.save, ("trying to load data from an incompatible version of Anselme; save was done using save version %s but current version is %s"):format(data.anselme.versions.save, anselme.versions.save))
		for k, v in pairs(data.variables) do
			self.state.variables[k] = v
		end
		return self
	end,
	--- Save script state.
	-- See `vm:load`.
	--
	-- Returns save data.
	save = function(self)
		local vars = {}
		for k, v in pairs(self.state.variables) do
			if should_keep_variable(self.state, k, v) then
				if v.type == "object" then -- filter object attributes
					local attributes = {}
					for kk, vv in pairs(v.value.attributes) do
						if should_keep_variable(self.state, kk, vv) then
							attributes[kk] = vv
						end
					end
					vars[k] = {
						type = "object",
						value = {
							class = v.value.class,
							attributes = attributes
						}
					}
				else
					vars[k] = v
				end
			end
		end
		return {
			anselme = {
				versions = anselme.versions,
				version = anselme.version
			},
			variables = vars
		}
	end,

	--- Perform parsing that needs to be done after loading code.
	-- This is automatically ran before starting an interpreter, but you may want to execute it before if you want to check for parsing error manually.
	--
	-- Returns self in case of success.
	--
	-- Returns nil, error message in case of error
	postload = function(self)
		if #self.state.queued_lines > 0 then
			local r, e = postparse(self.state)
			if not r then return r, e end
		end
		return self
	end,

	--- Enable feature flags.
	-- Available flags:
	-- * `"strip trailing spaces"`: remove trailing spaces from choice and text events (enabled by default)
	-- * `"strip duplicate spaces"`: remove duplicated spaces between text elements from choice and text events (enabled by default)
	--
	-- Returns this VM.
	enable = function(self, ...)
		for _, flag in ipairs{...} do
			self.state.feature_flags[flag] = true
		end
		return self
	end,
	--- Disable features flags.
	-- Returns this VM.
	disable = function(self, ...)
		for _, flag in ipairs{...} do
			self.state.feature_flags[flag] = nil
		end
		return self
	end,

	--- Run code.
	-- Will merge state after successful execution
	--
	-- * `expr`: expression to evaluate (string or parsed expression), or a block to run
	-- * `namespace`(default=""): namespace to evaluate the expression in
	-- * `tags`(default={}): defaults tags when evaluating the expression (Lua value)
	--
	-- Return interpreter in case of success.
	--
	-- Returns nil, error message in case of error.
	run = function(self, expr, namespace, tags)
		local s, e = self:postload()
		if not s then return s, e end
		--
		local err
		if type(expr) ~= "table" then expr, err = expression(tostring(expr), self.state, namespace or "") end
		if not expr then return expr, err end
		-- interpreter state
		local interpreter
		interpreter = {
			state = {
				inject = self.state.inject,
				feature_flags = self.state.feature_flags,
				builtin_aliases = self.state.builtin_aliases,
				aliases = setmetatable({}, { __index = self.state.aliases }),
				functions = self.state.functions, -- no need for a cache as we can't define or modify any function from the interpreter for now
				variable_constraints = self.state.variable_constraints, -- no cache as constraints are expected to be constant
				variables = setmetatable({}, {
					__index = function(variables, k)
						local cache = getmetatable(variables).cache
						if cache[k] == nil then
							cache[k] = copy(self.state.variables[k], getmetatable(variables).copy_cache)
						end
						return cache[k]
					end,
					-- variables that keep current state and should be cleared at each checkpoint
					cache = {}, -- cache of previously read values (copies), to get repeatable reads & handle mutable types without changing global state
					modified_tables = {}, -- list of modified tables (copies) that should be merged with global state on next checkpoint
					copy_cache = {}, -- table of [original table] = copied table. Automatically filled by copy().
					-- keep track of scoped variables in scoped functions [fn line] = {{scoped variables}, next scope, ...}
					-- (scoped variables aren't merged on checkpoint, shouldn't be cleared at checkpoints)
					-- (only stores scoped variables that have been reassigned at some point (i.e. every accessed one since they start as undefined))
					scoped = {}
				}),
				interpreter = {
					-- constant
					global_state = self.state,
					coroutine = coroutine.create(function() return "return", interpreter:run(expr, namespace) end),
					-- status
					running_line = nil,
					-- choice event
					choice_selected = nil,
					-- skip next choices until next event change (to skip currently running choice block when resuming from a checkpoint)
					skip_choices_until_flush = nil,
					-- active event buffer stack
					event_buffer_stack = {},
					-- current event waiting to be sent
					current_event = nil,
					-- interrupt
					interrupt = nil,
					-- tag stack
					tags = {},
					-- default tags for everything in this interpreter (Lua values)
					base_lua_tags = tags,
				},
			},
			vm = self
		}
		return setmetatable(interpreter, interpreter_methods)
	end,
	--- Evaluate code.
	-- Behave like `:run`, except the expression can not emit events and will return the result of the expression directly.
	-- Merge state after sucessful execution automatically like `:run`.
	--
	-- * `expr`: expression to evaluate (string or parsed expression), or a block to evaluate
	-- * `namespace`(default=""): namespace to evaluate the expression in
	-- * `tags`(default={}): defaults tags when evaluating the expression (Lua value)
	--
	-- Return value in case of success (nil if nothing returned).
	--
	-- Returns nil, error message in case of error.
	eval = function(self, expr, namespace, tags)
		local interpreter, err = self:run("()", namespace, tags)
		if not interpreter then return interpreter, err end
		local r, e = interpreter:eval(expr, namespace)
		if e then return r, e end
		assert(interpreter:step() == "return") -- trigger merge / end-of-script things
		return r
	end
}
vm_mt.__index = vm_mt

-- return anselme module
return setmetatable(anselme, {
	__call = function()
		-- global state
		local state = {
			inject = {
				-- function_start = "code block...", ...
			},
			feature_flags = {
				["strip trailing spaces"] = true,
				["strip duplicate spaces"] = true
			},
			builtin_aliases = {
				-- ["👁️"] = "seen",
				-- ["🔖"] = "checkpoint",
				-- ["🏁"] = "reached"
			},
			aliases = {
				-- ["bonjour.salutation"] = "hello.greeting", ...
			},
			functions = {
				-- ["script.fn"] = {
				-- 	{
				-- 		function or checkpoint table
				-- 	}, ...
				-- }, ...
			},
			variable_constraints = {
				-- foo = { constraint }, ...
			},
			variables = {
				-- foo = {
				-- 	type = "number",
				-- 	value = 42
				-- }, ...
			},
			queued_lines = {
				-- { line = line, namespace = "foo" }, ...
			},
			link_next_function_definition_to_lua_function = nil -- temporarly set to tell the preparser to link a anselme function definition with a lua function
		}
		local vm = setmetatable({ state = state }, vm_mt)
		-- bootscript
		local boot = assert(vm:loadstring(bootscript, "", "boot script"))
		local _, e = vm:eval(boot)
		if e then error(e) end
		-- lua-defined functions
		assert(vm:loadfunction(stdfuncs.lua))
		-- anselme-defined functions
		local ansfunc = assert(vm:loadstring(stdfuncs.anselme, "", "built-in functions"))
		_, e = vm:eval(ansfunc)
		if e then return error(e) end
		return vm
	end
})
