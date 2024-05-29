local ast = require("anselme.ast")
local Nil, String = ast.Nil, ast.String

return {
	{
		"print", "(a)",
		function(state, a)
			print(a:format_custom(state))
			return Nil:new()
		end
	},
	{
		"hash", "(a)",
		"format", "(val)",
		function(state, val)
			return String:new(val:format(state))
		end
	},
	{
		function(state, a)
			return String:new(a:hash())
		end
	},
	{
		"error", "(message=\"error\")",
		function(state, message)
			if message.type == "string" then message = message.string end
			error(message:format(state), 0)
		end
	}
}
