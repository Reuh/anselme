local ast = require("anselme.ast")
local Number, Struct, String, Nil, Boolean

local function to_anselme(val)
	if type(val) == "number" then
		return Number:new(val)
	elseif type(val) == "table" then
		local s = Struct:new()
		for k, v in pairs(val) do
			s:set(to_anselme(k), to_anselme(v))
		end
		return s
	elseif type(val) == "string" then
		return String:new(val)
	elseif type(val) == "nil" then
		return Nil:new()
	elseif type(val) == "boolean" then
		return Boolean:new(val)
	else
		error("can't convert "..type(val).." to an Anselme value")
	end
end

Number, Struct, String, Nil, Boolean = ast.Number, ast.Struct, ast.String, ast.Nil, ast.Boolean

return to_anselme
