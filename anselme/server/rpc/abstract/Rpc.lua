-- Note: this does not support multiple clients for a single server.

local class = require("anselme.lib.class")

local function default_callback() end
local function default_error_callback(message, data)
	if data then
		error(("in rpc call: %s\n%s"):format(message, data))
	else
		error(("in rpc call: %s"):format(message))
	end
end

local Rpc = class {
	--- The message exchanged are Lua table representing [JSON-RPC 2.0](https://www.jsonrpc.org/specification) Request and Response objects, with the following caveats:
	--
	-- * by-name parameters are not supported in requests;
	-- * result values in responses are always arrays (corresponding to the return list of a Lua function);
	-- * each side act both as both a client and a server.
	--
	-- These should not break compatility with any JSON-RPC 2.0 compliant service, just keep them in mind :)
	--
	-- Note however that the messages generated by this file require a couple change to be truly compliant:
	--
	-- * in error response caused by parsing errors, `id` will be unset instead of Null (since Lua considers nil values to be inexistent);
	-- * the `jsonrpc="2.0"` field isn't set;
	-- * and the message should be encoded/decoded to/from JSON obviously.
	--
	-- These are meant to be handled in the `:send` and `:receive` methods. See JsonRpc.lua.
	--
	-- Alternatively, look at LoveThread.lua if you don't care about full compliance.

	--- Send a message.
	--
	-- `data` must be a table reprensenting a JSON-RPC 2.0 message (with the considerations noted above).
	--
	-- Must be redefined to handle whatever inter-process comminication you are using.
	send = function(self, data) error("not implemented") end,
	--- Receives a message.
	--
	-- Must be non-blocking by default; may be optionnaly blocking if `block` if true. May raise errors.
	--
	-- Returns a table reprensenting a JSON RPC-2.0 message (see above) or `nil` if nothing to receive.
	--
	-- Must be redefined to handle whatever inter-process comminication you are using.
	receive = function(self, block) error("not implemented") end,

	--- Table of methods that can be called remotely:
	-- {
	--		["method1"] = function(param1, param2, ...)
	-- 		return ret1, ret2, ...
	-- 		-- may raise an error
	-- 	end,
	-- 	["method2"] = ...,
	-- 	...
	-- }
	methods = nil,

	--- Returns a new Rpc object.
	init = function(self)
		self.methods = {}
		self._callbacks = {}
		self._error_callbacks = {}
	end,

	_callbacks = nil, -- { [call id] = callback, ... }
	_error_callbacks = nil, -- { [call id] = error_callback, ... }
	id = 0, -- last used call id

	--- Call a remote method.
	--
	-- Parameters:
	-- * `method` (string) is the method name.
	-- * `params` (table) is the parameter list.
	-- * `callback` (function, optional) is either:
	-- 	* a function that will be called when the method returns. It receives all the returned values as arguments (ret1, ret2, ...). If not set, a default callback that discard all returns values will be used
	-- 	* the string "block", in which case the function will block until the remote method returns.
	-- * `error_callback` (function, optional) is a function that will be called if the method raise an error. It receives the error message and error details (usually the traceback; may be nil) as arguments (message, traceback). If not set, a default callback that raise an error will be used.
	--
	-- Returns:
	-- * the call id (number) if `callback` is not `"block"`
	-- * the values returned by the remote method if `callback` is `"block"`
	call = function(self, method, params, callback, error_callback)
		self.id = self.id + 1
		self:send{ method = method, params = params, id = self.id }
		if callback == "block" then
			local ok, response
			self._callbacks[self.id] = function(...) ok, response = true, { ... } end
			self._error_callbacks[self.id] = error_callback and function(...) ok, response = true, {}; error_callback(...) end or default_error_callback
			while not ok do self:process() end
			return unpack(response)
		else
			self._callbacks[self.id] = callback or default_callback
			self._error_callbacks[self.id] = error_callback or default_error_callback
			return self.id
		end
	end,
	--- Same as `:call`, but always discards all returned values and errors.
	-- NOTE unused for now
	notify = function(self, method, params)
		self:send{ method = method, params = params }
	end,
	--- Cancel callbacks associated with the call `call_id` (number).
	-- This does not stop the remote method execution.
	cancel = function(self, call_id)
		self._callbacks[call_id] = default_callback
		self._error_callbacks[call_id] = default_error_callback
	end,

	--- Process incoming message.
	-- This should be called regularly.
	-- If `block` is true, block execution until a message is received.
	process = function(self, block)
		local s, d = pcall(self.receive, self, block)
		if not s then
			self:send{ error = { code = -32700, message = "Parse error", data = d, id = nil } }
		elseif d then
			if type(d) ~= "table" then
				self:send{ error = { code = -32600, message = "Invalid Request", id = nil } }
			else
				-- request
				if d.method then
					self:send(self:_process_request(d))
				-- response
				elseif d.result or d.error then
					self:_process_response(d)
				-- batch
				elseif #d > 0 then
					local first = d[1]
					-- request batch
					if d.method then
						local responses = {}
						for _, req in ipairs(d) do
							table.insert(responses, self:_process_request(req))
						end
						if #responses > 1 then
							self:send(responses)
						end
					-- response batch
					else
						for _, res in ipairs(d) do
							self:_process_response(res)
						end
					end
				end
			end
		end
	end,
	--- Process a request or notification.
	-- Returns a response for requests.
	-- Returns nothing for notifications.
	_process_request = function(self, d)
		local method, params, id = d.method, d.params or {}, d.id
		if type(method) ~= "string" or type(d.params) ~= "table" then
			self:send{ error = { code = -32600, message = "Invalid Request" }, id = id }
			return
		end
		local fn = self.methods[method]
		if not fn then
			if id then self:send{ error = { code = -32601, message = ("Method not found %s"):format(method) }, id = id } end
			return
		end
		if params[1] == nil and not next(params) then
			if id then self:send{ error = { code = -32602, message = "Named parameters are not supported" }, id = id } end
			return
		end
		local r = { xpcall(fn, function(err) return { err, debug.traceback("Traceback from RPC:", 2) } end, unpack(params)) }
		if id then
			if r[1] then
				return { result = { unpack(r, 2) }, id = id }
			else
				return { error = { code = 0, message = r[2][1], data = r[2][2] }, id = id }
			end
		end
	end,
	--- Process a response.
	_process_response = function(self, d)
		local result, err, id = d.result, d.error, d.id
		if id then
			assert(self._callbacks[id], "invalid response call id")
			if err then
				assert(type(err) == "table", "error must be a table")
				self._error_callbacks[id](tostring(err.message), err.data)
			else
				assert(type(result) == "table", "result must be a table")
				self._callbacks[id](unpack(result))
			end
			self._callbacks[id] = nil
			self._error_callbacks[id] = nil
		else
			default_error_callback(tostring(err.message), err.data)
		end
	end
}

return Rpc
