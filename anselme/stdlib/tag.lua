local ast = require("anselme.ast")
local Tuple, Table, Struct, ArgumentTuple, Nil = ast.Tuple, ast.Table, ast.Struct, ast.ArgumentTuple, ast.Nil

local tag_manager = require("anselme.state.tag_manager")

return {
	{
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
