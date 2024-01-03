local ast = require("anselme.ast")
local assert0 = require("anselme.common").assert0

local Overload
Overload = ast.abstract.Node {
	type = "overload",
	_evaluated = true,

	list = nil, -- list of Overloadable
	_signatures = nil, -- map {[parameter hash]=true} of call signatures already registered in this overload

	init = function(self, ...)
		self.list = {}
		self._signatures = {}
		for _, fn in ipairs{...} do
			self:insert(fn)
		end
	end,
	insert = function(self, val) -- only for construction
		assert0(not self._signatures[val:hash_signature()], ("a function with parameters %s is already defined in the overload"):format(val:format_signature()))
		table.insert(self.list, val)
		self._signatures[val:hash_signature()] = true
	end,

	_format = function(self, ...)
		local s = "overload<"
		for i, e in ipairs(self.list) do
			s = s .. e:format(...)
			if i < #self.list then s = s .. ", " end
		end
		return s..">"
	end,

	traverse = function(self, fn, ...)
		for _, e in ipairs(self.list) do
			fn(e, ...)
		end
	end,

	dispatch = function(self, state, args)
		local failure = {} -- list of failure messages (kept until we find the first success)
		local success, success_specificity, success_secondary_specificity = nil, -1, -1
		-- some might think that iterating a list for every function call is a terrible idea, but that list has a fixed number of elements, so big O notation says suck it up
		for _, fn in ipairs(self.list) do
			local specificity, secondary_specificity = fn:compatible_with_arguments(state, args)
			if specificity then
				if specificity > success_specificity then
					success, success_specificity, success_secondary_specificity = fn, specificity, secondary_specificity
				elseif specificity == success_specificity then
					if secondary_specificity > success_secondary_specificity then
						success, success_specificity, success_secondary_specificity = fn, specificity, secondary_specificity
					elseif secondary_specificity == success_secondary_specificity then
						return nil, ("more than one function match %s, matching functions were at least (specificity %s.%s):\n\t• %s\n\t• %s"):format(args:format(state), specificity, secondary_specificity, fn:format_signature(state), success:format_signature(state))
					end
				end
				-- no need to add error message for less specific function since we already should have at least one success
			elseif not success then
				table.insert(failure, fn:format_signature(state) .. ": " .. secondary_specificity)
			end
		end
		if success then
			return success, args
		else
			return nil, ("no function match %s, possible functions were:\n\t• %s"):format(args:format(state), table.concat(failure, "\n\t• "))
		end
	end
}

return Overload
