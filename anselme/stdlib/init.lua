local parser = require("anselme.parser")

local function define_lua(state, list)
	for _, fn in ipairs(list) do
		state.scope:define_lua(fn[1], fn[2], fn[3], true)
	end
end
local function load(state, l)
	for _, m in ipairs(l) do
		define_lua(state, require("anselme.stdlib."..m))
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

	local boot = parser(require("anselme.stdlib.boot_script"), "boot.ans")
	boot:eval(main_state)

	load(main_state, {
		"number",
		"string",
		"text",
		"structures",
		"closure",
		"checkpoint",
		"persist",
	})
end
