local primary = require("anselme.parser.expression.primary.primary")
local type_check = require("anselme.parser.expression.secondary.infix.type_check")

local identifier = require("anselme.parser.expression.primary.identifier")

local ast = require("anselme.ast")
local Nil = ast.Nil

return primary {
	match = function(self, str)
		if str:match("^%::?[&@]?") then
			return identifier:match(str:match("^%::?[&@]?(.-)$"))
		end
		return false
	end,

	parse = function(self, source, str)
		local mod_const, mod_export, rem = source:consume(str:match("^(%:(:?)([&@]?))(.-)$"))
		local constant, alias, type_check_exp, exported

		-- get modifier
		if mod_const == ":" then constant = true end
		if mod_export == "&" then alias = true
		elseif mod_export == "@" then exported = true end

		-- name
		local ident
		ident, rem = identifier:parse(source, rem)

		-- type check
		local nil_val = Nil:new()
		if type_check:match(rem, 0, nil_val) then
			local exp
			exp, rem = type_check:parse(source, rem, nil, 0, nil_val)
			type_check_exp = exp.arguments.positional[2]
		end

		return ident:to_symbol{ constant = constant, alias = alias, exported = exported, type_check = type_check_exp }:set_source(source), rem
	end
}
