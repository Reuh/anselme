local common
common = {
	--- recursively copy a table, handle cyclic references, no metatable
	copy = function(t, cache)
		if type(t) == "table" then
			cache = cache or {}
			if cache[t] then
				return cache[t]
			else
				local c = {}
				cache[t] = c
				for k, v in pairs(t) do
					c[k] = common.copy(v, cache)
				end
				return c
			end
		else
			return t
		end
	end
}
return common
