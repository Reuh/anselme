This document describes the functions defined by default by Anselme. These are accessible from any Anselme script.

This document is generated automatically from the source files in [anselme/stdlib](../anselme/stdlib).



### print (val)

Print a human-readable string representation (using `format(val)`) of `val` to the console.

_defined at line 10 of [anselme/stdlib/base.lua](../anselme/stdlib/base.lua):_ `"print", "(val)",`

### format (val)

Returns a human-readable string representation of `val`.

This function is called by string and text interpolations to convert the value returned by the interpolation to a string.

This generic version uses the internal Anselme formatter for all other values, which tries to generate a representation close to valid Anselme code.

_defined at line 22 of [anselme/stdlib/base.lua](../anselme/stdlib/base.lua):_ `"format", "(val)",`

### hash (val)

Returns a hash of `val`.

A hash is a string that uniquely represents the value. Two equal hashes mean the values are equal.

_defined at line 31 of [anselme/stdlib/base.lua](../anselme/stdlib/base.lua):_ `"hash", "(val)",`

### error (message="error")

Throw an error.

_defined at line 38 of [anselme/stdlib/base.lua](../anselme/stdlib/base.lua):_ `"error", "(message=\"error\")",`


# Variable assignment

### identifier = value

Assign `value` to the variable `identifier`.
```
var = 42
```

_defined at line 56 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"_=_", "(quote::is quoted(\"identifier\"), value)",`

### symbol::is symbol = value

Define the variable using the symbol `symbol` with the initial value `value`.
```
:var = 42
```

_defined at line 68 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"_=_", "(quote::is quoted(\"symbol\"), value)",`

### variable tuple::is tuple = value tuple::is tuple

For each `variable` element of the variable tuple and associated `value` element of the value tuple, call `variable = value`.
```
(:a, :b) = (24, 42)
(a, b) = (b, a)
```

_defined at line 86 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"_=_", "(quote::is quoted(\"tuple\"), value::is tuple)",`


# Value checking

See the [language reference](language.md#value_checking) for information on how value checking functions works.

### is (t)

Returns a function `$(x)` that returns true if `x` is of type `t`, false otherwise.

### is equal (x)

Returns a function `$(y)` that returns true if `x` is equal to `y`, false otherwise.

### is nil (x)

Returns a true if `x` is a nil, false otherwise.

### is number (x)

Returns a true if `x` is a number, false otherwise.

### is string (x)

Returns a true if `x` is a string, false otherwise.

### is boolean (x)

Returns a true if `x` is a boolean, false otherwise.

### is false (x)

Returns a true if `x` is false, false otherwise.

### is true (x)

Returns a true if `x` is true, false otherwise.

### is symbol (x)

Returns a true if `x` is a symbol, false otherwise.

### is anchor (x)

Returns a true if `x` is an anchor, false otherwise.

### is pair (x)

Returns a true if `x` is a pair, false otherwise.

### is text (x)

Returns a true if `x` is a text, false otherwise.

### is sequence (x)

Returns a true if `x` is a sequence (a tuple or a list), false otherwise.

### is list (x)

Returns a true if `x` is a list, false otherwise.

### is map (x)

Returns a true if `x` is a map (a struct or a table), false otherwise.

### is struct (x)

Returns a true if `x` is a struct, false otherwise.

### is table (x)

Returns a true if `x` is a table, false otherwise.

### is environment (x)

Returns a true if `x` is an environment, false otherwise.

### is function (x)

Returns a true if `x` is a function, false otherwise.

### is overload (x)

Returns a true if `x` is an overload, false otherwise.

### constant (exp)

Always return false.
Can be used as variable value checking function to prevent any reassignment and thus make the variable constant.
```
:var::constant = 42
```

_defined at line 15 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"constant", "(exp)",`

### is tuple (exp)

Returns true if the expression is a tuple, false otherwise.

_defined at line 24 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"is tuple", "(exp)",`

### is range (val)

Returns true if `val` is a range, false otherwise.

### is script (x)

Returns true if `x` is a script, false otherwise.

### value :: check

Call `check(value)` and error if it returns a false value.
This can be used to ensure a value checking function is verified on a value.

_defined at line 12 of [anselme/stdlib/typed.lua](../anselme/stdlib/typed.lua):_ `"_::_", "(value, check)",`


# Boolean

### true

A boolean true value.

_defined at line 9 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `{ "true", Boolean:new(true) },`

### false

A boolean false value.

_defined at line 11 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `{ "false", Boolean:new(false) },`

### a == b

Equality operator.
Returns true if `a` and `b` are equal, false otherwise.

Mutable values are compared by reference, immutable values are compared by value.

_defined at line 18 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `"_==_", "(a, b)",`

### a != b

Inequality operator.
Retrusn false if `a` and `b` are equal, true otherwise.

_defined at line 29 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `"_!=_", "(a, b)",`

### ! a

Boolean not operator.
Returns false if `a` is true, false otherwise.

_defined at line 40 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `"!_", "(a)",`

### left & right

Boolean lazy and operator.
If `left` is truthy, evaluate `right` and returns it. Otherwise, returns left.

_defined at line 48 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `"_&_", "(left, right)",`

### left | right

Boolean lazy or operator.
If `left` is truthy, returns it. Otherwise, evaluate `right` and returns it.

_defined at line 60 of [anselme/stdlib/boolean.lua](../anselme/stdlib/boolean.lua):_ `"_|_", "(left, right)",`


# Control flow

```
if(5 > 3)
	print("called")

