local ast = require("anselme.ast")

local operator_priority = require("anselme.common").operator_priority

local ParameterTuple
ParameterTuple = ast.abstract.Node {
	type = "parameter tuple",

	assignment = false,
	list = nil,
	min_arity = 0,
	max_arity = 0,

	eval_depth = 0, -- scope deth where this parametertuple was evaluated, used as secondary specificity

	init = function(self, ...)
		self.list = {...}
	end,
	insert = function(self, val) -- only for construction
		assert(not self.assignment, "can't add new parameters after assignment parameter was added")
		table.insert(self.list, val)
		self.max_arity = self.max_arity + 1
		if not val.default then
			self.min_arity = self.min_arity + 1
		end
	end,
	insert_assignment = function(self, val) -- only for construction
		self:insert(val)
		self.assignment = true
	end,

	_format = function(self, state, prio, ...)
		local l = {}
		for i, e in ipairs(self.list) do
			if i < self.max_arity or not self.assignment then
				table.insert(l, e:format(state, operator_priority["_,_"], ...))
			end
		end
		local s = ("(%s)"):format(table.concat(l, ", "))
		if self.assignment then
			s = s .. (" = %s"):format(self.list[#self.list]:format_right(state, operator_priority["_=_"], ...))
		end
		return s
	end,
	_format_priority = function(self)
		if self.assignment then
			return operator_priority["_=_"]
		end
		return math.huge
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.list) do
			fn(e, ...)
		end
	end,

	_eval = function(self, state)
		local r = ParameterTuple:new()
		for i, param in ipairs(self.list) do
			if i < self.max_arity or not self.assignment then
				r:insert(param:eval(state))
			else
				r:insert_assignment(param:eval(state))
			end
		end
		r.eval_depth = state.scope:depth()
		return r
	end
}

return ParameterTuple
