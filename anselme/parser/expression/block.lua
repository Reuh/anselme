local expression_to_ast = require("anselme.parser.expression.to_ast")

local ast = require("anselme.ast")
local PartialScope, Block, Call, Identifier = ast.PartialScope, ast.Block, ast.Call, ast.Identifier

local function block(source, options, str)
	local start_source = source:clone()

	if not str:match("^\n") then
		str = "\n"..str
		source:increment_line(-1)
	end

	local levels = { { indentation = utf8.len(str:match("^\n([ \t]*)")), block = Block:new() } }
	local current_level = levels[#levels]

	local rem = str
	while rem:match("^\n") do
		local line = source:consume(rem:match("^(\n)(.*)$"))
		local new_indentation = utf8.len(line:match("^([ \t]*)"))
		-- indentation of empty line is determined using the next line
		-- (consecutive empty lines are merged into one)
		if line:match("^\n") then
			rem = line
		elseif line:match("[^%s]") then
			-- raise indentation
			if new_indentation > current_level.indentation then
				local child_block = Block:new()
				local cur_exps = current_level.block.expressions
				cur_exps[#cur_exps] = PartialScope:attach_block(cur_exps[#cur_exps], child_block):set_source(source)
				table.insert(levels, { indentation = new_indentation, block = child_block })
				current_level = levels[#levels]
			-- lower indentation
			elseif new_indentation < current_level.indentation then
				while new_indentation < current_level.indentation do
					table.remove(levels)
					current_level = levels[#levels]
				end
				if new_indentation ~= current_level.indentation then
					error(("invalid indentation; at %s"):format(source))
				end
			end

			-- parse line
			local s, exp
			s, exp, rem = pcall(expression_to_ast, source, options, line)
			if not s then error(("invalid expression in block: %s"):format(exp), 0) end

			-- single implicit _: line was effectively empty (e.g. single comment in the line)
			if Call:is(exp) and not exp.explicit and Identifier:is(exp.func) and exp.func.name == "_" then
				-- skip, empty line
			else
				-- add line
				current_level.block:add(exp)
			end
		else -- end-of-file
			rem = ""
		end
	end

	return levels[1].block:set_source(start_source), rem
end

return block
