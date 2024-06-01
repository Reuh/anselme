--- ## For loops
-- @titlelevel 3

--- Iterates over the elements of `var`: for each element, set the variable `symbol` in the function `block`'s environment and call it.
--
-- In order to get the elements of `var`, this calls `iter(var)` to obtain an iterator over var.
-- An iterator is a function that, each time it is called, returns the next value given to the for loop. When the iterator returns nil, the loop ends.
--
-- ```
-- :l = [1,2,3]
-- // prints 1, 2, and 3
-- for(:x, l)
-- 	print(x)
-- ```
-- @title for (symbol::is symbol, var, block=attached block(keep return=true))

--- ## Ranges

--- Returns true if `val` is a range, false otherwise.
-- @title is range (val)
-- @defer value checking

--- Returns a new range, going from 1 to `stop` with a step of 1.
-- @title range (stop::is number)

--- Returns a new range, going from `start` to `stop` with a step of `step`.
-- @title range (start::is number, stop::is number, step::is number=1)

--- Returns an iterator that iterates over the range.
-- For a range going from `start` to `stop` with a step of `step`, this means this will iterate over all the numbers `x` such that x = start + n⋅step with n ∈ N and x ≤ stop, starting from n = 0.
-- @title iter (t::is range)

--- Returns an iterator that iterates over the elements of the sequence (a list or tuple).
-- @title iter (t::is sequence)
-- @defer structures

--- Returns an iterator that iterates over the keys of the table.
-- @title iter (t::is table)
-- @defer structures

return [[
/* For loop */
:@$for(symbol::is symbol, var, block=attached block(keep return=true))
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
:@is range = is("range")
:@$range(stop::is number)
	[1, stop, 1]!type("range")
:@$range(start::is number, stop::is number, step::is number=1)
	[start, stop, step]!type("range")
:@$iter(range::is range)
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
:@$iter(tuple::is sequence)
	:n = tuple!len
	:i = 0
	$
		if(i < n)
			i += 1
			return(tuple(i))

/* Table */
:@$iter(table::is table)
	:s = table!to struct
	iter(s)
]]
