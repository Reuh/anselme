Anselme
=======

The overengineered dialog scripting system in pure Lua.

**Has been rewritten recently, doc and language are still WIP**

Purpose
-------

Once upon a time, I wanted to do a game with a branching story. I could store the current state in a bunch of variables and just write everything like the rest of my game's code. But no, that would be *too simple*. I briefly looked at [ink](https://github.com/inkle/ink), which looked nice but lacked some features I felt like I needed. Mainly, I wanted something more language independant and less linear. Also, I wasn't a fan of the syntax. And I'm a weirdo who make their game in Lua.

So, here we go. Let's make a new scripting language.

Anselme ended up with some features that are actually quite useful compared to the alternatives:

* allows for concurently running scripts (a conversation bores you? why not start another at the same time!)
* allows for script interuption with gracious fallback (so you can *finally* make that NPC shut up mid-sentence)
* a mostly consistent and easy to read syntax based around lines and whitespace
* easily extensible (at least from Lua ;))

And most stuff you'd expect from such a language:

* easy text writing, can integrate expressions into text, can assign tags to (part of) lines
* choices that lead to differents paths
* variables, functions, arbitrary expressions (not Lua, it's its own thing)
* can pause the interpreter when needed
* can save and restore state

And things that are halfway there but *should* be there eventually (i.e., TODO):
* language independant; scripts should (hopefully) be easily localizable into any language (it's possible, but doesn't provide any batteries for this right now)
    Defaults variables use emoji and then it's expected to alias them; works but not the most satisfying solution.
* a good documentation
    Need to work on consistent naming of Anselme concepts
    A step by step tutorial

Things that Anselme is not:
* a game engine. It's very specific to dialogs and text, so unless you make a text game you will need to do a lot of other stuff.
* a language based on Lua. It's imperative and arrays start at 1 but there's not much else in common.

Example
-------

Sometimes we need some simplicity:

```
HELLO SIR, HOW ARE YOU TODAY
> why are you yelling
    I LIKE TO
    > Well that's stupid.
        I DO NOT LIKE YOU SIR.
> I AM FINE AND YOU
    I AM FINE THANK YOU

    LOVELY WEATHER WE'RE HAVING, AREN'T WE?
    > Sure is!
        YEAH. YEAH.
    > I've seen better.
        ENTITLED PRICK.

WELL, GOOD BYE.
```

Othertimes we don't:

TODO: stupidly complex script

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

When executing a piece of Anselme code, it will not directly modify the global state (i.e. the values of variables used by every script), but only locally, in this execution.

Right after reaching a checkpoint line, Anselme will merge the local state with the global one, i.e., make every change accessible to other scripts.

```
$ main
    :5 var

    ~ var := 2

    before: {var}=2, because the value has been changed in the current execution context

    (But if we run the script "parallel" in parallel at this point, it will still think var=5)

    § foo
        But the variable will be merged with the global state on a checkpoint

    after: {var}=2, still, as expected

    (And if we run the script "parallel" in parallel at this point, it will now think var=2)

$ parallel
    parallel: {main.var}

~ main
```

The purpose of this system is both to allow several scripts to run at the same time with an easy way to avoid interferences, and to make sure the global state is always in a consistent (and not in the middle of a calculation): since scripts can be interrupted at any time, when it is interrupted, anything that was changed between the last checkpoint and the interruption will be discarded. When running the script again, it will resume correctly at the last reached checkpoint. See [function calls](#function-calls) for more details on how to call/resume a function.

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
~~ 1 = 0
    This neither.
~~
    This is.
```

* `>`: write a choice into the event buffer. Followed by arbitrary text. Support [text interpolation](#text-interpolation).

```
> First choice
> Second choice
> Last choice
```

* `$`: function line. Followed by an [identifier](#identifiers), then eventually an [alias](#aliases), and eventually a parameter list. Define a function using its children as function body. Also define a new namespace for its children.

The function body is not executed when the line is reached; it must be explicitely called in an expression. See [expressions](#function-calls) to see the different ways of calling a function.

A parameter list can be optionally given after the identifier. Parameter names are identifiers, with eventually an alias. It is enclosed with paranthesis and contain a comma-separated list of identifiers:

```
$ f(a, b, c)
    first argument: {a}
    second argument: {b}
    third argument: {c}
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

Functions with the same name can be defined, as long as they have a different number of argument. Functions will be selected based on the number of arguments given:

```
$ f(a, b)
    a

$ f(x)
    b

(will print a)
~ f(1,2)

(will print b)
~ f(1)
```

Functions can return a value using a [return line](#lines-that-can-t-have-children).

Functions always have the following variables defined in its namespace by default:

`👁️`: number, number of times the function was executed before
`🏁`: string, name of last reached checkpoint

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

`👁️`: number, number of times the checkpoint was reached or executed before

* `#`: tag line. Can be followed by an [expression](#expressions); otherwise nil expression is assumed. The results of the [expression](#expressions) will be added to the tags send along with any event sent from its children. Can be nested.

```
# "color": "red"
    Text tagged with a red color

    # "blink"
        Tagged with a red color and blink.
```

#### Lines that can't have children:

* `:`: variable declaration. Followed by an [expression](#expressions) and an [identifier](#identifiers), then eventually an [alias](#aliases). Defines a variable with a default value and this identifier in the current [namespace]("identifiers"). Once defined, the type of a variable can not change.

```
:42 foo
```

* `@`: return line. Can be followed by an [expression](#expressions); otherwise nil expression is assumed. Exit the current function and returns the expression's value.

```
$ hey
    @5

{hey} = 5
```

Be careful when using `@` in a choice block. Choice blocks are not ran right as they are read, but at the next event flush (i.e. empty line). This means that if there is no flush in the function itself, the choice will be ran *after* the function has already been executed and returning a value at this point makes no sense:

```
$ f
    > a
        @1
    @2

(f will return 2 since the choice is run after the @2 line)
~ f = 2

    Yes.

(Choice block is actually ran right before the "Yes" line, when the choice event is flushed.)

```

For this reason, Anselme will discard returns values sent from within a choice block. Returns inside choice block still have the expected behaviour of stopping the execution of the block.

* empty line: flush events, i.e., if there are any pending lines of text or choices, send them to your game. See [Event buffer](#event-buffer). This line always keep the same identation as the last non-empty line, so you don't need to put invisible whitespace on an empty-looking line. Is also automatically added at the end of a file.

* regular text: write some text into the event buffer. Support [text interpolation](#text-interpolation).

```
Hello,
this is some text.

And this is more text, in a different event.
```

### Line decorators

Every line can also be followed with decorators, which are appended at the end of the line and affect its behaviour. Decorators are just syntaxic sugar to make some common operations simpler to write.

* `~`: condition decorator. Same as an condition line, behaving as if this line was it sole child. Typically used to conditionally execute line.

```
$ fn
    run this line only once ~ 👁️
```

is equivalent to:

```
$ fn
    ~ 👁️
        run this line only once
```

* `#`: tag decorator. Same as a tag line, behaving as if this line was it sole child.

```
tagged # 42
```

is equivalent to:

```
# 42
    tagged
```

* `$`: function decorator. Same as a function line, behaving as if this line was it sole child, but also run the function.

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

is equivalent to (since empty condition is assumed true):

```
$ loop
    > Loop
        @loop
    > Exit
~ loop
```

### Text interpolation

Text and choice lines allow for arbitrary text. Expression can be evaluated and inserted into the text as the line is executed by enclosing the [expression](#expressions) into brackets.

```
:5 a

Value of a: {a}
```

### Event buffer

Since Lua mainly run into a signle thread, Anselme need to give back control to the game at some point. This is done with flush event lines (empty lines), where the intrepreter yield its coroutine and returns a buch of data to your game (called the event buffer). It's called an event buffer because, well, it's a buffer, and events are what we call whatever Anselme sends back to your game.

As Anselme interpret the script, it keeps a buffer of events that will be sent to your game on the next event flush line. These events are, by default, either text, choice or return (this one sent when the script end).

```
Some text.
Another text.

(the above flush line will cause Anselme to send two text events containing the two previous lines)
Text in another event.
```

Beyond theses pragmatic reasons, the event buffering also serves as a way to group together several lines. For example, choice A and B will be sent to the game at the same time and can therefore be assumed to be part of the same "choice block", as opposed to choice C wich will be sent alone:

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

Anselme will also flush events when the current event type change, so your game only has to handle a single event of a single type at a time. For example, this will send a text event, flush it, and then buffer a choice event:

```
Text
> Choice
```

Every event have a type (`text`, `choice`, `return` or `error` by default, custom types can also be defined), and consist of a `data` field, containing its contents, and a `tags` field, containing the tags at the time the event was created.

### Identifiers

Valid identifiers must be at least 1 caracters long and can contain anything except the caracters `%/*+-()!&|=$§?><:{}[],\`. They can contain spaces.

When defining an identifier (using a function, checkpoint or variable delcaration line), it will be defined into the current namespace (defined by the parent function/checkpoint). When evaluating an expression, Anselme will look for variables into the current line's namespace, then go up a level if it isn't found, and so on.

In practise, this means you have to use the "genealogy" of the variable to refer to it from a line not in the same namespace:

```
$ fn1
    (everything here is in the fn1 namespace)
    $ fn2
        (fn1.fn2 namespace)
        :var2 42
        Var2 = 42: {var2}

    Var2 = not found: {var2}
    Var2 = 42: {fn2.var2}

    :var1 1

Var2 = 42: {fn1.fn2.var2}

:var1 2

Var1 in the current namespace = 1: {var1}
Var1 in the fn1 namespace = 2: {fn1.var1}

(Weird, but valid, and also the reason I'm not talking of scoping:)
~ fn1.var1 = 3
```

#### Aliases

When defining identifiers (in variables, functions or checkpoint definitions), they can be followed by a colon and another identifier. This identifier can be used as a new way to access the identifier (i.e., an alias).

```
:42 name: alias

{name} is the same as {alias}
```

Note that alias have priority over normal identifiers; if both an identifier and an alias have the same name, the alias will be used.

The main purpose of aliases is translation. When saving the state of your game's script, Anselme will store the name of the variables and their contents, and require the name to be the same when loading the save later, in order to correctly restore their values.

This behaviour is fine if you only have one language; but if you want to translate your game, this means the translations will need to keep using the original, untranslated variables and functions names if it wants to be compatible with saves in differents languages. Which is not very practical or nice to read.

Anselme's solution is to keep the original name in the translated script file, but alias them with a translated name. This way, the translated script can be written withou constantly switching languages:

```
(in the original, english script)
:"John Pizzapone" player name

Hi {player name}!

(in a translated, french script)
:"John Pizzapone" player name : nom du joueur

Salut {nom du joueur} !
```

Variables that are defined automatically by Anselme (`👁️` and `🏁` in checkpoints and functions) can be automatically aliased using `vm:setaliases("👁️alias", "🏁alias")`. See [API](#api-reference).

### Expressions

Besides lines, plenty of things in Anselme take expressions, which allow various operations on values and variables.

Note that these are *not* Lua expressions.

#### Types

Default types are:

* `nil`: nil. Can be defined using empty parantheses `()`.

* `number`: a number. Can be defined similarly to Lua number literals.

* `string`: a string. Can be defined between double quotes `"string"`. Support [text interpolation](#text-interpolation).

* `list`: a list of values. Types can be mixed. Can be defined between square brackets and use comma as a separator '[1,2,3,4]'.

* `pair`: a couple of values. Types can be mixed. Can be defined using colon `"key":5`.

How conversions are handled from Anselme to Lua:

* `nil` -> `nil`

* `number` -> `number`

* `string` -> `string`

* `list` -> `table`. Pair elements in the list will be assigned as a key-value pair in the Lua list and its index skipped in the sequential part, e.g. `[1,2,"key":"value",3]` -> `{1,2,3,key="value"}`.

* `pair` -> `table`, with a signle key-value pair.

How conservions are handled from Lua to Anselme:

* `nil` -> `nil`

* `number` -> `number`

* `string` -> `string`

* `table` -> `list`. First add the sequential part of the table in the list, then add pairs for the remaining elements, e.g. `{1,2,key="value",3}` -> `[1,2,3,"key":"value"]`

* `boolean` -> `number`, 0 for false, 1 for true.

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
* will try to re-add every tag from parent lines; this require Anselme to re-evaluate every tag line and decorator that's a parent of the checkpoint in the function. Be careful if your tag expressions have side-effects.

#### Operators

Built-in operators:

##### Assignement

`a := b`: evaluate b, assign its value to identifier `a`. Returns the new value.

`a += b`: evaluate b, assign its the current value of a `+` the value of b to a. Returns the new value.

`-=`, `*=`, `/=`, `//=`, `%=`, `^=`: same with other arithmetic operators.

##### Comparaison

`a = b`: returns `1` if a and b have the same value (will recursively compare list and pairs), `0` otherwise

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

`a(b)`: evaluate b (number), returns the value with this index in a (list). Use 1-based indexing.

#### Built-in functions

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

`rand([m[, n]])`: when called whitout arguments, returns a random float in [0,1). Otherwise, returns a random number in [m,n]; m=1 if not given.

API reference
-------------

TODO see anselme.lua
