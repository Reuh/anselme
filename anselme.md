## Anselme Lua API reference

 We actively support LuaJIT and Lua 5.4.  Lua 5.1, 5.2 and 5.3 *should* work but I don't always test against them.

 This documentation is generated from the main module file `anselme.lua` using `ldoc --ext md anselme.lua`.

 Example usage:
 ```lua
 local anselme = require("anselme") -- load main module

 local vm = anselme() -- create new VM
 vm:loadgame("game") -- load some scripts, etc.
 local interpreter = vm:rungame() -- create a new interpreter using what was loaded with :loadgame

 -- simple function to convert text event data into a string
 -- in your game you may want to handle tags, here we ignore them for simplicity
 local function format_text(text)
   local r = ""
   for _, l in ipairs(t) do
     r = r .. l.text
   end
   return r
 end

 -- event loop
 repeat
   local event, data = interpreter:step() -- progress script until next event
   if event == "text" then
     print(format_text(d))
   elseif event == "choice" then
     for j, choice in ipairs(d) do
       print(j.."> "..format_text(choice))
     end
     interpreter:choose(io.read())
   elseif event == "error" then
     error(data)
   end
 until t == "return" or t == "error"
 ```

 Calling the Anselme main module will create a return a new [VM](#vms).

 The main module also contain a few fields:


### anselme.versions

Anselme version information table.

 Contains version informations as number (higher means more recent) of Anselme divied in a few categories:

 * `save`, which is incremented at each update which may break save compatibility
 * `language`, which is incremented at each update which may break script file compatibility
 * `api`, which is incremented at each update which may break Lua API compatibility

### anselme.version

General version number.

 It is incremented at each update.

### anselme.running

Currently running [interpreter](#interpreters).
 `nil` if no interpreter running.

## Interpreters

 An interpreter is in charge of running Anselme code and is spawned from a [VM](#vms).
 Several interpreters from the same VM can run at the same time.

 Typically, you would have a interpreter for each script that need at the same time, for example one for every NPC
 that is currently talking.

 Each interpreter can only run one script at a time, and will run it sequentially.
 You can advance in the script by calling the `:step` method, which will run the script until an event is sent (for example some text needs to be displayed),
 which will pause the whole interpreter until `:step` is called again.


### interpreter.vm

[VM](#vms) this interpreter belongs to.

### interpreter.end_event

String, type of the event that stopped the interpreter (`nil` if interpreter is still running).

### interpreter:step ()

Run the interpreter until the next event.
 Returns event type (string), data (any).

 Will merge changed variables on successful script end.

 If event is `"return"` or `"error"`, the interpreter can not be stepped further and should be discarded.

 Default event types and their associated data:
 * `text`: text to display, data is a list of text elements, each with a `text` field, containing the text contents, and a `tags` field, containing the tags associated with this text
 * `choice`: choices to choose from, data is a list of choices Each of these choice is a list of text elements like for the `text` event
 * `return`: when the script ends, data is the returned value (`nil` if nothing returned)
 * `error`: when there is an error, data is the error message.

 See [LANGUAGE.md](LANGUAGE.md) for more details on events.

### interpreter:choose (i)

Select a choice.
 `i` is the index (number) of the choice in the choice list (from the choice event's data).

 The choice will be selected on the next interpreter step.

 Returns this interpreter.

### interpreter:interrupt (expr)

Interrupt (abort the currently running script) the interpreter on the next step, executing an expression (string, if specified) in the current namespace instead.

 Returns this interpreter.

### interpreter:current_namespace ()

Returns the namespace (string) the last ran line belongs to.

### interpreter:run (expr, namespace)

Run an expression (string) or block, optionally in a specific namespace (string, will use root namespace if not specified).
 This may trigger events and must be called from within the interpreter coroutine (i.e. from a function called from a running script).

 No automatic merge if this change the interpreter state, merge is done once we reach end of script in a call to `:step` as usual.

 Returns the returned value (nil if nothing returned).

### interpreter:eval (expr, namespace)

Evaluate an expression (string) or block, optionally in a specific namespace (string, will use root namespace if not specified).
 The expression can't yield events.
 Can be called from outside the interpreter coroutine. Will create a new coroutine that operate on this interpreter state.

 No automatic merge if this change the interpreter state, merge is done once we reach end of script in a call to `:step` as usual.

 Returns the returned value in case of success (nil if nothing returned).

 Returns nil, error message in case of error.

## VMs

 A VM stores the state required to run Anselme scripts.  Each VM is completely independant from each other.


### vm:loadgame (path)

Wrapper for loading a whole set of scripts (a "game").
 Should be preferred to other loading functions if possible as this sets all the common options on its own.

 Requires LÖVE or LuaFileSystem.

 Will load from the directory given by `path` (string), in order:
 * `config.ans`, which will be executed in the "config" namespace and may contains various optional configuration options:
   * `anselme version`: number, version of the anselme language this game was made for
   * `game version`: any, version information of the game. Can be used to perform eventual migration of save with an old version in the main file.
                        Always included in saved variables.
   * `language`: string, built-in language file to load
   * `inject directory`: string, directory that may contain "function start.ans", "checkpoint end.ans", etc. which content will be used to setup
                       the custom code injection methods (see vm:setinjection)
   * `global directory`: string, path of global script directory. Every script file and subdirectory in the path will be loaded in the global namespace.
   * `start expression`: string, expression that will be ran when starting the game
 * files in the global directory, if defined in config.ans
 * every other file in the path and subdirectories, using their path as namespace (i.e., contents of path/world1/john.ans will be defined in a function world1.john)

 Returns this VM in case of success.

 Returns nil, error message in case of error.

### vm:rungame ()

Return a interpreter which runs the game start expression (if given).

 Returns interpreter in case of success.

 Returns nil, error message in case of error.

### vm:loadstring (str, name, source)

Load code from a string.
 Similar to Lua's code loading functions.

 Compared to their Lua equivalents, these also take an optional `name` argument (default="") that set the namespace to load the code in. Will define a new function is specified; otherwise, code will be parsed but not executable from an expression (as it is not named).

 Returns parsed block in case of success.

 Returns nil, error message in case of error.

### vm:loadfile (path, name)

Load code from a file.
 See `vm:loadstring`.

### vm:setaliases (seen, checkpoint, reached)

Set aliases for built-in variables 👁️, 🔖 and 🏁 that will be defined on every new checkpoint and function.
 This does not affect variables that were defined before this function was called.
 Set to nil for no alias.

 Returns this VM.

### vm:setinjection (inject, code)

Set some code that will be injected at specific places in all code loaded after this is called.
 Can typically be used to define variables for every function like 👁️, setting some value on every function resume, etc.

 Possible inject types:
 * `"function start"`: injected at the start of every non-scoped function
 * `"function end"`: injected at the end of every non-scoped function
 * `"function return"`: injected at the end of each return's children that is contained in a non-scoped function
 * `"checkpoint start"`: injected at the start of every checkpoint
 * `"checkpoint end"`: injected at the end of every checkpoint
 * `"class start"`: injected at the start of every class
 * `"class end"`: injected at the end of every class
 * `"scoped function start"`: injected at the start of every scoped function
 * `"scoped function end"`: injected at the end of every scoped function
 * `"scoped function return"`: injected at the end of each return's children that is contained in a scoped function

 Set `code` to nil to disable the inject.

 Returns this VM.

### vm:loadlanguage (lang)

Load and execute a built-in language file.

 The language file may optionally contain the special variables:
   * alias 👁️: string, default alias for 👁️
   * alias 🏁: string, default alias for 🏁
   * alias 🔖: string, default alias for 🔖

 Returns this VM in case of success.

 Returns nil, error message in case of error.

### vm:loadfunction (signature, fn)

Define functions from Lua.

 * `signature`: string, full signature of the function
 * `fn`: function (Lua function or table, see examples in `stdlib/functions.lua`)

 Returns this VM.

### vm:load (data)

Save/load script state

 Only saves persistent variables' full names and values.
 Make sure to not change persistent variables names, class name, class attribute names, checkpoint names and functions names between a
 save and a load (alias can of course be changed), as Anselme will not be able to match them to the old names stored in the save file.

 If a variable is stored in the save file but is not marked as persistent in the current scripts (e.g. if you updated the Anselme scripts to
 remove the persistence), it will not be loaded.

 Loading should be done after loading all the game scripts (otherwise you will get "variable already defined" errors).

 Returns this VM.

### vm:save ()

Save script state.
 See `vm:load`.

 Returns save data in case of success.

 Returns nil, error message in case of error.

### vm:postload ()

Perform parsing that needs to be done after loading code.
 This is automatically ran before starting an interpreter, but you may want to execute it before if you want to check for parsing error manually.

 Returns self in case of success.

 Returns nil, error message in case of error.

### vm:enable (...)

Enable feature flags.
 Available flags:
 * `"strip trailing spaces"`: remove trailing spaces from choice and text events (enabled by default)
 * `"strip duplicate spaces"`: remove duplicated spaces between text elements from choice and text events (enabled by default)

 Returns this VM.

### vm:disable (...)

Disable features flags.
 Returns this VM.

### vm:run (expr, namespace, tags)

Run code.
 Will merge state after successful execution

 * `expr`: expression to evaluate (string or parsed expression), or a block to run
 * `namespace`(default=""): namespace to evaluate the expression in
 * `tags`(default={}): defaults tags when evaluating the expression (Lua value)

 Return interpreter in case of success.

 Returns nil, error message in case of error.

### vm:eval (expr, namespace, tags)

Evaluate code.
 Behave like `:run`, except the expression can not emit events and will return the result of the expression directly.
 Merge state after sucessful execution automatically like `:run`.

 * `expr`: expression to evaluate (string or parsed expression), or a block to evaluate
 * `namespace`(default=""): namespace to evaluate the expression in
 * `tags`(default={}): defaults tags when evaluating the expression (Lua value)

 Return value in case of success (nil if nothing returned).

 Returns nil, error message in case of error.

