Various ideas and things that may or may not be done. It's like GitHub issues, but I don't have to leave my text editor or connect to the scary Internet.

Loosely ordered by willingness to implement.

---

Documentation:
* language reference
* tutorial

---

Write tests. Kinda mandatory actually, while I've tried to improve and do it much better than Anselme v1 there's still plenty interweaved moving parts here. Not sure how much better I can do with the same design requirements tbh. See anselme v1 tests to get a base library of tests.

---

Make requires relative. Currently Anselme expect its directory to be properly somewhere in package.path.
Also improve compatibility with Lua 5.3 and LuaJIT (I don't think we should support anything other than 5.4, 5.3 and LuaJIT).

---

Translation. TODO Design

Translation model:
- for text, choices: text+line+file as id, translation (either text or function)
- for strings, assets, ...: ? translatable string ?
- for variable names: ?
- for stdlib: ?

---

Persistence "issue": Storing a closure stores it whole environment, which includes all the stdlib. Technically it works, but that's a lot of useless information. Would need to track which variable is used (should be doable in prepare) and prune the closure.
Or register all functions as ressources in binser - that makes kinda sense, they're immutable, and their signature should be unique. Would need to track which functions are safe to skip / can be reloaded from somewhere on load.

---

Redesign the Node hierarchy to avoid cycles.

---

Standard library.

* Text manipulation would make sense, but that would require a full UTF-8/Unicode support library like https://github.com/starwing/luautf8.
* Something to load other files. Maybe not load it by default to let the calling game sandbox Anselme.
* Implement the useful functions from Anselme v1.
* Checkpoint management.
* Overloadable :format for custom types.

---

Server API.

To be able to use Anselme in another language, it would be nice to be able to access it over some form of IPC.

No need to bother with networking I think. Just do some stdin/stdout handling, maybe use something like JSON-RPC: https://www.jsonrpc.org/specification (reminder: will need to add some metadata to specify content length, not aware of any streaming json lib in pure Lua - here's a rxi seal of quality library btw: https://github.com/rxi/json.lua). Or just make our own protocol around JSON.
Issue: how to represent Anselme values? they will probably contain cycles, needs to access their methods, etc.
Probably wise to look into how other do it. LSP: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/

---

Syntax modifications:

* on the subject of assignments:
	- multiple assignments:

	:a, :b = 5, 6
	a, b = list!($(l) l[3], l[6])

		Easy by interpreting the left operand as a List.

	- regular operator assignments:
		Could interpret the left operand as a string when it is an identifier, like how _._ works.
		Would feel good to have less nodes. But because we can doesn't mean we should. Also Assignment is reused in a few other places.

---

Reduce the number of AST node types ; try to merge similar node and make simpler individuals nodes if possible by composing them.
Won't help with performance but make me feel better, and easier to extend. Anselme should be more minimal is possible.

---

Static analysis tools.

To draw a graph of branches, keep track of used variables and prune the unused ones from the Environments, pre-filter Overloads, etc.

---

Multiline expressions.

* add the ability to escape newlines
	Issue: need a way to correctly track line numbers, the current parser assumes one expression = one source
* allow some expressions to run over several lines (the ones that expect a closing token, like paren/list/structs)
	Issue: the line and expression parsing is completely separate

---

Performance:

* the most terribly great choice is the overload with parameter filtering.
	Assuming the filter functions are pure seems reasonable, so caching could be done.
	Could also hardcode some shortcut paths for the simple type equality check case.
	Or track function/expression purity and cache/precompute the results. Not sure how to do that with multiple dispatch though.
	(note for future reference: once a function is first evaluated into a closure, its parameters are fixed, including the type check overloads)
* the recursive AST interpreter is also pretty meh, could do a bytecode VM.
	This one seems like a lot more work.
	Could also compile to Lua and let LuaJIT deal with it. Or WASM, that sounds trendy.

Then again, performance has never been a goal of Anselme.

---

Macros.

Could be implemented by creating functions to build AST nodes from Anselme that can also take quotes as arguments.
That should be easy, but I don't remember why I wanted macros in the first place, so until I want them again, shrug.

---

High concept ideas / stuff that sounds cool but maybe not worth it.

* Instead of using a bunch of sigils as operators, accept fancy unicode caracters.
	Easy to parse, but harder to write.
	Could implement a formatter/linter/whatever this is called these days and have Anselme recompile the AST into a nice, properly Unicodified output.
	Issue: the parser may be performing some transformations on the AST that would make the output an uncanny valley copy of the original. Also we need to preserve comments.
* Files are so 2000; instead put everything in a big single file and use a custom editor to edit it.
	Imagine selecting an identifier, and then it zooms in and show the AST associated to it. Nested indefinitely. Feels very futuristic, so probably worth it.
* Frankly the event buffer system still feel pretty janky, but I don't have any better idea for now.