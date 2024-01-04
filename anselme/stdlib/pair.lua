return {
	{
		"name", "(pair::pair)",
		function(state, pair)
			return pair.name
		end
	},
	{
		"value", "(pair::pair)",
		function(state, pair)
			return pair.value
		end
	},
}
