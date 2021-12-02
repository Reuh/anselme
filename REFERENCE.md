Anselme reference
=================

Language reference
------------------

### Main structure

Anselme will read a bunch of different scripts files and execute them afterward. Like you would expect of... any? scripting language. We use the `.ans` file extension for files.

Scripts are read line per line, from top to bottom. Some lines can have children; children lines are indented with some sort of whitespace, whether it's tabs or space (as long as it's consistent), like in Python.

```
> Parent line.
    Child line.

    > Another child line.
        But this one have a child. Grand-child.

Another line.

                random line whith indentation which makes no sense at all.
```

#### Checkpoints

When executing a piece of Anselme code, your scripts will not directly modify the global state (i.e. the values of variables used by every script), but only locally, in its associated interpreter instance. Meaning that if you change a variable, its value will only be set in the local state, so the new value will be accessible from the current interpreter but not other interpreters, at least until the next checkpoint. Similarly, the first time your script reads a variable its value at this time is kept into the local state so it can not be affected by other scripts, at least until the next checkpoint.

Right after reaching a checkpoint line, Anselme will merge the local state with the global one, i.e., make every change accessible to other scripts, and get checkpointed changes from other scripts.

```
$ main
    :var = 5

    ~ var := 2

    before: {var}==2, because the value has been changed in the current execution context

    (But if we run the script "parallel" in parallel at this point, it will still think var==5)

    § foo
        But the variable will be merged with the global state on a checkpoint

    after: {var}==2, still, as expected

    (And if we run the script "parallel" in parallel at this point, it will now think var==2)

$ parallel
    parallel: {main.var}

~ main
```

The purpose of this system is both to allow several scripts to run at the same time with an easy way to avoid interferences, and to make sure the global state is always in a consistent (and not in the middle of a calculation): since scripts can be interrupted at any time, when it is interrupted, anything that was changed between the last checkpoint and the interruption will be discarded. If you're a RDBMS person, that's more-or-less equivalent to a transaction with a repeatable read isolation level (without any sort of locking or lost update protection though).

