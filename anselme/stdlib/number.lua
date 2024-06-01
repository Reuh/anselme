--- # Arithmetic and math functions
--
-- Comparaison operators are designed to be chained:
-- ```
-- 1 < 2 < 3
-- // is parsed as
-- (1 < 2) < 3
-- // (1 < 2) returns 2, 2 < 3 returns 3 which is true
-- ```
-- @titlelevel 3

local ast = require("anselme.ast")
local Boolean, Number = ast.Boolean, ast.Number

return {
	--- Pi.
	{ "pi", Number:new(math.pi) },

	{
		--- Returns `b` if `a` < `b`, false otherwise.
		"_<_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number < b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	--- Returns false.
	{ "_<_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{
		--- Returns `b` if `a` <= `b`, false otherwise.
		"_<=_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number <= b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	--- Returns false.
	{ "_<=_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{
		--- Returns `b` if `a` > `b`, false otherwise.
		"_>_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number > b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	--- Returns false.
	{ "_>_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	{
		--- Returns `b` if `a` >= `b`, false otherwise.
		"_>=_", "(a::is number, b::is number)",
		function(state, a, b)
			if a.number >= b.number then return b
			else return Boolean:new(false)
			end
		end
	},
	--- Returns false.
	{ "_>=_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },
	--- Returns `a` + `b`.
	{ "_+_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number + b.number) end },
	--- Returns `a` - `b`.
	{ "_-_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number - b.number) end },
	--- Returns `a` * `b`.
	{ "_*_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number * b.number) end },
	--- Returns `a` / `b`.
	{ "_/_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number / b.number) end },
	{
		--- Returns the integer division of `a` by `b`.
		"div", "(a::is number, b::is number)", function(state, a, b)
			local r = a.number / b.number
			if r < 0 then
				return Number:new(math.ceil(r))
			else
				return Number:new(math.floor(r))
			end
		end
	},
	--- Returns the modulo of `a` by `b`.
	{ "_%_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number % b.number) end },
	--- Returns `a` to the power of `b`.
	{ "_^_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number ^ b.number) end },
	--- Returns the negative of `a`.
	{ "-_", "(a::is number)", function(state, a) return Number:new(-a.number) end },
	--- Returns `a`.
	{ "+_", "(a::is number)", function(state, a) return a end },

	--- Returns a random integer number with uniform distribution in [`min`, `max`].
	{ "rand", "(min::is number, max::is number)", function(state, min, max) return Number:new(math.random(min.number, max.number)) end },
	--- Returns a random integer number with uniform distribution in [1, `max`].
	{ "rand", "(max::is number)", function(state, max) return Number:new(math.random(max.number)) end },
	--- Returns a random float number with uniform distribution in [0,1).
	{ "rand", "()", function(state) return Number:new(math.random()) end },

	--- Returns the largest integral value less than or equal to `x`.
	{ "floor", "(x::is number)", function(state, x) return Number:new(math.floor(x.number)) end },
	--- Returns the smallest integral value greater than or equal to `x`.
	{ "ceil", "(x::is number)", function(state, x) return Number:new(math.ceil(x.number)) end },
	{
		--- Returns `x` rounded to the nearest integer.
		-- If `increment` > 1, rounds to the nearest float with `increment` decimals.
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

	--- Returns the square root of `x`.
	{ "sqrt", "(x::is number)", function(state, x) return Number:new(math.sqrt(x.number)) end },

	--- Returns the absolute value of `x`.
	{ "abs", "(x::is number)", function(state, x) return Number:new(math.abs(x.number)) end },

	--- Returns the exponential of `x`.
	{ "exp", "(x::is number)", function(state, x) return Number:new(math.exp(x.number)) end },
	--- Returns the natural logarithm of `x`.
	{ "log", "(x::is number)", function(state, x) return Number:new(math.log(x.number)) end },
	--- Returns the logarithm in base `base` of `x`.
	{ "log", "(x::is number, base::is number)", function(state, x, base) return Number:new(math.log(x.number, base.number)) end },

	--- Convert `x` from radian to degrees.
	{ "deg", "(x::is number)", function(state, x) return Number:new(math.deg(x.number)) end },
	--- Convert `x` from degrees to radians.
	{ "rad", "(x::is number)", function(state, x) return Number:new(math.rad(x.number)) end },

	--- ## Trigonometric functions
	--
	-- All triginometric functions take and return angles in radians.

	--- Returns the cosinus of `x`.
	{ "cos", "(x::is number)", function(state, x) return Number:new(math.cos(x.number)) end },
	--- Returns the sinus of `x`.
	{ "sin", "(x::is number)", function(state, x) return Number:new(math.sin(x.number)) end },
	--- Returns the tagent of `x`.
	{ "tan", "(x::is number)", function(state, x) return Number:new(math.tan(x.number)) end },
	--- Returns the arc cosinus of `x`.
	{ "acos", "(x::is number)", function(state, x) return Number:new(math.acos(x.number)) end },
	--- Returns the arc sinus of `x`.
	{ "asin", "(x::is number)", function(state, x) return Number:new(math.asin(x.number)) end },
	--- Returns the arc tangent of `x`.
	{ "atan", "(x::is number)", function(state, x) return Number:new(math.atan(x.number)) end },
	--- Returns the arc tangent of `x` / `y`, taking the signs of both arguments into account to find the correct quandrant (see [atan2](https://en.wikipedia.org/wiki/Atan2)).
	{ "atan", "(y::is number, x::is number)", function(state, y, x) return Number:new((math.atan2 or math.atan)(y.number, x.number)) end },
}