if(3 > 5)
	print("not called")
else if(1 > 5)
	print("not called")
else!
	print("called")
```

### if (condition, expression=attached block(keep return=true))

Call `expression` if `condition` is true.
Returns the result of the call to `expression`, or nil if the condition was false.

If we are currently resuming to an anchor contained in `expression`, `expression` is called regardless of the condition result.

_defined at line 40 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"if", "(condition, expression=attached block(keep return=true))", function(state, condition, expression)`

### if (condition, if true, if false)

Call `if true` if `condition` is true, `if false` otherwise.
Return the result of the call.

If we are currently resuming to an anchor contained in `if true` or `if false`, `if true` or `if false` (respectively) is called regardless of the condition result.

_defined at line 56 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"if", "(condition, if true, if false)", function(state, condition, if_true, if_false)`

### else if (condition, expression=attached block(keep return=true))

Call `expression` if `condition` is true and the last if, else if or else's condition was false, or the last while loop was never entered.
Returns the result of the call to `expression`, or nil if not called.

If we are currently resuming to an anchor contained in `expression`, `expression` is called regardless of the condition result.

_defined at line 72 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"else if", "(condition, expression=attached block(keep return=true))",`

### else (expression=attached block(keep return=true))

Call `expression` if the last if, else if or else's condition was false, or the last while loop was never entered.
Returns the result of the call to `expression`, or nil if not called.

If we are currently resuming to an anchor contained in `expression`, `expression` is called regardless of the condition result.

_defined at line 89 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"else", "(expression=attached block(keep return=true))",`

### while (condition, expression=attached block(keep return=true))

Call `condition`, if it returns a true value, call `expression`, and repeat until `condition` returns a false value.

Returns the value returned by the the last loop.
If `condition` returns a false value on its first call, returns nil.

If a `continue` happens in the loop, the current iteration is stopped and skipped.
If a `break` happens in the loop, the whole loop is stopped.

```
:i = 1
while(i <= 5)
	print(i)
	i += 1
// 1, 2, 3, 4, 5
```

```
:i = 1
while(i <= 5)
	if(i == 3, break)
	print(i)
	i += 1
// 1, 2
```

```
:i = 1
while(i <= 5)
	if(i == 3, continue)
	print(i)
	i += 1
// 1, 2, 4, 5
```

```
:i = 10
while(i <= 5)
	print(i)
	i += 1
else!
	print("the while loop was never entered")
// the while loop was never entered
```

_defined at line 145 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"while", "(condition, expression=attached block(keep return=true))",`

### break (value=())

Returns a `break` return value, eventually with an associated value.
This can be used to exit a loop.

_defined at line 175 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"break", "(value=())",`

### continue (value=())

Returns a `continue` return value, eventually with an associated value.
This can be used to skip the current loop iteration.

_defined at line 184 of [anselme/stdlib/conditionals.lua](../anselme/stdlib/conditionals.lua):_ `"continue", "(value=())",`

## For loops

### for (symbol::is symbol, var, block=attached block(keep return=true))

Iterates over the elements of `var`: for each element, set the variable `symbol` in the function `block`'s environment and call it.

In order to get the elements of `var`, this calls `iter(var)` to obtain an iterator over var.
An iterator is a function that, each time it is called, returns the next value given to the for loop. When the iterator returns nil, the loop ends.

```
:l = [1,2,3]
// prints 1, 2, and 3
for(:x, l)
	print(x)
```

## Ranges

### range (stop::is number)

Returns a new range, going from 1 to `stop` with a step of 1.

### range (start::is number, stop::is number, step::is number=1)

Returns a new range, going from `start` to `stop` with a step of `step`.

### iter (t::is range)

Returns an iterator that iterates over the range.
For a range going from `start` to `stop` with a step of `step`, this means this will iterate over all the numbers `x` such that x = start + n⋅step with n ∈ N and x ≤ stop, starting from n = 0.


# Arithmetic and math functions

Comparaison operators are designed to be chained:
```
1 < 2 < 3
// is parsed as
(1 < 2) < 3
// (1 < 2) returns 2, 2 < 3 returns 3 which is true
```

### pi

Pi.

_defined at line 17 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "pi", Number:new(math.pi) },`

