-- anselme module
local anselme = {
	-- version
	version = "0.12.0",
	--- currently running interpreter
	running = nil
}
package.loaded[...] = anselme

-- TODO: improve type checking.
-- Right now, there is some basic type checking done at parsing - but since Lua and Anselme functions may not always define the type of
-- their parameters and return value, a lot of checks are skipped ("undefined argument" type).
-- Probably won't be able to remove them completely (since lists can have mixed types, etc.), but would be good to limit them.
-- Ideally, we'd avoid runtime type checking.

-- load libs
local preparse = require((...):gsub("anselme$", "parser.preparser"))
local postparse = require((...):gsub("anselme$", "parser.postparser"))
local expression = require((...):gsub("anselme$", "parser.expression"))
local eval = require((...):gsub("anselme$", "interpreter.expression"))
local run_line = require((...):gsub("anselme$", "interpreter.interpreter")).run_line
local to_lua = require((...):gsub("anselme$", "interpreter.common")).to_lua
local stdfuncs = require((...):gsub("anselme$", "stdlib.functions"))

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

--- interpreter methods
local interpreter_methods = {
	-- VM this interpreter belongs to
	vm = nil,

	--- run the VM until the next event
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
			return "return", to_lua(r)
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
			return data
		end
	end,
}
interpreter_methods.__index = interpreter_methods

--- vm methods
local vm_mt = {
	--- load code
	-- return self in case of success
	-- returns nil, err in case of error
	loadstring = function(self, str, name, source)
		local s, e = preparse(self.state, str, name or "", source)
		if not s then return s, e end
		return self
	end,
	loadfile = function(self, path, name)
		local f, e = io.open(path, "r")
		if not f then return f, e end
		local s, err = self:loadstring(f:read("*a"), name, path)
		f:close()
		if not s then return s, err end
		return self
	end,
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

	--- define functions
	-- return self
	loadfunction = function(self, name, fn)
		if type(name) == "table" then
			for k, v in pairs(name) do
				if type(v) == "table" then
					for _, variant in ipairs(v) do
						self:loadfunction(k, variant)
					end
				else
					self:loadfunction(k, v)
				end
			end
		else
			if not self.state.functions[name] then
				self.state.functions[name] = {}
			end
			if type(fn) == "function" then
				local info = debug.getinfo(fn)
				table.insert(self.state.functions[name], {
					arity = info.isvararg and {info.nparams, math.huge} or info.nparams,
					value = fn
				})
			else
				table.insert(self.state.functions[name], fn)
			end
		end
		return self
	end,

	--- set aliases for built-in variables 👁️ and 🏁 that will be defined on every new paragraph and function
	-- return self
	setaliases = function(self, seen, checkpoint)
		self.state.builtin_aliases["👁️"] = seen
		self.state.builtin_aliases["🏁"] = checkpoint
		return self
	end,

	--- save/load
	load = function(self, data)
		assert(data.anselme_version == anselme.version, ("trying to load a save from Anselme %s but current Anselme version is %s"):format(data.anselme_version, anselme.version))
		for k, v in pairs(data.variables) do
			self.state.variables[k] = v
		end
		return self
	end,
	save = function(self)
		return {
			anselme_version = anselme.version,
			variables = self.state.variables
		}
	end,

	--- run code
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
				builtin_aliases = self.builtin_aliases,
				aliases = self.state.aliases,
				functions = self.state.functions,
				variables = setmetatable({}, { __index = self.state.variables }),
				interpreter = {
					global_state = self.state,
					coroutine = coroutine.create(function() return "return", interpreter:run(expr, namespace) end),
					-- events
					event_type = nil,
					event_buffer = nil,
					-- status
					running_line = nil,
					-- choice
					choice_selected = nil,
					choice_available = {},
					-- interrupt
					interrupt = nil,
					-- conditions
					last_condition_success = nil,
					-- tags
					tags = tags or {},
				}
			},
			vm = self
		}
		return setmetatable(interpreter, interpreter_methods)
	end,
	--- eval code
	-- return value in case of success
	-- returns nil, err in case of error
	eval = function(self, expr, namespace, tags)
		local interpreter, err = self:run("@", namespace, tags)
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
				-- ["🏁"] = "checkpoint"
			},
			aliases = {
				-- ["bonjour.salutation"] = "hello.greeting",
			},
			functions = {
				-- [":="] = {
				-- 	{
				-- 		arity = {3,42}, type = { [1] = "variable" }, check = function, rewrite = function, vararg = 2, mode = "custom",
				-- 		value = function(state, exp)
				-- 		end -- or paragraph, function, line
				-- 	}
				-- },
			},
			variables = {
				-- foo = {
				-- 	type = "number",
				-- 	value = 42
				-- },
			},
			queued_lines = {
				-- { line = line, namespace = "foo" },
			}
		}
		local vm = setmetatable({ state = state }, vm_mt)
		vm:loadfunction(stdfuncs)
		return vm
	end
})
