local ast = require("ast")
local Nil, Return, AutoCall, ArgumentTuple, Flush

local resume_manager = require("state.resume_manager")

local Block = ast.abstract.Node {
	type = "block",

	expressions = {},

	init = function(self)
		self.expressions = {}
	end,
	add = function(self, expression) -- only for construction
		table.insert(self.expressions, expression)
	end,

	_format = function(self, state, prio, ...)
		local l = {}
		for _, e in ipairs(self.expressions) do
			if Flush:is(e) then
				table.insert(l, (e:format(state, 0, ...):gsub("\n$", "")))
			else
				table.insert(l, e:format(state, 0, ...))
			end
		end
		return table.concat(l, "\n")
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.expressions) do
			fn(e, ...)
		end
	end,

	_eval = function(self, state)
		local r
		state.scope:push()
		if self:contains_resume_target(state) then
			local anchor = resume_manager:get(state)
			local resumed = false
			for _, e in ipairs(self.expressions) do
				if e:contains_anchor(anchor) then resumed = true end
				if resumed then
					r = e:eval(state)
					if AutoCall:issub(r) then
						r = r:call(state, ArgumentTuple:new())
					end
					if Return:is(r) then
						break -- pass on to parent block until we reach a function boundary
					end
				end
			end
		else
			for _, e in ipairs(self.expressions) do
				r = e:eval(state)
				if AutoCall:issub(r) then
					r = r:call(state, ArgumentTuple:new())
				end
				if Return:is(r) then
					break -- pass on to parent block until we reach a function boundary
				end
			end
		end
		state.scope:pop()
		return r or Nil:new()
	end,

	_prepare = function(self, state)
		state.scope:push()
		for _, e in ipairs(self.expressions) do
			e:prepare(state)
		end
		state.scope:pop()
	end
}

package.loaded[...] = Block
Nil, Return, AutoCall, ArgumentTuple, Flush = ast.Nil, ast.Return, ast.abstract.AutoCall, ast.ArgumentTuple, ast.Flush

return Block
