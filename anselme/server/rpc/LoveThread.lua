--- Communicate over LÖVE threads using Channels.

local Rpc = require("anselme.server.rpc.abstract.Rpc")

local LoveThread = Rpc {
	_output = nil,
	_input = nil,

	send = function(self, data)
		self._output:push(data)
	end,

	receive = function(self, block)
		if block then
			return self._input:demand()
		else
			return self._input:pop()
		end
	end,

	-- `input` is the LÖVE thread Channel used to send data from the Anselme server to the game engine
	-- `output` is the LÖVE thread Channel used to send data from the game engine to the Anselme server
	init = function(self, input, output)
		Rpc.init(self)
		self._input = input
		self._output = output
	end
}

return LoveThread
