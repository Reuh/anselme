--- This is a Lua implementation of an Anselme client, with a nice API that mirrors the Anselme [State API](api.md#state) to communicate with the server.
--
-- Usage: create a Client object using the functions in the [anselme.server module](#anselme_server) and call `server:process()` regularly to process messages from the Server.
--
-- The API available here tries to follow the [State API](api.md#state) as much as possible, with the following differences:
-- * functions that return a value in State take an additionnal argument `callback`:
-- 	* if it is a function `callback(ret1, ret2, ...)`, it is called as soon as the return values `ret1, ret2, ...` are received. The function also returns the identifier `call_id` associated with the callback (to optionally cancel the callback later using `client:cancel(call_id)`).
-- 	* if it is `nil`, return values are discarded;
-- 	* if it is the string `"block"`, the call will block until the return values are received. The function returns these values directly.
-- * functions that returns a `State` in State now returns a `Client`;
-- * return values are converted to a simpler representation if possible (no metamethods, userdata or cycles) to make serialization simpler - in particular, Anselme values are automatically converted to Lua primitives.
-- * a few new methods are introduced, see below.
--
-- Implementing a Client in other languages should be relatively easy: if your client language has a [JSON-RPC 2.0](https://www.jsonrpc.org/specification) library, point it to the Anselme server you started using [`server.new_json_rpc_server()`](#new_json_rpc_server) and you're done.
-- You should then be able to call any of the methods described in the [Server](#server).
-- Additionnaly, if you plan to use the `define_rpc` or `define_local_rpc` server methods, you will need to implement the following remote method in your client that will be called by the server:
-- * `call(function_id, ...)` where `function_id` (string) is the function identifier that was given when `define_rpc` or `define_local_rpc` was called, and `...` is a list of arguments. This must call the function associated with the `function_id` using the given arguments, and returns the values returned by the call (as a list of return values: `{ret1, ret2, ...}`).

local class = require("anselme.lib.class")
local common = require("anselme.common")
local uuid = common.uuid

local Client
Client = class {
	rpc = nil,
	rpc_functions = nil,

	-- `rpc` is the Rpc object to use to communicate with the Anselme server
	init = function(self, rpc, branch_from, branch_id)
		-- create a new branch from an existing server
		if branch_from then
			self.branch_id = branch_id
			self.source_branch = branch_from
			self.rpc = branch_from.rpc
			self.rpc_functions = branch_from.rpc_functions
		-- create new empty server
		else
			self.rpc_functions = {}
			self.rpc = rpc
			self.rpc.methods.call = function(func_id, ...)
				local fn = assert(self.rpc_functions[func_id])
				return fn(...)
			end
		end
	end,

	--- Process received messages.
	--
	-- Must be called regularly.
	-- If `block` is true, the function is allowed to block execution until a message is received.
	process = function(self, block)
		self.rpc:process(block)
	end,

	--- Cancel the callback associated with the call `call_id`.
	-- This does not stop the remote method execution; only prevent the callback from being called.
	cancel = function(self, call_id)
		self.rpc:cancel(call_id)
	end,

	--- If the last event was a `choice`, choose the `i`-th choice.
	-- This must be called before calling `:step` again after receiving a choice event.
	choose = function(self, i)
		self.rpc:call("choose", { self.branch_id, i })
	end,
	--- Remove the branch from the server.
	-- The branch (and therefore this Client branch) can't be used after calling this method.
	remove = function(self)
		self.rpc:call("remove", { self.branch_id })
	end,

	--- Defines a function in the global scope, that calls the Lua function `func` on the Client when called.
	--
	-- The function will not be sent to the server; it will be directly executed on the client (i.e. your game code)
	-- each time a script on the server needs it to be called.
	--
	-- Usage: `client:define_rpc("teleport", "(position)", function(position) player:teleport(position) end)`
	define_rpc = function(self, name, args, func)
		local func_id = uuid()
		self.rpc_functions[func_id] = func
		self.rpc:call("define_rpc", { self.branch_id, name, args, func_id })
		return func_id
	end,
	--- Same as `:define_rpc`, but define the function in the current scope.
	define_local_rpc = function(self, name, args, func)
		local func_id = uuid()
		self.rpc_functions[func_id] = func
		self.rpc:call("define_local_rpc", { self.branch_id, name, args, func_id })
		return args
	end,

	--- ## Methods and fields that mirror the State API

	--- Same as [`state:load_stdlib(language)`](api.md#load_stdlib-language).
	load_stdlib = function(self, language)
		self.rpc:call("load_stdlib", { self.branch_id, language })
	end,

	--- Same as [`state.branch_id`](api.md#branch_id).
	branch_id = "main",
	--- Same as [`state.source_branch`](api.md#source_branch), but refers to the source `Client` instead of a `State`.
	source_branch = nil,
	--- Same as [`state:branch(branch_id)`](api.md#branch-branch_id), but returns a new `Client` instead of a `State`.
	branch = function(self, branch_id, callback)
		local branch_id
		if callback == "block" then
			return Client:new(self.rpc, self, self.rpc:call("branch", { self.branch_id, branch_id }, callback))
		else
			return self.rpc:call("branch", { self.branch_id, branch_id }, function(id) callback(Client:new(self.rpc, self, id)) end)
		end
	end,
	--- Same as [`state:merge()`](api.md#merge).
	merge = function(self)
		self.rpc:call("merge", { self.branch_id })
	end,

	--- Same as [`state:define(name, value, func, raw_mode)`](api.md#api.md#define-name-value-func-raw_mode), but if `func_code` is given, it must be a string containing the function code.
	--
	-- Note that the given code will be executed on the server, and that there is no sandboxing of any kind;
	--
	-- Example: `client:define("main", "print", "(message::is string)", "function(message) print(message) end")`.
	define = function(self, name, value, func_code, raw_mode)
		self.rpc:call("define", { self.branch_id, name, value, func_code, raw_mode })
	end,
	--- Same as [`define`](#define-name-value-func_code-raw_mode), but calls [`state:define_local(name, value, func, raw_mode)`](api.md#api.md#define_local-name-value-func-raw_mode).
	define_local = function(self, name, value, func_code, raw_mode)
		self.rpc:call("define_local", { self.branch_id, name, value, func_code, raw_mode })
	end,
	--- Same as [`state:defined(name)`](api.md#defined-name).
	defined = function(self, name, callback)
		return self.rpc:call("defined", { self.branch_id, name }, callback)
	end,
	--- Same as [`state:defined_local(name)`](api.md#defined_local-name).
	defined_local = function(self, name, callback)
		return self.rpc:call("defined_local", { self.branch_id, name }, callback)
	end,

	--- Same as [`state:save()`](api.md#save).
	save = function(self, callback)
		return self.rpc:call("save", { self.branch_id }, callback)
	end,
	--- Same as [`state:load(save)`](api.md#load-save).
	load = function(self, save)
		self.rpc:call("load", { self.branch_id, save })
	end,

	--- Same as [`state:active()`](api.md#active).
	active = function(self, callback)
		return self.rpc:call("active", { self.branch_id }, callback)
	end,
	--- Same as [`state:state()`](api.md#state).
	state = function(self, callback)
		return self.rpc:call("state", { self.branch_id }, callback)
	end,
	--- Same as [`state:run(code, source, tags)`](api.md#run-code-source-tags).
	run = function(self, code, source, tags)
		self.rpc:call("run", { self.branch_id, code, source, tags })
	end,
	--- Same as [`state:run_file(code, source, tags)`](api.md#run_file-code-source-tags).
	run_file = function(self, path, tags)
		self.rpc:call("run_file", { self.branch_id, path, tags })
	end,
	--- Same as [`state:step)`](api.md#step), but returns:
	-- * for `text` and `choice` events, a list of lines `{ { { text = "line 1 part 2", tags = { ... } }, ... }, ... }` (in other word, [`TextEventData`](api.md#texteventdata) and [`ChoiceEventData`](api.md#choiceeventdata) stripped of everything but their list of text parts);
	-- * for `return` events, the return value converted to Lua primitives;
	-- * for other events, it will try to return the event data as-is.
	step = function(self, callback)
		return self.rpc:call("step", { self.branch_id }, callback)
	end,
	--- Same as [`state:interrupt(code, source, tags)`](api.md#interrupt-code-source-tags).
	interrupt = function(self, code, source, tags)
		self.rpc:call("interrupt", { self.branch_id, code, source, tags })
	end,
	--- Same as [`state:eval(code, source, tags)`](api.md#eval-code-source-tags), but the returned value is converted to Lua primitives.
	eval = function(self, code, source, tags, callback)
		return self.rpc:call("eval", { self.branch_id, code, source, tags }, callback)
	end,
	--- Same as [`state:eval_local(code, source, tags)`](api.md#eval_local-code-source-tags), but the returned value is converted to Lua primitives.
	eval_local = function(self, code, source, tags, callback)
		return self.rpc:call("eval", { self.branch_id, code, source, tags }, callback)
	end,
}

return Client
