local primary = require("anselme.parser.expression.primary.primary")
local value_check = require("anselme.parser.expression.secondary.infix.value_check")

local identifier = require("anselme.parser.expression.primary.identifier")

local ast = require("anselme.ast")
local Nil = ast.Nil

return primary {
	match = function(self, str)
		if str:match("^%::?&?@?") then
			return identifier:match(str:match("^%::?&?@?(.-)$"))
		end
		return false
	end,

	parse = function(self, source, options, str)
		local mod_const, mod_alias, mod_export, rem = source:consume(str:match("^(%:(:?)(&?)(@?))(.-)$"))
		local constant, alias, value_check_exp, exported

		-- get modifier
		if mod_const == ":" then constant = true end
		if mod_alias == "&" then alias = true end
		if mod_export == "@" then exported = true end

		-- name
		local ident
		ident, rem = identifier:parse(source, options, rem)

		-- value check
		local nil_val = Nil:new()
		if value_check:match(rem, 0, nil_val) then
			local exp
			exp, rem = value_check:parse(source, options, rem, 0, nil_val)
			value_check_exp = exp.arguments.positional[2]
		end

		return ident:to_symbol{ constant = constant, alias = alias, exported = exported, value_check = value_check_exp }:set_source(source), rem
	end
}
