-- Require LuaFileSystem for running test suite: luarocks install luafilesystem
-- Not needed for running a single script in interactive mode.

package.path = "./?/init.lua;./?.lua;" .. package.path
local anselme = require("anselme")
local persistent_manager = require("anselme.state.persistent_manager")
local ast = require("anselme.ast")

io.stdout:setvbuf("no")

-- simple random to get the same result across lua versions
local prev = 0
local function badrandom(a, b)
	prev = (4241 * prev + 11) % 6997
	return a + prev % (b-a+1)
end
function math.randomseed()
	prev = 0
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

-- handle anselme run loop
local function run_loop(run_state, write_output, interactive)
	while run_state:active() do
		local e, data = run_state:step()
		write_output("--- "..e.." ---")
		if e == "text" then
			for _, l in ipairs(data) do
				write_output(l:format(run_state))
			end
		elseif e == "choice" then
			local choice
			if interactive then
				for i, l in ipairs(data) do
					write_output(("%s> %s"):format(i, l:format(run_state)))
				end
				io.write(("Select choice (1-%s): "):format(#data))
				choice = tonumber(io.read("l"))
			else
				choice = assert(run_state:eval_local("choice"), "no choice selected"):to_lua()
				for i, l in ipairs(data) do
					if i == choice then
						write_output(("=> %s"):format(l:format(run_state)))
					else
						write_output((" > %s"):format(l:format(run_state)))
					end
				end
			end
			data:choose(choice)
		elseif e == "return" then
			write_output(data:format(run_state))
			run_state:merge()
		else
			write_output(tostring(data))
		end
	end
end

-- run a test file and return the result
local function run(path, interactive)
	local out = { "--# run #--" }
	local write_output
	if interactive then write_output = print
	else write_output = function(str) table.insert(out, str) end
	end
	math.randomseed()

	local state = anselme:new()
	state:load_stdlib()

	state:define("interrupt", "(code::string)", function(state, code) state:interrupt(code:to_lua(state), "interrupt") return ast.Nil:new() end, true)
	state:define("interrupt", "()", function(state) state:interrupt() return ast.Nil:new() end, true)
	state:define("wait", "(duration::number)", function(duration) coroutine.yield("wait", duration) end)
	state:define("run in new branch", "(code)", function(code)
		local parallel_state = state:branch()
		write_output("--# parallel script #--")
		parallel_state:run(code, "parallel")
		run_loop(parallel_state, write_output, interactive)
		write_output("--# main script #--")
	end)
	state:define("serialize", "(value)", function(state, value) return ast.String:new(value:serialize(state)) end, true)
	state:define("deserialize", "(str::string)", function(state, str) return ast.abstract.Node:deserialize(state, str.string) end, true)

	local run_state = state:branch()

	local f = assert(io.open(path, "r"))
	local s, block = pcall(anselme.parse, f:read("a"), path)
	f:close()

	if not s then
		write_output("--# parse error #--")
		write_output(tostring(block))
		return table.concat(out, "\n")
	end

	run_state:run(block)

	run_loop(run_state, write_output, interactive)

	if state:defined("post run check") then
		local post_run_state = state:branch()
		post_run_state:run("post run check!")

		write_output("--# post run check #--")
		run_loop(post_run_state, write_output, interactive)
	end

	write_output("--# saved #--")
	write_output(persistent_manager:get_struct(state):format(state))

	return table.concat(out, "\n")
end

-- run!
if not arg[1] or arg[1] == "update" then
	-- display an animated loading indicator
	local loading = {
		loop = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
		loop_pos = 1,
		erase_code = "",

		write = function(self, message)
			self:clear()
			local str = self.loop[self.loop_pos].." "..message
			self.erase_code = ("\b \b"):rep(#str)
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
	local lfs = require("lfs")
	local tests = {}
	for test in lfs.dir("test/tests/") do
		if test:match("%.ans$") then
			table.insert(tests, "test/tests/"..test)
		end
	end

	local total, failure, errored, notfound = #tests, 0, 0, 0

	-- run tests
	for i, test in ipairs(tests) do
		-- status
		loading:write(("%s/%s tests ran; running %s"):format(i, #tests, test))
		if i % 10 == 0 then loading:update() end

		repeat
			local rerun = false

			-- load result
			local f = io.open(test:gsub("^test/tests/", "test/results/"), "r")
			local expected
			if f then
				expected = f:read("a")
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
					local code = c:read("a")
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
						r = io.read("l"):lower()
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
	end

	loading:clear()
	print("#### Results ####")
	local successes = total-failure-notfound-errored
	print(("%s successes, %s failures, %s errors, %s missing result files, out of %s tests"):format(successes, failure, errored, notfound, total))
	if successes < total then os.exit(1) end
elseif arg[1] == "interactive" and arg[2] then
	run(tostring(arg[2]), true)
else
	print("usage:")
	print("lua test/run.lua: run all the tests")
	print("lua test/run.lua update: run all tests, optionally updating incorrect or missing results")
	print("lua test/run.lua interactive <script>: run the file <script> in interactive mode")
	print("lua test/run.lua help: display this message")
end
