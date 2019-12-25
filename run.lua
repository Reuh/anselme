require("candran").setup()

local vm = require("anselme")()

vm:loaddirectory(".")
vm:loadfile("test.ans")

print(require("inspect")(vm.state))

while true do
	local e, d = vm:step()
	if e == "text" then
		for _, t in ipairs(d) do
			print(t.text)
			for k,v in pairs(t.tags) do
				print("> "..tostring(k)..": "..tostring(v))
			end
		end
		print("-----")
	elseif e == "choice" then
		for i, c in ipairs(d) do
			print(tostring(i)..": "..c.text)
			for k,v in pairs(c.tags) do
				print("> "..tostring(k)..": "..tostring(v))
			end
		end
		local choice
		repeat
			choice = tonumber(io.read("*l"))
		until choice ~= nil and choice > 0 and choice <= #d
		vm:choose(choice)
	elseif e == "end" then
		break
	else
		error("unknown event ("..tostring(e)..")")
	end
end
