This document describes how to use the main Anselme modules. This is generated automatically from the source files.

Note that this file only describes the `anselme` and `state.State` modules, as well as the `TextEventData` and `ChoiceEventData` classes, which are only a selection of what I consider to be the "public API" of Anselme that I will try to keep stable.
If you need more advanced control on Anselme, feel free to look into the other source files to find more; the most useful functions should all be reasonably commented.

# anselme

The main module.

Usage:
```lua
local anselme = require("anselme")

-- create a new state
local state = anselme.new()
state:load_stdlib()

-- load an anselme script file in a new branch
local run_state = state:branch()
run_state:run_file("script.ans")

-- run the script
while run_state:active() do
	local event, data = run_state:step()
	if event == "text" then
		for _, l in ipairs(data) do
			print(l)
		end
	elseif event == "choice" then
		for i, l in ipairs(data) do
			print(("%s> %s"):format(i, l))
		end
		local choice = tonumber(io.read("l"))
		data:choose(choice)
	elseif event == "return" then
		run_state:merge()
	elseif event == "error" then
		error(data)
	end
end
```

If `require("anselme")` fails with an error similar to `module 'anselme' not found`, you might need to redefine `package.path` before the require:
```lua
package.path = "path/?/init.lua;path/?.lua;" .. package.path -- where path is the directory where anselme is located
require("anselme")
```
Anselme expects that `require("anselme.module")` will try loading both `anselme/module/init.lua` and `anselme/module.lua`, which may not be the case without the above code as `package.path`'s default value is system dependent, i.e. not my problem.

### .version

Global version string. Follow semver.

_defined at line 53 of [anselme/init.lua](../anselme/init.lua):_ `version = "2.0.0-rc1",`

### .versions

Table containing per-category version numbers. Incremented by one for any change that may break compatibility.

_defined at line 56 of [anselme/init.lua](../anselme/init.lua):_ `versions = {`

#### .language

Version number for language and standard library changes.

_defined at line 58 of [anselme/init.lua](../anselme/init.lua):_ `language = 31,`

#### .save

Version number for save/AST format changes.

_defined at line 60 of [anselme/init.lua](../anselme/init.lua):_ `save = 7,`

#### .api

Version number for Lua API changes.

_defined at line 62 of [anselme/init.lua](../anselme/init.lua):_ `api = 10`

### .parse (code, source)

Parse a `code` string and return the generated AST.

`source` is an optional string; it will be used as the code source name in error messages.

Usage:
```lua
local ast = anselme.parse("1 + 2", "test")
ast:eval(state)
```

_defined at line 74 of [anselme/init.lua](../anselme/init.lua):_ `parse = function(code, source)`

### .parse_file (path)

Same as `:parse`, but reads the code from a file.
`source` will be set as the file path.

_defined at line 79 of [anselme/init.lua](../anselme/init.lua):_ `parse_file = function(path)`

### .generate_translation_template (code, source)

Generates and return Anselme code (as a string) that can be used as a base for a translation file.
This will include every translatable element found in this code.
`source` is an optional string; it will be used as the code source name in translation contexts.

_defined at line 88 of [anselme/init.lua](../anselme/init.lua):_ `generate_translation_template = function(code, source)`

### .generate_translation_template_file (path)

Same as `:generate_translation_template`, but reads the code from a file.
`source` will be set as the file path.

_defined at line 93 of [anselme/init.lua](../anselme/init.lua):_ `generate_translation_template_file = function(path)`

### .new ()

