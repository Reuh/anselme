Anselme is a dynamically typed scripting language intended to be embedded in game engines, focusing on making writing complex branching dialogues and interactions easier.

It is implemented in pure Lua and should be easily usable in any environment with the ability to run Lua 5.4, 5.3 or LuaJIT code.

This document will gives code examples and terse explanations of the most common patterns in Anselme, with links for more detailled descriptions from the [language reference](language.md).
This document does not attempt to explain basic programming concepts. If you haven't touched any other programming language before, good luck <3.

# Base syntax

_For more detailled information on this, look at the [language reference](language.md)._

Each line can contain an expression, and each expression return a value.

```
print("hello")

12+5
```

A line can be followed by an indented block (called an "attached block"). The indented block is stored in a variable `_` that run the block when retrieved.
If an expression is expected but the end-of-the-line is reached, a `_` is implicitely assumed.

```
12+
	5
// this is the same as
12+_
	5
```

## Multiline expressions

String, tuple literals, struct literals and parentheses ignore the one expression per line rule and can span several lines.

```
"hello i would like a
hot dog please"

[12
	+5]

{12
	+5}

(12
	+5)
```

## Comments

_For more detailled information on this, look at [comments](language.md#comments)._

```
// line comment

/* multiline
comment */

12 + // inline comment // 5
```

## Calling functions

_For more detailled information on this, look at [calling callables](language.md#calling-callables)._

```
// with no arguments
function!

// with arguments
function(12, "yes")
// is the same as
12!function("yes")
```

# Running Anselme scripts

## Script runner

To quickly test scripts, the test runner can be used to run individual anselme files using the `interactive` command.

`lua test/run.lua interactive script.ans`

## Implementing in your game

To see how to integrate Anselme into your game, look at the [Lua API documentation](api.md).

# Writing text

_For more detailled information on this, look at [events](language.md#events)._

## Text

_For more detailled information on this, look at [text](language.md#texts)._

Text values represent dialogs to be shown in the game.

```
// define a variable with a text value
:var = | Text |
// send the text to the game by calling it
var!

// the text is automatically called
| Hello world! |

// the closing | can be omitted on end-of-expression
| Hello world!
```

## Choices

_For more detailled information on this, look at [choices](language.md#choices)._

Choices represent a choice to be shown in the game.

```
| What do you want?

*| An ice cream
	| An ice cream coming up!
*| A bunch of sausages, NOW.
	sausage emergency function!
```

## Tags

_For more detailled information on this, look at [tags](language.md#tags)._

Tags can be used to add metatdata to text and choices sent to the game.

```
speaker: "Hero" #
	| I AM THE HERO, BOW DOWN BEFORE ME

	| IF YOU DON'T I'M GONNA HIT YOU WITH {color:"red" #| LOVE}!1!!1
```

# Variables

## Defining variables

_For more detailled information on this, look at [variables](language.md#variables), [scoping rules](language.md#scoping-rules)._

```
:var = 42 // definition
var = 12 // assignment
var += 2 // compound assignment

if(true)
	// other is not accessible from outside the scope where it was defined
	:other = 12

	// exported variables (with a @) are available in the whole file
	:@exported = 56

other // error
exported // 56
```

## Common types

_For more detailled information on this, look at [types](language.md#types-and-literals), [scoping rules](language.md#scoping-rules)._

```
:string = "strings"

:number = 42

:boolean = true

:nil = ()

:tuple = [1,2,3]
:list = *[1,2,3]

:struct = {name: "link", favorite food: "cheesecakes"}
:table = *{name: "link", favorite food: "cheesecakes"}
```

## Functions

_For more detailled information on this, look at [calling callables](language.md#calling-callables), [functions](language.md#functions), [dynamic dispatch](language.md#dynamic-dispatch), [value checking](language.md#value-checking)._

```
:$some function
	print("i take no arguments")
some function!

// functions can be overloaded
:$some function(x, y, and even some with default values="also this default one")
	print("i take way too many arguments, like {x}, {y} and {and stuff}")
some function("foo", "bar")

// conditions ("value checking") can be put on parameters
:$some function(x::is number)
	10+x
some function(2)

// assignment to a function are regular function calls with an assignement parameter
:$some function(x) = v
	x + v
some function(12) = 42

// anonymous functions / function literals
:some function = $(x::is string) print(x)
```

# Conditionals

_For more detailled information on this, look at [control flow](standard_library.md#control-flow)._

## If

```
if(3 > 5)
	print("not called")
else if(1 > 5)
	print("not called")
else!
	print("called")
```

## While

```
:i = 0
while(i < 5)
	i += 1
	if(i == 4)
		break!
```

## For

```
for(:x, range(10))
	print(x)
```

# Persistence

_For more detailled information on this, look at [persistence](standard_library.md#persistence-helpers), [alias variables](#api.md#alias-variables)._

Variables that needs to be saved and loaded alongside the game's save files can be stored in persistent storage.

```
// name in save is "money", with a default value of 0
:&money => "money"!persist(0)

money += 10000
```

The persistent storage can then be obtained as a serialized string using the [saving & loading Lua API methods](api.md#saving-and-loading-persistent-variables).

# Scripts

_For more detailled information on this, look at [scripts](standard_library.md#scripts)._

Scripts are functions enhanced with features to allow dialog resuming and tracking.

```
// create a script which use the name "presentation" in save files
:presentation = "presentation"!script
	| Hi I'm Max, the Hero.

// only calls presentation if it has never been run before
if(presentation.run == 0)
	presentation!
```

## Checkpoints

When a checkpoint is reached in a script, if the script if called again, it will be restarted from the checkpoint instead of the start of the script.
A checkpoint is created by using the `checkpoint` function on an anchor literal (ex. `#anchor name`).

```
:deep choice = "deep choice"!script
	| Do you want...

	*| A green drinky bird?
		| Your wish is my command.

		#green bird!checkpoint // once reached, the script will be resumed from this point when called again

		| What a magnificient drinky bird.

	*| Ten million dollars?
		| Your wish is my command.

		#the dumb choice!checkpoint
			// the checkpoint's attached block is called when resuming from the checkpoint only
			| No take-backs.

		| A bunch of useless money.

deep choice!

// will resume from the last reached checkpoint, i.e. in the previously selected choice
deep choice!

if(deep choice.reached(#green bird, false))
	| You made an excellent choice.
```

## Branches

_For more detailled information on this, look at [branching and merging](api.md#branching-and-merging)._

Anselme allows for several scripts to run in parallel through branches. A branch is always created from a parent branch and inherit all its state.
Values modified in the child branch do not affect the parent branch, until the changes are merged back into the parent using the [`merge branch` method](standard_library.md#merge-branch-complete-flush-true).

This means that if a script is interrupted for any reason (e.g. the player exited the dialog or the game) before merging its changes back into the parent branch, it would be as if whatever was ran since the last merge did not happen (similarly to e.g. database transactions). Note that changes are merged into the parent branch automatically when a checkpoint is reached in a script.

It is therefore recommended to never operate on the main branch directly but only child branches - this way the state of the main branch should only be updated on checkpoints and manual merges, and should therefore makes it possible to ensure its consistency (which is important when retrieving its persistent data to store in the game save file).

# Translation

_For more detailled information on this, look at [translatables](api.md#translatables)._

Text and any value preceded by a `%` prefix will be replaced with its translation (if it exists) when evaluated.

```
// no translation defined, "Hello" is sent to the game
| Hello

// define translation for "Hello", "Bonjour" is sent to the game
| Hello | -> | Bonjour |
| Hello

// making any value translatable with %
%"red" -> "rouge"
%"red" // "rouge"
```

An Anselme script containing a ready-to-translate list of all translatables elements of a file can be obtained using the [translation template generator Lua API methods](#api.md#generate-translation-template). The template can then be loaded as a regular Anselme file for all the translations to be applied.
