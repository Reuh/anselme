return [[
:@$is(t) $(x) x!type == t
:@$equal(x) $(y) x == y

:@is nil = is("nil")
:@is number = is("number")
:@is string = is("string")
:@is boolean = is("boolean")
:@is symbol = is("symbol")
:@is anchor = is("anchor")
:@is pair = is("pair")

:@is text = is("text")

:@is sequence = $(x) x!type == "tuple" | x!type == "list"
:@is tuple = is("tuple")
:@is list = is("list")

:@is map = $(x) x!type == "struct" | x!type == "table"
:@is struct = is("struct")
:@is table = is("table")

:@is environment = is("environment")

:@is function = is("function")
:@is overload = is("overload")
:@is callable = $(x) x!type == "overload" | x!type == "function" | x!type == "quote"
]]