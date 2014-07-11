--[[
	Copyright (c) 2011-2014 Kevin Smith
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

local function echo_message(command, params, message)
	swiftob.reply_to(message, params)
end

swiftob.register_command{
	name = "echo",
	description = "What did you say?",
	callback = echo_message
}
