local class = require("anselme.lib.class")

local ast = require("anselme.ast")
local Table, Identifier, Translatable

local translations_identifier, translations_symbol

local translation_manager = class {
	init = false,

	setup = function(self, state)
		state.scope:define(translations_symbol, Table:new(state))
	end,

	-- context is the context Struct - when translating, the translation will only be used for nodes that at least match this context
	-- original is the original node (non-evaluated)
	-- translated is the translated node (non-evaluated)
	set = function(self, state, context, original, translated)
		local translations = state.scope:get(translations_identifier)
		if not translations:has(state, original) then
			translations:set(state, original, Table:new(state))
		end
		local tr = translations:get(state, original)
		return tr:set(state, context, translated)
	end,

	-- context is the context Struct of the calling translation
	-- original is the original node to translate (non-evaluated)
	-- returns the (evaluated) translated node, or the original node if no translation defined
	eval = function(self, state, context, original)
		local translations = state.scope:get(translations_identifier)
		if translations:has(state, original) then
			local tr = translations:get(state, original)

			-- find most specific translation
			local translated, specificity = nil, -1
			for match_context, match_translated in tr:iter(state) do
				local matched, match_specificity = true, 0
				for key, val in match_context:iter() do
					if context:has(key) and val:hash() == context:get(key):hash() then
						match_specificity = match_specificity + 1
					else
						matched = false
						break
					end
				end
				if matched then
					if match_specificity > specificity then
						translated, specificity = match_translated, match_specificity
					elseif match_specificity == specificity then
						print("a a dà é payé")
					end
				end
			end

			-- found, evaluate translated
			if translated then
				-- eval in a scope where all active translations, as translating the translation would be stupid
				state.scope:push_partial(translations_identifier)
				state.scope:define(translations_symbol, Table:new(state))
				local r = translated:eval(state)
				state.scope:pop()
				return r
			end
		end

		-- no matching translation
		if Translatable:is(original) then
			return original.expression:eval(state)
		else
			return original:eval(state)
		end
	end,
}

package.loaded[...] = translation_manager
Table, Identifier, Translatable = ast.Table, ast.Identifier, ast.Translatable

translations_identifier = Identifier:new("_translations") -- Table of { Translatable = Table{ Struct context = translated node, ... }, ... }
translations_symbol = translations_identifier:to_symbol()

return translation_manager