Return a new [State](#state).

_defined at line 97 of [anselme/init.lua](../anselme/init.lua):_ `new = function()`


# State

Contains all state relative to an Anselme interpreter. Each State is fully independant from each other.
Each State can run a single script at a time, and variable changes are isolated between each State (see [branching](#branching-and-merging)).

### :load_stdlib (language)

Load standard library.
You will probably want to call this on every State right after creation.

Optionally, you can specify `language` (string) to instead load a translated version of the standaring library. Available translations:

* `"frFR"`

_defined at line 48 of [anselme/state/State.lua](../anselme/state/State.lua):_ `load_stdlib = function(self, language)`

## Branching and merging

### .branch_id

Name of the branch associated to this State.

_defined at line 76 of [anselme/state/State.lua](../anselme/state/State.lua):_ `branch_id = "main",`

### .source_branch

State this State was branched from. `nil` if this is the main branch.

_defined at line 78 of [anselme/state/State.lua](../anselme/state/State.lua):_ `source_branch = nil,`

### :branch (branch_id)

Return a new branch of this State.

Branches act as indepent copies of this State where any change will not be reflected in the source State until it is merged back into the source branch.
Note: probably makes the most sense to create branches from the main State only.

_defined at line 84 of [anselme/state/State.lua](../anselme/state/State.lua):_ `branch = function(self, branch_id)`

### :merge ()

Merge everything that was changed in this branch back into the main State branch.

Recommendation: only merge if you know that the state of the variables is consistent, for example at the end of the script, checkpoints, ...
If your script errored or was interrupted at an unknown point in the script, you might be in the middle of a calculation and variables won't contain
values you want to merge.

_defined at line 93 of [anselme/state/State.lua](../anselme/state/State.lua):_ `merge = function(self)`

## Variable definition

### :define (name, value, func, raw_mode)

Define a value in the global scope, converting it from Lua to Anselme if needed.

* for lua functions: `define("name", "(x, y, z=5)", function(x, y, z) ... end)`, where arguments and return values of the function are automatically converted between anselme and lua values
* for other lua values: `define("name", value)`
* for anselme AST: `define("name", value)`

`name` can be prefixed with symbol modifiers, for example "@name" for an exported variable.

If `raw_mode` is true, no anselme-to/from-lua conversion will be performed in the function.
The function will receive the state followed by AST nodes as arguments, and is expected to return an AST node.

_defined at line 111 of [anselme/state/State.lua](../anselme/state/State.lua):_ `define = function(self, name, value, func, raw_mode)`

### :define_local (name, value, func, raw_mode)

Same as `:define`, but define the expression in the current scope.

_defined at line 117 of [anselme/state/State.lua](../anselme/state/State.lua):_ `define_local = function(self, name, value, func, raw_mode)`

### :defined (name)

Returns true if `name` (string) is defined in the global scope.
Returns false otherwise.

_defined at line 122 of [anselme/state/State.lua](../anselme/state/State.lua):_ `defined = function(self, name)`

### :defined_local (name)

Same as `:defined`, but check if the variable is defined in the current scope.

_defined at line 129 of [anselme/state/State.lua](../anselme/state/State.lua):_ `defined_local = function(self, name)`

For anything more advanced, you can directly access the current scope stack stored in `state.scope`.
See [state/ScopeStack.lua](../state/ScopeStack.lua) for details; the documentation is not as polished as this file but you should still be able to find your way around.

## Saving and loading persistent variables

### :save ()

Return a serialized (string) representation of all persistent variables in this State.

This can be loaded back later using `:load`.

_defined at line 141 of [anselme/state/State.lua](../anselme/state/State.lua):_ `save = function(self)`

### :load (save)

Load a string generated by `:save`.

Variables that already exist will be overwritten with the loaded data.

_defined at line 148 of [anselme/state/State.lua](../anselme/state/State.lua):_ `load = function(self, save)`

## Current script state

### :active ()

Returns true if a script is currently loaded in this branch, false otherwise.

_defined at line 163 of [anselme/state/State.lua](../anselme/state/State.lua):_ `active = function(self)`

### :state ()

Returns `"running`" if a script is currently loaded and running (i.e. this was called from the script).

Returns `"active"` if a script is loaded but not currently running (i.e. the script has not started or is waiting on an event).

Returns `"inactive"` if no script is loaded.

_defined at line 171 of [anselme/state/State.lua](../anselme/state/State.lua):_ `state = function(self)`

### :run (code, source, tags)

Load a script in this branch. It will become the active script.

`code` is the code string or AST to run. If `code` is a string, `source` is the source name string to show in errors (optional).
`tags` is an optional Lua table; its content will be added to the tags for the duration of the script.

Note that this will only load the script; execution will only start by using the `:step` method. Will error if a script is already active in this State.

_defined at line 184 of [anselme/state/State.lua](../anselme/state/State.lua):_ `run = function(self, code, source, tags)`

### :run_file (path, tags)

Same as `:run`, but read the code from a file.
`source` will be set as the file path.

_defined at line 195 of [anselme/state/State.lua](../anselme/state/State.lua):_ `run_file = function(self, path, tags)`

### :step ()

When a script is active, will resume running it until the next event.

Will error if no script is active.

Returns `event type string, event data`.

See the [events](#events) section for details on event data types for built-in events.

_defined at line 208 of [anselme/state/State.lua](../anselme/state/State.lua):_ `step = function(self)`

### :interrupt (code, source, tags)

Stops the currently active script.

Will error if no script is active.

`code`, `source` and `tags` are all optional and have the same behaviour as in `:run`.
If they are given, the script will not be disabled but instead will be immediately replaced with this new script.
The new script will then be started on the next `:step` and will preserve the current scope. This can be used to trigger an exit function or similar in the active script.

If this is called from within a running script, this will raise an `interrupt` event in order to stop the current script execution.

_defined at line 229 of [anselme/state/State.lua](../anselme/state/State.lua):_ `interrupt = function(self, code, source, tags)`

### :eval (code, source, tags)

Evaluate an expression in the global scope.

This can be called from outside a running script, but an error will be triggered the expression raise any event other than return.

`code` is the code string or AST to run. If `code` is a string, `source` is the source name string to show in errors (optional).
`tags` is an optional Lua table; its content will be added to the tags for the duration of the expression.

* returns AST in case of success. Run `:to_lua(state)` on it to convert to a Lua value.
* returns `nil, error message` in case of error.

_defined at line 256 of [anselme/state/State.lua](../anselme/state/State.lua):_ `eval = function(self, code, source, tags)`

### :eval_local (code, source, tags)

Same as `:eval`, but evaluate the expression in the current scope.

_defined at line 263 of [anselme/state/State.lua](../anselme/state/State.lua):_ `eval_local = function(self, code, source, tags)`

If you want to perform more advanced manipulation of the resulting AST nodes, look at the `ast` modules.
In particular, every Node inherits the methods from [ast.abstract.Node](../ast/abstract/Node.lua).
Otherwise, each Node has its own module file defined in the [ast/](../ast) directory.


# Events

Anselme scripts communicate with the game by sending events. See the [language documentation](language.md#events) for more details on events.

Custom events can be defined; to do so, simply yield the coroutine with your custom event type (using `coroutine.yield("event type", event_data)`) from a function called in the anselme script.

For example, to add a `wait` event that pauses the script for some time, you could do something along these lines:
```lua
state:define("wait", "(duration::is number)", function(duration) coroutine.yield("wait", duration) end)
waiting = false

-- and edit your Anselme event handler with something like:
if not waiting then
	local event_type, event_data = run_state = run_state:step()
	if e == "wait" then
		waiting = true
		call_after_duration(event_data, function() waiting = false end)
	else
	-- handle other event types...
	end
end
```

And then from your Anselme script:
```
| Hello...
---
wait(5)
| ...world !
```

## TextEventData

TextEventData represent the data returned by an event with the type `"text"`.
See the [language documentation](language.md#texts) for more details on how to create a text event.

A TextEventData contains a list of [LuaText](#luatext), each LuaText representing a separate line of the text event.

For example, the following Anselme script:

```
| Hi!
| My name's John.
```
will return a text event containing two LuaTexts, the first containing the text "Hi!" and the second "My name's John.".

Usage:
```lua
local event_type, event_data = run_state:step()
if event_type == "text" then
	-- event_data is a TextEventData, i.e. a list of LuaText
	for _, luatext in ipairs(event_data) do
 		-- luatext is a list of text parts { text = "text string", tags = { ... } }
		for _, textpart in ipairs(luatext) do
			write_text_part_with_color(textpart.text, textpart.tags.color)
		end
		write_text("\n") -- for example, if we want a newline between each text line
	end
else
-- handle other event types...
end
```

_defined at line 87 of [anselme/ast/Text.lua](../anselme/ast/Text.lua):_ `local TextEventData`

### :group_by (tag_key)

Returns a list of TextEventData where the first part of each LuaText of each TextEventData has the same value for the tag `tag_key`.

In other words, this groups all the LuaTexts contained in this TextEventData using the `tag_key` tag and returns a list containing these groups.

For example, with the following Anselme script:
```
speaker: "John" #
	| A
	| B
speaker: "Lana" #
	| C
speaker: "John" #
	| D
```
calling `text_event_data:group_by("speaker")` will return a list of three TextEventData:
* the first with the texts "A" and "B"; both with the tag `speaker="John"`
* the second with the text "C"; with the tag `speaker="Lana"`
* the last with the text "D"; wiith the tag `speaker="John"`

_defined at line 109 of [anselme/ast/Text.lua](../anselme/ast/Text.lua):_ `group_by = function(self, tag_key)`


## ChoiceEventData

ChoiceEventData represent the data returned by an event with the type `"choice"`.
See the [language documentation](language.md#choices) for more details on how to create a choice event.

A ChoiceEventData contains a list of [LuaText](#luatext), each LuaText representing a separate choice of the choice event.

For example, the following Anselme script:

```
*| Yes!
*| No.
```
will return a choice event containing two LuaTexts, the first containing the text "Yes!" and the second "No.".

Usage:
```lua
current_choice = nil
waiting_for_choice = false

-- in your anselem event handling loop:
if not waiting_for_choice then
	local event_type, event_data = run_state:step()
	if event_type == "choice" then
		-- event_data is a ChoiceEventData, i.e. a list of LuaText
		for i, luatext in ipairs(event_data) do
			write(("Choice number %s:"):format(i))
 			-- luatext is a list of text parts { text = "text string", tags = { ... } }
			for _, textpart in ipairs(luatext) do
				write_choice_part_with_color(textpart.text, textpart.tags.color)
			end
		else
		-- handle other event types...
		end
		current_choice = event_data
		waiting_for_choice = true
	end
end

-- somewhere in your code where choices are selected
current_choice:select(choice_number)
waiting_for_choice = false
```

_defined at line 50 of [anselme/ast/Choice.lua](../anselme/ast/Choice.lua):_ `local ChoiceEventData = class {`

### :choose (choice)

Choose the choice at position `choice` (number).

A choice must be selected after receiving a choice event and before calling `:step` again.

_defined at line 58 of [anselme/ast/Choice.lua](../anselme/ast/Choice.lua):_ `choose = function(self, choice)`


## LuaText

A Lua-friendly representation of an Anselme Text value.
They appear in both TextEventData and ChoiceEventData to represent the text that has to be shown.

It contains a list of _text parts_, which are parts of a single text, each part potentially having differrent tags attached.
A text will typically only consist of a single part unless it was built using text interpolation.

Each text part is a table containing `text` (string) and  `tags` (table) properties, for example: `{ text = "text part string", tags = { color = "red" } }`.

_defined at line 19 of [anselme/ast/Text.lua](../anselme/ast/Text.lua):_ `local LuaText`

### .raw

Anselme Text value this was created from. For advanced usage only. See the source file [Text.lua](anselme/ast/Text.lua) for more information.

_defined at line 27 of [anselme/ast/Text.lua](../anselme/ast/Text.lua):_ `raw = nil,`

### :__tostring ()

Returns a text representation of the LuaText, using Anselme's default formatting. Useful for debugging.

Usage: `print(luatext)`

_defined at line 41 of [anselme/ast/Text.lua](../anselme/ast/Text.lua):_ `__tostring = function(self)`

---
_file generated at 2024-11-17T15:00:50Z_