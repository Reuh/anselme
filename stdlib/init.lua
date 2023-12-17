local parser = require("parser")

local function define_lua(state, list)
	for _, fn in ipairs(list) do
		state.scope:define_lua(fn[1], fn[2], fn[3], true)
	end
end
local function load(state, l)
	for _, m in ipairs(l) do
		define_lua(state, require("stdlib."..m))
	end
end

return function(main_state)
	load(main_state, {
		"boolean",
		"tag",
		"conditionals",
		"base",
		"type_check"
	})

	local f = assert(io.open("stdlib/boot.ans"))
	local boot = parser(f:read("*a"), "boot.ans")
	f:close()
	boot:eval(main_state)

	load(main_state, {
		"number",
		"string",
		"text",
		"structures",
		"closure",
		"checkpoint"
	})
end
