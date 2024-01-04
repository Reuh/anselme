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

	{ "rand", "(min::number, max::number)", function(state, min, max) return Number:new(math.random(min.number, max.number)) end },
	{ "rand", "(max::number)", function(state, max) return Number:new(math.random(max.number)) end },
	{ "rand", "()", function(state) return Number:new(math.random()) end },

	{ "floor", "(x::number)", function(state, x) return Number:new(math.floor(x.number)) end },
	{ "ceil", "(x::number)", function(state, x) return Number:new(math.ceil(x.number)) end },
	{
		"round", "(x::number, increment=1)",
		function(state, x, increment)
			local n = x.number / increment.number
			if n >= 0 then
				return Number:new(math.floor(n + 0.5) * increment.number)
			else
				return Number:new(math.ceil(n - 0.5) * increment.number)
			end
		end
	},

	{ "pi", Number:new(math.pi) }
}
