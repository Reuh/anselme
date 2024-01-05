return {

	{
		"to string", "(symbol::symbol)",
		function(state, sym)
			return sym:to_string()
		end
	},
}
