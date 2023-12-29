--- transform a tree of lines into raw AST

local tree_to_block

local ast = require("anselme.ast")
local Block, Flush, PartialScope

local expression_to_ast = require("anselme.parser.expression.to_ast")

-- wrapper for expression_to_ast to check that there is no crap remaining after the expression has been parsed
-- return AST
local function expect_end(exp, rem)
	if rem:match("[^%s]") then
		error(("expected end of expression before %q"):format(rem))
	end
	return exp
end
local function expect_end_block(exp, rem)
	if rem:match("[^%s]") and not rem:match("^ ?_$") then
		error(("expected end of expression before %q"):format(rem))
	end
	return exp
end

-- return AST
local function line_to_expression(content, tree)
	if #tree > 0 then
		local child_block = tree_to_block(tree)
		return PartialScope:attach_block(expect_end_block(expression_to_ast(tree.source:clone(), content.." _", " _$")), child_block):set_source(tree.source)
	else
		return expect_end(expression_to_ast(tree.source:clone(), content, nil, nil, nil, Flush:new())):set_source(tree.source)
	end
end

-- return AST (Block)
tree_to_block = function(tree)
	local block = Block:new()

	for _, l in ipairs(tree) do
		local s, expression = pcall(line_to_expression, l.content, l)
		if not s then error(("%s; at %s"):format(expression, l.source), 0) end

		block:add(expression)
	end

	return block
end

package.loaded[...] = tree_to_block
Block, Flush, PartialScope = ast.Block, ast.Flush, ast.PartialScope

return tree_to_block
