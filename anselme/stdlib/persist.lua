--- # Persistence helpers
--
-- Theses functions store and retrieve data from persistent storage.
-- Persistent storage is a key-value store intended to be saved and loaded alongside the host game's save files.
-- See the [relatied Lua API methods](api.md#saving_and_loading_persistent_variables) for how to retrieve and load the persistent data.
--
-- A persistent value can be accessed like a regular variable using aliases and the warp operator:
-- ```
-- :&var => persist("name", "Hero") // persistent value with key "name" and default value "Hero"
-- print(var) // gets persistent value "name": "Hero"
-- var = "Link" // sets persistent value "name" to "Link"
-- ```
-- @titlelevel 3

local ast = require("anselme.ast")
local Nil = ast.Nil

local persistent_manager = require("anselme.state.persistent_manager")

return {
	{
		--- Returns the value associated with the key `key` in persistent storage.
		-- If the key is not defined, returns `default`.
		"persist", "(key, default)",
		function(state, key, default)
			return persistent_manager:get(state, key, default)
		end
	},
	{
		--- Sets the value associated with the key `key` in persistent storage to `value`.
		"persist", "(key, default) = value",
		function(state, key, default, value)
			persistent_manager:set(state, key, value)
			return Nil:new()
		end
	},
	{
		--- Returns the value associated with the key `key` in persistent storage.
		-- If the key is not defined, raise an error.
		"persist", "(key)",
		function(state, key)
			return persistent_manager:get(state, key)
		end
	},
	{
		--- Sets the value associated with the key `key` in persistent storage to `value`.
		"persist", "(key) = value",
		function(state, key, value)
			persistent_manager:set(state, key, value)
			return Nil:new()
		end
	},
}
