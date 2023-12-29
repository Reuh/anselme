-- Require LuaFileSystem: luarocks install luafilesystem

local lfs = require("lfs")

package.path = "./?/init.lua;./?.lua;" .. package.path
local anselme = require("anselme")
local persistent_manager = require("anselme.state.persistent_manager")

-- simple random to get the same result across lua versions
local prev = 0
local function badrandom(a, b)
	prev = (4241 * prev + 11) % 6997
	return a + prev % (b-a+1)
end
function math.random(a, b)
	if not a and not b then
		return badrandom(0, 999) / 1000
	elseif not b then
		return badrandom(1, a)
	else
		return badrandom(a, b)
	end
end

-- run a test file and return the result
local function run(path)
	local state = anselme:new()
	state:load_stdlib()

	local run_state = state:branch()

	local f = assert(io.open(path, "r"))
	local s, block = pcall(anselme.parse, f:read("*a"), path)
	f:close()

	if not s then
		return "--# parse error #--\n"..tostring(block)
	end

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

-- display an animated loading indicator
io.stdout:setvbuf("no")
local loading = {
	loop = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
	loop_pos = 1,
	erase_code = "",

	write = function(self, message)
		self:clear()
		local str = self.loop[self.loop_pos].." "..message
		self.erase_code = ("\b"):rep(#str)
		io.write(str)
	end,
	clear = function(self)
		io.write(self.erase_code)
	end,
	update = function(self)
		self.loop_pos = self.loop_pos + 1
		if self.loop_pos > #self.loop then self.loop_pos = 1 end
	end
}

-- list tests
local tests = {}
for test in lfs.dir("test/tests/") do
	if test:match("%.ans$") then
		table.insert(tests, "test/tests/"..test)
	end
end

-- run!
if not arg[1] or arg[1] == "update" then
	local total, failure, errored, notfound = #tests, 0, 0, 0

	for i, test in ipairs(tests) do
		repeat
			local rerun = false

			-- load result
			local f = io.open(test:gsub("^test/tests/", "test/results/"), "r")
			local expected
			if f then
				expected = f:read("*a")
				f:close()
			end

			-- run test
			local result = run(test)
			if result ~= expected then
				loading:clear()
				print("* "..test)
				if expected then failure = failure + 1
				else notfound = notfound + 1
				end
				if arg[1] == "update" then
					local c = assert(io.open(test, "r"))
					local code = c:read("*a")
					c:close()
					print("  Code:")
					print("    "..code:gsub("\n", "\n    "))
				end
				if expected then
					print("  Expected result: \n    "..expected:gsub("\n", "\n    "))
					print("  But received: \n    "..result:gsub("\n", "\n    "))
				else
					print("  No result file found, generated result: \n    "..result:gsub("\n", "\n    "))
				end
				if arg[1] == "update" then
					local r
					repeat
						if expected then
							io.write("Update this result? (y/N/e) ")
						else
							io.write("Write this result? (y/N/e) ")
						end
						r = io.read("*l"):lower()
					until r == "y" or r == "n" or r == "e" or r == ""
					if r == "y" then
						local o = assert(io.open(test:gsub("^test/tests/", "test/results/"), "w"))
						o:write(result)
						o:close()
						if expected then failure = failure - 1
						else notfound = notfound - 1
						end
					elseif r == "e" then
						os.execute(("micro %q"):format(test)) -- hardcoded but oh well
						rerun = true
						if expected then failure = failure - 1
						else notfound = notfound - 1
						end
					end
				end
				print("")
			end
		until not rerun

		-- status
		loading:write(("%s/%s tests ran"):format(i, #tests))
		if i % 10 == 0 then loading:update() end
	end

	loading:clear()
	print("#### Results ####")
	local successes = total-failure-notfound-errored
	print(("%s successes, %s failures, %s errors, %s missing result files, out of %s tests"):format(successes, failure, errored, notfound, total))
	if successes < total then os.exit(1) end
else
	print("usage:")
	print("lua test/run.lua: run all the tests")
	print("lua test/run.lua update: run all tests, optionally updating incorrect or missing results")
	print("lua test/run.lua help: display this message")
end
