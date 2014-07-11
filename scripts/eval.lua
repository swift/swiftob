--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local debug = require('debug')

local function eval(command, params, message)
	local chunk, err = loadstring(params)
	if not chunk then
		swiftob.reply_to(message, err)
	else
		local result = { xpcall(chunk, function(e) return debug.traceback(e) end) }
		if result[2] then
			swiftob.reply_to(message, result[2])
		else
			swiftob.reply_to(message, "Done")
		end
	end
end

swiftob.register_command{
	name = "eval", 
	description = "Evaluate an expression",
	allowed_role = "owner", 
	callback = eval
}
