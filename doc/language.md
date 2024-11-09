# Language

The overengineered dialog scripting system.

Anselme is a dynamically typed scripting language intended to be embedded in game engines, focusing on making writing complex branching dialogues and interactions easier.

Anselme attemps to provide:

* first-class support for game dialog scripting, providing support for dialog blocks and choices along with flexible rich text metadata using tags;
* syntax that focuses on staying close to natural language, allowing for spaces in identifiers, full translation of the standard library, significant indentation;
* familiar enough constructs to be easily picked up by someone familiar with existing imperative and functional languages;
* be easily extensible and abusable by designing the language around simple but composable constructs.

Anselme does not attemps to provide:

* a general purpose language;
* speed or any kind of efficiency, as it is only aimed at dialogs and not general game scripting;
* and ultimately, Anselme was originally designed as a specific solution to a specific problem I had while making games without thinking about much else. I'd be flatterred if someone else ends up using it though.

Notable features:

* dynamic dispatch using user-definable type checking functions and function overloading;
* first-class functions with closures;
* can run several scripts in parallel and independently;
* built-in variable persistence with checkpoints.

This file is indented to be a description of the language. If you are rather looking for an introduction, you might want to look at the [tutorial](tutorial.md) instead.

## Syntax

Anselme files are UTF-8 encoded text files.

### Block

Anselme will try to parse the file as a block expression. A block is a list of expression, each on a separate line.

Each line can be prefixed with indentation, consisting of spaces or tabs. The number of spaces or tabs is the indentation level. Lines with a higher level of indentation than the previous line will create a new block; this new block will be evaluated wherever the `_` block identifier appear in the previous line.
Empty lines are ignored with regard to indentation.

```
1 // expression on line 1
42 // expression on line 2
5 + _ // _ will be replaced with the children block
	print("in children block")
	5
1 + _ // can be nested indefinitely
	2 + _
		3
```

### Expression

