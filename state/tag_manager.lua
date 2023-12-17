local class = require("class")

local ast = require("ast")
local Struct, Identifier

local tag_identifier, tag_symbol

local tag_manager = class {
	init = false,

	setup = function(self, state)
		state.scope:define(tag_symbol, Struct:new())
	end,

	push = function(self, state, tbl)
		local new_strct = Struct:new()
		new_strct:include(self:get(state))
		new_strct:include(tbl)

		state.scope:push_partial(tag_identifier)
		state.scope:define(tag_symbol, new_strct)
	end,
	pop = function(self, state)
		state.scope:pop()
	end,

	get = function(self, state)
		return state.scope:get(tag_identifier)
	end
}

package.loaded[...] = tag_manager
Struct, Identifier = ast.Struct, ast.Identifier

tag_identifier = Identifier:new("_tags")
tag_symbol = tag_identifier:to_symbol()

return tag_manager