### a::is number < b::is number

Returns `b` if `a` < `b`, false otherwise.

_defined at line 21 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `"_<_", "(a::is number, b::is number)",`

### a::is false < b::is number

Returns false.

_defined at line 29 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_<_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },`

### a::is number <= b::is number

Returns `b` if `a` <= `b`, false otherwise.

_defined at line 32 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `"_<=_", "(a::is number, b::is number)",`

### a::is false <= b::is number

Returns false.

_defined at line 40 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_<=_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },`

### a::is number > b::is number

Returns `b` if `a` > `b`, false otherwise.

_defined at line 43 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `"_>_", "(a::is number, b::is number)",`

### a::is false > b::is number

Returns false.

_defined at line 51 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_>_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },`

### a::is number >= b::is number

Returns `b` if `a` >= `b`, false otherwise.

_defined at line 54 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `"_>=_", "(a::is number, b::is number)",`

### a::is false >= b::is number

Returns false.

_defined at line 62 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_>=_", "(a::is false, b::is number)", function(state, a, b) return Boolean:new(false) end },`

### a::is number + b::is number

Returns `a` + `b`.

_defined at line 64 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_+_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number + b.number) end },`

### a::is number - b::is number

Returns `a` - `b`.

_defined at line 66 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_-_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number - b.number) end },`

### a::is number * b::is number

Returns `a` * `b`.

_defined at line 68 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_*_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number * b.number) end },`

### a::is number / b::is number

Returns `a` / `b`.

_defined at line 70 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_/_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number / b.number) end },`

### div (a::is number, b::is number)

Returns the integer division of `a` by `b`.

_defined at line 73 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `"div", "(a::is number, b::is number)", function(state, a, b)`

### a::is number % b::is number

Returns the modulo of `a` by `b`.

_defined at line 83 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_%_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number % b.number) end },`

### a::is number ^ b::is number

Returns `a` to the power of `b`.

_defined at line 85 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "_^_", "(a::is number, b::is number)", function(state, a, b) return Number:new(a.number ^ b.number) end },`

### - a::is number

Returns the negative of `a`.

_defined at line 87 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "-_", "(a::is number)", function(state, a) return Number:new(-a.number) end },`

### + a::is number

Returns `a`.

_defined at line 89 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "+_", "(a::is number)", function(state, a) return a end },`

### rand (min::is number, max::is number)

Returns a random integer number with uniform distribution in [`min`, `max`].

_defined at line 92 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "rand", "(min::is number, max::is number)", function(state, min, max) return Number:new(math.random(min.number, max.number)) end },`

### rand (max::is number)

Returns a random integer number with uniform distribution in [1, `max`].

_defined at line 94 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "rand", "(max::is number)", function(state, max) return Number:new(math.random(max.number)) end },`

### rand ()

Returns a random float number with uniform distribution in [0,1).

_defined at line 96 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "rand", "()", function(state) return Number:new(math.random()) end },`

### floor (x::is number)

Returns the largest integral value less than or equal to `x`.

_defined at line 99 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "floor", "(x::is number)", function(state, x) return Number:new(math.floor(x.number)) end },`

### ceil (x::is number)

Returns the smallest integral value greater than or equal to `x`.

_defined at line 101 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "ceil", "(x::is number)", function(state, x) return Number:new(math.ceil(x.number)) end },`

### round (x::is number, increment=1)

Returns `x` rounded to the nearest integer.
If `increment` > 1, rounds to the nearest float with `increment` decimals.

_defined at line 105 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `"round", "(x::is number, increment=1)",`

### sqrt (x::is number)

Returns the square root of `x`.

_defined at line 117 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "sqrt", "(x::is number)", function(state, x) return Number:new(math.sqrt(x.number)) end },`

### abs (x::is number)

Returns the absolute value of `x`.

_defined at line 120 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "abs", "(x::is number)", function(state, x) return Number:new(math.abs(x.number)) end },`

### exp (x::is number)

Returns the exponential of `x`.

_defined at line 123 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "exp", "(x::is number)", function(state, x) return Number:new(math.exp(x.number)) end },`

### log (x::is number)

Returns the natural logarithm of `x`.

_defined at line 125 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "log", "(x::is number)", function(state, x) return Number:new(math.log(x.number)) end },`

### log (x::is number, base::is number)

Returns the logarithm in base `base` of `x`.

_defined at line 127 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "log", "(x::is number, base::is number)", function(state, x, base) return Number:new(math.log(x.number, base.number)) end },`

### deg (x::is number)

Convert `x` from radian to degrees.

