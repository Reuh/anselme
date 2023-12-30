return [[
:@script = $(name, fn)
	:&current checkpoint => "{name}.checkpoint"!persist(false)
	:&reached => "{name}.reached"!persist(*{})
	:resumed from = ()

	fn.:check = $(anchor::anchor)
		reached(anchor) = (reached(anchor) | 0) + 1
	fn.:checkpoint = $(anchor::anchor)
		current checkpoint = anchor
		resumed from != anchor ~
			reached(anchor) = (reached(anchor) | 0) + 1
	fn.:checkpoint = $(anchor::anchor, on resume::function)
		current checkpoint = anchor
		resumed from == anchor | resuming(1) ~
			on resume!
		~
			reached(anchor) = (reached(anchor) | 0) + 1

	:f = $
		current checkpoint ~
			resumed from = current checkpoint
			fn!resume(current checkpoint)
		~
			resumed from = ()
			fn!
		run += 1
	f.:&run => "{name}.run"!persist(0)

	f!type("script")

:is script = is("script")

:@$_!(s::is script)
	s!value!

:@$_._(s::is script, k::string)
	:v = s!value
	v.fn!has upvalue(k) ~
		@v.fn.(k)
	~
		@v.(k)

:@$_._(s::is script, k::string) = val
	:v = s!value
	v.fn!has upvalue(k) ~
		v.fn.(k) = val
	~
		v.(k) = val

:@$from(s::is script, a::anchor)
	s.current checkpoint = a
	@s!
:@$from(s::is script)
	s.current checkpoint = ()
	@s!
]]