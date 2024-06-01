---# Value checking
--
-- See the [language reference](language.md#value_checking) for information on how value checking functions works.
-- @titlelevel 3

--- Returns a function `$(x)` that returns true if `x` is of type `t`, false otherwise.
-- @title is (t)

--- Returns a function `$(y)` that returns true if `x` is equal to `y`, false otherwise.
-- @title is equal (x)

--- Returns a true if `x` is a nil, false otherwise.
-- @title is nil (x)

--- Returns a true if `x` is a number, false otherwise.
-- @title is number (x)

--- Returns a true if `x` is a string, false otherwise.
-- @title is string (x)

--- Returns a true if `x` is a boolean, false otherwise.
-- @title is boolean (x)

--- Returns a true if `x` is false, false otherwise.
-- @title is false (x)

--- Returns a true if `x` is true, false otherwise.
-- @title is true (x)

--- Returns a true if `x` is a symbol, false otherwise.
-- @title is symbol (x)

--- Returns a true if `x` is an anchor, false otherwise.
-- @title is anchor (x)

--- Returns a true if `x` is a pair, false otherwise.
-- @title is pair (x)

--- Returns a true if `x` is a text, false otherwise.
-- @title is text (x)

--- Returns a true if `x` is a sequence (a tuple or a list), false otherwise.
-- @title is sequence (x)

--- Returns a true if `x` is a list, false otherwise.
-- @title is list (x)

--- Returns a true if `x` is a map (a struct or a table), false otherwise.
-- @title is map (x)

--- Returns a true if `x` is a struct, false otherwise.
-- @title is struct (x)

--- Returns a true if `x` is a table, false otherwise.
-- @title is table (x)

--- Returns a true if `x` is an environment, false otherwise.
-- @title is environment (x)

--- Returns a true if `x` is a function, false otherwise.
-- @title is function (x)

--- Returns a true if `x` is an overload, false otherwise.
-- @title is overload (x)

return [[
:@$is(t) $(x) x!type == t
:@$is equal(x) $(y) x == y

:@is nil = is("nil")
:@is number = is("number")
:@is string = is("string")
:@is boolean = is("boolean")
:@is false = $(x) !x
:@is true = $(x) !!x
:@is symbol = is("symbol")
:@is anchor = is("anchor")
:@is pair = is("pair")

:@is text = is("text")

:@is sequence = $(x) x!type == "tuple" | x!type == "list"
:@is list = is("list")

:@is map = $(x) x!type == "struct" | x!type == "table"
:@is struct = is("struct")
:@is table = is("table")

:@is environment = is("environment")

:@is function = is("function")
:@is overload = is("overload")
]]