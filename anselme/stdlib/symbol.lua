--- # Symbols
-- @titlelevel 3

return {
	{
		--- Return a string of the symbol name.
		"to string", "(symbol::is symbol)",
		function(state, sym)
			return sym:to_string()
		end
	},
}
