return setmetatable({
	abstract = setmetatable({}, {
		__index = function(self, key)
			self[key] = require("anselme.ast.abstract."..key)
			return self[key]
		end
	})
}, {
	__index = function(self, key)
		self[key] = require("anselme.ast."..key)
		return self[key]
	end
})
