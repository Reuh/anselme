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
		"div", "(a::is number, b::is number)", function(state, a, b)
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
	{ "+_", "(a::is number)", function(state, a) return a end },

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

	{ "sqrt", "(x::is number)", function(state, x) return Number:new(math.sqrt(x.number)) end },

	{ "abs", "(x::is number)", function(state, x) return Number:new(math.abs(x.number)) end },

	{ "exp", "(x::is number)", function(state, x) return Number:new(math.exp(x.number)) end },
	{ "log", "(x::is number)", function(state, x) return Number:new(math.log(x.number)) end },
	{ "log", "(x::is number, base::is number)", function(state, x, base) return Number:new(math.log(x.number, base.number)) end },

	{ "deg", "(x::is number)", function(state, x) return Number:new(math.deg(x.number)) end },
	{ "rad", "(x::is number)", function(state, x) return Number:new(math.rad(x.number)) end },
	{ "cos", "(x::is number)", function(state, x) return Number:new(math.cos(x.number)) end },
	{ "sin", "(x::is number)", function(state, x) return Number:new(math.sin(x.number)) end },
	{ "tan", "(x::is number)", function(state, x) return Number:new(math.tan(x.number)) end },
	{ "acos", "(x::is number)", function(state, x) return Number:new(math.acos(x.number)) end },
	{ "asin", "(x::is number)", function(state, x) return Number:new(math.asin(x.number)) end },
	{ "atan", "(x::is number)", function(state, x) return Number:new(math.atan(x.number)) end },
	{ "atan", "(y::is number, x::is number)", function(state, y, x) return Number:new((math.atan2 or math.atan)(y.number, x.number)) end },
}