_defined at line 130 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "deg", "(x::is number)", function(state, x) return Number:new(math.deg(x.number)) end },`

### rad (x::is number)

Convert `x` from degrees to radians.

_defined at line 132 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "rad", "(x::is number)", function(state, x) return Number:new(math.rad(x.number)) end },`

## Trigonometric functions

All triginometric functions take and return angles in radians.

### cos (x::is number)

Returns the cosinus of `x`.

_defined at line 139 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "cos", "(x::is number)", function(state, x) return Number:new(math.cos(x.number)) end },`

### sin (x::is number)

Returns the sinus of `x`.

_defined at line 141 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "sin", "(x::is number)", function(state, x) return Number:new(math.sin(x.number)) end },`

### tan (x::is number)

Returns the tagent of `x`.

_defined at line 143 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "tan", "(x::is number)", function(state, x) return Number:new(math.tan(x.number)) end },`

### acos (x::is number)

Returns the arc cosinus of `x`.

_defined at line 145 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "acos", "(x::is number)", function(state, x) return Number:new(math.acos(x.number)) end },`

### asin (x::is number)

Returns the arc sinus of `x`.

_defined at line 147 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "asin", "(x::is number)", function(state, x) return Number:new(math.asin(x.number)) end },`

### atan (x::is number)

Returns the arc tangent of `x`.

_defined at line 149 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "atan", "(x::is number)", function(state, x) return Number:new(math.atan(x.number)) end },`

### atan (y::is number, x::is number)

