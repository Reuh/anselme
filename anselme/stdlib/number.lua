local ast = require("anselme.ast")
local Boolean, Number = ast.Boolean, ast.Number

return {
	{
		"_<_", "(a::number, b::number)",
		function(state, a, b)
			if a.number < b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_<_", "(a::equal(false), b::number)", function(state, a, b) return Boolean:new(false) end },
	{
		"_<=_", "(a::number, b::number)",
		function(state, a, b)
			if a.number <= b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_<=_", "(a::equal(false), b::number)", function(state, a, b) return Boolean:new(false) end },
	{
		"_>_", "(a::number, b::number)",
		function(state, a, b)
			if a.number > b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_>_", "(a::equal(false), b::number)", function(state, a, b) return Boolean:new(false) end },
	{
		"_>=_", "(a::number, b::number)",
		function(state, a, b)
			if a.number >= b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_>=_", "(a::equal(false), b::number)", function(state, a, b) return Boolean:new(false) end },
	{ "_+_", "(a::number, b::number)", function(state, a, b) return Number:new(a.number + b.number) end },
	{ "_-_", "(a::number, b::number)", function(state, a, b) return Number:new(a.number - b.number) end },
	{ "_*_", "(a::number, b::number)", function(state, a, b) return Number:new(a.number * b.number) end },
	{ "_/_", "(a::number, b::number)", function(state, a, b) return Number:new(a.number / b.number) end },
	{ "_//_", "(a::number, b::number)", function(state, a, b) return Number:new(math.floor(a.number / b.number)) end },
	{ "_%_", "(a::number, b::number)", function(state, a, b) return Number:new(a.number % b.number) end },
	{ "_^_", "(a::number, b::number)", function(state, a, b) return Number:new(a.number ^ b.number) end },
	{ "-_", "(a::number)", function(state, a) return Number:new(-a.number) end },
}
