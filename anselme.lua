-- anselme module
local anselme = {
	-- version
	-- save is incremented a each update which may break save compatibility
	-- language is incremented a each update which may break script file compatibility
	-- api is incremented a each update which may break Lua API compatibility
	versions = {
		save = 1,
		language = 21,
		api = 4
	},
	-- version is incremented at each update
	version = 22,
	--- currently running interpreter
	running = nil
}
package.loaded[...] = anselme

-- load libs
local anselme_root = (...):gsub("anselme$", "")
local preparse = require(anselme_root.."parser.preparser")
local postparse = require(anselme_root.."parser.postparser")
local expression = require(anselme_root.."parser.expression")
local eval = require(anselme_root.."interpreter.expression")
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

--- interpreter methods
local interpreter_methods = {
	-- interpreter state
	state = nil,
	-- VM this interpreter belongs to
	vm = nil,
	-- event that stopped the interpreter
	end_event = nil,

	--- run the VM until the next event
	-- will merge changed variables on successful script end
	-- returns event, data; if event is "return" or "error", the interpreter can not be stepped further
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

	--- select an answer
	-- returns self
	choose = function(self, i)
		self.state.interpreter.choice_selected = tonumber(i)
		return self
	end,

	--- interrupt the vm on the next step, executing an expression is specified
	-- returns self
	interrupt = function(self, expr)
		self.state.interpreter.interrupt = expr or true
		return self
	end,

	--- search closest namespace from last run line
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

	--- run an expression or block: may trigger events and must be called from within the interpreter coroutine
	-- no automatic merge if this change the interpreter state, merge is done once we reach end of script in a call to :step as usual
	-- return lua value (nil if nothing returned)
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
	--- evaluate an expression or block
	-- can be called from outside the coroutine. Will create a new coroutine that operate on this interpreter state.
	-- no automatic merge if this change the interpreter state, merge is done once we reach end of script in a call to :step as usual
	-- the expression can't yield events
	-- return value in case of success (nil if nothing returned)
	-- return nil, err in case of error
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

--- vm methods
local vm_mt = {
	-- anselme state
	state = nil,

	-- loaded game state
	game = nil,

	--- wrapper for loading a whole set of scripts
	-- should be preferred to other loading functions if possible
	-- requires LÖVE or LuaFileSystem
	-- will load in path, in order:
	-- * config.ans, which will be executed in the "config" namespace and may contains various optional configuration options:
	--   * language: string, built-in language file to load
	--   * anselme version: number, version of the anselme language this game was made for
	--   * game version: any, version information of the game. Can be used to perform eventual migration of save with an old version in the main file.
	--                        Always included in saved variables.
	--   * main file: string, name (without .ans extension) of a file that will be loaded into the root namespace and ran when starting the game
	-- * main file, if defined in config.ans
	-- * every other file in the path and subdirectories, using their path as namespace (i.e., contents of path/world1/john.ans will be defined in a function world1.john)
	-- returns self in case of success
	-- returns nil, err in case of error
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
			language = self:eval("config.language"),
			anselme_version = self:eval("config.anselme version"),
			game_version = self:eval("config.game version"),
			main_file = self:eval("config.main file"),
			main_block = nil
		}
		-- check language version
		if self.game.anselme_version and self.game.anselme_version ~= anselme.versions.language then
			return nil, ("trying to load game made for Anselme language %s, but currently using version %s"):format(self.game.anselme_version, anselme.versions.language)
		end
		-- force merging version into state
		local interpreter, err = self:run("config.game version")
		if not interpreter then return interpreter, err end
		interpreter:step()
		-- load language
		if self.game.language then
			local s, e = self:loadlanguage(self.game.language)
			if not s then return s, e end
		end
		-- load main file
		if self.game.main_file then
			local s, e = self:loadfile(path.."/"..self.game.main_file..".ans")
			if not s then return s, e end
			self.game.main_block = s
		end
		-- load other files
		for _, item in ipairs(list_directory(path)) do
			if item:match("[^%.]") and item ~= "config.ans" and item ~= self.game.main_file..".ans" then
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
	--- return a interpreter which runs the game main file
	-- return interpreter in case of success
	-- returns nil, err in case of error
	rungame = function(self)
		if not self.game then error("no game loaded") end
		if self.game.main_block then
			return self:run(self.game.main_block)
		else
			return self:run("()")
		end
	end,

	--- load code
	-- similar to Lua's code loading functions.
	-- name(default=""): namespace to load the code in. Will define a new function is specified; otherwise, code will be parsed but not executable from an expression.
	-- return parsed block in case of success
	-- returns nil, err in case of error
	loadstring = function(self, str, name, source)
		local s, e = preparse(self.state, str, name or "", source)
		if not s then return s, e end
		return s
	end,
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
	-- load every file in a directory, using filename (without .ans extension) as its namespace
	-- requires LÖVE or LuaFileSystem
	-- return self in case of success
	-- returns nil, err in case of error
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

	--- set aliases for built-in variables 👁️, 🔖 and 🏁 that will be defined on every new checkpoint and function
	-- this does not affect variables that were defined before this function was called
	-- nil for no alias
	-- return self
	setaliases = function(self, seen, checkpoint, reached)
		self.state.builtin_aliases["👁️"] = seen
		self.state.builtin_aliases["🔖"] = checkpoint
		self.state.builtin_aliases["🏁"] = reached
		return self
	end,

	--- load & execute a built-in language file
	-- the language file may optionally contain the special variables:
	--   * alias 👁️: string, default alias for 👁️
	--   * alias 🏁: string, default alias for 🏁
	--   * alias 🔖: string, default alias for 🔖
	-- return self in case of success
	-- returns nil, err in case of error
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

	--- define functions from Lua
	-- signature: full signature of the function
	-- fn: function (Lua function or table, see examples in stdlib/functions.lua)
	-- return self
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

	--- save/load script state
	-- only saves variables full names and values, so make sure to not change important variables, checkpoints and functions names between a save and a load
	-- only save variables with usable identifiers, so will skip functions with arguments, operators, etc.
	-- loading should be after loading scripts (otherwise you will "variable already defined" errors)
	load = function(self, data)
		assert(anselme.versions.save == data.anselme.versions.save, ("trying to load data from an incompatible version of Anselme; save was done using save version %s but current version is %s"):format(data.anselme.versions.save, anselme.versions.save))
		for k, v in pairs(data.variables) do
			self.state.variables[k] = v
		end
		return self
	end,
	save = function(self)
		local vars = {}
		for k, v in pairs(self.state.variables) do
			if should_keep_variable(self.state, k) then
				vars[k] = v
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

	--- perform parsing that needs to be done after loading code
	-- automatically ran before starting an interpreter, but you may want to execute it before if you want to check for parsing error manually
	-- returns self in case of success
	-- returns nil, err in case of error
	postload = function(self)
		if #self.state.queued_lines > 0 then
			local r, e = postparse(self.state)
			if not r then return r, e end
		end
		return self
	end,

	--- enable feature flags
	-- available flags:
	-- * "strip trailing spaces": remove trailing spaces from choice and text events (enabled by default)
	-- * "strip duplicate spaces": remove duplicated spaces between text elements from choice and text events (enabled by default)
	-- returns self
	enable = function(self, ...)
		for _, flag in ipairs{...} do
			self.state.feature_flags[flag] = true
		end
		return self
	end,
	--- disable features flags
	-- returns self
	disable = function(self, ...)
		for _, flag in ipairs{...} do
			self.state.feature_flags[flag] = nil
		end
		return self
	end,

	--- run code
	-- expr: expression to evaluate (string or parsed expression), or a block to run
	-- will merge state after successful execution
	-- namespace(default=""): namespace to evaluate the expression in
	-- tags(default={}): defaults tag when evaluating the expression
	-- return interpreter in case of success
	-- returns nil, err in case of error
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
				feature_flags = self.state.feature_flags,
				builtin_aliases = self.state.builtin_aliases,
				aliases = setmetatable({}, { __index = self.state.aliases }),
				functions = self.state.functions, -- no need for a cache as we can't define or modify any function from the interpreter for now
				variables = setmetatable({}, {
					__index = function(variables, k)
						local cache = getmetatable(variables).cache
						if cache[k] == nil then
							cache[k] = copy(self.state.variables[k], getmetatable(variables).copy_cache)
						end
						return cache[k]
					end,
					-- variables that keep current state and should be cleared at each checkpoint
					copy_cache = {}, -- table of [original table] = copied table
					modified_tables = {}, -- list of modified tables (copies) that should be merged with global state on next checkpoint
					cache = {}, -- cache of previously read values (copies), to get repeatable reads & handle mutable types without changing global state
					-- keep track of scoped variables in scoped functions [fn line] = {{scoped variables}, next scope, ...}
					-- (scoped variables aren't merged on checkpoint, shouldn't be cleared at checkpoints)
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
					tags = tags or {},
				},
			},
			vm = self
		}
		return setmetatable(interpreter, interpreter_methods)
	end,
	--- eval code
	-- behave like :run, except the expression can not emit events and will return the result of the expression directly.
	-- merge state after sucessful execution automatically like :run
	-- expr: expression to evaluate (string or parsed expression), or a block to evaluate
	-- namespace(default=""): namespace to evaluate the expression in
	-- tags(default={}): defaults tag when evaluating the expression
	-- return value in case of success (nil if nothing returned)
	-- returns nil, err in case of error
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

--- anselme module
return setmetatable(anselme, {
	__call = function()
		-- global state
		local state = {
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
