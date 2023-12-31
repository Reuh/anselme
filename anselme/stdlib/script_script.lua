return [[
:@script = $(name, fn)
	fn.:&current checkpoint => "{name}.checkpoint"!persist(false)
	fn.:&reached => "{name}.reached"!persist(*{})
	fn.:&run => "{name}.run"!persist(0)

	:resumed from = ()

	fn.:check = $(anchor::anchor)
		fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
	fn.:checkpoint = $(anchor::anchor)
		fn.current checkpoint = anchor
		resumed from != anchor ~
			fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
			merge branch!
	fn.:checkpoint = $(anchor::anchor, on resume::function)
		fn.current checkpoint = anchor
		resumed from == anchor | resuming(1) ~
			on resume!
		~
			fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
			merge branch!

	:f = $
		fn.current checkpoint ~
			resumed from = fn.current checkpoint
			fn!resume(fn.current checkpoint)
		~
			resumed from = ()
			fn!
		fn.run += 1

	f!type("script")

:is script = is("script")

:@$_!(s::is script)
	s!value!

:@$_._(s::is script, k::string)
	@(s!value).fn.(k)
:@$_._(s::is script, k::string) = val
	(s!value).fn.(k) = val
:@$_._(s::is script, k::symbol) = val
	(s!value).fn.(k) = val

:@$from(s::is script, a::anchor)
	s.current checkpoint = a
	@s!
:@$from(s::is script)
	s.current checkpoint = ()
	@s!

/*Additionnal helpers*/
:@$ cycle(l::tuple)
	:i = 2
	i <= l!len ~?
		l(i).run < l(1).run ~
			@l(i)!
		i += 1
	l(1)!

:@$ next(l::tuple)
	:i = 1
	i <= l!len ~?
		l(i).run == 0 ~
			@l(i)!
		i += 1
	l(i-1)!

:@$ random(l::tuple)
	l(rand(1, l!len))!
]]