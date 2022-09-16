Anselme language reference
==========================

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
:$ main
    :var = 5

    ~ var := 2

    before: {var}==2, because the value has been changed in the current execution context

    (But if we run the script "parallel" in parallel at this point, it will still think var==5)

    :! foo
        But the variable will be merged with the global state on a checkpoint

    after: {var}==2, still, as expected

    (And if we run the script "parallel" in parallel at this point, it will now think var==2)

:$ parallel
    parallel: {main.var}

~ main

(note: if two scripts try to modify the same value at the same time, one of them will win, but which one is undefined/a surprise)
```

The purpose of this system is both to allow several scripts to run at the same time with an easy way to avoid interferences, and to make sure the global state is always in a consistent (and not in the middle of a calculation): since scripts can be interrupted at any time, when it is interrupted, anything that was changed between the last checkpoint and the interruption will be discarded. If you're a RDBMS person, that's more-or-less equivalent to a transaction with a repeatable read isolation level (without any sort of locking or lost update protection though).

When running the script again, it will resume correctly at the last reached checkpoint. See [function calls](#function-calls) for more details on how to call/resume a function.

Checkpoints are set per function, and are expected to be defined inside functions only.

State merging also happens after a checkpoint has been manually called or resumed from.

### Lines types

There's different types of lines, depending on their first character(s) (after indentation).

* `(`: comment line. Everything following this is ignored. Doesn't even check for children indentation and syntax correctness, so have fun.

```
(FANCY COMMENT YEAH)
    so many
            things
        to say
    here
```

#### Text lines:

Lines that can append data to the event buffer and emit text or choice events.

* `>`: write a choice into the [event buffer](#event-buffer). Followed by arbitrary text. Support [text interpolation](#text-interpolation); if a text event is created during the text interpolation, it is added to the choice text content instead of the global event buffer. Support [escape codes](#escape-codes). Empty choices are discarded.

```
:$ f
    Third choice

> First choice
> Second choice
> Last choice
> {f}
```

If an unescaped `~`, `~?` or `#` appears in the line, the associated operator is applied to the line (see [operators](#operators)), using the previous text as the left argument and everything that follows as the right argument expression.

```
(Conditionnaly executing a line)
:$ fn
    > show this choice only once ~ 👁️

(Tagging a single line)
> tagged # 42
    not tagged
```

* regular text, i.e. any line that doesn't start with a special line type character: write some text into the [event buffer](#event-buffer). Support [text interpolation](#text-interpolation). Support [escape codes](#escape-codes). Don't accept children lines.

```
Hello,
this is some text.

And this is more text, in a different event.
```

If an unescaped `~`, `~?` or `#` appears in the line, the associated operator is applied to the line (see [operators](#operators)), using the previous text as the left argument and everything that follows as the right argument expression.

```
(Conditionnaly executing a line)
:$ fn
    run this line only once ~ 👁️

(Tagging a single line)
tagged # 42
```

* empty line: flush the event buffer, i.e., if there are any pending lines of text or choices, send them to your game. See [Event buffer](#event-buffer). This line always keep the same identation as the last non-empty line, so you don't need to put invisible whitespace on an empty-looking line. Is also automatically added at the end of a file. Don't accept children lines.

#### Expression lines:

Lines that evaluate an [expression](#expressions) and do something with the result.

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

* `~?`: while loop line. Works like `~` condition lines, but if the expression evaluates to true and after it ran its children, will reevaluate the expression again and repeat the previous logic until the expression eventually evaluates to false.

```
(Count to 10:)
:i = 1
~? i < 10
    {i}

    ~ i += 1

(else-conditions can be used if the expression has never evalated to true in the loop:)
~ i := 5
~? i < 2
    Never happens.
~~
    This is run.
```

* `#`: tag line. Can be followed by an [expression](#expressions); otherwise nil expression is assumed. The results of the [expression](#expressions) will be wrapped in a map and added to the tags send along with any `choice` or `text` event sent from its children. Can be nested.

```
# color="red"
    Text tagged with a red color

    # "blink"
        Tagged with a red color and blink.
```

* `@`: return line. Can be followed by an [expression](#expressions); otherwise nil expression is assumed. Exit the current function and returns the expression's value.

```
:$ hey
    @5

{hey} = 5
```

If this line has children, they will be ran _after_ evaluating the returned expression but _before_ exiting the current function. If the children return a value, it is used instead.

```
(Returns 0 and print 5)
:$ fn
    :i=0

    @i
        ~ i:=5
        {i}

(Returns 3)
:$ g
    @0
        @3
```

Please note that Anselme will discard returns values sent from within a choice block. Returns inside choice block still have the expected behaviour of stopping the execution of the choice block.

This is the case because choice blocks are not ran right as they are read, but only at the next event flush (i.e. empty line). This means that if there is no flush in the function itself, the choice will be ran *after* the function has already been executed and returning a value at this point makes no sense:

```
:$ f
    > a
        @1
    @2

(f will return 2 since the choice is run after the @2 line)
~ f == 2

    Yes.

(Choice block is actually ran right before the "Yes" line, when the choice event is flushed.)
```

#### Definition lines:

Definition lines are used to define variables, constants, functions, checkpoints, and objects. Definition lines always start with `:`.

For every definition line type, it is possible to make it so it is immediately ran after definition by inserting a `~` after the initial `:`:

```
:~ var = &fn

:~$ loop
    This text is run immediately.
    > Loop
        @loop
    > Exit
```

is equivalent to

```
:var = &fn
~ var

:$ loop
    This text is run immediately.
    > Loop
        @loop
    > Exit
~ loop
```

* `:$`: function definition line. Followed by an [identifier](#identifiers), then eventually an [alias](#aliases), and eventually a parameter list. Define a function using its children as function body. Also define a new namespace for its children (using the function name if it has no arguments, or a unique name otherwise).

The function body is not executed when the line is reached; it must be explicitely called in an expression. See [expressions](#function-calls) to see the different ways of calling a function.

A parameter list can be optionally given after the identifier. Parameter names are identifiers, with eventually an alias (after a `:`) and a default value (after a `=`), and then a type constraint (after a `::`). It is enclosed with paranthesis and contain a comma-separated list of identifiers:

```
:$ f(a, b: alias for b, c="default for c", d: alias for d = "default for d")
    first argument: {a}
    second argument: {b}
    third argument: {c}
    fourth argument: {d}

:$ f(a::string, b: alias for b::string, c::alias="default for c"::string)
    same
```

Functions can also have a variable number of arguments. By adding `...` after the last argument identifier, it will be considered a variable length argument ("vararg"), and will contain a list of every extraneous argument.

```
:$ f(a, b...)
    {b}

(will print [1])
~ f("discarded", 1)

(will print [1,2,3])
~ f("discarded", 1, 2, 3)

(will print [])
~ f("discarded")
```

When a parameter list is given (or just empty parentheses `()`), the function is considered `scoped` - this means that any variable defined in it will only be defined in a call to the function and can only be accessed from this specific call:

```
(Non-scoped function: usual behaviour, variables are accessible from everywhere and always.)
:$ f
    :a = 1
    ~ a += 1

{f.a} is 1

~ f
{f.a} is 2

(Scoped function: can't access g.a from outside the function)
:$ g()
    :a = 1
    {a}
    ~ a += 1

(Each time the function is called, it has access to its own version of g.a, and don't share it - so this display 1 both times:)
~ g

~ g
```

This is basically the behaviour you'd expect from functions in most other programming languages, and what you would use in Anselme any time you don't care about storing the function variables or want the exact same initial function variables each time you call the function (e.g. recursion). Scoped variables are not kept in save files, and are not affected by checkpointing.

Functions with the same name can be defined, as long as they have a different arguments. Functions will be selected based on the number of arguments given, their name and their type constraint:

```
:$ f(a, b)
    a

:$ f(x)
    b

:$ f(x::string)
    c

(will print a)
~ f(1,2)

(will print b)
~ f(1)

(will print c)
~ f("hello")
```

Every operator, except assignement operators, `|`, `&`, `,`, `~?`, `~` and `#` can also be use as a function name in order to overload the operator:

```
(binary operator names: _op_)
(prefix unary operator: op_)
(suffix unary operator: _op)
:$ _/_(a::string, b::string)
    @"{a}/{b}"
```

After the parameter list, you may also write `:=` followed by an identifier, and eventually an alias. This defines an assignement function, which will be called when assigning a value to the function:

```
:x = "value"
:$ f()
    @x
:$ f() := v
    @x := v

value = {f}

~ f() := "other"

other = {f}
```

Functions can return a value using a [return line](#lines-that-can-t-have-children).

Functions always have the following variables defined in its namespace by default:

`👁️`: number, number of times the function was executed before
`🔖`: function reference, last reached checkpoint. `nil` if no checkpoint reached.

* `:!`: checkpoint definition. Followed by an [identifier](#identifiers), then eventually an [alias](#aliases). Define a checkpoint. Also define a new namespace for its children.

Checkpoints share most of their behavior with functions, with several exceptions. Like functions, the body is not executed when the line is reached; it must either be explicitely called in an expression or executed when resuming the parent function (see checkpoint behaviour below). Can be called in an expression. See [expressions](#checkpoint-calls) to see the different ways of calling a checkpoint manually.

The local interpreter state will be merged with the global state when the line is reached. See [checkpoints](#checkpoints).

When executing the parent function after this checkpoint has been reached (using the paranthesis-less function call syntax), the function will resume from this checkpoint, and the checkpoint's children will be run. This is meant to be used as a way to restart the conversation from this point after it was interrupted, providing necessary context.

```
:$ inane dialog
    Hello George. Nice weather we're having today?
    :! interrupted
        What was I saying? Ah yes, the weather...
    (further dialog here)
```

Checkpoints always have the following variable defined in its namespace by default:

`👁️`: number, number of times the checkpoint was executed before
`🏁`: number, number of times the checkpoint was reached before (includes times where it was resumed from and executed)

* `:%`: class definition. Followed by an [identifier](#identifiers), then eventually an [alias](#aliases). Define a class. Also define a new namespace for its children.

Classes share most of their behavior with functions, with a few exceptions. Classes can not take arguments or be scoped; and when called, if the function does not return a value or returns `()` (nil), it will returns a new object instead based on this class. The object can be used to access variables ("attributes") defined in the class, but if one of these attributes is modified on the object it will not change the value in the base class but only in the object.

Objects can therefore be used to create independant data structures that can contain any variable defined in the base class, inspired by object-oriented programming.

```
:% class
    :a = 1

:object = class

~ object.a := 3

Is 3: {object.a}
Is 1: {class.a}
```

Note that the new object returned by the class is also automatically given an annotation that is a reference to the class. This can be used to define methods/function that operate only on objects based on this specific class.

```
:% class
    :a = 1

:$ show(object::&class)
    a = {object.a}

:object = class

~ object!show
```

* `:`: variable declaration. Followed by an [identifier](#identifiers) (with eventually an [alias](#aliases)), a `=` and an [expression](#expressions). Defines a variable with a default value and this identifier in the current [namespace]("identifiers"). The expression is not evaluated instantly, but the first time the variable is used. Don't accept children lines.

```
:foo = 42
:bar : alias = 12
```

* `::`: constant declaration. Work the same way as a variable declaration, but the variable can't be reassigned after their declaration and first evaluation, and their value is marked as constant (i.e. can not be modified even it is of a mutable type). Constants are not stored in save files and should therefore always contain the result of the expression written in the script file, even if the script has been updated.

```
::foo = 42
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
:$ f
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
* `choice` (choices to choose from) is a list of choices. Each of these choice is a list of text elements like for the `text` event.
* `return` (when the script ends) is the returned value.
* `error` (when there is an error) is the error message.

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
:$ reusable choice
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

* strip trailing spaces: will remove any space characters at the end of the text (for text event), or at the end of each choice (for choice event).

```
(There is a space between the text and the tag expression that would be included in the text event otherwise.)
Some text # tag
```

* strip duplicate spaces: will remove any duplicated space characters between each element that constitute the text (for text event), or for each choice (for choice event).

```
(There is a space between the text and the tag expression; but there is a space as well after the text interpolation in the last line. The two spaces are converted into a single space (the space will belong to the first text element, i.e. the "text " element).)
:$ f
    text # tag

Some {text} here.
```

TODO: check if spacing rules are language-specific and move this to language files if appropriate

### Identifiers

Valid identifiers must be at least 1 characters long and can contain anything except the characters ``~`^+-=<>/[]*{}|\_!?,;:()"@&$#%`` (that is, every special character on a US keyboard except '). They can contain spaces. They can not start with a number.

When defining an identifier (using a function, checkpoint or variable delcaration line), it will be defined into the current namespace (defined by the parent function/checkpoint). When evaluating an expression, Anselme will look for variables into the current line's namespace, then go up a level if it isn't found, and so on. Note that the namespace of functions with arguments are not accessible from outside the function.

In practise, this means you have to use the "genealogy" of the variable to refer to it from a line not in the same namespace:

```
:$ fn1
    (everything here is in the fn1 namespace)
    :$ fn2
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

* `pair`: a couple of values. Types can be mixed. Can be defined using equal sign `"key"=5` or a colon `"key":5`. Pairs named by a string that is also a valid identifier can be created using the `key=5` shorthand syntax; `key` will not be interpreted as the variable `key` but the string `"key"` (if `key` is a variable and you want to force the use of its value as a key instead of the string `"key"`, you can either wrap it in parentheses or use the colon syntax).

* `annotated`: a couple of values. Types can be mixed. Can be defined using colon `expr::type`. The second value is used in type constraints, this is intended to be use to give a custom type to a value.

* `function reference`: reference to one or more function(s) with a given name. Can be defined using `&function name`, which will create a reference to every function with this name accessible from the current namespace. Will behave as if it was the original function (can be called using `func ref`, `func ref!` or `func ref(args)`).

* `variable reference`: reference to a single variable with a given name. Can be defined using `&variable name`, which will create a reference to the closest variable with this name accessible from the current namespace. Will behave as if it was the original variable, returning the value when called (value can be retrieved using `var ref!` or simply `var ref`).

* `list`: a list of values. Mutable. Types can be mixed. Can be defined between square brackets and use comma as a separator '[1,2,3,4]'.

* `map`: a map of keys-values. Mutable. Types can be mixed. Can be defined between curly braces and use comma as a separator, using pairs to define the key-values pairs (otherwise the numeric position of the element is used as a key). '{1=1,2=2,3,4="heh",foo="bar"}'.

* `object`: an object/record. Mutable. Can be created by calling a class function.

Every type is immutable, except `list`, `map` and `object`.

How conversions are handled from Anselme to Lua:

* `nil` -> `nil`

* `number` -> `number`

* `string` -> `string`

* `list` -> `table` (purely sequential table).

* `map` -> `table` (will map each key to a key in the Lua table).

* `pair` -> `table`, with a single key-value pair.

How conservions are handled from Lua to Anselme:

* `nil` -> `nil`

* `number` -> `number`

* `string` -> `string`

* `table` -> `list` or `map`. Converted to a list if the table is purely sequential, otherwise returns a map; e.g. `{1,2,key="value",3}` -> `{1=1,2=2,3=3,key="value"}` and `{1,2,3}` -> [1,2,3]

* `boolean` -> `number`, 0 for false, 1 for true.

#### Escape codes

These can be used to represent some character in string and other text elements that would otherwise be difficult to express due to conflicts with Anselme syntax; for example to avoid a character at the start of a text line to be interpreted as another line type.

* `\n` for a newline
* `\t` for a tabulation
* `\\` for `\`
* `\"` for `"` to escape string delimiters
* `\{` and `\}` for `{` and `}` to escape text interpolation
* `\[` and `\]` for `[` and `]` to escape subtexts
* and, in general, for any character X we can get it by prefixing it with an `\`: `\X` for `X`

#### Truethness

Only `0` and `nil` are false. Everything else is considered true.

#### Equality

Anselme consider two objects to be equal if they can *always* be used interchangeably.

In practice, this results in two main cases for equality tests:

* immutable values (strings, numbers, constants, ...). They are compared by recursively making sure all of their values and structure are equal.

```
(All of the following if true)
~ 5 == 5
~ "foo" == "foo"
~ constant([1,2,3]) == constant([1,2,3])
```

* mutable values (list, map, objects that are not constant). They are compared by reference, i.e. they are only considered equal if they are not distinct objects, even if they contain the same values and structure.

```
:a = [1,2,3]
:b = a
:c = [1,2,3]

(True:)
~ a == b

(False:)
~ a == c

(a and c are not interchangeable as they are two distinct lists; if we do:)
~ a(1) = 42
(This will change the first value of both a and b, but not c.)
```

#### Refering to an identifier

Any defined identifier can be accessed from an expression by using its name; the identifier will be first searched in the current namespace, then go up until it finds it as described in [identifiers](#identifiers).

What will happen then depends on what the identifier refer to: see [function calls](#function-calls) for functions and [checkpoint calls](#checkpoint-calls) for checkpoints.

For variables, the identifier will returns the value of the variable when evaluated.

When the identifier is preceeded by another expression directly (without any operator between the two), Anselme consider this to be an implicit multiplication. This behave in the same way as if there was a `*` operator between the expression and identifier, but has a priority just higher than explicit multiplication.

```
:x = 3

{2x} = {2*x} = 6

(Priority is made slighly higher to avoid parentheses in this kind of operation:)
{1/2x} = {1/(2*x)} = 1/6
```

#### Function calls

The simplest way to call a function is simply to use its name. If the function has no arguments, parantheses are optional, or can be replaced with a `!`:

```
:$ f
    called

~ f
(equivalent to)
~ f!

:$ f(a)
    called with {a}

~ f("an argument")
```

Please note, however, that if the function contains checkpoints, these two syntaxes behave differently. Without parantheses, the function will resume from the last reached checkpoint; with parantheses, the function always restart from its beginning:

```
:$ f
    a
    :! checkpoint
        b
    c

No checkpoint reached, will write "a" and "c":
~ f

Checkpoint is now reached, will write "b" and "c":
~ f

Force no checkpoint, will write "a" and "c":
~ f()

```

Functions with arguments can also be called with a "method-like" syntax using the `!` operator (though Anselme has no concept of classes and methods):

```
:$ f(a)
    called with {a}

"an argument"!f

:$ f(a, b)
    called with {a} and {b}

"an argument"!f("another argument")
```

If the function has a return value, any of these calls will of course return the value.

```
:$ f
    @"text"

this is text: {f}
```

Functions can also have default arguments. Defaults values can be any expression and are re-evaluated each time the function is called:

```
:$ f(a, b=1)
    @a+b

{f(1)} = 2

:$ g(a, b=a)
    @a+b

{g(1)} = 2
{g(2)} = 4
```

Arguments can also be passed by naming them instead of their position. These syntaxes can be mixed:

```
:$ f(a, b, c)
    @a + b + c

{f(1,2,3)} = {f(c=3,b=2,a=1)} = {f(1,2,c=3)}
```

Anselme actually treat argument maps are regular maps; named arguments are actually pairs and positional arguments are implicitely converted to pairs with their position as a key. Arguments are evaluated left-to-right. The call will error if one of the keys in the map is not a string or number.

This means that pairs can't be passed directly as arguments to a function (as they will be considered named arguments). If you want to use pairs, always wrap them in a list.

Functions can have a variable number of arguments. Additional arguments are added in a list:

```
:$ f(a, b...)
    {a}

    {b}

{f(1, 2, 3, 4, 5)}

(Will print:)
    1
    [2,3,4,5]
```

Anselme use dynamic dispatch, meaning the correct function is selected at runtime. The correct function is selected based on number of arguments, argument names, and argument type constraint. The function with the most specific arguments will be selected. If several functions match, an error is thrown.

```
:$ fn(x::number, y)
    a

:$ fn(x::number)
    b

:$ fn(a::string)
    c

:$ fn(x::number, y::number)
    c

a = {fn(5, "s")}

b = {fn("s")}

c = {fn(5)}

d = {fn(5, 2)}

:$ g(x)

:$ g(x, a="t")

error, can't select unique function: {g(5)}
```

Note that types constraints are expected to be constant and are evaluated only once. Default values, however, are evaluated each time the function is called (and the user didn't explicitely give an argument that would replace this default).

#### Checkpoint calls

Most of the time, you should'nt need to call checkpoints yourself - they will be automatically be set as the active checkpoint when the interperter reach their line, and they will be automatically called when resuming its parent function.

But in the cases when you want to manually set the current checkpoint, you can call it with a similar syntax to paranthesis-less function calls:

```
:$ f
    a
    :! checkpoint
        b
    c

Force run the function starting from checkpoint, will write "b" and "c" and set the current checkpoint to "checkpoint":
~ f.checkpoint

Will correctly resumes from the last set checkpoint, and write "b" and "c":
~ f
f! can also be used for the exact same result.

Function can always be restarted from the begining using parantheses:
~ f()
```

You can also only execute the checkpoints' children code only by using a parantheses-syntax:

```
:$ f
    a
    :! checkpoint
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
_;_   _;
_:=_  _+=_  _-=_  _//=_  _/=_  _*=_  _%=_  _^=_
_,_
_~?_  _~_   _#_
_=_
_|_   _&_
_!=_  _==_  _>=_  _<=_  _<_   _>_
_+_   _-_
_*_   _//_  _/_   _%_
_::_ 
-_  !_
_^_
_!_
&_
_._
```

A series of operators with the same priority are evaluated left-to-right.

The function called for a binary operator op is named `_op_`, for a prefix unary operator `op_`, for a suffix unary operator `_op`. Theses names are used to defined new operator behaviour; see function line.

#### Operators

Built-in operators:

##### Assignement

`a := b`: evaluate b, assign its value to identifier `a`. Returns the new value.

`a(index) := b`: evaluate b, assign its value to element of specific index in list/map `a`. Element is searched using the same method as list/map index operator `a(b)`; in the case of list, also allows to add a new element to the list by giving `len(a)+1` as the index. In the case of a map, if b is nil `()`, deletes the key-value pair from the map. Returns the new value.

`a.b := v`: if a is a function reference or an object, modify the b variable in the reference function or object.

`a += b`: evaluate b, assign its the current value of a `+` the value of b to a. Returns the new value.

`-=`, `*=`, `/=`, `//=`, `%=`, `^=`: same with other arithmetic operators.

##### Comparaison

`a == b`: returns `1` if a and b are considered equal, `0` otherwise

`a != b`: returns `1` if a and b are not equal, `0` otherwise

These only work on numbers:

`a > b`: returns `1` if a is greater than b are different, `0` otherwise

`<`, `>=`, `<=`: same with lower, greater or equal, lower or equal

##### Arithmetic

These only work on numbers.

`a + b`: evaluate a and b, returns their sum.

`-`, `*`, `/`, `//`, `^`, `%`: same for substraction, multiplication, division, integer division, exponentiation, modulo

`-a`: evaluate a, returns its opposite

This only works on strings:

`a + b`: evaluate a and b, concatenate them.

##### Logic operators

`!a`: evaluate a, returns `0` if it is true, `1` otherwise

`a & b`: and operator, lazy

`a | b`: or operator, lazy

`a ~ b`: evaluates b, if true evaluates a and returns it, otherwise returns nil (lazy).

`a ~? b`: evaluates b, if true evaluates a then reevaluate b and loop this until b is false; returns a list containing all successive values that a returned.

##### Functions and function references

`fn(args)`: call the function, checkpoint or function reference with the given arguments.

`fn!`: call the function, checkpoint or function reference without arguments. Can leads to different behaviour that the syntax with parantheses; see [function calls](#function-calls).

`fn`: call the function, checkpoint or function reference without arguments. Can leads to different behaviour that the other syntaxes; see [function calls](#function-calls).

`&fn`: returns a function reference to the given function. If it is already a reference, returns the same reference.

`a!fn(args)`: call the function or function reference with the variable as first argument. Parantheses are optional.

##### Variable references

`&var`: returns a variable reference to the given variable. If it is already a reference, returns the same reference.

`a!`: returns the value associated with the referenced variable.

`a`: returns the value associated with the referenced variable.

##### Various

`a ; b`: evaluate a, discard its result, then evaluate b. Returns the result of b.

`a;`: evaluate a, discard its result, returns nil.

`a = b`: evaluate a and b, returns a new pair with a as key and b as value. If a is an identifier, will interpret it as a string (and not a variable; you can wrap a in parentheses if you want to use the value associated with variable a instead, or just use the alternative pair operator `a:b` which does not have this behavior).

`a : b`: evaluate a and b, returns a new pair with a as key and b as value. Unlike the `a=b` operator, will evaluate a as and will get the value associated with the identifier if a is a variable identifier. Can be used for example to benefit from variable aliases and have translatable keys.

`a :: b`: evaluate a and b, returns a new annotated value with a as value and b as the annotation. This annotation will be checked in type constraints.

`a # b`: evaluates b, then evaluates a with b added to the active tags (wrap b in a map and merges it with the current tag map). Returns a.

`a.b`: if a is a function reference, returns the first found variable named `b` in the referenced function namespace; or if `b` is a subfunction in the referenced function, will call it (you can use the usual ways to call functions and gives arguments as well: `a.b!` or `a.b(x, y, ...)`). When overloading this operator, if `b` is an identifier, the operator will interpret it as a string (instead of returning the evaluated value of the variable eventually associated to the identifier).

`object.b`: if object is an object, returns the first found variable named `b` in the object, or, if the object does not contain it, found in its base class. If `b` is a subfunction in the base class, will call it (arguments can also be given using the usual syntax).

`list(b)`: evaluate b (number), returns the value with this index in the list. Use 1-based indexing. If a negative value is given, will look from the end of the list (`-1` is the last element, `-2` the one before, etc.). Error on invalid index. Operator is named `()`.

`map(b)`: evaluate b, returns the value with this key in the map. If the key is not present in the map, returns `nil`.

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

`cycle(...)`: given function/checkpoint references as arguments, will execute them in the order given each time the function is ran; e.g., `cycle(&a, &b)` will execute a on the first execution, then b, then a again, etc.

`next(...)`: same as cycle, but will not cycle; once the end of sequence is reached, will keep executing the last element.

`random(...)`: same arguments as before, but execute a random element at every execution.

##### String methods

`len(string)`: returns length of the string in UTF-8 characters

##### Various

`alias(ref::reference, alias::string)`: define an alias `alias` for the variable or function referenced by `ref`. Expect fully qualified names for the alias.

`rand([m[, n]])`: when called whitout arguments, returns a random float in [0,1). Otherwise, returns a random number in [m,n]; m=1 if not given.

`error(str)`: throw an error with the specified message

`annotation(v::annotated)`: returns v's annotation

`unannotated(v)`: return v, eventual annotations removed

`type(v)`: return v's type

`is a(v, type or annotation)`: check if v is of a certain type or annotation

`constant(v)`: create a constant copy of v and returns it. The resulting value is immutable, even if it contains mutable types (will raise an error if you try to change it).

#### Built-in variables

Variables for default types (each is associated to a string of the internal variable type name): `nil`, `number`, `string`, `list`, `map`, `pair`, `function reference`, `variable reference`.

The π constant is also defined in `pi`.

#### Built-in language scripts

Anselme provides some scripts that define translated aliases for built-in variables and functions. Currently `enUS` (English) and `frFR` (French) are provided.

See the `stdlib/languages` for details on each language.
