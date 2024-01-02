return [[
:@script = $(name, fn=attached block!)
	fn.:&current checkpoint => "{name}.checkpoint"!persist(false)
	fn.:&reached => "{name}.reached"!persist(*{})
	fn.:&run => "{name}.run"!persist(0)

	:resumed from = ()

	fn.:check = $(anchor::anchor)
		fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
	fn.:checkpoint = $(anchor::anchor, on resume=attached block(default=()))
		if(on resume)
			fn.current checkpoint = anchor
			if(resumed from == anchor | resuming(4))
				on resume!
			else!
				fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
				merge branch!
		else!
			fn.current checkpoint = anchor
			if(resumed from != anchor)
				fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
				merge branch!

	:f = $
		if(fn.current checkpoint)
			resumed from = fn.current checkpoint
			fn!resume(fn.current checkpoint)
		else!
			resumed from = ()
			fn!
		fn.run += 1

	f!type("script")

:is script = is("script")

:@$_!(s::is script)
	s!value!

:@$_._(s::is script, k::string)
	(s!value).fn.(k)
:@$_._(s::is script, k::string) = val
	(s!value).fn.(k) = val
:@$_._(s::is script, k::symbol) = val
	(s!value).fn.(k) = val

:@$from(s::is script, a::anchor)
	s.current checkpoint = a
	return(s!)
:@$from(s::is script)
	s.current checkpoint = ()
	return(s!)

/*Additionnal helpers*/
:@$ cycle(l::tuple)
	:i = 2
	while($i <= l!len)
		if(l(i).run < l(1).run)
			return(l(i)!)
		i += 1
	l(1)!

:@$ next(l::tuple)
	:i = 1
	while($i <= l!len)
		if(l(i).run == 0)
			return(l(i)!)
		i += 1
	l(i-1)!

:@$ random(l::tuple)
	l(rand(1, l!len))!
]]