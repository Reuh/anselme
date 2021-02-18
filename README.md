Anselme
=======

The overengineered dialog scripting system in pure Lua.

**Has been rewritten recently, doc is still WIP**

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

And things that are halfway there but *should* be there eventually:
* language independant; scripts should (hopefully) be easily localizable into any language (it's possible, but doesn't provide any batteries for this right now)

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

* `~`: condition line. Can be followed by an [expression](#expressions); otherwise the expression `1` is assumed. If the expression evaluates to [true](#truethness), run its children.

* `~~`: else condition. Same as a condition line, but is only run if the last condition or else-condition line failed (regardless of line distance).

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

* `$`: function line. Followed by an [identifier](#identifiers). Define a function. TODO

* `§`: paragraph. Followed by an [identifier](#identifiers). Define a paragraph. A paragraph act as a checkpoint. TODO

* `#`: tag line. Can be followed by an [expression](#expressions). The results of the [expression](#expressions) will be added to the tags send along with any event sent from its children. Can be nested.

```
# "color": "red"
    Text tagged with a red color

    # "blink"
        Tagged with a red color and blink.
```

#### Lines that can't have children:

* `:`: variable declaration. Followed by an [expression](#expressions) and an [identifier](#identifiers). Defines a variable with this identifier and default value in the current [namespace]("identifiers").

```
:foo 42
```

* `@`: return line. Can be followed by an [expression](#expressions). Exit the current function and returns the expression's value.

```
$ hey
    @5

{hey} = 5
```

* empty line: flush events, i.e., if there are any pending lines of text or choices, send them to your game. See [Event buffer](#event-buffer). This line always keep the same identation as the last non-empty line, so you don't need to put invisible whitespace on an empty-looking line. Is also automatically added at the end of a file.

* regular text: write some text into the event buffer. Support [text interpolation](#text-interpolation).

```
Hello,
this is some text.

And this is more text, in a different event.
```

### Line decorators

Every line can also be followed with decorators, which are appended at the end of the line and affect its behaviour.

* `~`: condition decorator. Same as a condition line, behaving as if this line was it sole child.

* `§`: paragraph decorator. Same as a paragraph line, behaving as if this line was it sole child.

* `#`: tag decorator. Same as a tag line, behaving as if this line was it sole child.

```
$ fn
    run this line only once ~ 👁️
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
```

Beyond theses pragmatic reasons, the event buffering also serves as a way to group together several lines. For example, choice A and B will be sent to the game at the same time and can therefore be assumed to be part of the same "choice block", as opposed to choice C wich will be sent alone:

```
> Choice A
> Choice B

> Choice C
```

Anselme will also flush events when the current event type change, so your game only has to handle a single event of a single type at a time. For example, this will send a text event, flush it, and then buffer a choice event:

```
Text
> Choice
```

Every event have a type, and consist of a `data` field, containing its contents, and a `tags` field, containing the tags at the time the event was created.

### Identifiers

Valid identifiers must be at least 1 caracters long and can contain anything except the caracters `%/*+-()!&|=$?><:{}[],\`. They can contain spaces.

When defining an identifier (using a function, paragraph or variable delcaration line), it will be defined into the current namespace (defined by the parent function/paragraph). When evaluating an expression, Anselme will look for variables into the current line's namespace, then go up a level if it isn't found, and so on.

In practise, this means you have to use the "genealogy" of the variable to refer to it from a line not in it indentation block:

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

### Expressions

Besides lines, plenty of things in Anselme take expressions, which allow various operations on values and variables.

Note that these are *not* Lua expressions.

#### Types

Default types are:

* `nil`: nil.

* `number`: a number. Can be defined similarly to Lua number literals.

* `string`: a string. Can be defined between double quotes `"string"`. Support [text interpolation](#text-interpolation).

* `list`: a list of values. Types can be mixed. Can be defined between square brackets and use comma as a separator '[1,2,3,4]'.

* `pair`: a couple of values. Types can be mixed. Can be defined using colon `"key":5`.

TODO: conversion table to/from Lua. See stdlib/types.lua

#### Truethness

Only `0` is false. Everything else is considered true.

#### Operators

TODO See stdlib/functions.lua

#### Built-in functions

TODO See stdlib/functions.lua

API reference
-------------

TODO see anselme.lua
