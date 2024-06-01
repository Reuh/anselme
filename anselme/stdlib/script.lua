--- # Scripts
--
-- Scripts extends on functions to provide tracking and persistence features useful for game dialogs:
--
-- * checkpoints allow scripts to be restarted from specific points when they are interrupted or restarted;
-- * tracking of reached status of anchors to be able to know what has already been shown to the player;
-- * helper functions to call scripts in common patterns.
--
-- ```
-- :hello = "hello"!script
-- 	| Hello...
-- 	#midway!checkpoint
-- 		| Let's resume. Hello...
-- 	| ...world!
-- hello! // Hello..., ...world!
-- hello! // Let's resume. Hello..., ...world!
-- print(hello.reached(#midway)) // 1
-- print(hello.run) // 2
-- print(hello.current checkpoint) // #midway
-- ```
-- @titlelevel 3

--- Creates and returns a new script.
--
-- `name` is the script identifier (typically a string), which is used as a prefix for the persistent storage keys of the script variables. This means that for the script variables to be stored and retrieved properly from a game save, the script name must stays the same and be unique for each script.
--
-- `fn` is the function that will be run when the script is called.
--
-- Some variables are defined into the script/`fn` scope. They are all stored from persistent storage, using the script name as part of their persistent key:
--
-- * `current checkpoint` is the currently set checkpoint (an anchor);
-- * `reached` is a table of *{ #anchor = number, ... } which associates to an anchor the number of times it was reached (see `check` and `checkpoint`);
-- * `run` is the number of times the script was successfully called.
--
-- As well as functions defined in the script scope:
--
-- * `check (anchor::is anchor)` increment by 1 the number of times `anchor` was reached in `reached`;
-- * `checkpoint (anchor::is anchor, on resume=attached block(default=()))` sets the current checkpoint to `anchor`, increment by 1 the number of times `anchor` was reached in `reached`, and merge the current branch state into the parent branch. If we are currently resuming to `anchor`, instead this only calls `on resume!` and keep resuming the script from the anchor.
-- @title script (name, fn=attached block!)

--- Returns true if `x` is a script, false otherwise.
-- @title is script (x)
-- @defer value checking

--- Run the script `s`.
--
-- If a checkpoint is set, resume the script from this checkpoint.
-- Otherwise, run the script from the beginning.
-- `s.run` is incremented by 1 after it is run.
-- @title s::is script !

--- Returns the value of the variable `k` defined in the scripts `s`'s scope.
-- @title s::is script . k::is string

--- Sets the value of the variable `k` defined in the scripts `s`'s scope to `val`.
-- @title s::is script . k::is string = val

--- Define the variable `k` in the scripts `s`'s scope with the value `val`.
-- @title s::is script . k::is symbol = val

--- Resume the script `s` from anchor `a`, setting it as the current checkpoint.
-- @title from (s::is script, a::is anchor)

--- Run the script `s` from its beginning, discarding any current checkpoint.
-- @title from (s::is script, anchor::is nil=())

--- Run the first script in the the tuple `l` with a `run` variable strictly lower than the first element, or the first element if it has the lowest `run`.
--
-- This means that, if the scripts are only called through `cycle`, the scripts in the tuple `l` will be called in a cycle:
-- when `cycle` is first called the 1st script is called, then the 2nd, ..., then the last, and then looping back to the 1st.
-- @title cycle (l::is tuple)

--- Run the first script in the tuple `l` with a `run` that is 0, or the last element if there is no such script.
--
-- This means that, if the scripts are only called through `next`, the scripts in the tuple `l` will be called in order:
-- when `next` is first called the 1st script is called, then the 2nd, ..., then the last, and then will keep calling the last element.
-- @title next (l::is tuple)

--- Run a random script from the typle `l`.
-- @title random (l::is tuple)

return [[
:@ script = $(name, fn=attached block!)
	fn.:&current checkpoint => "{name}.checkpoint"!persist(false)
	fn.:&reached => "{name}.reached"!persist(*{})
	fn.:&run => "{name}.run"!persist(0)

	:resume target = ()

	fn.:check = $(anchor::is anchor)
		fn.reached(anchor, 0) += 1
	fn.:checkpoint = $(anchor::is anchor, on resume=attached block(default=()))
		:resuming = resuming(1) /* calling function is resuming */
		if(on resume)
			fn.current checkpoint = anchor
			if(resume target == anchor | resuming)
				on resume!
			else!
				fn.reached(anchor, 0) += 1
				merge branch!
		else!
			fn.current checkpoint = anchor
			if(resume target != anchor)
				fn.reached(anchor, 0) += 1
				merge branch!

	:f = $
		if(fn.current checkpoint)
			resume target = fn.current checkpoint
			fn!from(fn.current checkpoint)
		else!
			resume target = ()
			fn!
		fn.run += 1

	f!type("script")

:is script = is("script")

:@$_!(s::is script)
	s!value!

:@$_._(s::is script, k::is string)
	(s!value).fn.(k)
:@$_._(s::is script, k::is string) = val
	(s!value).fn.(k) = val
:@$_._(s::is script, k::is symbol) = val
	(s!value).fn.(k) = val

:@$ from(s::is script, a::is anchor)
	s.current checkpoint = a
	return(s!)
:@$ from(s::is script, anchor::is nil=())
	s.current checkpoint = ()
	return(s!)

/* Additionnal helpers */
:@$ cycle(l::is tuple)
	:i = 2
	while($i <= l!len)
		if(l(i).run < l(1).run)
			return(l(i)!)
		i += 1
	l(1)!

:@$ next(l::is tuple)
	:i = 1
	while($i <= l!len)
		if(l(i).run == 0)
			return(l(i)!)
		i += 1
	l(i-1)!

:@$ random(l::is tuple)
	l(rand(1, l!len))!
]]