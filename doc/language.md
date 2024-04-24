# Language

The overengineered dialog scripting system.

TODO Introduction: what Anselme is and isn't

This file is indented to be a description of the language. If you are rather looking for an introduction, you might want to look at the [tutorial](tutorial.md) instead.

## Syntax

Anselme files are UTF-8 encoded text files.

### Block

Anselme will try to parse the file as a block expression. A block is a list of expression, each on a separate line.

Each line can be prefixed with indentation, consisting of spaces or tabs. The number of spaces or tabs is the indentation level. Lines with a higher level of indentation than the previous line will create a new block; this new block will be evaluated wherever the `_` block identifier appear in the previous line.

TODO Empty lines

```
1 -- expression on line 1
42 -- expression on line 2
5 + _ -- _ will be replaced with the children block
	print("in children block")
	5
1 + _ -- can be nested indefinitely
	2 + _
		3
```

### Expression

An expression consist of a [literal or identifier](#types_and_literals) and optional [operators](#operators). Operators can be:

* prefix operators that appear before the expression on which it operates, for example the `-` in `-5`;
* suffix operators that appear after the expression on which it operates, for example the `!` in `fn!`;
* infix operators that appear between the two expression on which it operates, for example the `+` in `2+5`.

In the rest of the document, prefix operators are referred using `op_` where `op` is the operator (example: `-_`), suffix operators are referred using `_op` where `op` is the operator (example: `_!`), and infix operators are referred using `_op_` where `op` is the operator (example: `_+_`).

#### Operator precedence

Each operator has an associated precedence number. An operation with a higher precedence will be computed before an operation with a lower precedence. When precedences are the same, operations are performed left-to-right.

```
1+2*2 -- parsed as 1+(2*2)
1*2*3 -- parsed as (1*2)*3
```

List of operators and their precedence:

```
1: _;  _;_  ;_
2:  $_ _,_ _#_ _->_
3: _=_
4:  >_
5: _&_ _|_ _:_
6: _==_ _!=_ _>=_ _<=_ _<_ _>_
7: _+_ _-_
8: _//_ _/_ _*_ _%_
9: _implicit*_
10: _^_
11: _::_  !_  -_ +_  *_  %_
12: _! _!_
13: _()
14: _._
```

#### Built-in operators

The operators described in this section can not be overloaded or redefined in an Anselme script.

`_;` creates a new block expression with the given expression followed by a nil expression.

`_;_` creates a new block expression with the two given expressions.

`;_` returns the given expression.

```
5; -- returns a block containing 5; ()
2; 3 -- returns a block containing 2; 3
;4 -- returns 4
```

`$_` creates a new function. See [function literals](#functions) for details.

`_,_` creates a new tuple with the two given expressions. Additionnal `_,_` can be chained and will add items to to the same tuple.

```
1,2,3,4 -- returns a new tuple [1,2,3,4]
```

`_implicit*_` is invoked when an expression is immediately followed by an identifier, and will call the `_*_` multiplication operator.

```
:x = 3
2x -- returns 6
1/2x -- _implicit*_ has a higher precedence than _/_, so this returns 1/(2*x) = 1/6
```

`_!_` calls the expression on the right with the left expression as an argument. If a `_()` parenthesis call appear immediately after the right expression, the expressions in the parentheses is added to the argument list.

`_()` is used when calling a callable with parentheses, eventually containing arguments. See the [calling callables](#calling_callables) documentation for more details.

```
print("hello world")
-- is the same as
"hello world"!print

function(1, 2, 3)
-- is the same as
1!function(2, 3)
```

#### Overloadable operators

The operators described in this section are defined using regular Anselme functions and can be redefined or overloaded. For example, `1+1` is equivalent `_+_(1, 1)`. For a detailled description of what these operators do by default, look at the [standard library](standard_library.md) documentation.

`_+_`, `_-_`, `_*_`, `_/_`, `_//_`, `_%_`, `_^_` are intended to be used as addition, substraction, multiplication, division, integer division, modulo, and exponentiation respectively.

`-_` and `+_` are intended to be used as the negation and positive prefixes.

`==` and `!=` are intended to be used as the equality and non-equality comparaison.

`>=`, `>`, `<=`, and `<` are intended to be used as the greater-or-equal, greater, lower-or-equal, and lower comparaison respectively.

`_&_` and `_|_`, and `!_` are intended to be used as the boolean short circuiting _and_, boolean short circuiting _or_, and boolean _not_ respectively.

`*_` is intended to be used as the mutability and choice operator. See [list and tables](#list_and_tables) and [choices](#choices) documentation for details.

`_:_` is intended to be used to create pairs. See [pairs](#pairs) documentation for details.

`_#_` is intended to be used to assign tags to an expression. The right expression is automatically wrapped in a function. See [tags](#tags) documentation for details.

`%_` and `_->_` are intended to be used to make an expresion translatable, and define translations respectiveley. See [translatables](#translatables) documentation for details.

`>_` returns a function without parameters that evaluates and return the right expression when called. If the right expression is an identifier or a call, this returns an overload instead which contains the previous function as well as a `() = arg` setter function that set the value associated to the identifier or call the call with an additionnal assignement argument respectively.

`_!` is called when trying to call an expression. It receives the call arguments after the called expression. See the [calling callables](#calling_callables) documentation for more details.

```
var(1, 2)
-- is the same as
_!(var, 1, 2)
```

`_._` is intended to be used to access the variable associated with the right expression into the left expression. If the right expression is an identifier, it will be replaced by a string containing the identifier name.

`_::_` is intended to check the left expression using the right callable expression, and raise an error if its returns a false value. See the [value checking](#value_checking) documentation for more details.

`_=_` is intended to assign the value on the right to the identifier or symbols on the left.

#### Parentheses

An expression can be wrapped in parentheses to bypass usual precedence rules.

```
2*2+1 -- 5
2*(2+1) -- 6
```

Newlines are allowed inside parentheses, so parentheses can also be used to write an expression that span several lines:

```
2 * ( -- indentation is ignored inside the parentheses
	2 +
	1
)
```

#### Calling callables

Callables are values that can be called. This includes functions, overloads, and any other value for which a compatible `_!` operator is defined.

There are four different ways to call a value:

* `val!` to call `val` with no arguments;
* `val(list of arguments)` to call `val` with the given list of arguments (can be empty) (example: `val(1, 2, option=3)`);
* `val!function` to call `function` with a single argument `val`;
* `val!function(list of arguments)` to call `function` with the first argument `val` followed by the given list of arguments (can be empty).

##### Dynamic dispatch

Anselme uses [dynamic dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch), meaning it determine which function should be called at run-time. The dispatch is performed using all of the function parameters.

Functions parameters are set when definining the function as a list of identifiers. See [function literals](#functions) for details on how to define functions.

Each parameter can be associated with a value check function and a default value.

If a default value is set, the associated argument can be omitted when calling the function; the default value expression will be evaluated each time the function is called without the argument and assigned to the parameter.

If a value check function is set, it will be called with the associated argument when trying to dispatch the call. If the value check returns a false value, the dispatch is considered invalid. If the value check returns a number value, it is added to the disptach priority. If the value check returns anything else, the dispatch priority is incremented by one.

When calling an overload (which contains a list of functions, see the [overload documentation](#overloads)), Anselme will try to dispatch to all of the functions defined in the overload, and then select the function with the highest dispatch priority among all of those with a succesful dispatch.

```
:f = $(x, y) 1 -- dispatch priority: 0
:f = $(x::is number, y) 2 -- dispatch priority: 1
:f = $(x::is number, y::is number) 3 -- dispatch priority: 2

f("x", "y") -- returns 1
f(1, "y") -- returns 2
f(1, 2) -- returns 3
```

#### Value checking

Value checking callables can be used to ensure constraint on values at run-time. A value checking function takes a single value as an argument and returns a value. If it returns a false value, the test is considered to be failed, it it returns anything else it is considered to be a success. A value checking variable returning a number have a special meaning when using to check function parameters, see [dynamic dispatch](#dynamic_dispatch) for details. Value checking callables can otherwise appear in [symbol literals](#symbols) and as the right argument of the `_::_` operator.

```
:is positive = $(x::is number) x > 0

5::is positive -- no error
-5::is positive -- error
```

#### Implicit block identifier

If an expression is needed but the end of line is reached instead, an implicit block identifier `_` will be used.

```
1 +
	2
-- is the same as
1 + _
	2
```

### Comments

Comments can appear anywhere in an expression in an expression and are ignored by Anselme.

Inline comments starts with `--` and are terminaed either by another `--` or the end of the line or expression.

Multiline comments starts with `/*` and are terminated with `*/`. They can be nested, and can also appear in inline comments.

```
-- inline comment
-- inline comment, explicit end --
/*
multiline
comment
/* nested */
*/
```

### Scoping rules

TODO

## Types and literals

Unless specified otherwise, all types are immutable.

### Nil

Nil values are used as a fallback when no value is explicitely given but one is still needed, for example if a function or block do not return a value. A nil value is therefore intended to be used to represent the absence of a useful value.

Nil values are the only values, along with the false boolean, to not be considered true in conditions.

A nil value can be obtained explicitely using empty parentheses:

```
()
```

### Numbers

All Anselme numbers are IEEE 754 double precision floating point numbers.

Numbers literals can be written with a integer part, a fractional part, or both. The fractional part must be preceded by a decimal point separator:

```
0
0.0
.0
-- are all equal to 0
```

### String

Strings represent a string of characters.

Strings literal starts with a `"` and end with a `"`. Specials characters, including `\"` can be escaped by prefixing them by a `\`. Some escape sequences have a special meaning:

* `\n` is replaced with a newline
* `\t` is replaced with a tab character

Non-escaped `{` in the string start an interpolated expression; any expression can then follow, but a closing `}` is expected after it. When the string literal is evaluated, each interpolated expression will be evaluated, the returned value will be formatted to a string and appear in the string where the `{` expression `}` appeared in the literal.

Strings can contain newlines.

```
"string"
"multiline
string"
"1+1={1+1}"
```

### Boolean

Booleans can be either true or false, and are intended to be used when testing for a condition.

The boolean false is the only value, along with nil, to not be considered true in conditions.

The `true` and `false` variables defined in the standard library contains a true and false boolean value, respectively:

```
true
false
```

### Anchors

Anchors consist of a name which is a string of characters. Anchors are intended to be used to mark a specific position in the Anselme code (the position where the anchor literal appear), in order to resume the code execution from this point, similar to goto labels in other programming languages.

Anchor literals consist of a `#` followed by any valid identifier, that will be used as the anchor name:

```
#anchor name
```

### Symbols

Symbols consist of an identifier and additionnal metadata, and are intended to be used in variable definitions.
See the [assignment operators](#assignments) documentation for details on how they are used.

Symbols literals consist of a `:` followed by optional metadata flags, and then any valid identifier. Valid metadata flags are:

* `&` to indicate the variable is an alias:
* `@` to indicate the variable is exported.

Several metadata flags can be used at the same time, as long as they always appear in the order above.

Following the identifier, the `::` operator can optionnaly be used. See [value checking](#value_checking) for information on the `::` operator.
A variable defined using a symbol with value checking will perform the value check every time the variable is re-assigned. Note that the value check is only done for re-assignment and not the initial variable declaration. See the [assignment operators](#assignments) documentation for details.

```
:symbol
:&alias symbol
:@exported symbol
:&@alias exported symbol

:positive::is positive
:constant symbol::constant -- constant is a special value checking function that always fail, thus preventing reassignment
```

### Identifiers

Identifiers are a string of characters that represent a variable.

When evaluated, an identifier will return the value associated with the variable represented by the identifier, or raise an error if there is no such variable.

An identifier must not contain any of the characters ``+-*/%^=<>[]{}()|\_.,`!?;:~"@&$#`` and newline characters.
They must not start with a digit or a `'` character. Any space or tab characters at the start or end of the identifier are ignored.

Any other valid unicode character is otherwise allowed.

```
identifier
spaces are allowed
and so are numbers like 42 as long as they are not the first character of the identifier
```

In addition, Anselme define some special identifiers that do not follow these rules. `_` is a valid identifier representing the attached block (see the [block](#block) documentation). Operators that can be redefined each have an associated special identifier:

* `_op_` for infix operators, where `op` is the operator (example: `_+_`)
* `_op` for suffix operators, where `op` is the operator (example: `_!`)
* `op_` for prefix operators, where `op` is the operator (example: `-_`)

### Text

Texts represent a list of strings and tags. See the [event](#events) documentation for details on texts and tags.

Texts literal starts with a `|` and are terminated either by another `|` or the end of the line or expression. Specials characters can be escaped and interpolated expressions can be used in the same way as in [string literals](#string). If an interpolated expression returns a text, it is merged into the current text, keeping its tags.

When evaluated the text literal will evaluate each string and interpolated expression that appear in it and store the result along the current tag state.

If a space or tab appear at the start or end of the text literal, it is ignored.

When one of the lines of a block consist only of a text literal, it is automatically called.

```
| text
| text with explicit terminator |
| text with explicit terminator |! -- equivalent to the previous line
| 1+1={1+1}

1 #
	| tagged 1 {2 # | tagged 2}

fn(| Text) -- the text literal is not automatically called when it is not the main expression of the line
```

#### Return

Return values consist of a an arbitrary value.

When a return value appear as one of the lines of a block, the block is stopped and immediately return the return value.

When a return value is returned from a function call, the value associated with the return value is returned instead.

Return values can be created using the `return` function from the standard library.

```
:a = $
	return(5)
	12
a! -- a! is 5
```

The `break` and `continue` functions from the standard library also return return values, with additionnal metadata to allow special behavior when returned from [control flow functions](standard_library.md#control_flow).

### Pairs

Pairs associate two arbitrary values.

Pairs are built using the `_:_` identifier, with the left argument giving the name and the right the value of the pair.

```
"name":"value"
```

### Tuple

Tuples consist of a list of arbitrary values.

A tuple literal starts with `[` and is terminated with `]`. Tuple elements are separated by commas `,`. Newlines are allowed inside the tuple litteral.

Tuples can also be build using the `_,_` operator, without enclosing them in braces.

```
[1,2,"3","4"]
1,2,"3","4"
[] -- empty tuple
[ 1, 2,
	3 ] -- can span several lines
```

### Structs

Structs consist of a map of arbitraty key-values pairs.

A struct literal starts with `{` and is terminated with `}`. Structs elements are separated by commas `,`. Newlines are allowed inside the struct litteral. Each element can be:

* a pair, in which case the name and value of the pair is used are used as the key and value of the struct element, respectively;
* any other value, in which case the position number (starting from 1) of the element in the struct literal is used as the key and the value as the value of the struct element.

```
{1:"a", "key":"value", 3:"b"}
-- is the same as
{"a", "key":"value", "b"}
{} -- empty struct
{ 1, 2,
	3 } -- can span several lines
```

### List and tables

Lists are mutable tuples. Tables are mutable structs.

Lists and tables can be obtained by using the `*_` operator on a tuple and struct, respectively.

```
*[1,2,"3","4"]
*{"a", "key":"value", "b"}
```

### Typed types

Custom types consist of an arbitraty value associated with another arbitraty value. The associated type value will be considered to be the new type of the value.

A custom type can be obtained using the `type(value, custom type)` function from the standard library.

```
:var = type(10, "$")
var!type -- returns "$"
var!value -- returns 10
```

When trying to convert the custom type to a string, for example in a string interpolation, the `format(custom type)` function call will be tried. If the function can be called, its return value will be used as the string representation of the value.

```
:var = type(10, "$")
:$format(x::is("$"))
	"${x!value}"
print("{var}") -- prints "$10"
```

### Functions

TODO incl func def

### Overloads

TODO

### Translatables

Any expression can be made translatable using the `%_` operator. A translatable expression, when evaluated, will return the translation associated with the expression, or the unchanged expression if no translation is defined.

```
%"hello" -> "bonjour"
%"hello" -- returns "bonjour"
%"world" -- returns "world"
```

TODO contexts

## Events

TODO

### Tags

TODO

### Texts

TODO

### Choices

TODO
