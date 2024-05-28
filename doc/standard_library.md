TODO

# Variable assignment

TODO intro

#### identifier = value

Assign `value` to the variable `identifier`.

_defined at line 50 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"_=_", "(quote::is quoted(\"identifier\"), value)",`

#### symbol::is symbol = value

Define the variable using the symbol `symbol` with the initial value `value`.

_defined at line 59 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"_=_", "(quote::is quoted(\"symbol\"), value)",`

#### variable tuple::is tuple = value tuple::is tuple

For each `variable` element of the variable tuple and associated `value` element of the value tuple, call `variable = value`.

_defined at line 73 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"_=_", "(quote::is quoted(\"tuple\"), value::is tuple)",`


# Value checking

TODO

#### constant (exp)

Always return false.
Can be used as variable value checking function to prevent any reassignment and thus make the variable constant.
```
:var::constant = 42
```

_defined at line 12 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"constant", "(exp)",`

#### is tuple (exp)

Returns true if the expression is a tuple, false otherwise.

_defined at line 21 of [anselme/stdlib/assignment.lua](../anselme/stdlib/assignment.lua):_ `"is tuple", "(exp)",`


# Control flow

TODO

---
_file generated at 2024-05-28T16:12:56Z_