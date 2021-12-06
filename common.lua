--- replace values recursively in table t according to to_replace ([old table] = new table)
local function replace_in_table(t, to_replace, already_replaced)
	already_replaced = already_replaced or {}
	already_replaced[t] = true
	for k, v in pairs(t) do
		if to_replace[v] then
			t[k] = to_replace[v]
		elseif type(v) == "table" and not already_replaced[v] then
			replace_in_table(v, to_replace, already_replaced)
		end
	end
end

local common
common = {
	--- recursively copy a table, handle cyclic references, no metatable, don't copy keys
	-- cache is table with copied tables [original table] = copied value, will use temporary table is omitted
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
	end,
	--- given a table t from which some copy was issued, the copy cache, and a list of tables from the copied version,
	-- put theses copied tables in t in place of their original values, preserving references to non-modified values
	replace_with_copied_values = function(t, cache, copied_to_replace)
		-- reverse copy cache
		local ehcac = {}
		for k, v in pairs(cache) do ehcac[v] = k end
		-- build table of [original table] = replacement copied table
		local to_replace = {}
		for _, v in ipairs(copied_to_replace) do
			local original = ehcac[v]
			if original then -- table doesn't have an original value if it's a new table...
				to_replace[original] = v
			end
		end
		-- fix references to not-modified tables in modified values
		local not_modified = {}
		for original, modified in pairs(cache) do
			if not to_replace[original] then
				not_modified[modified] = original
			end
		end
		for _, m in ipairs(copied_to_replace) do
			replace_in_table(m, not_modified)
		end
		-- replace
		replace_in_table(t, to_replace)
	end
}
return common
