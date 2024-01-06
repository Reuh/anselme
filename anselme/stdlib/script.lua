return [[
:@script = $(name, fn=attached block!)
	fn.:&current checkpoint => "{name}.checkpoint"!persist(false)
	fn.:&reached => "{name}.reached"!persist(*{})
	fn.:&run => "{name}.run"!persist(0)

	:resume target = ()

	fn.:check = $(anchor::is anchor)
		fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
	fn.:checkpoint = $(anchor::is anchor, on resume=attached block(default=()))
		if(on resume)
			fn.current checkpoint = anchor
			if(resume target == anchor | resuming(4))
				on resume!
			else!
				fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
				merge branch!
		else!
			fn.current checkpoint = anchor
			if(resume target != anchor)
				fn.reached(anchor) = (fn.reached(anchor) | 0) + 1
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

:@$from(s::is script, a::is anchor)
	s.current checkpoint = a
	return(s!)
:@$from(s::is script)
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