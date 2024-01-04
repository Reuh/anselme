local ast = require("anselme.ast")
local Nil, String = ast.Nil, ast.String

return {
	{ "_;_", "(left, right)", function(state, left, right) return right end },
	{ "_;", "(left)", function(state, left) return Nil:new() end },

	{
		"print", "(a)",
		function(state, a)
			print(a:format(state))
			return Nil:new()
		end
	},
	{
		"hash", "(a)",
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
