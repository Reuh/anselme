---
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil, String = ast.Nil, ast.String

return {
	{
		--- Print a human-readable string representation (using `format(val)`) of `val` to the console.
		"print", "(val)",
		function(state, a)
			print(a:format_custom(state))
			return Nil:new()
		end
	},
	{
		--- Returns a human-readable string representation of `val`.
		--
		-- This function is called by string and text interpolations to convert the value returned by the interpolation to a string.
		--
		-- This generic version uses the internal Anselme formatter for all other values, which tries to generate a representation close to valid Anselme code.
		"format", "(val)",
		function(state, val)
			return String:new(val:format(state))
		end
	},
	{
		--- Returns a hash of `val`.
		--
		-- A hash is a string that uniquely represents the value. Two equal hashes mean the values are equal.
		"hash", "(val)",
		function(state, a)
			return String:new(a:hash())
		end
	},
	{
		--- Throw an error.
		"error", "(message=\"error\")",
		function(state, message)
			if message.type == "string" then message = message.string end
			error(message:format(state), 0)
		end
	}
}
