local resumable_manager = require("state.resumable_manager")

return {
	{
		"new checkpoint", "(level::number=0)",
		function(state, level)
			return resumable_manager:capture(state, level.number)
		end
	}
}
