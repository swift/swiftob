--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

-- Create a default environment for use by the scripts.
-- This copies everything from the global environment that we want to
-- expose.
local function new_environment()
	local members = {
		-- Variables
		"_VERSION",

		-- Modules
		"string",
		"package",
		"os",
		"io",
		"math",
		"debug",
		"table",
		"coroutine",

		-- Functions
		"xpcall",
		"tostring",
		"print",
		"unpack",
		"require",
		"getfenv",
		"setmetatable",
		"next",
		"assert",
		"tonumber",
		"rawequal",
		"collectgarbage",
		"getmetatable",
		"module",
		"rawset",
		"pcall",
		"newproxy",
		"type",
		"select",
		"gcinfo",
		"pairs",
		"rawget",
		"loadstring",
		"ipairs",
		"dofile",
		"setfenv",
		"load",
		"error",
		"loadfile",
	}
	local env = {}
	for _, member in pairs(members) do
		env[member] = _G[member]
	end
	env._G = env

	return env
end

return { new_environment = new_environment }
