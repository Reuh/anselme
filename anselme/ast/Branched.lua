-- branched: associate to each branch a different value
-- used to handle mutability. probably the only mutable node you'll ever need! it's literally perfect!
-- note: all values here are expected to be already evaluated

local ast = require("anselme.ast")

local Branched
Branched = ast.abstract.Runtime {
	type = "branched",
	mutable = true,

	value = nil, -- { [branch name] = value, ... }

	init = function(self, state, value)
		self.value = {}
		self:set(state, value)
	end,

	in_branch = function(self, state)
		return not not self.value[state.branch_id]
	end,
	get = function(self, state)
		return self.value[state.branch_id] or self.value[state.source_branch_id]
	end,
	set = function(self, state, value)
		self.value[state.branch_id] = value
	end,
	_merge = function(self, state, cache)
		local val = self.value[state.branch_id]
		if val then
			self.value[state.source_branch_id] = val
			self.value[state.branch_id] = nil
			val:merge(state, cache)
		end
	end,

	_format = function(self, state, ...)
		if state then
			return self:get(state):format(state, ...)
		else
			local t = {}
			for b, v in pairs(self.value) do
				table.insert(t, ("%s→%s"):format(b, v))
			end
			return "<"..table.concat(t, ", ")..">"
		end
	end,

	traverse = function(self, fn, ...)
		for _, v in pairs(self.value) do
			fn(v, ...)
		end
	end,

	_eval = function(self, state)
		return self:get(state)
	end,

	-- serialize/deserialize in current branch and discard other branches
	_serialize = function(self)
		local state = require("anselme.serializer_state")
		return self:get(state)
	end,
	_deserialize = function(self)
		local state = require("anselme.serializer_state")
		return Branched:new(state, self)
	end
}

return Branched
