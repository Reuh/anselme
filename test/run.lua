local lfs = require("lfs")

local anselme = require("anselme")
local persistent_manager = require("state.persistent_manager")

local function run(path)
	local state = anselme:new()
	state:load_stdlib()

	local run_state = state:branch()

	local f = assert(io.open(path, "r"))
	local block = anselme.parse(f:read("*a"), path)
	f:close()

	run_state:run(block)

	local out = { "--# run #--" }

	while run_state:active() do
		local e, data = run_state:step()
		table.insert(out, "--- "..e.." ---")
		if e == "text" then
			for _, l in ipairs(data) do
				table.insert(out, l:format(run_state))
			end
		elseif e == "choice" then
			local choice = assert(run_state:eval_local("choice"), "no choice selected"):to_lua()
			for i, l in ipairs(data) do
				if i == choice then
					table.insert(out, "=> "..l:format(run_state))
				else
					table.insert(out, " > "..l:format(run_state))
				end
			end
			data:choose(choice)
		elseif e == "return" then
			table.insert(out, data:format(run_state))
			run_state:merge()
		else
			table.insert(out, tostring(data))
		end
	end

	table.insert(out, "--# saved #--")
	table.insert(out, persistent_manager:capture(run_state):format(run_state))

	return table.concat(out, "\n")
end

local tests = {}
for test in lfs.dir("test/tests/") do
	if test:match("%.ans$") then
		table.insert(tests, "test/tests/"..test)
	end
end

if arg[1] == "help" then
	print("usage:")
	print("lua test/run.lua: run all the tests")
	print("lua test/run.lua write: write missing result files")
	print("lua test/run.lua help: display this message")
elseif arg[1] == "write" then
	for _, test in ipairs(tests) do
		local f = io.open(test:gsub("^test/tests/", "test/results/"), "r")
		if f then
			f:close()
		else
			repeat
				local rerun = false
				print("* "..test)
				local c = assert(io.open(test, "r"))
				local code = c:read("*a")
				c:close()
				print("  Code:")
				print("    "..code:gsub("\n", "\n    "))
				local s, result = pcall(run, test)
				if not s then
					print("  Unexpected error: "..tostring(result))
					local r
					repeat
						io.write("Edit this file? (y/N) ")
						r = io.read("*l"):lower()
					until r == "y" or r == "n" or r == ""
					if r == "y" then
						os.execute(("micro %q"):format(test)) -- hardcoded but oh well
						rerun = true
					end
				else
					print("  Result:")
					print("    "..result:gsub("\n", "\n    "))
					local r
					repeat
						io.write("Write this result? (y/N/e) ")
						r = io.read("*l"):lower()
					until r == "y" or r == "n" or r == "e" or r == ""
					if r == "y" then
						local o = assert(io.open(test:gsub("^test/tests/", "test/results/"), "w"))
						o:write(result)
						o:close()
					elseif r == "e" then
						os.execute(("micro %q"):format(test)) -- hardcoded but oh well
						rerun = true
					end
				end
			until not rerun
		end
	end
elseif not arg[1] then
	local total, failure, errored, notfound = #tests, 0, 0, 0

	for _, test in ipairs(tests) do
		local f = io.open(test:gsub("^test/tests/", "test/results/"), "r")
		if f then
			local s, result = pcall(run, test)
			if not s then
				errored = errored + 1
				print("* "..test)
				print("  Unexpected error: "..tostring(result))
			else
				local expected = f:read("*a")
				if result ~= expected then
					failure = failure + 1
					print("* "..test)
					print("  Expected: \n    "..expected:gsub("\n", "\n    "))
					print("  But received: \n    "..result:gsub("\n", "\n    "))
					print("")
				end
			end
			f:close()
		else
			notfound = notfound + 1
			print("* "..test)
			print("  Result file not found.")
			print("")
		end
	end

	print("#### Results ####")
	print(("%s successes, %s failures, %s errors, %s missing result files, out of %s tests"):format(total-failure-notfound-errored, failure, errored, notfound, total))
else
	print("unknown command, run `lua test/run.lua help` for usage")
end
