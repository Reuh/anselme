return [[
/* For loop */
:@$for(symbol::symbol, var, block=attached block(keep return=true))
	:iterator = iter(var)
	:value = iterator()
	:name = symbol!to string
	block.(symbol) = value
	while($value != ())
		:r = block!
		value = iterator()
		block.(name) = value
		r

/* Range iterables */
:@$range(stop)
	[1, stop, 1]!type("range")
:@$range(start, stop, step=1)
	[start, stop, step]!type("range")
:@$iter(range::is("range"))
	:v = range!value
	:start = v(1)
	:stop = v(2)
	:step = v(3)
	:i = start
	if(step > 0)
		return($_)
			if(i <= stop)
				i += step
				return(i-step)
	else!
		return($_)
			if(i >= stop)
				i += step
				return(i-step)

/* List/tuple iterables */
:tuple or list = $(x) x!type == "tuple" | x!type == "list"
:@$iter(tuple::tuple or list)
	:n = tuple!len
	:i = 0
	$
		if(i < n)
			i += 1
			return(tuple(i))

/* Table */
:@$iter(table::table)
	:s = table!to struct
	iter(s)
]]
