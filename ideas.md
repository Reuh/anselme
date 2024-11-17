Various ideas and things that may or may not be done. It's like GitHub issues, but I don't have to leave my text editor or connect to the scary Internet.

Loosely ordered by willingness to implement.

---

Redundant `TextEventData:group_by` and `stdlib.group text by tag`: there can be only one.

---

Translation.

Do some more fancy scope work to allow the translation to access variables defined in the translation file?

---

Return system.

Could be reused for exception handling or other purposes if accessible by the user.

Also, named break for nested loops.

---

Custom function for building text/string interpolation.

---

Static analysis tools.

To draw a graph of branches, keep track of used variables and prune the unused ones from the Environments, pre-filter Overloads, etc.

---

Performance:

* the most terribly great choice is the overload with parameter filtering.
	Assuming the filter functions are pure seems reasonable, so caching could be done.
	Could also hardcode some shortcut paths for the simple type equality check case.
	Or track function/expression purity and cache/precompute the results. Not sure how to do that with multiple dispatch though.
	(note for future reference: once a function is first evaluated into a closure, its parameters are fixed, including the value check callable)
* the recursive AST interpreter is also pretty meh, could do a bytecode VM.
	This one seems like a lot more work.
	Could also compile to Lua and let LuaJIT deal with it. Or WASM, that sounds trendy.

Then again, performance has never been a goal of Anselme.

---

High concept ideas / stuff that sounds cool but likely not worth it.

* Instead of using a bunch of sigils as operators, accept fancy unicode caracters.
	Easy to parse, but harder to write.
	Could implement a formatter/linter/whatever this is called these days and have Anselme recompile the AST into a nice, properly Unicodified output.
	Issue: the parser may be performing some transformations on the AST that would make the output an uncanny valley copy of the original. Also we need to preserve comments.
* Files are so 2000; instead put everything in a big single file and use a custom editor to edit it.
	Imagine selecting an identifier, and then it zooms in and show the AST associated to it. Nested indefinitely. Feels very futuristic, so probably worth it.
* Frankly the event buffer system still feel pretty janky, but I don't have any better idea for now.
