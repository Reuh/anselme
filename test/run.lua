local lfs = require("lfs")
local anselme = require("anselme")
local ser = require("test.ser")
local inspect = require("test.inspect")

local function format_text(t, prefix)
	prefix = prefix or " "
	local r = ""
	for _, l in ipairs(t) do
		r = r .. prefix
		local tags = ""
		for k, v in pairs(l.tags) do
			tags = tags .. ("[%q]=%q"):format(k, v)
		end
		if tags ~= "" then
			r = r .. ("[%s]%s"):format(tags, l.data)
		else
			r = r .. l.data
		end
	end
	return r
end

local function compare(a, b)
	if type(a) == "table" and type(b) == "table" then
		for k, v in pairs(a) do
			if not compare(v, b[k]) then
				return false
			end
		end
		for k, v in pairs(b) do
			if not compare(v, a[k]) then
				return false
			end
		end
		return true
	else
		return a == b
	end
end

local function write_result(filebase, result)
	local o = assert(io.open(filebase..".lua", "w"))
	o:write(ser(result))
	o:write("\n--[[\n")
	for _, v in ipairs(result) do
		o:write(inspect(v).."\n")
	end
	o:write("]]--")
	o:close()
end

-- parse args
local args = {}
local i=1
while i <= #arg do
	if arg[i+1] and not arg[i+1]:match("^%-%-") then
		args[arg[i]:gsub("^%-%-", "")] = arg[i+1]
		i = i + 2
	else
		args[arg[i]:gsub("^%-%-", "")] = true
		i = i + 1
	end
end

-- list tests
local files = {}
for item in lfs.dir("test/tests/") do
	if item:match("%.ans$") and item:match(args.filter or "") then
		table.insert(files, "test/tests/"..item)
	end
end
table.sort(files)

-- test script
if args.script then
	local vm = anselme()
	local state, err = vm:loadfile(args.script, "script")
	if state then
		local istate, e = vm:run("script")
		if not istate then
			print("error", e)
		else
			repeat
				local t, d = istate:step()
				if t == "text" then
					print(format_text(d))
				elseif t == "choice" then
					print(format_text(d, "\n> "))
					istate:choose(io.read())
				elseif t == "error" then
					print(t, d)
				else
					print(t, inspect(d))
				end
			until t == "return" or t == "error"
		end
		if args.save then
			print(inspect(vm:save()))
		end
	else
		print("error", err)
	end
-- run tests
else
	local total, success = #files, 0
	for _, file in ipairs(files) do
		local filebase = file:match("^(.*)%.ans$")
		local namespace = filebase:match("([^/]*)$")
		math.randomseed(0)
		local vm = anselme()
		vm:setaliases("seen", "checkpoint", "reached")
		vm:loadfunction {
			-- custom event test
			["wait(time::number)"] = {
				value = function(duration)
					coroutine.yield("wait", duration)
				end
			},
			-- run another function in parallel
			["run(name::string)"] = {
				value = function(str)
					local istate, e = anselme.running.vm:run(str, anselme.running:current_namespace())
					if not istate then coroutine.yield("error", e) end
					local event, data = istate:step()
					coroutine.yield(event, data)
				end
			},
			-- manual choice
			["choose(choice::number)"] = {
				value = function(c)
					anselme.running:choose(c)
				end
			},
			-- manual interrupt
			["interrupt(name::string)"] = {
				value = function(str)
					anselme.running:interrupt(str)
					coroutine.yield("wait", 0)
				end
			},
			["interrupt()"] = {
				value = function()
					anselme.running:interrupt()
					coroutine.yield("wait", 0)
				end
			}
		}
		local state, err = vm:loadfile(file, namespace)

		local result = {}
		if state then
			local istate, e = vm:run(namespace)
			if not istate then
				table.insert(result, { "error", e })
			else
				repeat
					local t, d = istate:step()
					table.insert(result, { t, d })
				until t == "return" or t == "error"
			end
		else
			table.insert(result, { "error", err })
		end

		if args["write-all"] then
			write_result(filebase, result)
		else
			local o, e = loadfile(filebase..".lua")
			if o then
				local output = o()
				if not compare(result, output) then
					if not args.silent then
						print("> "..namespace)
						print(inspect(result))
						print("is not equal to")
						print(inspect(output))
						print("")
					end
				else
					success = success + 1
				end
			else
				if args["write-new"] and e:match("No such file") then
					write_result(filebase, result)
					print("Written result file for "..filebase)
					success = success + 1
				elseif not args.silent then
					print("> "..namespace)
					print(e)
					print("result was:")
					print(inspect(result))
					print("")
				end
			end
		end
	end
	if args.write then
		print("Wrote test results.")
	else
		print(("%s/%s tests success."):format(success, total))
	end
end
