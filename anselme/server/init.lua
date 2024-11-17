--- Main functions to create clients and servers.

local Client = require("anselme.server.Client")

local server
server = {
	--- Starts a Server in a new LÖVE thread and returns a Client connected to that server.
	--
	-- Should be called from a [LÖVE](https://www.love2d.org/) game code only.
	new_love_thread = function()
		local LoveThread = require("anselme.server.rpc.LoveThread")
		local input = love.thread.newChannel()
		local output = love.thread.newChannel()

		local thread = love.thread.newThread[[
		local path, input_channel, output_channel = ...
		package.path = path

		local LoveThread = require("anselme.server.rpc.LoveThread")
		local Server = require("anselme.server.Server")

		local rpc = LoveThread:new(input_channel, output_channel)
		local server = Server:new(rpc)

		while true do
			server:process(true)
		end
		]]
		thread:start(package.path, input, output)

		return Client:new(LoveThread:new(output, input))
	end,

	--- Returns a new Server that communicate with a Client using JSON-RPC 2.0.
	--
	-- This does not define _how_ the two comminicate (through sockets, http, etc.), you will need to define this using the `send` and `receive` arguments.
	--
	-- `send(message)` is a function that send a single message to the associated Client.
	--
	-- `receive(block)` is a function that receive a single message from the associated Client (or `nil` if no message available). If `block` is true, the function is allowed to block execution until a message is received.
	new_json_rpc_server = function(send, receive)
		local Server = require("anselme.server.Server")
		local JsonRpc = require("anselme.server.rpc.JsonRpc")
		return Server:new(JsonRpc:new(send, receive))
	end,
	--- Returns a new Client that communicate with a Server using JSON-RPC 2.0.
	--
	-- This does not define _how_ the two comminicate (through sockets, http, etc.), you will need to define this using the `send` and `receive` arguments.
	--
	-- `send(message)` is a function that send a single message to the associated Server.
	--
	-- `receive(block)` is a function that receive a single message from the associated Server (or `nil` if no message available). If `block` is true, the function is allowed to block execution until a message is received.
	new_json_rpc_client = function(send, receive)
		local Client = require("anselme.server.Client")
		local JsonRpc = require("anselme.server.rpc.JsonRpc")
		return Client:new(JsonRpc:new(send, receive))
	end,
}

return server
