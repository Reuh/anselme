local code_to_tree = require("parser.code_to_tree")
local tree_to_ast = require("parser.tree_to_ast")

-- parse code (string) with the associated source (Source)
-- the returned AST tree is stateless and can be stored/evaluated/etc as you please
return function(code, source)
	local tree = code_to_tree(code, source)
	local block = tree_to_ast(tree)

	block:prepare()

	return block
end
