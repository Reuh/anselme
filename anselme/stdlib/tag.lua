--- # Tagging
-- @titlelevel 3

local ast = require("anselme.ast")
local Tuple, Table, Struct, ArgumentTuple, Nil = ast.Tuple, ast.Table, ast.Struct, ast.ArgumentTuple, ast.Nil

local tag_manager = require("anselme.state.tag_manager")

return {
	{
		--- Add the tags from `tags` to the tag stack while calling `expression`.
		--
		-- `tags` can be:
		--
		-- * a tuple of tags
		-- * a struct of tags
		-- * a table of tags
		-- * nil, for no new tags
		-- * any other value, for a single tag
		"_#_", "(tags, expression)",
		function(state, tags, expression)
			local tags_struct
			if Tuple:is(tags) and not tags.explicit then
				tags_struct = Struct:from_tuple(tags):eval(state)
			elseif Struct:is(tags) then
				tags_struct = tags
			elseif Table:is(tags) then
				tags_struct = tags:to_struct(state)
			elseif Nil:is(tags) then
				tags_struct = Struct:new()
			else
				tags_struct = Struct:from_tuple(Tuple:new(tags)):eval(state)
			end

			tag_manager:push(state, tags_struct)
			local v = expression:call(state, ArgumentTuple:new())
			tag_manager:pop(state)
			return v
		end
	}
}
