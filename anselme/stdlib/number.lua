local ast = require("anselme.ast")
local Boolean, Number = ast.Boolean, ast.Number

return {
	{ "pi", Number:new(math.pi) },

	{
		"_<_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number < b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_<_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{
		"_<=_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number <= b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_<=_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{
		"_>_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number > b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_>_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{
		"_>=_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number >= b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	{ "_>=_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{ "_+_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number + b.number) end },
	{ "_-_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number - b.number) end },
	{ "_*_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number * b.number) end },
	{ "_/_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number / b.number) end },
	{
		"_//_", "(a::is number, b::is number)", function(state, a, b)
			local r = a.number / b.number
			if r < 0 then
				return Number:new(math.ceil(r))
			else
				return Number:new(math.floor(r))
			end
		end
	},
	{ "_%_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number % b.number) end },
	{ "_^_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number ^ b.number) end },
	{ "-_", "(a::is number)", function(state, a) return Number:new(-a.number) end },

	{ "rand", "(min::is number, max::is number)", function(state, min, max) return Number:new(math.random(min.number, max.number)) end },
	{ "rand", "(max::is number)", function(state, max) return Number:new(math.random(max.number)) end },
	{ "rand", "()", function(state) return Number:new(math.random()) end },

	{ "floor", "(x::is number)", function(state, x) return Number:new(math.floor(x.number)) end },
	{ "ceil", "(x::is number)", function(state, x) return Number:new(math.ceil(x.number)) end },
	{
		"round", "(x::is number, increment=1)",
		function(state, x, increment)
			local n = x.number / increment.number
			if n >= 0 then
				return Number:new(math.floor(n + 0.5) * increment.number)
			else
				return Number:new(math.ceil(n - 0.5) * increment.number)
			end
		end
	},
}
