-- anselme module
local anselme = {
	-- version
	-- major.minor.fix
	-- saves files are incompatible between major versions
	-- scripts files may break between minor versions
	version = "0.15.0",
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
local to_lua = require(anselme_root.."interpreter.common").to_lua
local identifier_pattern = require(anselme_root.."parser.common").identifier_pattern
local merge_state = require(anselme_root.."interpreter.common").merge_state
local stdfuncs = require(anselme_root.."stdlib.functions")
local bootscript = require(anselme_root.."stdlib.bootscript")

-- wrappers for love.filesystem / luafilesystem
local function list_directory(path)
	local t = {}
	if love then
		t = love.filesystem.getDirectoryItems(path)
	else
		local lfs = require("lfs")
		for item in lfs.dir(path) do
			table.insert(t, path.."/"..item)
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

	--- run the VM until the next event
	-- will merge changed variables on successful script end
	-- returns event, data; if event is "return" or "error", the interpreter must not be stepped further
	step = function(self)
		-- check status
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
		if not success then return "error", event end
		if event == "return" then merge_state(self.state) end
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

	--- run an expression: may trigger events and must be called from within the interpreter coroutine
	-- return lua value
	run = function(self, expr, namespace)
		-- parse
		local err
		if type(expr) ~= "table" then expr, err = expression(tostring(expr), self.state.interpreter.global_state, namespace or "") end
		if not expr then coroutine.yield("error", err) end
		-- run
		local r, e = eval(self.state, expr)
		if not r then coroutine.yield("error", e) end
		if self.state.interpreter.event_buffer then -- flush final events
			local rf, re = run_line(self.state, { type = "flush_events" })
			if re then coroutine.yield("error", re) end
			if rf then r = rf end
		end
		return to_lua(r)
	end,
	--- evaluate an expression
	-- return value in case of success
	-- return nil, err in case of error
	eval = function(self, expr, namespace)
		-- parse
		local err
		if type(expr) ~= "table" then expr, err = expression(tostring(expr), self.state.interpreter.global_state, namespace or "") end
		if not expr then return nil, err end
		-- run
		local co = coroutine.create(function()
			local r, e = eval(self.state, expr)
			if not r then return "error", e end
			return "return", r
		end)
		local previous = anselme.running
		anselme.running = self
		local success, event, data = coroutine.resume(co)
		anselme.running = previous
		if not success then
			return nil, event
		elseif event ~= "return" then
			return nil, ("evaluated expression generated an %q event"):format(event)
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

	--- wrapper for loading a whole set of scripts
	-- should be preferred to other loading functions if possible
	-- requires LÖVE or LuaFileSystem
	-- will load in path, in order:
	-- * config.ans, which contains various optional configuration options:
	--   * alias 👁️: string, default alias for 👁️
	--   * alias 🏁: string, default alias for 🏁
	--   * alias 🔖: string, default alias for 🔖
	--   * language: string, built-in language file to load
	--   * main file: string, name (without .ans extension) of a file that will be loaded into the root namespace
	-- * main file, if defined in config.ans
	-- * every other file in the path and subdirectories, using their path as namespace (i.e., contents of path/world1/john.ans will be defined in a function world1.john)
	-- returns self in case of success
	-- returns nil, err in case of error
	loadgame = function(self, path)
		-- get config
		if is_file(path.."/config.ans") then
			local s, e = self:loadfile(path.."/config.ans", "config")
			if not s then return s, e end
		end
		local seen_alias = self:eval("config.alias 👁️")
		local checkpoint_alias = self:eval("config.alias 🔖")
		local reached_alias = self:eval("config.alias 🏁")
		local main_file = self:eval("config.main file")
		local language = self:eval("config.language")
		-- set aliases
		self:setaliases(seen_alias, checkpoint_alias, reached_alias)
		-- load language
		if language then
			local s, e = self:loadlanguage(language)
			if not s then return s, e end
		end
		-- load main file
		if main_file then
			local s, e = self:loadfile(path.."/"..main_file..".ans")
			if not s then return s, e end
		end
		-- load other files
		for _, item in ipairs(list_directory(path)) do
			if item:match("[^%.]") and item ~= "config.ans" and item ~= main_file then
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

	--- load code
	-- similar to Lua's code loading functions.
	-- name(default=""): namespace to load the code in. Will define a new function is specified; otherwise, code will be parsed but not executable from an expression.
	-- return self in case of success
	-- returns nil, err in case of error
	loadstring = function(self, str, name, source)
		local s, e = preparse(self.state, str, name or "", source)
		if not s then return s, e end
		return self
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
		return self
	end,
	loaddirectory = function(self, path, name) -- requires LÖVE or LuaFileSystem
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
	-- nil for no alias
	-- return self
	setaliases = function(self, seen, checkpoint, reached)
		self.state.builtin_aliases["👁️"] = seen
		self.state.builtin_aliases["🔖"] = checkpoint
		self.state.builtin_aliases["🏁"] = reached
		return self
	end,

	--- load & execute a built-in language file
	-- return self in case of success
	-- returns nil, err in case of error
	loadlanguage = function(self, lang)
		local code = require(anselme_root.."stdlib.languages."..lang)
		local s, e = self:loadstring(code, "anselme."..lang, lang)
		if not s then return s, e end
		s, e = self:eval("anselme."..lang)
		if e then return s, e end
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
		local saveMajor, currentMajor = data.anselme_version:match("^[^%.]*"), anselme.version:match("^[^%.]*")
		assert(saveMajor == currentMajor, ("trying to load data from an incompatible version of Anselme; save was done using %s but current version is %s"):format(data.anselme_version, anselme.version))
		for k, v in pairs(data.variables) do
			self.state.variables[k] = v
		end
		return self
	end,
	save = function(self)
		local vars = {}
		for k, v in pairs(self.state.variables) do
			if v.type ~= "undefined argument" and v.type ~= "pending definition" and k:match("^"..identifier_pattern.."$") then
				vars[k] = v
			end
		end
		return {
			anselme_version = anselme.version,
			variables = vars
		}
	end,

	--- run code
	-- expr: expression to evaluate
	-- namespace(default=""): namespace to evaluate the expression in
	-- tags(default={}): defaults tag when evaluating the expression
	-- return interpreter in case of success
	-- returns nil, err in case of error
	run = function(self, expr, namespace, tags)
		if #self.state.queued_lines > 0 then
			local r, e = postparse(self.state)
			if not r then return r, e end
		end
		--
		local err
		if type(expr) ~= "table" then expr, err = expression(tostring(expr), self.state, namespace or "") end
		if not expr then return expr, err end
		-- interpreter state
		local interpreter
		interpreter = {
			state = {
				builtin_aliases = self.state.builtin_aliases,
				aliases = self.state.aliases,
				functions = self.state.functions,
				variables = setmetatable({}, { __index = self.state.variables }),
				interpreter = {
					-- constant
					global_state = self.state,
					coroutine = coroutine.create(function() return "return", interpreter:run(expr, namespace) end),
					-- status
					running_line = nil,
					-- events
					event_type = nil,
					event_buffer = nil,
					-- choice event
					choice_selected = nil,
					choice_available = {},
					-- skip next choices until next event change (to skip currently running choice block when resuming from a checkpoint)
					skip_choices_until_flush = nil,
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
	-- unlike :run, this does not support events and will return the result of the expression directly.
	-- expr: expression to evaluate
	-- namespace(default=""): namespace to evaluate the expression in
	-- tags(default={}): defaults tag when evaluating the expression
	-- return value in case of success (nil if nothing returned)
	-- returns nil, err in case of error
	eval = function(self, expr, namespace, tags)
		local interpreter, err = self:run("0", namespace, tags)
		if not interpreter then return interpreter, err end
		return interpreter:eval(expr, namespace)
	end
}
vm_mt.__index = vm_mt

--- anselme module
return setmetatable(anselme, {
	__call = function()
		-- global state
		local state = {
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
		assert(vm:loadstring(bootscript, "", "boot script"))
		assert(vm:loadfunction(stdfuncs))
		return vm
	end
})