Returns the arc tangent of `x` / `y`, taking the signs of both arguments into account to find the correct quandrant (see [atan2](https://en.wikipedia.org/wiki/Atan2)).

_defined at line 151 of [anselme/stdlib/number.lua](../anselme/stdlib/number.lua):_ `{ "atan", "(y::is number, x::is number)", function(state, y, x) return Number:new((math.atan2 or math.atan)(y.number, x.number)) end },`


# Strings

### a::is string + b::is string

Concatenate two strings and return the result as a new string.

_defined at line 10 of [anselme/stdlib/string.lua](../anselme/stdlib/string.lua):_ `{ "_+_", "(a::is string, b::is string)", function(state, a, b) return String:new(a.string .. b.string) end },`

### len (s::is string)

Returns the length of the string `s`.

_defined at line 13 of [anselme/stdlib/string.lua](../anselme/stdlib/string.lua):_ `"len", "(s::is string)",`

### format (val::is string)

Return the same string.
See [format](#format-val) for details on the format function.

_defined at line 21 of [anselme/stdlib/string.lua](../anselme/stdlib/string.lua):_ `"format", "(val::is string)",`


# Text

### a::is text + b::is text

Concatenate two texts, returning a new text value.

_defined at line 16 of [anselme/stdlib/text.lua](../anselme/stdlib/text.lua):_ `"_+_", "(a::is text, b::is text)",`

### txt::is text !

Write a text event in the event buffer using this text.

_defined at line 30 of [anselme/stdlib/text.lua](../anselme/stdlib/text.lua):_ `"_!", "(txt::is text)",`

### tag (txt::is text, tags::is struct)

Create and return a new text from `text`, with the tags from `tags` added.

_defined at line 38 of [anselme/stdlib/text.lua](../anselme/stdlib/text.lua):_ `"tag", "(txt::is text, tags::is struct)",`

### write choice (text::is text, fn=attached block(keep return=true, default=($()())))

Write a choice event to the event buffer using this text and `fn` as the function to call if the choice is selected.

The same function is also defined in the `*_` operator:
```
*| Choice
	42
// is the same as
write choice(| Choice |, $42)
```

If we are currently resuming to an anchor contained in `fn`, `fn` is directly called and the current choice event buffer will be discarded on flush, simulating the choice event buffer being sent to the host game and this choice being selected.

_defined at line 57 of [anselme/stdlib/text.lua](../anselme/stdlib/text.lua):_ `"write choice", "(text::is text, fn=attached block(keep return=true, default=($()())))",`

### original -> translated

Add a translation so `original` is replaced with `translated`.

_defined at line 74 of [anselme/stdlib/text.lua](../anselme/stdlib/text.lua):_ `"_->_", "(original::is(\"quote\"), translated::is(\"quote\"))",`


# Symbols

### to string (symbol::is symbol)

Return a string of the symbol name.

_defined at line 7 of [anselme/stdlib/symbol.lua](../anselme/stdlib/symbol.lua):_ `"to string", "(symbol::is symbol)",`


# Pairs

### name : value

Returns a new pair with name `name` and value `value`.

Note that if the left expression is an identifier, it is parsed as a string.
```
name: 42
// is the same as
"name": 42
```

_defined at line 16 of [anselme/stdlib/pair.lua](../anselme/stdlib/pair.lua):_ `{ "_:_", "(name, value)", function(state, a, b) return Pair:new(a,b) end },`

### name (pair::is pair)

Returns the pair `pair`'s name.

_defined at line 20 of [anselme/stdlib/pair.lua](../anselme/stdlib/pair.lua):_ `"name", "(pair::is pair)",`

### value (pair::is pair)

Returns the pair `pair`'s value.

_defined at line 27 of [anselme/stdlib/pair.lua](../anselme/stdlib/pair.lua):_ `"value", "(pair::is pair)",`


# Structures

Anselme offers:
* indexed structures: tuple (immutable) and list (mutable)
* dictionary structures: struct (immutable) and table (mutable)

```
:tuple = ["a","b",42]
tuple(2) // "b"

:list = *["a","b",42]
list(2) = "c"

:struct = { a: 42, 2: "b" }
struct("a") // 42

:table = *{ a: 42, 2: "b" }
table(2) = "c"
```


### * t::is tuple

Create a list from the tuple.

_defined at line 30 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"*_", "(t::is tuple)",`

### l::is tuple, i::is number !

Returns the `i`-th element of the tuple.

_defined at line 37 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(l::is tuple, i::is number)",`

### len (l::is tuple)

Returns the length of the tuple.

_defined at line 44 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"len", "(l::is tuple)",`

### find (l::is tuple, value)

Returns the index of the `value` element in the tuple. If `value` is not in the tuple, returns nil.

_defined at line 51 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"find", "(l::is tuple, value)",`

### l::is list, i::is number !

Returns the `i`-th element of the list.

_defined at line 65 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(l::is list, i::is number)",`

### l::is list, i::is number ! = value

Set the `i`-th element of the list to `value`.

_defined at line 72 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(l::is list, i::is number) = value",`

### len (l::is list)

Returns the length of the list.

_defined at line 80 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"len", "(l::is list)",`

### find (l::is list, value)

Returns the index of the `value` element in the list. If `value` is not in the list, returns nil.

_defined at line 87 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"find", "(l::is list, value)",`

### insert (l::is list, value)

Insert a new value `value` at the end of the list.

_defined at line 99 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"insert", "(l::is list, value)",`

### insert (l::is list, i::is number, value)

Insert a new value `value` at the `i`-th position in list, shifting the `i`, `i`+1, etc. elements by one.

_defined at line 107 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"insert", "(l::is list, i::is number, value)",`

### remove (l::is list)

Remove the last element of the list.

_defined at line 115 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"remove", "(l::is list)",`

### remove (l::is list, i::is number)

Remove the `i`-th element of the list, shifting the `i`, `i`+1, etc. elements by minus one.

_defined at line 123 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"remove", "(l::is list, i::is number)",`

### to tuple (l::is list)

Returns a tuple with the same content as this list.

_defined at line 131 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"to tuple", "(l::is list)",`

### * s::is struct

Create a table from the struct.

_defined at line 140 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"*_", "(s::is struct)",`

### s::is struct, key !

Returns the value associated with `key` in the struct.

_defined at line 147 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(s::is struct, key)",`

### s::is struct, key, default !

Returns the value associated with `key` in the struct.
If the `key` is not present in the struct, returns `default` instead.

_defined at line 155 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(s::is struct, key, default)",`

### has (s::is struct, key)

Returns true if the struct contains the key `key`, false otherwise.

_defined at line 166 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"has", "(s::is struct, key)",`

### iter (s::is struct)

Returns an iterator over the keys of the struct.

_defined at line 173 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"iter", "(s::is struct)",`

### t::is table, key !

Returns the value associated with `key` in the table.

_defined at line 187 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(t::is table, key)",`

### t::is table, key, default !

Returns the value associated with `key` in the table.
If the `key` is not present in the table, returns `default` instead.

_defined at line 195 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(t::is table, key, default)",`

### t::is table, key ! = value

Sets the value associated with `key` in the table to `value`, creating it if not present
If `value` is nil, deletes the entry in the table.

_defined at line 207 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(t::is table, key) = value",`

### t::is table, key, default ! = value

Sets the value associated with `key` in the table to `value`, creating it if not present
If `value` is nil, deletes the entry in the table.

_defined at line 216 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"_!", "(t::is table, key, default) = value",`

### has (t::is table, key)

Returns true if the table contains the key `key`, false otherwise.

_defined at line 224 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"has", "(t::is table, key)",`

### to struct (t::is table)

Returns a struct with the same content as this table.

_defined at line 231 of [anselme/stdlib/structures.lua](../anselme/stdlib/structures.lua):_ `"to struct", "(t::is table)",`

### iter (t::is sequence)

Returns an iterator that iterates over the elements of the sequence (a list or tuple).

### iter (t::is table)

Returns an iterator that iterates over the keys of the table.


# Function

### defined (fn::is function, var::is string, search parent::is boolean=false)

Returns true if the variable named `var` is defined in in the function `fn`'s scope, false otherwise.

If `search parent` is true, this will also search in parent scopes of the function scope.

_defined at line 13 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"defined", "(fn::is function, var::is string, search parent::is boolean=false)",`

### overload (l::is sequence)

Creates and returns a new overload containing all the callables in sequence `l`.

_defined at line 25 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"overload", "(l::is sequence)",`

### keep return (f::is function)

Returns a copy of the function that keeps return values intact when returned, instead of only returning the associated value.

_defined at line 38 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"keep return", "(f::is function)",`

### call (func, args::is tuple)

Call `func` with the arguments in `args`, and returns the result.
If pairs with a string name appear in `args`, they are interpreted as named arguments.

_defined at line 47 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"call", "(func, args::is tuple)",`

### call (func, args::is tuple) = v

Call `func` with the arguments in `args` and assignment argument `v`, and returns the result.
If pairs with a string name appear in `args`, they are interpreted as named arguments.

_defined at line 55 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"call", "(func, args::is tuple) = v",`

### can dispatch (func, args::is tuple)

Returns true if `func` can be called with arguments `args`.
If pairs with a string name appear in `args`, they are interpreted as named arguments.

_defined at line 65 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"can dispatch", "(func, args::is tuple)",`

### can dispatch (func, args::is tuple) = v

Returns true if `func` can be called with arguments `args` and assignment argument `v`.
If pairs with a string name appear in `args`, they are interpreted as named arguments.

_defined at line 73 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"can dispatch", "(func, args::is tuple) = v",`

### fn::is function . var::is string

Returns the value of the variable `var` defined in the function `fn`'s scope.

_defined at line 83 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"_._", "(fn::is function, var::is string)",`

### fn::is function . var::is string = v

Sets the value of the variable `var` defined in the function `fn`'s scope to `v`.

_defined at line 92 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"_._", "(fn::is function, var::is string) = v",`

### fn::is function . var::is symbol = v

Define a variable `var` in the function `fn`'s scope with the value `v`.

_defined at line 102 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"_._", "(fn::is function, var::is symbol) = v",`

### return (value=())

Returns a return value with an associated value `value`.
This can be used to exit a function.

_defined at line 114 of [anselme/stdlib/function.lua](../anselme/stdlib/function.lua):_ `"return", "(value=())",`

## Resuming functions

Instead of starting from the beginning of the function expression each time, functions can be started from any anchor anchor literal present in the function expression using the functions resuming functions described below.

```
:$f
	print(1)
	#anchor
	print(2)
f!from(#anchor) // 2
f! // 1, 2
```

To execute a function from an anchor, or _resuming_ a function, Anselme, when evaluating a block, simply skip any line that does not contain the anchor literal (either in the line itself or its attached block) until we reach the anchor.

```
:$f
	print("not run")
	(print("run"), _)
		print("not run")
		#anchor
		print("run")
	print("run")
f!from(#anchor)
```

### from (function::is function, anchor::is anchor)

Call the function `function` with no arguments, starting from the anchor `anchor`.

_defined at line 38 of [anselme/stdlib/resume.lua](../anselme/stdlib/resume.lua):_ `"from", "(function::is function, anchor::is anchor)",`

### from (function::is function, anchor::is nil=())

Call the function `function` with no arguments, starting from the beginning.

_defined at line 45 of [anselme/stdlib/resume.lua](../anselme/stdlib/resume.lua):_ `"from", "(function::is function, anchor::is nil=())",`

### resuming (level::is number=0)

Returns true if we are currently resuming the function call (i.e. the function started from a anchor instead of its beginning).

`level` indicates the position on the call stack where the resuming status should be checked. 0 is where `resuming` was called, 1 is where the function calling `resuming` was called, 2 is where the function calling the function that called `resuming` is called, etc.

_defined at line 54 of [anselme/stdlib/resume.lua](../anselme/stdlib/resume.lua):_ `"resuming", "(level::is number=0)",`

### resume target ()

Returns the current resuming target (an anchor).

_defined at line 65 of [anselme/stdlib/resume.lua](../anselme/stdlib/resume.lua):_ `"resume target", "()",`

### merge branch (complete flush=true)

Merge all variables defined or changed in the branch back into the parent branch.

If `complete flush` is true, all waiting events will be flushed until no events remain before merging the state.

_defined at line 74 of [anselme/stdlib/resume.lua](../anselme/stdlib/resume.lua):_ `"merge branch", "(complete flush=true)",`


# Scripts

Scripts extends on functions to provide tracking and persistence features useful for game dialogs:

* checkpoints allow scripts to be restarted from specific points when they are interrupted or restarted;
* tracking of reached status of anchors to be able to know what has already been shown to the player;
* helper functions to call scripts in common patterns.

```
:hello = "hello"!script
	| Hello...
	#midway!checkpoint
		| Let's resume. Hello...
	| ...world!
hello! // Hello..., ...world!
hello! // Let's resume. Hello..., ...world!
print(hello.reached(#midway)) // 1
print(hello.run) // 2
print(hello.current checkpoint) // #midway
```

### script (name, fn=attached block!)

Creates and returns a new script.

`name` is the script identifier (typically a string), which is used as a prefix for the persistent storage keys of the script variables. This means that for the script variables to be stored and retrieved properly from a game save, the script name must stays the same and be unique for each script.

`fn` is the function that will be run when the script is called.

Some variables are defined into the script/`fn` scope. They are all stored from persistent storage, using the script name as part of their persistent key:

* `current checkpoint` is the currently set checkpoint (an anchor);
* `reached` is a table of *{ #anchor = number, ... } which associates to an anchor the number of times it was reached (see `check` and `checkpoint`);
* `run` is the number of times the script was successfully called.

As well as functions defined in the script scope:

* `check (anchor::is anchor)` increment by 1 the number of times `anchor` was reached in `reached`;
* `checkpoint (anchor::is anchor, on resume=attached block(default=()))` sets the current checkpoint to `anchor`, increment by 1 the number of times `anchor` was reached in `reached`, and merge the current branch state into the parent branch. If we are currently resuming to `anchor`, instead this only calls `on resume!` and keep resuming the script from the anchor.

### s::is script !

Run the script `s`.

If a checkpoint is set, resume the script from this checkpoint.
Otherwise, run the script from the beginning.
`s.run` is incremented by 1 after it is run.

### s::is script . k::is string

Returns the value of the variable `k` defined in the scripts `s`'s scope.

### s::is script . k::is string = val

Sets the value of the variable `k` defined in the scripts `s`'s scope to `val`.

### s::is script . k::is symbol = val

Define the variable `k` in the scripts `s`'s scope with the value `val`.

### from (s::is script, a::is anchor)

Resume the script `s` from anchor `a`, setting it as the current checkpoint.

### from (s::is script, anchor::is nil=())

Run the script `s` from its beginning, discarding any current checkpoint.

### cycle (l::is tuple)

Run the first script in the the tuple `l` with a `run` variable strictly lower than the first element, or the first element if it has the lowest `run`.

This means that, if the scripts are only called through `cycle`, the scripts in the tuple `l` will be called in a cycle:
when `cycle` is first called the 1st script is called, then the 2nd, ..., then the last, and then looping back to the 1st.

### next (l::is tuple)

Run the first script in the tuple `l` with a `run` that is 0, or the last element if there is no such script.

This means that, if the scripts are only called through `next`, the scripts in the tuple `l` will be called in order:
when `next` is first called the 1st script is called, then the 2nd, ..., then the last, and then will keep calling the last element.

### random (l::is tuple)

Run a random script from the typle `l`.


# Environment

### defined (env::is environment, var::is string, search parent::is boolean=false)

Returns true if the variable named `var` is defined in in the environment `env`, false otherwise.

If `search parent` is true, this will also search in parent scopes of the environment `env`.

_defined at line 14 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"defined", "(env::is environment, var::is string, search parent::is boolean=false)",`

### c::is environment . s::is string

Gets the variable named `s` defined in the environment `c`.

_defined at line 26 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"_._", "(c::is environment, s::is string)",`

### c::is environment . s::is string = v

Sets the variable named `s` defined in the environment `c` to `v`.

_defined at line 35 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"_._", "(c::is environment, s::is string) = v",`

### c::is environment . s::is symbol = v

Define a new variable `s` in the environment `c` with the value `v`.

_defined at line 45 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"_._", "(c::is environment, s::is symbol) = v",`

### import (env::is environment, symbol tuple::is tuple)

Get all the variables indicated in the tuple `symbol typle` from the environment `env`,
and define them in the current scope.
```
import(env, [:a, :b])
// is the same as
:a = env.a
:b = env.b
```

_defined at line 63 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"import", "(env::is environment, symbol tuple::is tuple)",`

### import (env::is environment, symbol::is symbol)

Get the variable `symbol` from the environment `env`,
and define it in the current scope.
```
import(env, :a)
// is the same as
:a = env.a
```

_defined at line 79 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"import", "(env::is environment, symbol::is symbol)",`

### load (path::is string)

Load an Anselme script from a file and run it.
Returns the environment containing the exported variables from the file.

_defined at line 89 of [anselme/stdlib/environment.lua](../anselme/stdlib/environment.lua):_ `"load", "(path::is string)",`


# Typed values

### is typed (value)

Returns true if `value` is a typed value, false otherwise.

_defined at line 25 of [anselme/stdlib/typed.lua](../anselme/stdlib/typed.lua):_ `"is typed", "(value)",`

### type (value)

Returns the type of `value`.

If `value` is a typed value, returns its associated type.
Otherwise, returns a string of its type (`"string"`, `"number"`, etc.).

_defined at line 35 of [anselme/stdlib/typed.lua](../anselme/stdlib/typed.lua):_ `"type", "(value)",`

### type (value, type)

Returns a new typed value with value `value` and type `type`.

_defined at line 46 of [anselme/stdlib/typed.lua](../anselme/stdlib/typed.lua):_ `"type", "(value, type)",`

### value (value)

Returns the value of `value`.

If `value` is a typed value, returns its associated value.
Otherwise, returns a `value` directly.

_defined at line 56 of [anselme/stdlib/typed.lua](../anselme/stdlib/typed.lua):_ `"value", "(value)",`


# Persistence helpers

Theses functions store and retrieve data from persistent storage.
Persistent storage is a key-value store intended to be saved and loaded alongside the host game's save files.
See the [relatied Lua API methods](api.md#saving_and_loading_persistent_variables) for how to retrieve and load the persistent data.

A persistent value can be accessed like a regular variable using aliases and the warp operator:
```
:&var => persist("name", "Hero") // persistent value with key "name" and default value "Hero"
print(var) // gets persistent value "name": "Hero"
var = "Link" // sets persistent value "name" to "Link"
```

### persist (key, default)

Returns the value associated with the key `key` in persistent storage.
If the key is not defined, returns `default`.

_defined at line 24 of [anselme/stdlib/persist.lua](../anselme/stdlib/persist.lua):_ `"persist", "(key, default)",`

### persist (key, default) = value

Sets the value associated with the key `key` in persistent storage to `value`.

_defined at line 31 of [anselme/stdlib/persist.lua](../anselme/stdlib/persist.lua):_ `"persist", "(key, default) = value",`

### persist (key)

Returns the value associated with the key `key` in persistent storage.
If the key is not defined, raise an error.

_defined at line 40 of [anselme/stdlib/persist.lua](../anselme/stdlib/persist.lua):_ `"persist", "(key)",`

### persist (key) = value

Sets the value associated with the key `key` in persistent storage to `value`.

_defined at line 47 of [anselme/stdlib/persist.lua](../anselme/stdlib/persist.lua):_ `"persist", "(key) = value",`


# Attached block

The attached block can usually be accessed using the `_` variable. However, `_` is only defined in the scope of the line the block is attached to.
These functions are intended to be used to retrieve an attached block where `_` can not be used directly.

```
// `if` use `attached block!` in order to obtain the attached block without needing to pass `_` as an argument
if(true)
	print("hello")
```

### attached block (level::is number=1, keep return=false)

Return the attached block (as a function).

`level` indicates the position on the call stack where the attached block should be searched. 0 is where `attached block` was called, 1 is where the function calling `attached block` was called, 2 is where the function calling the function that called `attached block` is called, etc.

```
// level is 1, `attached block` is called from `call attached block`: the attached block will be searched from where `call attached block` was called
:$call attached block()
	:fn = attached block!
	fn!
call attached block!
	print("hello")
```

```
// level is 0: the attached block is searched where `attached block` was called, i.e. the current scope
:block = attached block(level=0)
	print("hello")
block! // hello
// which is the same as
:block = $_
	print("hello")
```

if `keep return` is true, if the attached block function returns a return value when called, it will be returned as is (instead of unwrapping only the value associated with the return), and will therefore propagate the return to the current block.

_defined at line 46 of [anselme/stdlib/attached block.lua](../anselme/stdlib/attached block.lua):_ `"attached block", "(level::is number=1, keep return=false)",`

### attached block (level::is number=1, keep return=false, default)

Same as the above function, but returns `default` if there is no attached block instead of throwing an error.

_defined at line 65 of [anselme/stdlib/attached block.lua](../anselme/stdlib/attached block.lua):_ `"attached block", "(level::is number=1, keep return=false, default)",`


# Tagging

### tags # expression

Add the tags from `tags` to the tag stack while calling `expression`.

`tags` can be:

* a tuple of tags
* a struct of tags
* a table of tags
* nil, for no new tags
* any other value, for a single tag

_defined at line 20 of [anselme/stdlib/tag.lua](../anselme/stdlib/tag.lua):_ `"_#_", "(tags, expression)",`


# Wrap operator

### > expression

Returns a new function or overload with `expression` as the function expression.

If `expression` is a function call or an identifier, this returns instead an overload of two functions,
defined like `$<expression>` and `$() = v; <expression> = v`, where `<expression>` is replaced by `expression`.

_defined at line 14 of [anselme/stdlib/wrap.lua](../anselme/stdlib/wrap.lua):_ `">_", "(q::is(\"quote\"))",`


---
_file generated at 2024-06-01T11:51:03Z_