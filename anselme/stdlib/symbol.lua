return {

	{
		"to string", "(symbol::is symbol)",
		function(state, sym)
			return sym:to_string()
		end
	},
}
