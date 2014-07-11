--[[
	Copyright (c) 2014 Remko Tronçon
	Licensed under the GNU General Public License v3.
	See LICENSE for more information.
--]]

swiftob.register_command({
	name = 'quit',
	allowed_role = 'owner',
	description = 'Quit the bot',
	callback = swiftob.quit
})

swiftob.register_command({
	name = 'restart',
	allowed_role = 'owner',
	description = 'Restart bot',
	callback = swiftob.restart
})

swiftob.register_command({
	name = 'rehash',
	allowed_role = 'owner',
	description = 'Reload scripts',
	callback = swiftob.reload
})


swiftob.register_command({
	name = 'help',
	description = 'Get help',
	callback = function(command, parameters, message)
		swiftob.reply_to(
			message, 
			swiftob.command_descriptions_for_jid(message['from']),
			message['type'] == 'groupchat')
	end
})

swiftob.register_command({
	name = 'join',
	allowed_role = 'owner',
	description = 'Join a MUC',
	callback = function()
		-- TODO
	end
})

swiftob.register_command({
	name = 'part',
	allowed_role = 'owner',
	description = 'Leave a MUC',
	callback = function()
		-- TODO
	end
})

swiftob.register_command({
	name = 'nick',
	allowed_role = 'owner',
	description = 'Change nick (requires restart)',
	callback = function()
		-- TODO
	end
})
