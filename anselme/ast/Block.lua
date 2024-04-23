local ast = require("anselme.ast")
local Nil, Return, Flush

local resume_manager = require("anselme.state.resume_manager")

local Block = ast.abstract.Node {
	type = "block",

	expressions = {},

	init = function(self, ...)
		self.expressions = {...}
	end,
	add = function(self, expression) -- only for construction
		table.insert(self.expressions, expression)
	end,

	_format = function(self, state, prio, indentation, ...)
		local l = {}
		local indent = ("\t"):rep(indentation)
		for _, e in ipairs(self.expressions) do
			if Flush:is(e) then
				table.insert(l, indent..(e:format(state, 0, indentation, ...):gsub("\n$", "")))
			else
				table.insert(l, indent..e:format(state, 0, indentation, ...))
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
		if self:contains_current_resume_target(state) then
			local target = resume_manager:get(state)
			local resumed = false
			for _, e in ipairs(self.expressions) do
				if e:contains_resume_target(target) then resumed = true end
				if resumed then
					r = e:eval_statement(state)
					if Return:is(r) then
						break -- pass on to parent block until we reach a function boundary
					end
				end
			end
		else
			for _, e in ipairs(self.expressions) do
				r = e:eval_statement(state)
				if Return:is(r) then
					break -- pass on to parent block until we reach a function boundary
				end
			end
		end
		state.scope:pop()
		return r or Nil:new()
	end,
}

package.loaded[...] = Block
Nil, Return, Flush = ast.Nil, ast.Return, ast.Flush

return Block