When running the script again, it will resume correctly at the last reached checkpoint. See [function calls](#function-calls) for more details on how to call/resume a function.

Checkpoints are set per function, and are expected to be defined inside functions only.

State merging also happens after a checkpoint has been manually called or resumed from.

### Lines types

There's different types of lines, depending on their first character(s) (after indentation).

#### Lines that can have children:

* `(`: comment line. Everything following this is ignored. Doesn't even check for children indentation and syntax correctness, so have fun.

```
(FANCY COMMENT YEAH)
    so many
            things
        to say
    here
```

* `~`: condition line. Can be followed by an [expression](#expressions); otherwise the expression `1` is assumed. If the expression evaluates to [true](#truethness), run its children. Without children, this line is typically use to simply run an expression.

* `~~`: else-condition. Same as a condition line, but is only run if the last condition or else-condition line (in the same indentation block) was false (regardless of line distance).

```
~ 1
    This is true
~~
    This is never run.


~ 0
    This is never run.
~~ 1 == 0
    This neither.
~~
    This is.
```

* `>`: write a choice into the [event buffer](#event-buffer). Followed by arbitrary text. Support [text interpolation](#text-interpolation); if a text event is created during the text interpolation, it is added to the choice text content instead of the global event buffer. Support [escape codes](#escape-codes). Empty choices are discarded.

```
$ f
    Third choice

> First choice
> Second choice
> Last choice
> {f}
```

If an unescaped `~` or `#` appears in the line, the associated operator is applied to the line (see [operators](#operators)), using the previous text as the left argument and everything that follows as the right argument expression.

```
(Conditionnaly executing a line)
$ fn
    > show this choice only once ~ 👁️

(Tagging a single line)
> tagged # 42
    not tagged
```

* `$`: function line. Followed by an [identifier](#identifiers), then eventually an [alias](#aliases), and eventually a parameter list. Define a function using its children as function body. Also define a new namespace for its children (using the function name if it has no arguments, or a unique name otherwise).

The function body is not executed when the line is reached; it must be explicitely called in an expression. See [expressions](#function-calls) to see the different ways of calling a function.

A parameter list can be optionally given after the identifier. Parameter names are identifiers, with eventually an alias (after a `:`) and a default value (after a `=`), and then a type annotation (after a `::`). It is enclosed with paranthesis and contain a comma-separated list of identifiers:

```
$ f(a, b: alias for b, c="default for c", d: alias for d = "default for d")
    first argument: {a}
    second argument: {b}
    third argument: {c}
    fourth argument: {d}

$ f(a::string, b: alias for b::string, c::alias="default for c"::string)
    same
```

Functions can also have a variable number of arguments. By adding `...` after the last argument identifier, it will be considered a variable length argument ("vararg"), and will contain a list of every extraneous argument.

```
$ f(a, b...)
    {b}

(will print [1])
~ f("discarded", 1)

(will print [1,2,3])
~ f("discarded", 1, 2, 3)

(will print [])
~ f("discarded")
```

Functions with the same name can be defined, as long as they have a different arguments. Functions will be selected based on the number of arguments given, their name and their type annotation:

```
$ f(a, b)
    a

$ f(x)
    b

$ f(x::string)
    c

(will print a)
~ f(1,2)

(will print b)
~ f(1)

(will print c)
~ f("hello")
```

Every operator, except assignement operators, `|`, `&`, `,`, `~` and `#` can also be use as a function name in order to overload the operator:

```
$ /(a::string, b::string)
    @"{a}/{b}"
```

After the parameter list, you may also write `:=` followed by an identifier, and eventually an alias. This defines an assignement function, which will be called when assigning a value to the function:

```
:x = "value"
$ f()
    @x
$ f() := v
    @x := v

value = {f}

~ f() := "other"

other = {f}
```

Functions can return a value using a [return line](#lines-that-can-t-have-children).

Functions always have the following variables defined in its namespace by default:

`👁️`: number, number of times the function was executed before
`🔖`: string, name of last reached checkpoint

* `§`: checkpoint. Followed by an [identifier](#identifiers), then eventually an [alias](#aliases). Define a checkpoint. Also define a new namespace for its children.

The function body is not executed when the line is reached; it must either be explicitely called in an expression or executed when resuming the parent function (see checkpoint behaviour below). Can be called in an expression. See [expressions](#checkpoint-calls) to see the different ways of calling a checkpoint manually.

The local interpreter state will be merged with the global state when the line is reached. See [checkpoints](#checkpoints).

When executing the parent function after this checkpoint has been reached (using the paranthesis-less function call syntax), the function will resume from this checkpoint, and the checkpoint's children will be run. This is meant to be used as a way to restart the conversation from this point after it was interrupted, providing necessary context.

```
$ inane dialog
    Hello George. Nice weather we're having today?
    § interrupted
        What was I saying? Ah yes, the weather...
    (further dialog here)
```

Checkpoints always have the following variable defined in its namespace by default:

`👁️`: number, number of times the checkpoint was executed before
`🏁`: number, number of times the checkpoint was reached before (includes times where it was resumed from and executed)

* `#`: tag line. Can be followed by an [expression](#expressions); otherwise nil expression is assumed. The results of the [expression](#expressions) will be added to the tags send along with any `choice` or `text` event sent from its children. Can be nested.

```
# "color": "red"
    Text tagged with a red color

    # "blink"
        Tagged with a red color and blink.
```

#### Lines that can't have children:

* `:`: variable declaration. Followed by an [identifier](#identifiers) (with eventually an [alias](#aliases)), a `=` and an [expression](#expressions). Defines a variable with a default value and this identifier in the current [namespace]("identifiers"). The expression is not evaluated instantly, but the first time the variable is used.

```
:foo = 42
:bar : alias = 12
```

* `@`: return line. Can be followed by an [expression](#expressions); otherwise nil expression is assumed. Exit the current function and returns the expression's value.

```
$ hey
    @5

{hey} = 5
```

Please note that Anselme will discard returns values sent from within a choice block. Returns inside choice block still have the expected behaviour of stopping the execution of the choice block.

This is the case because choice blocks are not ran right as they are read, but only at the next event flush (i.e. empty line). This means that if there is no flush in the function itself, the choice will be ran *after* the function has already been executed and returning a value at this point makes no sense:

```
$ f
    > a
        @1
    @2

(f will return 2 since the choice is run after the @2 line)
~ f == 2

    Yes.

(Choice block is actually ran right before the "Yes" line, when the choice event is flushed.)

```

* empty line: flush the event buffer, i.e., if there are any pending lines of text or choices, send them to your game. See [Event buffer](#event-buffer). This line always keep the same identation as the last non-empty line, so you don't need to put invisible whitespace on an empty-looking line. Is also automatically added at the end of a file.

* regular text: write some text into the [event buffer](#event-buffer). Support [text interpolation](#text-interpolation). Support [escape codes](#escape-codes).

```
Hello,
this is some text.

And this is more text, in a different event.
```

If an unescaped `~` or `#` appears in the line, the associated operator is applied to the line (see [operators](#operators)), using the previous text as the left argument and everything that follows as the right argument expression.

```
(Conditionnaly executing a line)
$ fn
    run this line only once ~ 👁️

(Tagging a single line)
tagged # 42
```

### Line decorators

Every line can also be followed with decorators, which are appended at the end of the line and affect its behaviour. Decorators are just syntaxic sugar to make some common operations simpler to write.

* `$`: function decorator. Same as a function line, behaving as if this line was it sole child, but also run the function. Function can not take arguments.

```
text $ f
```

is equivalent to:

```
~ f
$ f
    text 
```

This is typically used for immediatletly running functions when defining them, for example for a looping choice :

```
~$ loop
    > Loop
        @loop
    > Exit
```

is equivalent to:

```
$ loop
    > Loop
        @loop
    > Exit
~ loop
```

### Text interpolation

Text and choice lines allow for arbitrary text. Expression can be evaluated and inserted into the text as the line is executed by enclosing the [expression](#expressions) into brackets. The expressions are evaluated in the same order as the reading direction.

The expression is automatically wrapped in a call to `{}(expr)`. You can overload `{}` to change its behaviour for custom types; main intended use is to provide some pretty-printing function.

Note that events can be sent from the interpolated expression as usual. So you may not want to send a choice event or flush the event buffer from, for example, an interpolated expression in a text line, as your text line will be cut in two with the flush or choice between the two halves.

Text interpolated in choices have the special property of capturing text events into the choice text.

```
:a = 5

Value of a: {a}

(in text and choices, text events created from an interpolated expression are included in the final text)
$ f
    wor
    (the returned value comes after)
    @"ld."

(Will print "Hello world.")
Hello {f}

> Hello {f}

(keep in mind that events are also sent as usual in places that would usually not send event and thus can't really handle them in a sensible manner)
(for example in text litterals: this will send a "wor" text event and put "ld." in b)
:b = "{f}"
```

Text interpolation in text and choices lines also support subtexts: this will process text in squares brackets `[]` in the same way as a regular text line.

```
Hello [world].

(Typically used to tag part of a line in a compact manner)
Hello [world#5]

> Hello [world#5]
```

### Events

Anselme need to give back control to the game at some point. This is done through events: the interpreter regularly yield its coroutine and returns a bunch of data to your game. This is the "event", it is what we call whatever Anselme sends back to your game.

Each event is composed of two elements: a type (string; `text`, `choice`, `return` or `error` by default, custom types can also be defined) and associated data; the data associated with each event depends on its type. For the default events this data is:

* `text` (text to display) is a list of text elements, each with a `text` field, containing the text contents, and a `tags` field, containing the tags associated with this text.
* `choice` (choices to choose from) is a list of tableas, each associated to a choice. Each of these choice is a list of text elements like for the `text` event.
* `return` (when the script ends) is the returned value.
* `error` (when the script error) is the error message.

#### Event buffer

For some event types (`text` and `choice`), Anselme does not immediately sends the event as soon as they are available but appends them to a buffer of events that will be sent to your game on the next event flush line (empty line): this is the "event buffer".

```
Some text.
Another text.

(the above flush line will cause Anselme to send two text events containing the two previous lines)
Text in another event.
```

Beyond technical reasons, the event buffer serves as a way to group together several lines. For example, choice A and B will be sent to the game at the same time and can therefore be assumed to be part of the same "choice block", as opposed to choice C wich will be sent alone:

```
> Choice A
> Choice B

> Choice C
```

In practise, this is mostly useful to provide some choice or text from another function:

```
$ reusable choice
    > Reusable choice

> Choice A
~ reusable choice
> Choice C
```

Besides empty lines, Anselme will also automatically flush events when the current event type change (when reaching a choice line with a text event in the event buffer, or vice versa), so your game only has to handle a single event of a single type at a time. For example, this will send a text event, flush it, and then buffer a choice event:

```
Text
> Choice
```

By default, some processing is done on the event buffer before sending it to your game. You can disable these by disabling the associated features flages using `vm:disable` (see #api-reference).

* strip trailing spaces: will remove any space caracters at the end of the text (for text event), or at the end of each choice (for choice event).

```
(There is a space between the text and the tag expression that would be included in the text event otherwise.)
Some text # tag
```

* strip duplicate spaces: will remove any duplicated space caracters between each element that constitute the text (for text event), or for each choice (for choice event).

```
(There is a space between the text and the tag expression; but there is a space as well after the text interpolation in the last line. The two spaces are converted into a single space (the space will belong to the first text element, i.e. the "text " element).)
$ f
    text # tag

Some {text} here.
```

TODO: check if spacing rules are language-specific and move this to language files if appropriate

### Identifiers

Valid identifiers must be at least 1 caracters long and can contain anything except the caracters ``~`^+-=<>/[]*{}|\_!?,;:()"@&$#%`` (that is, every special caracter on a US keyboard except '). They can contain spaces. They can not start with a number.

When defining an identifier (using a function, checkpoint or variable delcaration line), it will be defined into the current namespace (defined by the parent function/checkpoint). When evaluating an expression, Anselme will look for variables into the current line's namespace, then go up a level if it isn't found, and so on. Note that the namespace of functions with arguments are not accessible from outside the function.

In practise, this means you have to use the "genealogy" of the variable to refer to it from a line not in the same namespace:

```
$ fn1
    (everything here is in the fn1 namespace)
    $ fn2
        (fn1.fn2 namespace)
        :var2 = 42
        Var2 = 42: {var2}

    Var2 = not found: {var2}
    Var2 = 42: {fn2.var2}

    :var1 = 1

Var2 = 42: {fn1.fn2.var2}

:var1 = 2

Var1 in the current namespace = 1: {var1}
Var1 in the fn1 namespace = 2: {fn1.var1}

(Weird, but valid, and also the reason I'm not talking of scoping:)
~ fn1.var1 == 3
```

#### Aliases

When defining identifiers (in variables, functions or checkpoint definitions), they can be followed by a colon and another identifier. This identifier can be used as a new way to access the identifier (i.e., an alias).

```
:name: alias = 42

{name} is the same as {alias}
```

Note that alias have priority over normal identifiers; if both an identifier and an alias have the same name, the alias will be used.

The main purpose of aliases is translation. When saving the state of your game's script, Anselme will store the name of the variables and their contents, and require the name to be the same when loading the save later, in order to correctly restore their values.

This behaviour is fine if you only have one language; but if you want to translate your game, this means the translations will need to keep using the original, untranslated variables and functions names if it wants to be compatible with saves in differents languages. Which is not very practical or nice to read.

Anselme's solution is to keep the original name in the translated script file, but alias them with a translated name. This way, the translated script can be written withou constantly switching languages:

```
(in the original, english script)
:player name = "John Pizzapone"

Hi {player name}!

(in a translated, french script)
:player name : nom du joueur = "John Pizzapone"

Salut {nom du joueur} !
```

Variables that are defined automatically by Anselme (`👁️`, `🔖` and `🏁` in checkpoints and functions) can be automatically aliased using `vm:setaliases("👁️alias", "🔖alias", 🏁alias")`. See [API](#api-reference).

### Expressions

Besides lines, plenty of things in Anselme take expressions, which allow various operations on values and variables.

Note that these are *not* Lua expressions.

#### Types

Default types are:

* `nil`: nil. Can be defined using empty parantheses `()`.

* `number`: a number (double). Can be defined using the forms `42`, `.42`, `42.42`.

* `string`: a string. Can be defined between double quotes `"string"`. Support [text interpolation](#text-interpolation). Support [escape codes](#escape-codes).

* `list`: a list of values. Types can be mixed. Can be defined between square brackets and use comma as a separator '[1,2,3,4]'.

* `pair`: a couple of values. Types can be mixed. Can be defined using colon `"key":5`. Pairs named by a string that is also a valid identifier can be created using the `key=5` shorthand syntax.

* `type`: a couple of values. Types can be mixed. Can be defined using colon `expr::type`. The second value is used in type checks, this is intended to be use to give a custom type to a value.

How conversions are handled from Anselme to Lua:

* `nil` -> `nil`

* `number` -> `number`

* `string` -> `string`

* `list` -> `table`. Pair elements in the list will be assigned as a key-value pair in the Lua list and its index skipped in the sequential part, e.g. `[1,2,"key":"value",3]` -> `{1,2,3,key="value"}`.

* `pair` -> `table`, with a single key-value pair.

How conservions are handled from Lua to Anselme:

* `nil` -> `nil`

* `number` -> `number`

* `string` -> `string`

* `table` -> `list`. First add the sequential part of the table in the list, then add pairs for the remaining elements, e.g. `{1,2,key="value",3}` -> `[1,2,3,"key":"value"]`

* `boolean` -> `number`, 0 for false, 1 for true.

#### Escape codes

These can be used to represent some caracters in string and other text elements that would otherwise be difficult to express due to conflicts with Anselme syntax.

* `\\` for `\`
* `\"` for `"`
* `\n` for a newline
* `\t` for a tabulation
* `\{` for `{`
* `\[` for `[`
* `\~` for `~`
* `\#` for `#`
* `\$` for `$`

#### Truethness

Only `0` and `nil` are false. Everything else is considered true.

#### Function calls

The simplest way to call a function is simply to use its name. If the function has no arguments, parantheses are optional:

```
$ f
    called

~ f

$ f(a)
    called with {a}

~ f("an argument")
```

Please note, however, that if the function contains checkpoints, these two syntaxes behave differently. Without parantheses, the function will resume from the last reached checkpoint; with parantheses, the function always restart from its beginning:

```
$ f
    a
    § checkpoint
        b
    c

No checkpoint reached, will write "a" and "c":
~ f

Checkpoint is now reached, will write "b" and "c":
~ f

Force no checkpoint, will write "a" and "c":
~ f()

```

Functions with arguments can also be called with a "method-like" syntax (though Anselme has no concept of classes and methods):

```
$ f(a)
    called with {a}

"an argument".f

$ f(a, b)
    called with {a} and {b}

"an argument".f("another argument")
```

If the function has a return value, any of these calls will of course return the value.

```
$ f
    @"text"

this is text: {f}
```

Functions can also have default arguments. Defaults values can be any expression and are re-evaluated each time the function is called:

```
$ f(a, b=1)
    @a+b

{f(1)} = 2

$ g(a, b=a)
    @a+b

{g(1)} = 2
{g(2)} = 4
```

Arguments can also be passed by naming them instead of their position. These syntaxes can be mixed:

```
$ f(a, b, c)
    @a + b + c

{f(1,2,3)} = {f(c=3,b=2,a=1)} = {f(1,2,c=3)}
```

Anselme actually treat argument list are regular lists; named arguments are actually pairs. Arguments are evaluated left-to-right.

This means that pairs can't be passed directly as arguments to a function (as they will be considered named arguments). If you want to use pairs, always wrap them in a list.

Functions can have a variable number of arguments. Additional arguments are added in a list:

```
$ f(a, b...)
    {a}

    {b}

{f(1, 2, 3, 4, 5)}

(Will print:)
    1
    [2,3,4,5]
```

Anselme use dynamic dispatch, meaning the correct function is selected at runtime. The correct function is selected based on number of arguments, argument names, and argument type annotations. The function with the most specific arguments will be selected. If several functions match, an error is thrown.

```
$ fn(x::number, y)
    a

$ fn(x::number)
    b

$ fn(a::string)
    c

$ fn(x::number, y::number)
    c

a = {fn(5, "s")}

b = {fn("s")}

c = {fn(5)}

d = {fn(5, 2)}

$ g(x)

$ g(x, a="t")

error, can't select unique function: {g(5)}
```

#### Checkpoint calls

Most of the time, you should'nt need to call checkpoints yourself - they will be automatically be set as the active checkpoint when the interperter reach their line, and they will be automatically called when resuming its parent function.

But in the cases when you want to manually set the current checkpoint, you can call it with a similar syntax to paranthesis-less function calls:

```
$ f
    a
    § checkpoint
        b
    c

Force run the function starting from checkpoint, will write "b" and "c" and set the current checkpoint to "checkpoint":
~ f.checkpoint

Will correctly resumes from the last set checkpoint, and write "b" and "c":
~ f

Function can always be restarted from the begining using parantheses:
~ f()
```

You can also only execute the checkpoints' children code only by using a parantheses-syntax:

```
$ f
    a
    § checkpoint
        b
    c

Run the checkpoint only, will only write "b" and set the current checkpoint to "checkpoint":
~ f.checkpoint()

And will resume from the checkpoint like before:
~ f
```

Method style calling is also possible, like with functions.

Checkpoints merge variables after being called (either manually or automatically from resuming a function). See [checkpoints](#checkpoints). The merge always happen after the checkpoint's child block has been ran.

Please also be aware that when resuming from a checkpoint, Anselme will try to restore the interpreter state as if the function was correctly executed from the start up to this checkpoint. This includes:

* if the checkpoint is in a condition block, it will assume the condition was true (but will not re-evaluate it)
* if the checkpoint is in a choice block, it will assume this choice was selected (but will not re-evaluate any of the choices from the same choice group)
* will try to re-add every tag from parent lines; this require Anselme to re-evaluate every tag lines that are a parent of the checkpoint in the function. Be careful if your tag expressions have side-effects.

##### Operator priority

From lowest to highest priority:

```
;
:=  +=  -=  //= /=  *=  %=  ^=
,
|   &   ~   #
!=  ==  >=  <=  <   >
+   -
*   //  /   %
::  :
unary -, unary !
^
.
```

A series of operators with the same priority are evaluated left-to-right.

#### Operators

Built-in operators:

##### Assignement

`a := b`: evaluate b, assign its value to identifier `a`. Returns the new value.

`a(index) := b`: evaluate b, assign its value to element of specific index in list `a`. Element is searched using the same method as list index operator `a(b)`; if indexing using a string and an associated pair doesn't exist, add a new one at the end of the list. Returns the new value.

`a += b`: evaluate b, assign its the current value of a `+` the value of b to a. Returns the new value.

`-=`, `*=`, `/=`, `//=`, `%=`, `^=`: same with other arithmetic operators.

##### Comparaison

`a == b`: returns `1` if a and b have the same value (will recursively compare list and pairs), `0` otherwise

`a != b`: returns `1` if a and b do not have the same value, `0` otherwise

These only work on numbers:

`a > b`: returns `1` if a is greater than b are different, `0` otherwise

`<`, `>=`, `<=`: same with lower, greater or equal, lower or equal

##### Arithmetic

These only work on numbers.

`a + b`: evaluate a and b, returns their sum.

`-`, `*`, `/`, `//`, `^`: same for substraction, multiplication, division, integer division, exponentiation

`-a`: evaluate a, returns its opposite

This only works on strings:

`a + b`: evaluate a and b, concatenate them.

##### Logic operators

`!a`: evaluate a, returns `0` if it is true, `1` otherwise

`a & b`: and operator, lazy

`a | b`: or operator, lazy

##### Various

`a ; b`: evaluate a, discard its result, then evaluate b. Returns the result of b.

`a : b`: evaluate a and b, returns a new pair with a as key and b as value.

`a :: b`: evaluate a and b, returns a new typed value with a as value and b as type.

`a ~ b`: evaluates b, if true evaluates a and returns it, otherwise returns nil (lazy).

`a # b`: evaluates b, then evaluates a whith b added to the active tags. Returns a.

`a(b)`: evaluate b (number), returns the value with this index in a (list). Use 1-based indexing. If b is a string, will search the first pair in the list with this string as its name. Operator is named `()`.

`{}(v)`: function called when formatting a value in a text interpolation for printing.

#### Built-in functions

##### Pair methods

`name(pair)`: returns the name (first element) of a pair

`value(pair)`: returns the value (second element) of a pair

##### List methods

`len(list)`: returns length of the list

`insert(list[, position], value)`: insert a value at position (by default, the end of the list)

`remove(list, [position])`: remove the list element at position (by default, the end of the list)

`find(list, value)`: returns the index of the first element equal to value in the list; returns 0 if no such element found.

##### Sequential execution

`cycle(...)`: given function/checkpoint identifiers as string as arguments, will execute them in the order given each time the function is ran; e.g., `cycle("a", "b")` will execute a on the first execution, then b, then a again, etc.

`next(...)`: same as cycle, but will not cycle; once the end of sequence is reached, will keep executing the last element.

`random(...)`: same arguments as before, but execute a random element at every execution.

##### Various

`alias(identifier::string, alias::string)`: define an alias `alias` for variable `identifier`. Expect fully qualified names.

`rand([m[, n]])`: when called whitout arguments, returns a random float in [0,1). Otherwise, returns a random number in [m,n]; m=1 if not given.

`error(str)`: throw an error with the specified message

`raw(v)`: return v, stripped of its custom types

`type(v)`: return v's type

#### Built-in variables

TODO see stdlib/bootscript.lua

API reference
-------------

TODO see anselme.lua
