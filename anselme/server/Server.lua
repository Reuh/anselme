--- An Anselme server instance.
--
-- Usage: create a Server object using the functions in the [anselme.server module](#anselme_server) and call `server:process()` regularly to process messages from the Client.
--
-- If you are implementing your own client, the following methods are available to be remotely called by your client:
-- * Note:
-- 	* in all the following methods, the first parameter `branch_id` (string) is the id of the Anselme branch to operate on;
-- 	* methods that return something always returns a list of return values: `{ ret1, ret2, ... }`.
-- * `choose(branch_id, i)`: if the last event was a `choice`, choose the `i`-th (number) line in the choice list;
-- * `remove(branch_id)`: removes the branch from the server; no further operation will be possible on the branch;
-- * `load_stdlib(branch_id, language)`: calls [`state:load_stdlib(language)`](api.md#load_stdlib-language) on the branch;
-- * `branch(branch_id[, new_branch_id])`: calls [`state:branch(branch_id)`](api.md#branch-branch_id) on the branch; returns the id of the new branch (string);
-- * `merge(branch_id)`: calls [`state:merge()`](api.md#merge) on the branch;
-- * `define(branch_id, name, args, func_code, raw_mode)`: calls [`state:define(branch_id, name, args, func, raw_mode)`](api.md#define-name-value-func-raw_mode) on the branch; if `func_code` is given, `func` will be a function generated from the Lua code `func_code` (string, example: `define("main", "print", "(message::is string)", "function(message) print(message) end")`). Note that whatever is in `func_code` will be executed on the server, and that there is no sandboxing of any kind;
-- * `define_rpc(branch_id, name, args, func_id)`: defines a function in the branch that, when called, will call the remote method `call(func_id, ...)` on the client and block until it returns. In other words, this allows the Anselme script running on the server to transparently call the function that is associated with the id `func_id` on the client.
-- * `define_local(branch_id, name, args, func_code, raw_mode)`: same as `define`, but calls [`state:define_local(branch_id, name, args, func, raw_mode)`](api.md#define_local-name-value-func-raw_mode);
-- * `define_local_rpc(branch_id, name, args, func_id)`: same as `define_rpc`, but defines the function in the current scope;
-- * `defined(branch_id, name)`: calls [`state:defined(name)`](api.md#defined-name) on the branch and returns its result;
-- * `defined_local(branch_id, name)`: calls [`state:defined_local(name)`](api.md#defined_local-name) on the branch and returns its result;
-- * `save(branch_id)`: calls [`state:save()`](api.md#save) on the branch and returns its result;
-- * `load(branch_id, save)`: calls [`state:load(save)`](api.md#load-save) on the branch;
-- * `active(branch_id)`: calls [`state:active()`](api.md#active) on the branch and returns its result;
-- * `state(branch_id)`: calls [`state:state()`](api.md#state) on the branch and returns its result;
-- * `run(branch_id, code, source, tags)`: calls [`state:run(code, source, tags)`](api.md#run-code-source-tags) on the branch;
-- * `run_file(branch_id, path, tags)`: calls [`state:run_file(path, tags)`](api.md#run_file-path-tags) on the branch;
-- * `step(branch_id)`: calls [`state:step()`](api.md#step) on the branch and returns:
-- 	* for `text` and `choices` events, a list of lines `{ { { text = "line 1 part 2", tags = { ... } }, ... }, ... }` (in other word, [`TextEventData`](api.md#texteventdata) and [`ChoiceEventData`](api.md#choiceeventdata) stripped of everything but their list of text parts);
-- 	* for `return` events, the return value converted to Lua;
-- 	* for other events, it will try to return the event data as-is.
-- * `interrupt(branch_id, code, source, tags)`: calls [`state:interrupt(code, source, tags)`](api.md#interrupt-code-source-tags) on the branch;
-- * `eval(branch_id, code, source, tags)`: calls [`state:eval(code, source, tags)`](api.md#eval-code-source-tags) on the branch and returns its result, converted to Lua;
-- * `eval_local(branch_id, code, source, tags)`: calls [`state:eval_local(code, source, tags)`](api.md#eval_local-code-source-tags) on the branch and returns its result, converted to Lua.

local class = require("anselme.lib.class")
local anselme = require("anselme")

local Server
Server = class {
	rpc = nil,
	branches = nil,

	-- `rpc` is the Rpc object to use to communicate with the Anselme client
	init = function(self, rpc)
		local branches = {
			main = {
				choice = nil,
				state = anselme.new()
			}
		}

		local methods = {
			choose = function(branch, i)
				branch.choice:choose(i)
			end,
			remove = function(branch)
				branches[branch.state.branch_id] = nil
			end,

			load_stdlib = function(branch, language)
				branch.state:load_stdlib(language)
			end,

			branch = function(branch, new_branch_id)
				local new_branch = branch.state:branch(new_branch_id)
				branches[new_branch.branch_id] = {
					choice = nil,
					state = new_branch
				}
				return new_branch.branch_id
			end,
			merge = function(branch)
				branch.state:merge()
			end,

			define = function(branch, name, args, func_code, raw_mode)
				if func_code then func_code = assert(load("return "..func_code))() end
				branch.state:define(name, args, func_code, raw_mode)
			end,
			define_rpc = function(branch, name, args, func_id)
				branch.state:define(name, args, function(...)
					return rpc:call("call", { func_id, ... }, "block")
				end)
			end,
			define_local = function(branch, name, args, func_code, raw_mode)
				if func_code then func_code = assert(load("return "..func_code))() end
				branch.state:define_local(name, args, func_code, raw_mode)
			end,
			define_local_rpc = function(branch, name, args, func_id)
				branch.state:define_local(name, args, function(...)
					return rpc:call("call", { func_id, ... }, "block")
				end)
			end,
			defined = function(branch, name)
				return branch.state:defined(name)
			end,
			defined_local = function(branch, name)
				return branch.state:defined_local(name)
			end,

			save = function(branch)
				return branch.state:save()
			end,
			load = function(branch, save)
				branch.state:load(save)
			end,

			active = function(branch)
				return branch.state:active()
			end,
			state = function(branch)
				return branch.state:state()
			end,
			run = function(branch, code, source, tags)
				branch.state:run(code, source, tags)
			end,
			run_file = function(branch, path, tags)
				branch.state:run_file(path, tags)
			end,
			step = function(branch)
				local event, data = branch.state:step()
				if event == "text" then
					return "text", data:to_simple_table()
				elseif event == "choice" then
					branch.choice = data
					return "choice", data:to_simple_table()
				elseif event == "return" then
					return "return", data:to_lua(branch.state)
				elseif event == "error" then
					return "error", data
				else
					return event, data
				end
			end,
			interrupt = function(branch, code, source, tags)
				branch.state:interrupt(code, source, tags)
			end,
			eval = function(branch, code, source, tags)
				return branch.state:eval(code, source, tags):to_lua(branch.state)
			end,
			eval_local = function(branch, code, source, tags)
				return branch.state:eval_local(code, source, tags):to_lua(branch.state)
			end,
		}

		for method, fn in pairs(methods) do
			rpc.methods[method] = function(branch_id, ...)
				local branch = assert(branches[branch_id], ("can't find branch %s"):format(branch_id))
				return fn(branch, ...)
			end
		end

		self.rpc = rpc
		self.branches = branches
	end,

	--- Process received messages.
	--
	-- Must be called regularly.
	-- If `block` is true, the function is allowed to block execution until a message is received.
	process = function(self, block)
		self.rpc:process(block)
	end,
}

return Server
