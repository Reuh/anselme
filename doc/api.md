This document describes how to use the main Anselme modules. This is generated automatically from the source files.

Note that this file only describes the `anselme` and `state.State` modules, which are only a selection of what I consider to be the "public API" of Anselme that I will try to keep stable.
If you need more advanced control on Anselme, feel free to look into the other source files to find more; the most useful functions should all be reasonably commented.

# anselme

The main module.

Usage:
```lua
local anselme = require("anselme")

-- create a new state
local state = anselme.new()
state:load_stdlib()

-- read an anselme script file
local f = assert(io.open("script.ans"))
local script = anselme.parse(f:read("*a"), "script.ans")
f:close()

-- load the script in a new branch
local run_state = state:branch()
run_state:run(script)

-- run the script
while run_state:active() do
	local e, data = run_state:step()
	if e == "text" then
		for _, l in ipairs(data) do
			print(l:format(run_state))
		end
	elseif e == "choice" then
		for i, l in ipairs(data) do
			print(("%s> %s"):format(i, l:format(run_state)))
		end
		local choice = tonumber(io.read("*l"))
		data:choose(choice)
	elseif e == "return" then
		run_state:merge()
	elseif e == "error" then
		error(data)
	end
end
```

### .version

Global version string. Follow semver.

_defined at line 52 of [anselme.lua](../anselme.lua):_ `version = "2.0.0-alpha",`

### .versions

Table containing per-category version numbers. Incremented by one for any change that may break compatibility.

_defined at line 55 of [anselme.lua](../anselme.lua):_ `versions = {`

#### .language

Version number for languages and standard library changes.

_defined at line 57 of [anselme.lua](../anselme.lua):_ `language = 27,`

#### .save

Version number for save/AST format changes.

_defined at line 59 of [anselme.lua](../anselme.lua):_ `save = 4,`

#### .api

Version number for Lua API changes.

_defined at line 61 of [anselme.lua](../anselme.lua):_ `api = 8`

### .parse (code, source)

Parse a `code` string and return the generated AST.

`source` is an optional string; it will be used as the code source name in error messages.

Usage:
```lua
local ast = anselme.parse("1 + 2", "test")
ast:eval()
```

_defined at line 73 of [anselme.lua](../anselme.lua):_ `parse = function(code, source)`

### .new ()

