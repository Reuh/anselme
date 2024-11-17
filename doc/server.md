Instead of the scripts running in the same Lua process as the one of your game, Anselme can run in a Client-Server mode. This allows:

* Anselme to run in a separate thread and therefore not affect your game's frame times (Anselme is not very fast)
* to use Anselme other game engine that don't use Lua

The _server_ is the process that holds and process the Anselme state. Typically, the server would run in a separate process or thread that your game.

The _client_ connects to a server and sends instructions to execute Anselmes scripts and receive the response. Typically, the client correspond to your game.

For now, the whole system assumes that there is a single client per server - so you should not share a single server among serveral client.

How the Client and Server communicate between each other is defined using a RPC object.
Out-of-the-box, Anselme provides RPC objects that can communicate over [LÖVE](https://www.love2d.org/) threads, and over [JSON-RPC 2.0](https://www.jsonrpc.org/specification); these can be easily created using the functions in [anselme.server](#anselme_server).
If you want to implement a custom RPC mechanism, you can look at the existing implementations in `anselme/server/rpc/`.

Example usage in a LÖVE game:
```lua
local server = require("anselme.server")

-- create a new client+server
local client = server.new_love_thread()
client:load_stdlib()

-- load an anselme script file in a new branch
local run_state = client:branch("block")
run_state:run_file("script.ans")

-- start script
run_state:step(handle_event)

-- callback to handle an anselme event
function handle_event(event, data)
	if event == "text" then
		show_dialog_box {
			lines = data,
			on_dialog_box_closed = function()
				run_state:step(handle_event) -- resume script
			end
		}
	elseif event == "choice" then
		show_choice_dialog_box {
			choices = data,
			on_dialog_box_closed = function(choice_number)
				run_state:choose(choice_number)
				run_state:step(handle_event)
			end
		}
	elseif event == "return" then
		run_state:merge()
		run_state:remove() -- remove branch from server
	elseif event == "error" then
		print("error in anselme thread!", data)
		run_state:remove()
	end
end

function love.update()
	client:process() -- handle messages coming from the server
end
```

# anselme.server

Main functions to create clients and servers.

### .new_love_thread ()

Starts a Server in a new LÖVE thread and returns a Client connected to that server.

Should be called from a [LÖVE](https://www.love2d.org/) game code only.

_defined at line 10 of [anselme/server/init.lua](../anselme/server/init.lua):_ `new_love_thread = function()`

### .new_json_rpc_server (send, receive)

Returns a new Server that communicate with a Client using JSON-RPC 2.0.

This does not define _how_ the two comminicate (through sockets, http, etc.), you will need to define this using the `send` and `receive` arguments.

`send(message)` is a function that send a single message to the associated Client.

`receive(block)` is a function that receive a single message from the associated Client (or `nil` if no message available). If `block` is true, the function is allowed to block execution until a message is received.

_defined at line 41 of [anselme/server/init.lua](../anselme/server/init.lua):_ `new_json_rpc_server = function(send, receive)`

### .new_json_rpc_client (send, receive)

Returns a new Client that communicate with a Server using JSON-RPC 2.0.

This does not define _how_ the two comminicate (through sockets, http, etc.), you will need to define this using the `send` and `receive` arguments.

`send(message)` is a function that send a single message to the associated Server.

`receive(block)` is a function that receive a single message from the associated Server (or `nil` if no message available). If `block` is true, the function is allowed to block execution until a message is received.

_defined at line 53 of [anselme/server/init.lua](../anselme/server/init.lua):_ `new_json_rpc_client = function(send, receive)`


# Client

This is a Lua implementation of an Anselme client, with a nice API that mirrors the Anselme [State API](api.md#state) to communicate with the server.

Usage: create a Client object using the functions in the [anselme.server module](#anselme_server) and call `server:process()` regularly to process messages from the Server.

The API available here tries to follow the [State API](api.md#state) as much as possible, with the following differences:
* functions that return a value in State take an additionnal argument `callback`:
	* if it is a function `callback(ret1, ret2, ...)`, it is called as soon as the return values `ret1, ret2, ...` are received. The function also returns the identifier `call_id` associated with the callback (to optionally cancel the callback later using `client:cancel(call_id)`).
	* if it is `nil`, return values are discarded;
	* if it is the string `"block"`, the call will block until the return values are received. The function returns these values directly.
* functions that returns a `State` in State now returns a `Client`;
* return values are converted to a simpler representation if possible (no metamethods, userdata or cycles) to make serialization simpler - in particular, Anselme values are automatically converted to Lua primitives.
* a few new methods are introduced, see below.

Implementing a Client in other languages should be relatively easy: if your client language has a [JSON-RPC 2.0](https://www.jsonrpc.org/specification) library, point it to the Anselme server you started using [`server.new_json_rpc_server()`](#new_json_rpc_server) and you're done.
You should then be able to call any of the methods described in the [Server](#server).
Additionnaly, if you plan to use the `define_rpc` or `define_local_rpc` server methods, you will need to implement the following remote method in your client that will be called by the server:
* `call(function_id, ...)` where `function_id` (string) is the function identifier that was given when `define_rpc` or `define_local_rpc` was called, and `...` is a list of arguments. This must call the function associated with the `function_id` using the given arguments, and returns the values returned by the call (as a list of return values: `{ret1, ret2, ...}`).

### :process (block)

Process received messages.

Must be called regularly.
If `block` is true, the function is allowed to block execution until a message is received.

_defined at line 51 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `process = function(self, block)`

### :cancel (call_id)

Cancel the callback associated with the call `call_id`.
This does not stop the remote method execution; only prevent the callback from being called.

_defined at line 57 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `cancel = function(self, call_id)`

### :choose (i)

If the last event was a `choice`, choose the `i`-th choice.
This must be called before calling `:step` again after receiving a choice event.

_defined at line 63 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `choose = function(self, i)`

### :remove ()

Remove the branch from the server.
The branch (and therefore this Client branch) can't be used after calling this method.

_defined at line 68 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `remove = function(self)`

### :define_rpc (name, args, func)

Defines a function in the global scope, that calls the Lua function `func` on the Client when called.

The function will not be sent to the server; it will be directly executed on the client (i.e. your game code)
each time a script on the server needs it to be called.

Usage: `client:define_rpc("teleport", "(position)", function(position) player:teleport(position) end)`

_defined at line 78 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `define_rpc = function(self, name, args, func)`

### :define_local_rpc (name, args, func)

Same as `:define_rpc`, but define the function in the current scope.

_defined at line 85 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `define_local_rpc = function(self, name, args, func)`

## Methods and fields that mirror the State API

### :load_stdlib (language)

Same as [`state:load_stdlib(language)`](api.md#load_stdlib-language).

_defined at line 95 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `load_stdlib = function(self, language)`

### .branch_id

Same as [`state.branch_id`](api.md#branch_id).

_defined at line 100 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `branch_id = "main",`

### .source_branch

Same as [`state.source_branch`](api.md#source_branch), but refers to the source `Client` instead of a `State`.

_defined at line 102 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `source_branch = nil,`

### :branch (branch_id, callback)

Same as [`state:branch(branch_id)`](api.md#branch-branch_id), but returns a new `Client` instead of a `State`.

_defined at line 104 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `branch = function(self, branch_id, callback)`

### :merge ()

Same as [`state:merge()`](api.md#merge).

_defined at line 113 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `merge = function(self)`

### :define (name, value, func_code, raw_mode)

Same as [`state:define(name, value, func, raw_mode)`](api.md#api.md#define-name-value-func-raw_mode), but if `func_code` is given, it must be a string containing the function code.

Note that the given code will be executed on the server, and that there is no sandboxing of any kind;

Example: `client:define("main", "print", "(message::is string)", "function(message) print(message) end")`.

_defined at line 122 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `define = function(self, name, value, func_code, raw_mode)`

### :define_local (name, value, func_code, raw_mode)

Same as [`define`](#define-name-value-func_code-raw_mode), but calls [`state:define_local(name, value, func, raw_mode)`](api.md#api.md#define_local-name-value-func-raw_mode).

_defined at line 126 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `define_local = function(self, name, value, func_code, raw_mode)`

### :defined (name, callback)

Same as [`state:defined(name)`](api.md#defined-name).

_defined at line 130 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `defined = function(self, name, callback)`

### :defined_local (name, callback)

Same as [`state:defined_local(name)`](api.md#defined_local-name).

_defined at line 134 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `defined_local = function(self, name, callback)`

### :save (callback)

Same as [`state:save()`](api.md#save).

_defined at line 139 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `save = function(self, callback)`

### :load (save)

Same as [`state:load(save)`](api.md#load-save).

_defined at line 143 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `load = function(self, save)`

### :active (callback)

Same as [`state:active()`](api.md#active).

_defined at line 148 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `active = function(self, callback)`

### :state (callback)

Same as [`state:state()`](api.md#state).

_defined at line 152 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `state = function(self, callback)`

### :run (code, source, tags)

Same as [`state:run(code, source, tags)`](api.md#run-code-source-tags).

_defined at line 156 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `run = function(self, code, source, tags)`

### :run_file (path, tags)

Same as [`state:run_file(code, source, tags)`](api.md#run_file-code-source-tags).

_defined at line 160 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `run_file = function(self, path, tags)`

### :step (callback)

Same as [`state:step)`](api.md#step), but returns:
* for `text` and `choice` events, a list of lines `{ { { text = "line 1 part 2", tags = { ... } }, ... }, ... }` (in other word, [`TextEventData`](api.md#texteventdata) and [`ChoiceEventData`](api.md#choiceeventdata) stripped of everything but their list of text parts);
* for `return` events, the return value converted to Lua primitives;
* for other events, it will try to return the event data as-is.

_defined at line 167 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `step = function(self, callback)`

### :interrupt (code, source, tags)

Same as [`state:interrupt(code, source, tags)`](api.md#interrupt-code-source-tags).

_defined at line 171 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `interrupt = function(self, code, source, tags)`

### :eval (code, source, tags, callback)

Same as [`state:eval(code, source, tags)`](api.md#eval-code-source-tags), but the returned value is converted to Lua primitives.

_defined at line 175 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `eval = function(self, code, source, tags, callback)`

### :eval_local (code, source, tags, callback)

Same as [`state:eval_local(code, source, tags)`](api.md#eval_local-code-source-tags), but the returned value is converted to Lua primitives.

_defined at line 179 of [anselme/server/Client.lua](../anselme/server/Client.lua):_ `eval_local = function(self, code, source, tags, callback)`


# Server

An Anselme server instance.

Usage: create a Server object using the functions in the [anselme.server module](#anselme_server) and call `server:process()` regularly to process messages from the Client.

If you are implementing your own client, the following methods are available to be remotely called by your client:
* Note:
	* in all the following methods, the first parameter `branch_id` (string) is the id of the Anselme branch to operate on;
	* methods that return something always returns a list of return values: `{ ret1, ret2, ... }`.
* `choose(branch_id, i)`: if the last event was a `choice`, choose the `i`-th (number) line in the choice list;
* `remove(branch_id)`: removes the branch from the server; no further operation will be possible on the branch;
* `load_stdlib(branch_id, language)`: calls [`state:load_stdlib(language)`](api.md#load_stdlib-language) on the branch;
* `branch(branch_id[, new_branch_id])`: calls [`state:branch(branch_id)`](api.md#branch-branch_id) on the branch; returns the id of the new branch (string);
* `merge(branch_id)`: calls [`state:merge()`](api.md#merge) on the branch;
* `define(branch_id, name, args, func_code, raw_mode)`: calls [`state:define(branch_id, name, args, func, raw_mode)`](api.md#define-name-value-func-raw_mode) on the branch; if `func_code` is given, `func` will be a function generated from the Lua code `func_code` (string, example: `define("main", "print", "(message::is string)", "function(message) print(message) end")`). Note that whatever is in `func_code` will be executed on the server, and that there is no sandboxing of any kind;
* `define_rpc(branch_id, name, args, func_id)`: defines a function in the branch that, when called, will call the remote method `call(func_id, ...)` on the client and block until it returns. In other words, this allows the Anselme script running on the server to transparently call the function that is associated with the id `func_id` on the client.
* `define_local(branch_id, name, args, func_code, raw_mode)`: same as `define`, but calls [`state:define_local(branch_id, name, args, func, raw_mode)`](api.md#define_local-name-value-func-raw_mode);
* `define_local_rpc(branch_id, name, args, func_id)`: same as `define_rpc`, but defines the function in the current scope;
* `defined(branch_id, name)`: calls [`state:defined(name)`](api.md#defined-name) on the branch and returns its result;
* `defined_local(branch_id, name)`: calls [`state:defined_local(name)`](api.md#defined_local-name) on the branch and returns its result;
* `save(branch_id)`: calls [`state:save()`](api.md#save) on the branch and returns its result;
* `load(branch_id, save)`: calls [`state:load(save)`](api.md#load-save) on the branch;
* `active(branch_id)`: calls [`state:active()`](api.md#active) on the branch and returns its result;
* `state(branch_id)`: calls [`state:state()`](api.md#state) on the branch and returns its result;
* `run(branch_id, code, source, tags)`: calls [`state:run(code, source, tags)`](api.md#run-code-source-tags) on the branch;
* `run_file(branch_id, path, tags)`: calls [`state:run_file(path, tags)`](api.md#run_file-path-tags) on the branch;
* `step(branch_id)`: calls [`state:step()`](api.md#step) on the branch and returns:
	* for `text` and `choices` events, a list of lines `{ { { text = "line 1 part 2", tags = { ... } }, ... }, ... }` (in other word, [`TextEventData`](api.md#texteventdata) and [`ChoiceEventData`](api.md#choiceeventdata) stripped of everything but their list of text parts);
	* for `return` events, the return value converted to Lua;
	* for other events, it will try to return the event data as-is.
* `interrupt(branch_id, code, source, tags)`: calls [`state:interrupt(code, source, tags)`](api.md#interrupt-code-source-tags) on the branch;
* `eval(branch_id, code, source, tags)`: calls [`state:eval(code, source, tags)`](api.md#eval-code-source-tags) on the branch and returns its result, converted to Lua;
* `eval_local(branch_id, code, source, tags)`: calls [`state:eval_local(code, source, tags)`](api.md#eval_local-code-source-tags) on the branch and returns its result, converted to Lua.

### :process (block)

Process received messages.

Must be called regularly.
If `block` is true, the function is allowed to block execution until a message is received.

_defined at line 160 of [anselme/server/Server.lua](../anselme/server/Server.lua):_ `process = function(self, block)`


---
_file generated at 2024-11-17T15:00:50Z_