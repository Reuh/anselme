--- Communicate over JSON-RPC 2.0.
--
-- You will need to implement your own `_send` and `_receive` methods to send the message over your wanted communication channel (socket, stdio, etc.).

local Rpc = require("anselme.server.rpc.abstract.Rpc")
local json = require("anselme.lib.json")

local JsonRpc = Rpc {
	_send = nil,
	_receive = nil,

	send = function(self, data)
		if data.error and data.error.id == nil then
			data.error.id = json.null
		end
		data.jsonrpc = "2.0"
		self._send(json.encode(data))
	end,

	receive = function(self, block)
		return json.decode(self._receive(block))
	end,

	-- `send(message)` is a function that send a single message to the other party
	-- `receive(block)` is a function that receive a single message from the other party (or nil if no message available). If `block` is true, the function is allowed to block execution until a message is received.
	init = function(self, send, receive)
		Rpc.init(self)
		self._send = send
		self._receive = receive
	end
}

return JsonRpc