Return a new [State](#state).

_defined at line 77 of [anselme.lua](../anselme.lua):_ `new = function()`


---
_file generated at 2023-12-21T20:56:31Z_

# State

Contains all state relative to an Anselme interpreter. Each State is fully independant from each other.
Each State can run a single script at a time, and variable changes are isolated between each State (see [branching](#branching-and-merging)).

### :load_stdlib ()

Load standard library.
You will probably want to call this on every State right after creation.

_defined at line 40 of [state/State.lua](../state/State.lua):_ `load_stdlib = function(self)`

## Branching and merging

### .branch_id

Name of the branch associated to this State.

_defined at line 47 of [state/State.lua](../state/State.lua):_ `branch_id = "main",`

### .source_branch_id

Name of the branch this State was branched from.

_defined at line 49 of [state/State.lua](../state/State.lua):_ `source_branch_id = "main",`

### :branch ()

Return a new branch of this State.

Branches act as indepent copies of this State where any change will not be reflected in the source State until it is merged back into the source branch.
Note: probably makes the most sense to create branches from the main State only.

_defined at line 55 of [state/State.lua](../state/State.lua):_ `branch = function(self)`

### :merge ()

Merge everything that was changed in this branch back into the main State branch.

Recommendation: only merge if you know that the state of the variables is consistent, for example at the end of the script, checkpoints, ...
If your script errored or was interrupted at an unknown point in the script, you might be in the middle of a calculation and variables won't contain
values you want to merge.

_defined at line 64 of [state/State.lua](../state/State.lua):_ `merge = function(self)`

## Variable definition

### :define (name, value, func, raw_mode)

Define a value in the global scope, converting it from Lua to Anselme if needed.

* for lua functions: `define("name", "(x, y, z=5)", function(x, y, z) ... end)`, where arguments and return values of the function are automatically converted between anselme and lua values
* for other lua values: `define("name", value)`
* for anselme AST: `define("name", value)`

`name` can be prefixed with symbol modifiers, for example ":name" for a constant variable.

If `raw_mode` is true, no anselme-to/from-lua conversion will be performed in the function.
The function will receive the state followed by AST nodes as arguments, and is expected to return an AST node.

_defined at line 82 of [state/State.lua](../state/State.lua):_ `define = function(self, name, value, func, raw_mode)`

### :define_local (name, value, func, raw_mode)

Same as `:define`, but define the expression in the current scope.

_defined at line 88 of [state/State.lua](../state/State.lua):_ `define_local = function(self, name, value, func, raw_mode)`

For anything more advanced, you can directly access the current scope stack stored in `state.scope`.
See [state/ScopeStack.lua](../state/ScopeStack.lua) for details; the documentation is not as polished as this file but you should still be able to find your way around.

## Saving and loading persistent variables

### :save ()

Return a serialized (string) representation of all global persistent variables in this State.

This can be loaded back later using `:load`.

_defined at line 100 of [state/State.lua](../state/State.lua):_ `save = function(self)`

### :load (save)

Load a string generated by `:save`.

Variables that do not exist currently in the global scope will be defined, those that do will be overwritten with the loaded data.

_defined at line 107 of [state/State.lua](../state/State.lua):_ `load = function(self, save)`

## Current script state

### :active ()

Indicate if a script is currently loaded in this branch.

_defined at line 127 of [state/State.lua](../state/State.lua):_ `active = function(self)`

### :state ()

Returns `"running`" if a script is currently loaded and running (i.e. this was called from the script).

Returns `"active"` if a script is loaded but not currently running (i.e. the script has not started or is waiting on an event).

Returns `"inactive"` if no script is loaded.

_defined at line 135 of [state/State.lua](../state/State.lua):_ `state = function(self)`

### :run (code, source)

Load a script in this branch. It will become the active script.

`code` is the code string or AST to run, `source` is the source name string to show in errors (optional).

Note that this will only load the script; execution will only start by using the `:step` method. Will error if a script is already active in this State.

_defined at line 147 of [state/State.lua](../state/State.lua):_ `run = function(self, code, source)`

### :step ()

When a script is active, will resume running it until the next event.

Will error if no script is active.

Returns `event type string, event data`.

_defined at line 160 of [state/State.lua](../state/State.lua):_ `step = function(self)`

### :interrupt (code, source)

Stops the currently active script.

Will error if no script is active.

If `code` is given, the script will not be disabled but instead will be immediately replaced with this new script.
The new script will then be started on the next `:step` and will preserve the current scope. This can be used to trigger an exit function or similar in the active script.

_defined at line 178 of [state/State.lua](../state/State.lua):_ `interrupt = function(self, code, source)`

### :eval (code, source)

Evaluate an expression in the global scope.

This can be called from outside a running script, but an error will be triggered the expression raise any event other than return.

* returns AST in case of success. Run `:to_lua(state)` on it to convert to a Lua value.
* returns `nil, error message` in case of error.

_defined at line 199 of [state/State.lua](../state/State.lua):_ `eval = function(self, code, source)`

### :eval_local (code, source)

Same as `:eval`, but evaluate the expression in the current scope.

_defined at line 206 of [state/State.lua](../state/State.lua):_ `eval_local = function(self, code, source)`

If you want to perform more advanced manipulation of the resulting AST nodes, look at the `ast` modules.
In particular, every Node inherits the methods from [ast.abstract.Node](../ast/abstract/Node.lua).
Otherwise, each Node has its own module file defined in the [ast/](../ast) directory.


---
_file generated at 2023-12-21T20:56:31Z_