An expression consist of a [literal or identifier](#types-and-literals) and optional [operators](#operators). Operators can be:

* prefix operators that appear before the expression on which it operates, for example the `-` in `-5`;
* suffix operators that appear after the expression on which it operates, for example the `!` in `fn!`;
* infix operators that appear between the two expression on which it operates, for example the `+` in `2+5`.

In the rest of the document, prefix operators are referred using `op_` where `op` is the operator (example: `-_`), suffix operators are referred using `_op` where `op` is the operator (example: `_!`), and infix operators are referred using `_op_` where `op` is the operator (example: `_+_`).

#### Operator precedence

Each operator has an associated precedence number. An operation with a higher precedence will be computed before an operation with a lower precedence. When precedences are the same, operations are performed left-to-right.

```
1+2*2 // parsed as 1+(2*2)
1*2*3 // parsed as (1*2)*3
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
8: _/_ _*_ _%_
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
5; // returns a block containing 5; ()
2; 3 // returns a block containing 2; 3
;4 // returns 4
```

`$_` creates a new function. See [function literals](#functions) for details.

`_,_` creates a new tuple with the two given expressions. Additionnal `_,_` can be chained and will add items to to the same tuple.

```
1,2,3,4 // returns a new tuple [1,2,3,4]
```

`_implicit*_` is invoked when an expression is immediately followed by an identifier, and will call the `_*_` multiplication operator.

```
:x = 3
2x // returns 6
1/2x // _implicit*_ has a higher precedence than _/_, so this returns 1/(2*x) = 1/6
```

`_!_`, where the right expression is an identifier, calls the expression on the right with the left expression as an argument. If a `_()` parenthesis call appear immediately after the right expression, the expressions in the parentheses is added to the argument list.

```
"hello"!len
// is the same as
len(hello)

[1]!insert(2)
// is the same as
insert([1], 2)

// If the right expression is not an identifier, the ! is interpreted as a _! operator, i.e. calling the left expression without arguments.
fn!-5
// is the same as
fn() - 5
```

`_()` is used when calling a callable with parentheses, eventually containing arguments. See the [calling callables](#calling-callables) documentation for more details.

```
print("hello world")
// is the same as
"hello world"!print

function(1, 2, 3)
// is the same as
1!function(2, 3)
```

#### Overloadable operators

The operators described in this section are defined using regular Anselme functions and can be redefined or overloaded. For example, `1+1` is equivalent `_+_(1, 1)`. For a detailled description of what these operators do by default, look at the [standard library](standard_library.md) documentation.

`_+_`, `_-_`, `_*_`, `_/_`, `_%_`, `_^_` are intended to be used as addition, substraction, multiplication, division, modulo, and exponentiation respectively.

`-_` and `+_` are intended to be used as the negation and positive prefixes.

`==` and `!=` are intended to be used as the equality and non-equality comparaison.

`>=`, `>`, `<=`, and `<` are intended to be used as the greater-or-equal, greater, lower-or-equal, and lower comparaison respectively.

`_&_` and `_|_`, and `!_` are intended to be used as the boolean short circuiting _and_, boolean short circuiting _or_, and boolean _not_ respectively.

`*_` is intended to be used as the mutability and choice operator. See [list and tables](#list-and-tables) and [choices](#choices) documentation for details.

`_:_` is intended to be used to create pairs. See [pairs](#pairs) documentation for details.

`_#_` is intended to be used to assign tags to an expression. The right expression is automatically wrapped in a function. See [tags](#tags) documentation for details.

`%_` and `_->_` are intended to be used to make an expresion translatable, and define translations respectiveley. See [translatables](#translatables) documentation for details.

`>_` returns a function without parameters that evaluates and return the right expression when called. If the right expression is an identifier or a call, this returns an overload instead which contains the previous function as well as a `() = arg` setter function that set the value associated to the identifier or call the call with an additionnal assignement argument respectively.

`_!` is called when trying to call an expression. It receives the call arguments after the called expression. See the [calling callables](#calling-callables) documentation for more details.

```
var(1, 2)
// is the same as
_!(var, 1, 2)
```

`_._` is intended to be used to access the variable associated with the right expression into the left expression. If the right expression is an identifier, it will be replaced by a string containing the identifier name.

`_::_` is intended to check the left expression using the right callable expression, and raise an error if its returns a false value. See the [value checking](#value-checking) documentation for more details.

`_=_` is intended to assign the value on the right to the identifier or symbols on the left.

#### Parentheses

An expression can be wrapped in parentheses to bypass usual precedence rules.

```
2*2+1 // 5
2*(2+1) // 6
```

Newlines are allowed inside parentheses, so parentheses can also be used to write an expression that span several lines:

```
2 * ( // indentation is ignored inside the parentheses
	2 +
	1
)
```

#### Calling callables

Callables are values that can be called. This includes functions, overloads, and any other value for which a compatible `_!` function is defined.

There are four different ways to call a value:

* `function!` to call `function` with no arguments;
* `function(list of arguments)` to call `function` with the given list of arguments (can be empty) (example: `function(1, 2, option=3)`);
* `val!function` to call `function` with a single argument `val`;
* `val!function(list of arguments)` to call `function` with the first argument `val` followed by the given list of arguments (can be empty).

For all of these syntax, an assignment argument can optionally be given by following the call with a `=` followed by the assignment argument expression.

```
:$no argument
no argument!
no argument()

:$with argument(x)
with argument(42)
42!with argument
42!with argument()

:$with arguments(x, y)
with arguments(42, 24)
42!with arguments(24)

:$with assignment(x="default") = v
with assignment! = 42
with assignment() = 42
"x"!with assignment = 42
"x"!with assignment() = 42
```

There are three ways to associate an argument to a function parameter:

* named arguments: using the argument name followed by the `=` operator and the argument expression (ex: `argument name=value`), the expression will be assoctaed with the parameter with the same name;
* positional arguments: the i-th argument in the argument list is associated with the i-th parameter in the function definition parameter list;
* the assignment argument is always associated with the assignment parameter.

If the function only takes a single tuple or struct as an argument, the parentheses can be omitted.

```
:$fn(x)

fn[1,2,3]
// is the same as
fn([1,2,3])

fn{1:2,3}
// is the same as
fn({1:2,3})
```

##### Dynamic dispatch

Anselme uses [dynamic dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch), meaning it determine which function should be called at run-time. The dispatch is performed using all of the function parameters.

Functions parameters are set when definining the function as a list of identifiers. See [function literals](#functions) for details on how to define functions.

Each parameter can be associated with a value check function and a default value.

If a default value is set, the associated argument can be omitted when calling the function; the default value expression will be evaluated each time the function is called without the argument and assigned to the parameter.

If a value check function is set, it will be called with the associated argument when trying to dispatch the call. If the value check returns a false value, the dispatch is considered invalid. If the value check returns a number value, it is added to the disptach priority. If the value check returns anything else, the dispatch priority is incremented by one.

When calling an overload (which contains a list of functions, see the [overload documentation](#overloads)), Anselme will try to dispatch to all of the functions defined in the overload, and then select the function with the highest dispatch priority among all of those with a succesful dispatch.

```
:f = $(x, y) 1 // dispatch priority: 0
:f = $(x::is number, y) 2 // dispatch priority: 1
:f = $(x::is number, y::is number) 3 // dispatch priority: 2

f("x", "y") // returns 1
f(1, "y") // returns 2
f(1, 2) // returns 3
```

#### Value checking

Value checking callables can be used to ensure constraint on values at run-time. A value checking function takes a single value as an argument and returns a value. If it returns a false value, the test is considered to be failed, it it returns anything else it is considered to be a success. A value checking variable returning a number have a special meaning when using to check function parameters, see [dynamic dispatch](#dynamic-dispatch) for details. Value checking callables can otherwise appear in [symbol literals](#symbols) and as the right argument of the `_::_` operator.

```
:is positive = $(x::is number) x > 0

5::is positive // no error
-5::is positive // error
```

#### Implicit block identifier

If an expression is needed but the end of line is reached instead, an implicit block identifier `_` will be used.

```
1 +
	2
// is the same as
1 + _
	2
```

### Comments

Comments can appear anywhere in an expression in an expression and are ignored by Anselme.

Inline comments starts with `//` and are terminaed either by another `//` or the end of the line or expression.

Multiline comments starts with `/*` and are terminated with `*/`. They can be nested, and can also appear in inline comments.

```
// inline comment
// inline comment, explicit end //
/*
multiline
comment
/* nested */
*/
```

### Variables

Variables can be defined and assigned using the `_=_` operator.

To define a variable, the left expression must be a [symbol](#symbols), for an assignment, an identifier. The left expression can also be a tuple for multiple assignments.

```
:x = 3 // definition

x = 12 // assignment

:y = 2
(x, y) = (y, x) // multiple assignment (value swap)
```

When defining a variable, the symbol can have additionnal metadata (value check, exported, and alias) that affect the variable definition behavior.

#### Variable value checking

If the symbol has a [value checking](#value-checking) function associated, the defined variable will perform the value check every time it is re-assigned. Note that the value check is only done for re-assignment and not the initial variable declaration.

```
:$is positive(x) x > 0
:x::is positive = 0
x = 5 // ok
x = -4 // value checking error!

:constant symbol::constant = 12 // constant is a special value checking function that always fail, thus preventing reassignment
constant symbol = 13 // value checking error!
```

#### Exported variables

If the symbol has an `@` export flag, the variable will be defined in the [export scope](#export-scope) instead of the current scope, i.e. will be defined for the whole file and be made accessible from outside files. See [export scope](#export-scope) for details.

#### Alias variables

If the symbol has an `&` alias flag, the variable will be an alias. Instead of directly accessing the value of the variable, the variable will:

* when get, call its value with no argument and returns the result;
* whet set, call its value with an assignment argument and returns the result.

```
:&x = overload [
	$() "variable read"
	$() = v; "variable set to {v}"
]
x // "variable read"
x = 42 // "variable set to 42"

:&y = 	$() "variable read"
x // "variable read"
x = 42 // error, since function can't be called with an assignment argument
```

The `>_` wrap operator is intended to be used alongside aliases. The `>_` operator will wrap the expression on the right in a function, so that it is evaluated when called without arguments, and evaluated with an added assignement (if possible) when called with an assignment argument.

```
:&x => persist("x")
// is the same as
:&x = overload [
	$() persist("x"),
	$() = v; persist("x") = v
]
```

### Scoping rules

A variable is only accessible in the scope it was defined in and its children scopes.

Once a variable is defined in a scope, it cannot be redefined in this scope. Trying to access a variable that is not defined or accessible in a scope raises and error.

A new scope is defined:

* for the whole file;
* for each code block, as a child of the scope the block appears in;
* and for a function body, when it is defined and then each time is is called.

```
// define in the whole file scope
:a = "accessible in the whole script"

a // refer to the whole file scope

if(true)
	a // refer to the whole file scope

	// redefine in a child block scope
	:a = "accessible in this block"

	a // refer to the block scope

a // we exited the block, refer to the whole file scope again
```

For functions, a new scope is created when the function is defined, where upvalue definitions are linked with their initial definitions.

Then, each time the function is called, a new call scope is crated as a child of the function scope when running the function body.

```
// define in the whole file scope
:a = 2

:$f(x)
	a = 3 // refer to the function definition scope (upvalue linked with the whole file scope)

	// redefine in function call scope
	:a = [x, a]

	a // refer to the function call scope

f(1) // [1, 3]

a // 3
```

The function definition scope can be accessed using the `_._` operator if there is a need to define custom variables in it. As the function definition scope is not recreated on each call, this can be used to store function state accross calls.

```
:$f() a
f.:a = 6

f! // 6
```

#### Export scope

Exported variables, unlike regular variables, are not defined in the current scope but the closest export scope. An export scope is defined for each file, so any exported variable will be defined for the whole file.

Additionnaly, when loading a file using the `load` function, the loaded file's export scope is returned and can thus be accessed from other files.

```
// in first.ans
:@exported = "hello"

// in second.ans
load("first.ans").exported
```

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
// are all equal to 0
```

### String

Strings represent a string of characters.

Strings literal starts with a `"` and end with a `"`. Specials characters, including `\"` can be escaped by prefixing them by a `\`. Some escape sequences have a special meaning:

* `\n` is replaced with a newline
* `\t` is replaced with a tab character

Non-escaped `{` in the string start an interpolated expression; any expression can then follow, but a closing `}` is expected after it. When the string literal is evaluated, each interpolated expression will be evaluated, the returned value will be converted to a string using `format` and appear in the string where the `{` expression `}` appeared in the literal.

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
See the [variable definition](#variables) documentation for details on how they are used.

Symbols literals consist of a `:` followed by optional metadata flags, and then any valid identifier. Valid metadata flags are:

* `&` to indicate the variable is an alias:
* `@` to indicate the variable is exported.

Several metadata flags can be used at the same time, as long as they always appear in the order above.

Following the identifier, the `::` operator can optionnaly be used. See [value checking](#value-checking) for information on the `::` operator.

```
:symbol
:&alias symbol
:@exported symbol
:&@alias exported symbol

:positive::is positive
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
| text with explicit terminator |! // equivalent to the previous line
| 1+1={1+1}

1 #
	| tagged 1 {2 # | tagged 2}

fn(| Text) // the text literal is not automatically called when it is not the main expression of the line
```

### Return

Return values consist of a an arbitrary value.

When a return value is returned by one of the lines of a block, the block is stopped and immediately return the return value.

When a return value is returned from a function call, the value associated with the return value is returned instead.

Return values can be created using the `return` function from the standard library.

```
:a = $
	return(5)
	12
a! // a! is 5
```

The `break` and `continue` functions from the standard library also return return values, with additionnal metadata to allow special behavior when returned from [control flow functions](standard_library.md#control-flow).

### Pairs

Pairs associate two arbitrary values.

Pairs are built using the `_:_` identifier, with the left argument giving the name and the right the value of the pair. If the left argument is an identifier, it will be converted to a string for convenience.

```
"name":"value" -- is the same as
name:"value"

-- if you need to use the value associated with the `name` variable instead, the identifier can be wrapped in parentheses
:name = "key"
(name):"value"
```

### Tuple

Tuples consist of a list of arbitrary values.

A tuple literal starts with `[` and is terminated with `]`. Tuple elements are separated by commas `,`. Newlines are allowed inside the tuple litteral.

Tuples can also be build using the `_,_` operator, without enclosing them in braces.

```
[1,2,"3","4"]
1,2,"3","4"
[] // empty tuple
[ 1, 2,
	3 ] // can span several lines
```

### Structs

Structs consist of a map of arbitraty key-values pairs.

A struct literal starts with `{` and is terminated with `}`. Structs elements are separated by commas `,`. Newlines are allowed inside the struct litteral. Each element can be:

* a pair, in which case the name and value of the pair is used are used as the key and value of the struct element, respectively;
* any other value, in which case the position number (starting from 1) of the element in the struct literal is used as the key and the value as the value of the struct element.

```
{1:"a", "key":"value", 3:"b"}
// is the same as
{"a", "key":"value", "b"}
{} // empty struct
{ 1, 2,
	3 } // can span several lines
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
var!type // returns "$"
var!value // returns 10
```

When trying to convert the custom type to a string, for example in a string interpolation, the `format(custom type)` function will be called. How custom types appear in strings can therefore be changed by overloading the `format` function.

```
:var = type(10, "$")
:$format(x::is("$"))
	"${x!value}"
print("{var}") // prints "$10"
```

### Functions

Functions can be created using the function literal starting with the `$_` operator.

The `$_` operator has two forms:

* if it is followed by a opening parenthesis `(`, it expects the `(` to start a parameter list; then the function expression is expected;
* otherwise, the function expression is expected right after and the function will take no parameter.

The function expression is the expression run when the function is called.

The parameter list is a comma separated list of identifier (the parameter name). Each parameter name can be optionally followed by either or both of, in this order:

* `::` followed by a [value checking](#value-checking) function;
* `=` followed by a default value. The default value will be evaluated and used as the parameter value each time the function is called without the associated argument.

After the `)` closing the parameter list, an assignment parameter can optionally be given after a `=` operator. The assignment parameter follows the same syntax as other parameters otherwise.

See [calling callabales](#calling-callables) to see how arguments are passed to functions and [dynamic dispatch](#dynamic-dispatch) to see how function parameters influence function dispatch.

When evaluated, the function literal will evaluate its parameter list, create a new scope for the function, link the scope with the function's upvalue, and returns an evaluated function (a closure).

```
// no parameter
$5+2
// is the same as
$() 5+2

// single parameter
$(x) x*x

// several parameters
$(x, y) x*y

// optional parameter
$(x, multiply by=2) x*multiply by

// assignment parameter
$() = v; v
$(x) = v; x*v

// note: $_ has an operator precedence of 2, so the body will continue until an operator of lower or equal precedence is used in the expression
$1, $2 // same as ($1), ($2) as _,_ has a precedence of 2
```

#### Function definition

A variable can be defined and assigned a new function quickly using the function definition syntax.

The function definition syntax consist of a modified [symbol literal](#symbols) with a `$` right before the symbol name, followed by either a parameter list and expression or the function expression directly, in the same way as the [`$_` operator](#functions) described above.

When evaluated, the function definition will create a new function and define a new variable set to this function.

```
:$f(x) x
// is the same as
:f = $(x) x

:$f
	42
```

Additionally, special forms of the function definition syntax exists for operator functions:

* for prefix operators, the operator followed by the parameter can be used (e.g., `-x` for `-_` with an `x` parameter);
* for infix operators, the operator followed by the parameter can be used (e.g., `x+y` for `_+_` with an `x` and `y` parameters);
* for suffix operators, the operator followed by the parameter can be used (e.g., `x!` for `_!` with an `x` parameter).

For these forms, the parameters can optionally be wrapped in parentheses in case of operator precedence conflicts.

```
:$-x
// is the same as
:$-_(x)

:$x+y
// is the same as
:$_+_(x, y)

:$x!
// is the same as
:$_!(x)

// _::_ has a lower precedence than _._, parentheses are needed or this would be parsed as a::(is number.b)
:$(a::is number).b
```

### Environments

Environments consist of a scope, and can be used to get, set, and define variable in a scope that isn't the current one.

An environment can, for example, be obtained using `load(path)`, which returns the exported scope of the file `path`.

### Overloads

Overloads consist of a list of arbitrary values. Each value should be [callable](#calling-callables).

An overload can be created using the `overload(tuple)` function. An overload is also automatically created when redefining a variable that contains a callable value.

```
:f = $(x) x
:f = $(x, y) x, y
f!type // f is now an overload containing the two functions defined above

// and this is the same as
:g = overload [
	$(x)(x),
	$(x, y)(x, y)
]
```

When called, the call arguments will be checked against each element of the overload for dispatchability. The dispatchable element with the highest dispatch priority will then be called. See [dynamic dispatch](#dynamic-dispatch) for details on the dispatch process.

### Translatables

Any expression can be made translatable using the `%_` operator. A translatable expression, when evaluated, will return the translation associated with the expression, or the unchanged expression if no translation is defined.

Translations can be defined using the `_->_` operator.

```
%"hello" -> "bonjour"
%"hello" // returns "bonjour"
%"world" // returns "world"
```

When searching for a translation, the translation context will also be checked. The translation context is a struct; for the translation to be used, the elements of the context of the translated expression must match the context of the translatable expression. If there are several translation that match the translatable context, the one with the most matching contexts elements is selected.

Each translatable expression has the following context elements defined in its context struct:

* `source`, the full source string (e.g. `file.ans:5:6`, from file.ans, line 5, column 6)
* `file`, the path of the file the script is from (e.g. `file.ans`).

When defining a translation using the `_->_` operator, the translation context is obtained from the current tags.

```
file: "first.ans" #
	%"hello" -> "bonjour"

// in first.ans
%"hello" // returns "bonjour"

// in second.ans
%"hello" // returns "hello"
```

## Events

Events are message passed from Anselme to the host game. For example, a text event can be sent to indicate to the game that it should display some text. Each event consist of an event type (a string) and associated data (arbitrary value).

Events are buffered; i.e. when an Anselme script write a new event, it is not immediately sent to the host game but added to a buffer list until a flush occurs. Flushs are trigerred when:

* an event of a different type from the one currently stored in the buffer is writtent;
* on a manual flush.

Manual flush can be trigerred using the `---` keyword.

Additionally, when the end of the currently running script is reached, Anselme will flush the event buffer repeately until it is empty (flushes can have side-effects, including writing new events to the buffer, thus requiring further flushing).

```
| Write a text event to the buffer.
| Another text event.

*| Write a choice event, trigerring a flush (the list of buffered text events is sent to the host game) since event type changed.

--- // manual flush, choice event is sent to the host game

*| Write a choice event to a new buffer.

// end-of-script, last choice event is sent to the host game
```

### Texts

Text events are intended represent a line of text, dialog, or other textual information to be shown in the host game.

A text event value can be created using the [text literal](#text). A text is written to the buffer when it is called. When a text literal appear alone as a line of a block, it is automatically called.

```
| Write a text event.

:text = | Text
text!
```

### Choices

Choice events are intended to represent a player choice in the host game. Each choice event in the buffer list is intended to represent a distinct choice.

A choice consist of a text value and a function; when the choice is selected, the function is run.

A choice event can be written to the buffer using the `*_` operator on a text event value. The attached block will be used as the associated function.

```
*| Choice A
	| Choice A has been selected.
*| Choice B
	| Choice B has been selected.
```

### Tags

Text and choice events can also carry metadata through tags. Tags are stored as a [struct](#struct).

When evaluated, text literals retrieve the current tags and associate them to the text. Tags are also evaluated for each text interpolation that is part of the text separately.

Tags can be set using the `_#_` operator: the tags elements from the left expression (either a single value, a list of values, a struct or table) are added to the current tag struct while evaluation the right expression. If a tag element in the left expression is already set in the current tag struct, it is redefined.

```
| No tags

"one" # | Tags: {1:"one"}

color:"red", from:"Alex" #
	| Tags: {color:"red", from:"Alex"}

	size:"humongous" #
		| Tags: {color:"red", from:"Alex", size:"humongous"}

	from:"You" #
		| Tags: {color:"red", from:"You"}

| To assign different tags to different parts of the text, {color:"red" #| text interpolations} can be used.
```
